import Foundation
import Testing
@testable import InputRelay

struct MappingInputCaptureTests {
    private func event(_ button: GamepadButton, _ pressed: Bool = true) -> GamepadEvent {
        GamepadEvent(button: button, value: pressed ? 1 : 0, timestamp: 1)
    }

    @Test func waitsForFreshPressAndIgnoresStickDirections() {
        var capture = MappingInputCapture()
        capture.begin(heldButtons: [.buttonA])
        capture.receive(event(.buttonA))
        capture.receive(event(.leftStickUp))
        capture.receive(event(.buttonB, false))
        #expect(capture.selectedButton == nil)
        #expect(capture.isWaiting)
        capture.receive(event(.buttonA, false))
        capture.receive(event(.buttonA))
        #expect(capture.selectedButton == .buttonA)
        #expect(!capture.isWaiting)
        capture.receive(event(.buttonB))
        #expect(capture.selectedButton == .buttonA)
    }

    @Test func canRecaptureOrChooseManually() {
        var capture = MappingInputCapture(selectedButton: .buttonA)
        capture.begin(heldButtons: [])
        capture.receive(event(.rightTrigger))
        #expect(capture.selectedButton == .rightTrigger)
        capture.begin(heldButtons: [])
        capture.stop()
        capture.receive(event(.buttonB))
        #expect(capture.selectedButton == .rightTrigger)
        capture.select(.leftShoulder)
        #expect(capture.selectedButton == .leftShoulder)
        #expect(!capture.isWaiting)
    }

    @Test func duplicateRequiresExplicitReplacementIncludingDisabledBindings() {
        let original = ButtonMapping(button: .buttonA, action: .mouseAction(.leftClick))
        let disabledDuplicate = ButtonMapping(button: .buttonA, action: .mouseAction(.middleClick), enabled: false)
        let other = ButtonMapping(button: .buttonB, action: .mouseAction(.rightClick))
        var profile = Profile(name: "Test", mappings: [original, disabledDuplicate, other])
        let newMapping = ButtonMapping(button: .buttonA, action: .mouseAction(.scrollUp))
        #expect(profile.mappingConflicts(for: .buttonA, excluding: nil).count == 2)
        let rejected = profile.storeMapping(newMapping)
        #expect(!rejected)
        #expect(profile.mappings.map(\.id) == [original.id, disabledDuplicate.id, other.id])
        let replaced = profile.storeMapping(newMapping, replacingConflicts: true)
        #expect(replaced)
        #expect(profile.mappings.map(\.id) == [newMapping.id, other.id])
        #expect(profile.mappings.first?.action == .mouseAction(.scrollUp))
    }

    @Test func editingSelfIsAllowedAndRebindingRemovesBothOldAndConflictingEntry() {
        let a = ButtonMapping(button: .buttonA, action: .mouseAction(.leftClick))
        let b = ButtonMapping(button: .buttonB, action: .mouseAction(.rightClick))
        var profile = Profile(name: "Test", mappings: [a, b])
        #expect(profile.mappingConflicts(for: .buttonA, excluding: a.id).isEmpty)
        let edited = profile.storeMapping(a)
        #expect(edited)
        let rebound = ButtonMapping(id: a.id, button: .buttonB, action: .mouseAction(.scrollDown))
        let rejected = profile.storeMapping(rebound)
        #expect(!rejected)
        let reboundSaved = profile.storeMapping(rebound, replacingConflicts: true)
        #expect(reboundSaved)
        #expect(profile.mappings.count == 1)
        #expect(profile.mappings.first?.id == a.id)
        #expect(profile.mappings.first?.button == .buttonB)
    }

    @Test func sameActionOnDifferentButtonsDoesNotConflict() {
        let a = ButtonMapping(button: .buttonA, action: .mouseAction(.leftClick))
        let b = ButtonMapping(button: .buttonB, action: a.action)
        var profile = Profile(name: "Test", mappings: [a])
        let saved = profile.storeMapping(b)
        #expect(saved)
        #expect(profile.mappings.count == 2)
    }
}
