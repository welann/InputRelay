import Foundation
import GameController
import Combine

/// 使用系统标准化后的 Xbox 位置语义，不依赖不同连接模式的 HID 编号。
@MainActor
final class GamepadManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var controllerName: String?
    @Published private(set) var lastEvent: GamepadEvent?
    @Published private(set) var buttonStates: [GamepadButton: Float] = [:]
    @Published private(set) var leftStick = SIMD2<Float>.zero
    @Published private(set) var rightStick = SIMD2<Float>.zero

    var isCapturingInput = false
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
        refreshControllers()
        // 提高输出频率；位移按单调时钟的实际间隔计算。
        Timer.publish(every: 1.0 / 120.0, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.sampleInput() }
            .store(in: &observations)
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
        NotificationCenter.default.post(name: Notification.Name("GamepadConnectionChanged"), object: nil)
    }

    func sampleInput(advanceSticks: Bool = true, timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        let elapsed: TimeInterval
        if advanceSticks {
            // 长时间停顿后不追赶积压位移，避免唤醒或主线程阻塞后光标跳跃。
            elapsed = min(max(timestamp - (lastStickTick ?? (timestamp - 1.0 / 120.0)), 0), 1.0 / 30.0)
            lastStickTick = timestamp
        } else {
            elapsed = 0
        }
        guard let pad = controller?.capture().extendedGamepad else { return }
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
        if advanceSticks && !isCapturingInput { stickHandler?(elapsed) }
    }

    private func updateButton(_ button: GamepadButton, value: Float) {
        let previous = buttonStates[button] ?? 0
        guard previous != value else { return }
        buttonStates[button] = value
        // 扳机是模拟量；只在跨越按下阈值时触发动作，避免一次扣动连续点击。
        if (previous > 0.5) != (value > 0.5) {
            emit(button, value: value)
        }
    }

    private func updateStick(isLeft: Bool, x: Float, y: Float) {
        let axes = SIMD2<Float>(x, y)
        guard axes != (isLeft ? leftStick : rightStick) else { return }
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
    }

    private func emit(_ button: GamepadButton, value: Float) {
        let event = GamepadEvent(button: button, value: value, timestamp: Date().timeIntervalSince1970)
        lastEvent = event
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
