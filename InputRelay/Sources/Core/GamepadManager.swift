import Foundation
import IOKit
import IOKit.hid

/// HID 回调的上下文载体
///
/// IOKit 的回调在 HID 的 RunLoop 线程上触发，直接把 `GamepadManager` 自身作为
/// 上下文传递会让并发检查认为跨越了隔离域。这里用一个独立的 final 类承载，
/// 它只持有弱引用，不需要自身是 Sendable。
private final class HIDContext {
    weak var manager: GamepadManager?

    init(manager: GamepadManager) {
        self.manager = manager
    }
}

/// 持有 IOHIDManager 的引用盒
///
/// `deinit` 是 nonisolated 的，无法直接访问 actor 隔离的属性。把句柄放进一个
/// 独立对象后，盒子析构时会自动关闭 HID 管理器，无需在 GamepadManager 中写 deinit。
private final class HIDManagerBox: @unchecked Sendable {
    var manager: IOHIDManager?

    deinit {
        if let manager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }
}

/// 手柄管理器 - 负责检测和监听手柄输入
@MainActor
final class GamepadManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var lastEvent: GamepadEvent?

    private let hidBox = HIDManagerBox()
    private var device: IOHIDDevice?
    private var context: HIDContext?
    private var buttonStates: [GamepadButton: Float] = [:]
    private var eventHandler: ((GamepadEvent) -> Void)?

    // 摇杆轴值（归一化后 -1.0 到 1.0）
    private var leftStickX: Float = 0
    private var leftStickY: Float = 0
    private var rightStickX: Float = 0
    private var rightStickY: Float = 0

    init() {}

    func setEventHandler(_ handler: @escaping (GamepadEvent) -> Void) {
        self.eventHandler = handler
    }

    // MARK: - HID Setup

    func start() {
        guard hidBox.manager == nil else { return }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        hidBox.manager = manager

        // 使用独立上下文对象，避免在回调中捕获 self
        let context = HIDContext(manager: self)
        self.context = context
        let opaque = Unmanaged.passUnretained(context).toOpaque()

        // 匹配所有标准游戏手柄
        let matching: [String: Any] = [
            kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey: kHIDUsage_GD_GamePad
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)

        IOHIDManagerRegisterDeviceMatchingCallback(manager, { rawContext, _, _, device in
            guard let rawContext else { return }
            let context = Unmanaged<HIDContext>.fromOpaque(rawContext).takeUnretainedValue()
            MainActor.assumeIsolated {
                context.manager?.deviceConnected(device)
            }
        }, opaque)

        IOHIDManagerRegisterDeviceRemovalCallback(manager, { rawContext, _, _, device in
            guard let rawContext else { return }
            let context = Unmanaged<HIDContext>.fromOpaque(rawContext).takeUnretainedValue()
            MainActor.assumeIsolated {
                context.manager?.deviceDisconnected(device)
            }
        }, opaque)

        // 在 HID 的 RunLoop 上调度；注意设备级回调必须注册在主线程，
        // 因此这里使用主 RunLoop 并只在主线程读取输入。
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        let result = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if result != kIOReturnSuccess {
            print("Failed to open HID manager: \(result)")
        }
    }

    private func deviceConnected(_ device: IOHIDDevice) {
        self.device = device
        isConnected = true

        if let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int,
           let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int {
            print("Gamepad connected — Vendor: \(vendorID), Product: \(productID)")
        } else {
            print("Gamepad connected")
        }

        guard let context else { return }
        let opaque = Unmanaged.passUnretained(context).toOpaque()

        IOHIDDeviceRegisterInputValueCallback(device, { rawContext, _, _, value in
            guard let rawContext else { return }
            let context = Unmanaged<HIDContext>.fromOpaque(rawContext).takeUnretainedValue()
            MainActor.assumeIsolated {
                context.manager?.handleInput(value)
            }
        }, opaque)

        NotificationCenter.default.post(name: Notification.Name("GamepadConnectionChanged"), object: nil)
    }

    private func deviceDisconnected(_ device: IOHIDDevice) {
        guard self.device === device else { return }
        self.device = nil
        isConnected = false
        buttonStates.removeAll()
        leftStickX = 0; leftStickY = 0; rightStickX = 0; rightStickY = 0

        NotificationCenter.default.post(name: Notification.Name("GamepadConnectionChanged"), object: nil)
    }

    // MARK: - Input Handling

    private func handleInput(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        let intValue = IOHIDValueGetIntegerValue(value)

        if usagePage == UInt32(kHIDPage_Button) {
            handleButtonInput(usage: usage, pressed: intValue != 0)
        } else if usagePage == UInt32(kHIDPage_GenericDesktop) {
            handleAxisInput(usage: usage, value: intValue, element: element)
        }
    }

    private func handleButtonInput(usage: UInt32, pressed: Bool) {
        let button: GamepadButton?
        switch usage {
        case 1: button = .buttonA
        case 2: button = .buttonB
        case 3: button = .buttonX
        case 4: button = .buttonY
        case 5: button = .leftShoulder
        case 6: button = .rightShoulder
        case 7: button = .leftTrigger
        case 8: button = .rightTrigger
        case 9: button = .selectButton
        case 10: button = .startButton
        case 11: button = .leftStickButton
        case 12: button = .rightStickButton
        case 13: button = .homeButton
        default: button = nil
        }

        guard let button else { return }

        buttonStates[button] = pressed ? 1.0 : 0.0
        emit(GamepadEvent(
            button: button,
            value: pressed ? 1.0 : 0.0,
            timestamp: Date().timeIntervalSince1970
        ))
    }

    private func handleAxisInput(usage: UInt32, value: Int, element: IOHIDElement) {
        let min = IOHIDElementGetLogicalMin(element)
        let max = IOHIDElementGetLogicalMax(element)
        guard max > min else { return }

        // 归一化到 -1.0 到 1.0
        let normalized = Float(value - min) / Float(max - min) * 2.0 - 1.0

        switch usage {
        case UInt32(kHIDUsage_GD_X):   // 左摇杆 X
            leftStickX = normalized
        case UInt32(kHIDUsage_GD_Y):   // 左摇杆 Y（屏幕坐标系向下为正，故取反）
            leftStickY = -normalized
        case UInt32(kHIDUsage_GD_Z):   // 右摇杆 X
            rightStickX = normalized
        case UInt32(kHIDUsage_GD_Rz):  // 右摇杆 Y
            rightStickY = -normalized
        case UInt32(kHIDUsage_GD_Hatswitch):
            handleDPad(value: value, element: element)
        default:
            return
        }

        if usage != UInt32(kHIDUsage_GD_Hatswitch) {
            emitStickEvents()
        }
    }

    /// 以四个方向的虚拟按键形式发出摇杆事件，供映射引擎消费
    private func emitStickEvents() {
        let samples: [(GamepadButton, Float)] = [
            (.leftStickRight, max(0, leftStickX)),
            (.leftStickLeft, max(0, -leftStickX)),
            (.leftStickUp, max(0, leftStickY)),
            (.leftStickDown, max(0, -leftStickY)),
            (.rightStickRight, max(0, rightStickX)),
            (.rightStickLeft, max(0, -rightStickX)),
            (.rightStickUp, max(0, rightStickY)),
            (.rightStickDown, max(0, -rightStickY))
        ]

        for (button, value) in samples where value > 0.08 {
            emit(GamepadEvent(
                button: button,
                value: value,
                timestamp: Date().timeIntervalSince1970
            ))
        }
    }

    private func handleDPad(value: Int, element: IOHIDElement) {
        // 帽子开关通常为 0-7（顺时针），或以逻辑最小值表示"未按下"
        let logicalMin = IOHIDElementGetLogicalMin(element)
        let isNeutral = value < logicalMin || value > 7
        guard !isNeutral else { return }

        // 0=上 1=右上 2=右 3=右下 4=下 5=左下 6=左 7=左上
        let directions: [GamepadButton] = [
            .dpadUp, .dpadUp, .dpadRight, .dpadRight,
            .dpadDown, .dpadDown, .dpadLeft, .dpadLeft
        ]
        let button = directions[Int(value)]
        emit(GamepadEvent(button: button, value: 1.0, timestamp: Date().timeIntervalSince1970))
    }

    private func emit(_ event: GamepadEvent) {
        lastEvent = event
        eventHandler?(event)
    }

    func getButtonState(_ button: GamepadButton) -> Float {
        buttonStates[button] ?? 0.0
    }

    func getStickAxes(isLeft: Bool) -> (x: Float, y: Float) {
        isLeft ? (leftStickX, leftStickY) : (rightStickX, rightStickY)
    }
}
