import AppKit
import GameController
import Combine

/// 使用系统标准化后的 Xbox 位置语义，不依赖不同连接模式的 HID 编号。
@MainActor
final class GamepadManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var controllerName: String?
    private(set) var lastEvent: GamepadEvent?
    private(set) var buttonStates: [GamepadButton: Float] = [:]
    private var pressedTriggers = Set<GamepadButton>()
    private(set) var leftStick = SIMD2<Float>.zero
    private(set) var rightStick = SIMD2<Float>.zero
    let displayState = GamepadDisplayState()
    var isStatusVisible = false { didSet { updateDisplayTimer() } }
    private var displayDirty = true
    private var displayTimer: AnyCancellable?

    var isCapturingInput = false { didSet { updateMotionTimer() } }
    var onMotionStopped: (() -> Void)?
    var motionEnabled = false { didSet { updateMotionTimer() } }
    var motionSettings = StickSettings() { didSet { updateMotionTimer() } }
    private var motionTimer: AnyCancellable?
    var isMotionTimerRunning: Bool { motionTimer != nil }
    private var tickInterval: TimeInterval = 1.0 / 60.0
    // 录入只订阅新事件，不能重放打开弹窗之前的 lastEvent。
    let inputEvents = PassthroughSubject<GamepadEvent, Never>()

    private let controllers: () -> [GCController]
    private var controller: GCController?
    private var observations = Set<AnyCancellable>()
    private var eventHandler: ((GamepadEvent) -> Void)?
    private var stickHandler: ((TimeInterval) -> Void)?
    private var lastStickTick: TimeInterval?

    init(controllers: @escaping () -> [GCController] = { GCController.controllers() }) {
        self.controllers = controllers
    }

    func setEventHandler(_ handler: @escaping (GamepadEvent) -> Void) {
        eventHandler = handler
    }

    func setStickHandler(_ handler: @escaping (TimeInterval) -> Void) {
        stickHandler = handler
    }

    func start() {
        guard observations.isEmpty else { return }
        GCController.shouldMonitorBackgroundEvents = true
        for name in [Notification.Name.GCControllerDidConnect, .GCControllerDidDisconnect] {
            NotificationCenter.default.publisher(for: name)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.refreshControllers() }
                .store(in: &observations)
        }
        for name in [NSApplication.didChangeScreenParametersNotification,
                     NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification,
                     NSWindow.didChangeOcclusionStateNotification,
                     NSWindow.didMiniaturizeNotification, NSWindow.didDeminiaturizeNotification] {
            NotificationCenter.default.publisher(for: name)
                .sink { [weak self] _ in
                    self?.updateDisplayTimer()
                    self?.updateRefreshRate()
                }.store(in: &observations)
        }
        updateRefreshRate()
        refreshControllers()
    }

    func refreshControllers() {
        let available = controllers().filter { $0.extendedGamepad != nil }
        if let controller, available.contains(where: { $0 === controller }) { return }

        controller?.extendedGamepad?.valueChangedHandler = nil
        resetInput()
        controller = available.first
        controller?.handlerQueue = .main
        controller?.extendedGamepad?.valueChangedHandler = { [weak self] _, _ in
            MainActor.assumeIsolated {
                self?.sampleInput(advanceSticks: false)
            }
        }
        controllerName = controller?.vendorName ?? (controller == nil ? nil : "Xbox 兼容手柄")
        isConnected = controller != nil
        sampleInput(advanceSticks: false)
        updateMotionTimer()
        NotificationCenter.default.post(name: Notification.Name("GamepadConnectionChanged"), object: nil)
    }

    func sampleInput(advanceSticks: Bool = true, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        guard let pad = controller?.extendedGamepad else { return }
        let inputs: [(GamepadButton, GCControllerButtonInput?)] = [
            (.buttonA, pad.buttonA), (.buttonB, pad.buttonB),
            (.buttonX, pad.buttonX), (.buttonY, pad.buttonY),
            (.leftShoulder, pad.leftShoulder), (.rightShoulder, pad.rightShoulder),
            (.leftTrigger, pad.leftTrigger), (.rightTrigger, pad.rightTrigger),
            (.dpadUp, pad.dpad.up), (.dpadDown, pad.dpad.down),
            (.dpadLeft, pad.dpad.left), (.dpadRight, pad.dpad.right),
            (.leftStickButton, pad.leftThumbstickButton), (.rightStickButton, pad.rightThumbstickButton),
            (.selectButton, pad.buttonOptions), (.startButton, pad.buttonMenu),
            (.homeButton, pad.buttonHome)
        ]
        for (button, input) in inputs {
            updateButton(button, value: input?.value ?? 0)
        }
        updateStick(isLeft: true, x: pad.leftThumbstick.xAxis.value, y: pad.leftThumbstick.yAxis.value)
        updateStick(isLeft: false, x: pad.rightThumbstick.xAxis.value, y: pad.rightThumbstick.yAxis.value)
        updateMotionTimer()
        if advanceSticks { advanceMotion(timestamp: timestamp) }
    }

    /// The output clock only integrates cached axes; it never scans controller inputs.
    func advanceMotion(timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        let elapsed = min(max(timestamp - (lastStickTick ?? (timestamp - tickInterval)), 0), 1.0 / 30.0)
        lastStickTick = timestamp
        if !isCapturingInput { stickHandler?(elapsed) }
    }

    private func updateMotionTimer() {
        func active(_ axes: SIMD2<Float>, mode: StickSettings.StickMode) -> Bool {
            switch mode {
            case .disabled: return false
            case .scroll: return abs(axes.y) > motionSettings.deadzone
            case .mouse: return sqrt(axes.x * axes.x + axes.y * axes.y) > motionSettings.deadzone
            }
        }
        let needed = isConnected && motionEnabled && !isCapturingInput &&
            (active(leftStick, mode: motionSettings.leftStickMode) || active(rightStick, mode: motionSettings.rightStickMode))
        if needed && motionTimer == nil {
            lastStickTick = nil
            motionTimer = Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
                .sink { [weak self] _ in self?.advanceMotion() }
        } else if !needed && motionTimer != nil {
            motionTimer = nil
            lastStickTick = nil
            onMotionStopped?()
        }
    }

    private func updateRefreshRate() {
        // Use 120 Hz only when a connected display benefits from it; preserve time-based speed.
        let rate = NSScreen.screens.map(\.maximumFramesPerSecond).max() ?? 60
        let interval = 1.0 / Double(min(120, max(60, rate)))
        guard interval != tickInterval else { return }
        tickInterval = interval
        motionTimer = nil
        updateMotionTimer()
    }

    private func updateDisplayTimer() {
        let visible = isStatusVisible && NSApp?.isActive == true &&
            (NSApp?.windows.contains { $0.isVisible && !$0.isMiniaturized } == true)
        guard visible else { displayTimer = nil; return }
        guard displayTimer == nil else { return }
        displayDirty = true
        displayTimer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self, self.displayDirty else { return }
                self.displayDirty = false
                self.displayState.refresh(from: self)
            }
    }

    private func updateButton(_ button: GamepadButton, value: Float) {
        let previous = buttonStates[button] ?? 0
        guard previous != value else { return }
        buttonStates[button] = value
        displayDirty = true
        // 扳机按下后，必须松至 0.2 以下（含边界）才能再次触发。
        // 单独保存逻辑状态，避免模拟值在 0.5 附近波动时重复点击。
        if button == .leftTrigger || button == .rightTrigger {
            let wasPressed = pressedTriggers.contains(button)
            let isPressed = value > (wasPressed ? 0.2 : 0.5)
            guard wasPressed != isPressed else { return }
            if isPressed {
                pressedTriggers.insert(button)
            } else {
                pressedTriggers.remove(button)
            }
            emit(button, value: value)
            return
        }
        if (previous > 0.5) != (value > 0.5) {
            emit(button, value: value)
        }
    }

    private func updateStick(isLeft: Bool, x: Float, y: Float) {
        let axes = SIMD2<Float>(x, y)
        guard axes != (isLeft ? leftStick : rightStick) else { return }
        displayDirty = true
        if isLeft { leftStick = axes } else { rightStick = axes }
        let samples: [(GamepadButton, Float)] = isLeft ? [
            (.leftStickRight, max(0, x)), (.leftStickLeft, max(0, -x)),
            (.leftStickUp, max(0, y)), (.leftStickDown, max(0, -y))
        ] : [
            (.rightStickRight, max(0, x)), (.rightStickLeft, max(0, -x)),
            (.rightStickUp, max(0, y)), (.rightStickDown, max(0, -y))
        ]
        for (button, value) in samples {
            updateButton(button, value: value)
        }
    }

    private func resetInput() {
        lastStickTick = nil
        for button in GamepadButton.allCases {
            updateButton(button, value: 0)
        }
        leftStick = .zero
        rightStick = .zero
        lastEvent = nil
        displayDirty = true
    }

    private func emit(_ button: GamepadButton, value: Float) {
        let event = GamepadEvent(button: button, value: value, timestamp: Date().timeIntervalSince1970)
        lastEvent = event
        displayDirty = true
        inputEvents.send(event)
        if !isCapturingInput { eventHandler?(event) }
    }

    func getButtonState(_ button: GamepadButton) -> Float {
        buttonStates[button] ?? 0
    }

    /// GameController 坐标：向右 / 向上为正。
    func getStickAxes(isLeft: Bool) -> (x: Float, y: Float) {
        let axes = isLeft ? leftStick : rightStick
        return (axes.x, axes.y)
    }
}
