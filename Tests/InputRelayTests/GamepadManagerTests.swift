import Foundation
import GameController
import Testing
@testable import InputRelay

@MainActor
struct GamepadManagerTests {
    private func fixture() -> (GamepadManager, GCExtendedGamepad) {
        let controller = GCController.withExtendedGamepad()
        let manager = GamepadManager(controllers: { [controller] })
        manager.refreshControllers()
        return (manager, controller.extendedGamepad!)
    }

    @Test func xboxButtonsKeepTheirPositions() {
        let (manager, pad) = fixture()
        let inputs: [(GamepadButton, GCControllerButtonInput)] = [
            (.buttonA, pad.buttonA), (.buttonB, pad.buttonB),
            (.buttonX, pad.buttonX), (.buttonY, pad.buttonY),
            (.leftShoulder, pad.leftShoulder), (.rightShoulder, pad.rightShoulder),
            (.startButton, pad.buttonMenu)
        ]
        for (button, input) in inputs {
            input.setValue(1)
            manager.sampleInput()
            #expect(manager.lastEvent?.button == button)
            #expect(manager.getButtonState(button) == 1)
            input.setValue(0)
            manager.sampleInput()
            #expect(manager.lastEvent?.button == button)
            #expect(manager.lastEvent?.isPressed == false)
        }
    }

    @Test func dpadDiagonalAndRelease() {
        let (manager, pad) = fixture()
        var events: [GamepadEvent] = []
        manager.setEventHandler { events.append($0) }
        pad.dpad.setValueForXAxis(1, yAxis: 1)
        manager.sampleInput()
        #expect(manager.getButtonState(.dpadUp) == 1)
        #expect(manager.getButtonState(.dpadRight) == 1)
        pad.dpad.setValueForXAxis(0, yAxis: 0)
        manager.sampleInput()
        #expect(manager.getButtonState(.dpadUp) == 0)
        #expect(manager.getButtonState(.dpadRight) == 0)
        #expect(events.filter { !$0.isPressed }.count == 2)
    }

    @Test func triggersAreIndependentAndFireOncePerPress() {
        let (manager, pad) = fixture()
        var events: [GamepadEvent] = []
        manager.setEventHandler { events.append($0) }
        for value: Float in [0.1, 0.4, 0.6, 0.8, 1, 0.7, 0.2, 0] {
            pad.leftTrigger.setValue(value)
            manager.sampleInput()
        }
        #expect(events.filter { $0.button == .leftTrigger && $0.isPressed }.count == 1)
        #expect(events.filter { $0.button == .leftTrigger && !$0.isPressed }.count == 1)
        pad.rightTrigger.setValue(1)
        manager.sampleInput()
        #expect(manager.getButtonState(.leftTrigger) == 0)
        #expect(manager.getButtonState(.rightTrigger) == 1)
        #expect(manager.getStickAxes(isLeft: false).x == 0)
    }

    @Test func sticksReturnToCenterAndKeepUpPositive() {
        let (manager, pad) = fixture()
        pad.leftThumbstick.setValueForXAxis(-0.8, yAxis: 0.9)
        pad.rightThumbstick.setValueForXAxis(0.7, yAxis: -0.6)
        manager.sampleInput()
        #expect(manager.getStickAxes(isLeft: true).x < 0)
        #expect(manager.getStickAxes(isLeft: true).y > 0)
        #expect(manager.getButtonState(.leftStickUp) > 0.5)
        #expect(manager.getButtonState(.rightStickDown) > 0.5)
        pad.leftThumbstick.setValueForXAxis(0, yAxis: 0)
        pad.rightThumbstick.setValueForXAxis(0, yAxis: 0)
        manager.sampleInput()
        #expect(manager.getStickAxes(isLeft: true).y == 0)
        #expect(manager.getButtonState(.leftStickUp) == 0)
        #expect(manager.getButtonState(.rightStickDown) == 0)
    }

    @Test func heldStickKeepsTickingWithoutRepeatingButtonActions() {
        let (manager, pad) = fixture()
        var ticks = 0
        var presses = 0
        manager.setStickHandler { ticks += 1 }
        manager.setEventHandler { if $0.button == .buttonA && $0.isPressed { presses += 1 } }
        pad.buttonA.setValue(1)
        pad.leftThumbstick.setValueForXAxis(1, yAxis: 0)
        for _ in 0..<5 { manager.sampleInput() }
        #expect(ticks == 5)
        #expect(presses == 1)
    }

    @Test func captureDoesNotReplaceMappingHandler() {
        let (manager, pad) = fixture()
        var presses = 0
        manager.setEventHandler { if $0.isPressed { presses += 1 } }
        manager.isCapturingInput = true
        pad.buttonA.setValue(1)
        manager.sampleInput()
        #expect(manager.lastEvent?.button == .buttonA)
        #expect(presses == 0)
        pad.buttonA.setValue(0)
        manager.sampleInput()
        manager.isCapturingInput = false
        pad.buttonB.setValue(1)
        manager.sampleInput()
        #expect(presses == 1)
    }

    @Test func disconnectClearsStateAndSelectsRemainingController() {
        let first = GCController.withExtendedGamepad()
        let second = GCController.withExtendedGamepad()
        var available = [first, second]
        let manager = GamepadManager(controllers: { available })
        manager.refreshControllers()
        first.extendedGamepad!.buttonA.setValue(1)
        first.extendedGamepad!.leftThumbstick.setValueForXAxis(1, yAxis: 1)
        manager.sampleInput()
        available = [second]
        manager.refreshControllers()
        #expect(manager.isConnected)
        #expect(manager.getButtonState(.buttonA) == 0)
        #expect(manager.getStickAxes(isLeft: true).x == 0)
        second.extendedGamepad!.buttonB.setValue(1)
        manager.sampleInput()
        #expect(manager.getButtonState(.buttonB) == 1)
        available = []
        manager.refreshControllers()
        #expect(!manager.isConnected)
        #expect(manager.getButtonState(.buttonB) == 0)
        #expect(manager.lastEvent == nil)
    }

    @Test func legacyMappingsDecodeWithXboxLabels() throws {
        let buttons = try JSONDecoder().decode([GamepadButton].self,
            from: Data(#"["L1","R1","L2","R2","L3","R3","Select","Start","Home"]"#.utf8))
        #expect(buttons.map(\.displayName) == ["LB", "RB", "LT", "RT", "LS", "RS", "View", "Menu", "Xbox"])
        let roundTrip = try JSONDecoder().decode([GamepadButton].self, from: JSONEncoder().encode(buttons))
        #expect(roundTrip == buttons)
    }
}
