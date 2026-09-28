import AppKit
import Carbon
import Testing
@testable import InputRelay

private func keyEvent(_ type: NSEvent.EventType, _ code: Int, flags: NSEvent.ModifierFlags = [],
                      repeatKey: Bool = false, window: Int = 0) -> NSEvent {
    NSEvent.keyEvent(with: type, location: .zero, modifierFlags: flags, timestamp: 0,
                    windowNumber: window, context: nil, characters: "", charactersIgnoringModifiers: "",
                    isARepeat: repeatKey, keyCode: UInt16(code))!
}

struct KeyboardShortcutTests {
    @Test func oldAndNewMappingsRoundTripWithCorrectNames() throws {
        let legacy = try JSONDecoder().decode(KeyboardShortcut.self,
            from: Data(#"{"keyCode":13,"modifiers":1}"#.utf8))
        #expect(legacy.displayString == "⌘W")
        let shortcuts = [legacy, KeyboardShortcut(keyCodes: [kVK_ANSI_A, kVK_ANSI_S], modifiers: [.shift, .control]),
                         KeyboardShortcut(keyCodes: [], modifiers: .option)]
        for shortcut in shortcuts {
            let encoded = try JSONEncoder().encode(shortcut)
            #expect(try JSONDecoder().decode(KeyboardShortcut.self, from: encoded) == shortcut)
        }
        #expect(KeyboardShortcut.keyName(kVK_ANSI_B) == "B")
        #expect(KeyboardShortcut.keyName(kVK_ANSI_1) == "1")
        #expect(KeyboardShortcut.keyName(kVK_ANSI_Slash) == "/")
        #expect(KeyboardShortcut.keyName(kVK_F12) == "F12")
        #expect(KeyboardShortcut.keyName(kVK_ANSI_KeypadEnter) == "Num Enter")
        #expect(KeyboardShortcut(keyCodes: [0, 0, 1], modifiers: []).keyCodes == [0, 1])
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(KeyboardShortcut.self, from: Data(#"{"keyCodes":[],"modifiers":0}"#.utf8))
        }
    }

    @Test func returnEscapeAndTabAreCapturedAsKeys() {
        for code in [kVK_Return, kVK_Escape, kVK_Tab, kVK_Space, kVK_F12] {
            var capture = KeyboardInputCapture()
            #expect(capture.receive(keyEvent(.keyDown, code)) == nil)
            #expect(capture.preview?.keyCodes == [code])
            #expect(capture.receive(keyEvent(.keyUp, code)) == KeyboardShortcut(keyCode: code, modifiers: []))
        }
    }

    @Test func capturesMultipleKeysAndModifiersUntilAllReleased() {
        var capture = KeyboardInputCapture()
        #expect(capture.receive(keyEvent(.flagsChanged, kVK_Command, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.keyDown, kVK_ANSI_A, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.keyDown, kVK_ANSI_A, flags: .command, repeatKey: true)) == nil)
        #expect(capture.receive(keyEvent(.keyDown, kVK_ANSI_S, flags: .command)) == nil)
        #expect(capture.preview?.displayString == "⌘A + S")
        #expect(capture.receive(keyEvent(.keyUp, kVK_ANSI_A, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.flagsChanged, kVK_Command)) == nil)
        #expect(capture.receive(keyEvent(.keyUp, kVK_ANSI_S)) == KeyboardShortcut(keyCodes: [kVK_ANSI_A, kVK_ANSI_S], modifiers: .command))
    }

    @Test func preheldKeysMustBeReleasedBeforeRecording() {
        var capture = KeyboardInputCapture(heldKeys: [kVK_Space], heldModifiers: .shift)
        #expect(capture.receive(keyEvent(.keyDown, kVK_Space, flags: .shift, repeatKey: true)) == nil)
        #expect(capture.receive(keyEvent(.keyUp, kVK_Space, flags: .shift)) == nil)
        #expect(capture.receive(keyEvent(.flagsChanged, kVK_Shift)) == nil)
        #expect(!capture.isWaitingForRelease)
        #expect(capture.preview == nil)
        #expect(capture.receive(keyEvent(.keyDown, kVK_ANSI_B)) == nil)
        #expect(capture.receive(keyEvent(.keyUp, kVK_ANSI_B))?.displayString == "B")
    }

    @Test func modifierOnlyAndSequentialTypingAreNotConfused() {
        var capture = KeyboardInputCapture()
        #expect(capture.receive(keyEvent(.flagsChanged, kVK_Control, flags: .control)) == nil)
        #expect(capture.receive(keyEvent(.flagsChanged, kVK_Control)) == KeyboardShortcut(keyCodes: [], modifiers: .control))
        capture = KeyboardInputCapture()
        #expect(capture.receive(keyEvent(.flagsChanged, kVK_Command, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.keyDown, kVK_ANSI_A, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.keyUp, kVK_ANSI_A, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.keyDown, kVK_ANSI_B, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.keyUp, kVK_ANSI_B, flags: .command)) == nil)
        #expect(capture.receive(keyEvent(.flagsChanged, kVK_Command))?.displayString == "⌘A")
    }

    @Test func simulatorPressesTogetherAndReleasesInReverseOrder() {
        var events: [CGEvent] = []
        let simulator = KeyboardSimulator { events.append($0) }
        simulator.sendShortcut(KeyboardShortcut(keyCodes: [kVK_ANSI_A, kVK_ANSI_S], modifiers: [.control, .shift]))
        #expect(events.map { Int($0.getIntegerValueField(.keyboardEventKeycode)) } ==
                [kVK_Control, kVK_Shift, kVK_ANSI_A, kVK_ANSI_S, kVK_ANSI_S, kVK_ANSI_A, kVK_Shift, kVK_Control])
        #expect(events.map(\.type) == [.flagsChanged, .flagsChanged, .keyDown, .keyDown,
                                      .keyUp, .keyUp, .flagsChanged, .flagsChanged])
        #expect(events[2].flags.contains([.maskControl, .maskShift]))
        #expect(events[6].flags == .maskControl)
        #expect(events.last?.flags == [])
        events.removeAll()
        simulator.sendShortcut(KeyboardShortcut(keyCode: -1, modifiers: []))
        #expect(events.isEmpty)
        simulator.sendShortcut(KeyboardShortcut(keyCodes: [], modifiers: .option))
        #expect(events.count == 2)
        #expect(events.last?.flags == [])
    }
}

@MainActor
struct KeyboardShortcutRecorderTests {
    @Test func interceptsOnlyRecordingWindowAndStopsOnFocusLoss() {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                              styleMask: .titled, backing: .buffered, defer: false)
        let other = NSWindow(contentRect: .zero, styleMask: .titled, backing: .buffered, defer: false)
        let recorder = KeyboardShortcutRecorder()
        var result: KeyboardShortcut?
        recorder.start(in: window) { result = $0 }
        defer { recorder.stop() }
        let outsideEvent = keyEvent(.keyDown, kVK_ANSI_A, window: other.windowNumber)
        #expect(recorder.handle(outsideEvent, in: other) === outsideEvent)
        #expect(recorder.handle(keyEvent(.keyDown, kVK_Return), in: window) == nil)
        #expect(recorder.handle(keyEvent(.keyUp, kVK_Return), in: window) == nil)
        #expect(result?.keyCodes == [kVK_Return])
        #expect(!recorder.isRecording)
        recorder.start(in: window) { result = $0 }
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        #expect(!recorder.isRecording)
        let normal = keyEvent(.keyDown, kVK_Escape, window: window.windowNumber)
        #expect(recorder.handle(normal, in: window) === normal)
    }
}
