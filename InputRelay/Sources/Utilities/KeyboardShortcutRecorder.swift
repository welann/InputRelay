import AppKit
import Combine

@MainActor
final class KeyboardShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var preview: KeyboardShortcut?
    @Published private(set) var isWaitingForRelease = false
    private var capture = KeyboardInputCapture()
    private weak var window: NSWindow?
    private var onCapture: ((KeyboardShortcut) -> Void)?
    private let monitors = KeyboardMonitorTokens()

    func start(in window: NSWindow?, onCapture: @escaping (KeyboardShortcut) -> Void) {
        stop()
        guard let window else { return }
        self.window = window
        self.onCapture = onCapture
        let heldKeys = Set(KeyboardShortcut.keyNames.keys.filter {
            CGEventSource.keyState(.combinedSessionState, key: CGKeyCode($0))
        })
        capture = KeyboardInputCapture(heldKeys: heldKeys, heldModifiers: .init(eventFlags: NSEvent.modifierFlags))
        preview = nil
        isWaitingForRelease = capture.isWaitingForRelease
        isRecording = true
        monitors.event = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            let consumed = MainActor.assumeIsolated {
                guard let self else { return false }
                return self.handle(event, in: event.window ?? NSApp.keyWindow) == nil
            }
            return consumed ? nil : event
        }
        for (name, object) in [(NSWindow.didResignKeyNotification, window as AnyObject),
                               (NSApplication.didResignActiveNotification, NSApp as AnyObject)] {
            monitors.notifications.append(NotificationCenter.default.addObserver(forName: name, object: object, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.stop() }
            })
        }
    }

    func handle(_ event: NSEvent, in eventWindow: NSWindow?) -> NSEvent? {
        guard isRecording, let window, eventWindow === window else { return event }
        let completed = capture.receive(event)
        preview = capture.preview
        isWaitingForRelease = capture.isWaitingForRelease
        if let completed {
            let callback = onCapture
            stop()
            callback?(completed)
        }
        return nil
    }

    func stop() {
        monitors.removeAll()
        isRecording = false
        window = nil
        onCapture = nil
    }
}

private final class KeyboardMonitorTokens {
    var event: Any?
    var notifications: [NSObjectProtocol] = []

    func removeAll() {
        if let event { NSEvent.removeMonitor(event) }
        event = nil
        notifications.forEach { NotificationCenter.default.removeObserver($0) }
        notifications.removeAll()
    }

    deinit { removeAll() }
}
