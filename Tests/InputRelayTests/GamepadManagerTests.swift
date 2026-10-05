import Combine
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

    @Test func triggerNoiseNearPressThresholdDoesNotRepeatClicks() {
        let (manager, pad) = fixture()
        var events: [GamepadEvent] = []
        manager.setEventHandler { events.append($0) }
        let triggers: [(GamepadButton, GCControllerButtonInput)] = [
            (.leftTrigger, pad.leftTrigger), (.rightTrigger, pad.rightTrigger)
        ]
        for (button, input) in triggers {
            for value: Float in [0.48, 0.53, 0.49, 0.56, 1, 0.48, 0.52, 0.3] {
                input.setValue(value)
                manager.sampleInput()
            }
            let presses = events.filter { $0.button == button && $0.isPressed }
            #expect(presses.count == 1)
            #expect(events.filter { $0.button == button && !$0.isPressed }.isEmpty)
            // 原始模拟值仍更新，状态页面可以展示实际扳机行程。
            #expect(abs(manager.getButtonState(button) - 0.3) < 0.0001)
            input.setValue(0.1)
            manager.sampleInput()
            #expect(events.filter { $0.button == button && !$0.isPressed }.count == 1)
        }
    }

    @Test func triggerReleaseRearmsWithoutDelayingConsecutivePresses() {
        let (manager, pad) = fixture()
        var events: [GamepadEvent] = []
        manager.setEventHandler { events.append($0) }
        for input in [pad.leftTrigger, pad.rightTrigger] {
            for value: Float in [0.5, 0.51, 0.21, 0.49, 0.55, 0.2, 0.21, 0.19, 0.5, 0.51, 0] {
                input.setValue(value)
                manager.sampleInput()
            }
        }
        for button in [GamepadButton.leftTrigger, .rightTrigger] {
            #expect(events.filter { $0.button == button }.map(\.isPressed) == [true, false, true, false])
        }
    }

    @Test func disconnectReleasesLatchedTriggersBeforeControllerSwitch() {
        let first = GCController.withExtendedGamepad()
        let second = GCController.withExtendedGamepad()
        var available = [first]
        let manager = GamepadManager(controllers: { available })
        var events: [GamepadEvent] = []
        manager.setEventHandler { events.append($0) }
        manager.refreshControllers()
        for value: Float in [0.8, 0.3] {
            first.extendedGamepad!.leftTrigger.setValue(value)
            first.extendedGamepad!.rightTrigger.setValue(value)
            manager.sampleInput()
        }
        available = []
        manager.refreshControllers()
        #expect(!manager.isConnected)
        available = [second]
        manager.refreshControllers()
        second.extendedGamepad!.leftTrigger.setValue(0.8)
        second.extendedGamepad!.rightTrigger.setValue(0.8)
        manager.sampleInput()
        for button in [GamepadButton.leftTrigger, .rightTrigger] {
            #expect(events.filter { $0.button == button }.map(\.isPressed) == [true, false, true])
        }
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
        manager.setStickHandler { _ in ticks += 1 }
        manager.setEventHandler { if $0.button == .buttonA && $0.isPressed { presses += 1 } }
        pad.buttonA.setValue(1)
        pad.leftThumbstick.setValueForXAxis(1, yAxis: 0)
        for _ in 0..<5 { manager.sampleInput() }
        #expect(ticks == 5)
        #expect(presses == 1)
    }

    @Test func stickTimingUsesElapsedTimeAndIgnoresDeviceCallbacks() {
        let (manager, _) = fixture()
        var intervals: [TimeInterval] = []
        manager.setStickHandler { intervals.append($0) }
        manager.sampleInput(timestamp: 10)
        manager.sampleInput(advanceSticks: false, timestamp: 10.004)
        manager.sampleInput(timestamp: 10.01)
        manager.isCapturingInput = true
        manager.sampleInput(timestamp: 10.02)
        manager.isCapturingInput = false
        manager.sampleInput(timestamp: 10.03)
        manager.sampleInput(timestamp: 20)
        #expect(intervals.count == 4)
        #expect(abs(intervals[1] - 0.01) < 0.000001)
        #expect(abs(intervals[2] - 0.01) < 0.000001)
        #expect(intervals[3] <= 1.0 / 30.0)
    }

    @Test func motionClockOnlyRunsForUsableStickInput() {
        let (manager, pad) = fixture()
        manager.motionEnabled = true
        #expect(!manager.isMotionTimerRunning)
        pad.leftThumbstick.setValueForXAxis(0.05, yAxis: 0)
        manager.sampleInput(advanceSticks: false)
        #expect(!manager.isMotionTimerRunning)
        pad.leftThumbstick.setValueForXAxis(0.8, yAxis: 0)
        manager.sampleInput(advanceSticks: false)
        #expect(manager.isMotionTimerRunning)
        manager.isCapturingInput = true
        #expect(!manager.isMotionTimerRunning)
        manager.isCapturingInput = false
        #expect(manager.isMotionTimerRunning)
        manager.motionEnabled = false
        #expect(!manager.isMotionTimerRunning)
        manager.motionEnabled = true
        manager.motionSettings = StickSettings(leftStickMode: .disabled, rightStickMode: .disabled)
        #expect(!manager.isMotionTimerRunning)
        manager.motionSettings = StickSettings(leftStickMode: .scroll, rightStickMode: .disabled)
        #expect(!manager.isMotionTimerRunning) // Horizontal movement cannot scroll vertically.
        pad.leftThumbstick.setValueForXAxis(0, yAxis: 0.8)
        manager.sampleInput(advanceSticks: false)
        #expect(manager.isMotionTimerRunning)
        pad.leftThumbstick.setValueForXAxis(0, yAxis: 0)
        manager.sampleInput(advanceSticks: false)
        #expect(!manager.isMotionTimerRunning)
    }

    @Test func outputTicksUseCacheWithoutBroadcastingUIChanges() {
        let (manager, pad) = fixture()
        var notifications = 0
        let observation = manager.objectWillChange.sink { notifications += 1 }
        defer { observation.cancel() }
        pad.leftThumbstick.setValueForXAxis(0.8, yAxis: 0)
        manager.sampleInput(advanceSticks: false)
        manager.displayState.refresh(from: manager)
        let cached = manager.leftStick
        pad.valueChangedHandler = nil
        pad.leftThumbstick.setValueForXAxis(0, yAxis: 0)
        var ticks = 0
        manager.setStickHandler { _ in ticks += 1 }
        for i in 0..<120 { manager.advanceMotion(timestamp: Double(i) / 120) }
        #expect(ticks == 120)
        #expect(manager.leftStick == cached)
        #expect(manager.displayState.leftStick == cached)
        #expect(notifications == 0)
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
