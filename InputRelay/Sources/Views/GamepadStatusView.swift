import SwiftUI

struct GamepadStatusView: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 连接状态卡片
                StatusCard(isConnected: gamepadManager.isConnected, controllerName: gamepadManager.controllerName)
                
                // 手柄可视化
                GamepadVisualization(gamepadManager: gamepadManager)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

// MARK: - 状态卡片（参考图1风格）

struct StatusCard: View {
    let isConnected: Bool
    let controllerName: String?
    
    var body: some View {
        HStack(spacing: 16) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(isConnected ? AppTheme.success.opacity(0.15) : AppTheme.muted.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isConnected ? AppTheme.success : AppTheme.warning)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isConnected ? "手柄已连接" : "手柄未连接")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.text)
                
                Text(isConnected ? "\(controllerName ?? "手柄") · Xbox 按键布局" : "请通过蓝牙或 USB 连接；多模式手柄请选择 Xbox / XInput 模式")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(AppTheme.inset)
        .cornerRadius(16)
    }
}

// MARK: - 手柄可视化（修复布局）

struct GamepadVisualization: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Xbox 按键布局")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Spacer()
                Text("按下按键，查看对应位置的反馈")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.secondary)
            }

            VStack(spacing: 20) {
                HStack {
                    HStack(spacing: 10) {
                        ShoulderButton(label: "LT", isPressed: pressed(.leftTrigger))
                        ShoulderButton(label: "LB", isPressed: pressed(.leftShoulder))
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        ShoulderButton(label: "RB", isPressed: pressed(.rightShoulder))
                        ShoulderButton(label: "RT", isPressed: pressed(.rightTrigger))
                    }
                }

                HStack(alignment: .center) {
                    StickView(
                        label: "LS · 左摇杆",
                        x: gamepadManager.getStickAxes(isLeft: true).x,
                        y: gamepadManager.getStickAxes(isLeft: true).y,
                        isPressed: pressed(.leftStickButton)
                    )
                    .frame(width: 150)
                    Spacer()
                    HStack(spacing: 10) {
                        SmallButton(label: "View", isPressed: pressed(.selectButton))
                        SmallButton(label: "Xbox", isPressed: pressed(.homeButton))
                        SmallButton(label: "Menu", isPressed: pressed(.startButton))
                    }
                    Spacer()
                    FaceButtonsView(gamepadManager: gamepadManager)
                        .frame(width: 150)
                }

                HStack {
                    Spacer()
                    DPadView(gamepadManager: gamepadManager)
                    Spacer(minLength: 100)
                    StickView(
                        label: "RS · 右摇杆",
                        x: gamepadManager.getStickAxes(isLeft: false).x,
                        y: gamepadManager.getStickAxes(isLeft: false).y,
                        isPressed: pressed(.rightStickButton)
                    )
                    Spacer()
                }
            }
            .padding(28)
            .background(
                LinearGradient(colors: [AppTheme.background, AppTheme.selection.opacity(0.5)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(AppTheme.border, lineWidth: 1))

            HStack {
                Text("LT \(Int(gamepadManager.getButtonState(.leftTrigger) * 100))%   RT \(Int(gamepadManager.getButtonState(.rightTrigger) * 100))%")
                    .monospacedDigit()
                Spacer()
                if let event = gamepadManager.lastEvent {
                    Text("最近事件：\(event.button.displayName) · \(event.isPressed ? "按下" : "松开")")
                } else {
                    Text("等待手柄输入")
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(AppTheme.secondary)
            Text("Xbox 键可能被系统保留；不支持的系统键不会产生事件。")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(20)
        .background(AppTheme.surface)
        .cornerRadius(16)
    }

    private func pressed(_ button: GamepadButton) -> Bool {
        gamepadManager.getButtonState(button) > 0.5
    }
}

// MARK: - 子组件

struct ShoulderButton: View {
    let label: String
    let isPressed: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(isPressed ? AppTheme.onAccent : AppTheme.secondary)
            .frame(width: 56, height: 28)
            .background(isPressed ? AppTheme.accent : AppTheme.border)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isPressed ? AppTheme.accent : Color.clear, lineWidth: 2)
                    .blur(radius: isPressed ? 4 : 0)
            )
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

struct DPadView: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        VStack(spacing: 0) {
            Text("D-Pad")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.muted)
                .padding(.bottom, 8)
            
            VStack(spacing: 4) {
                DPadButton(label: "↑", isPressed: gamepadManager.getButtonState(.dpadUp) > 0.5)
                HStack(spacing: 4) {
                    DPadButton(label: "←", isPressed: gamepadManager.getButtonState(.dpadLeft) > 0.5)
                    Color.clear.frame(width: 36, height: 36)
                    DPadButton(label: "→", isPressed: gamepadManager.getButtonState(.dpadRight) > 0.5)
                }
                DPadButton(label: "↓", isPressed: gamepadManager.getButtonState(.dpadDown) > 0.5)
            }
        }
    }
}

struct DPadButton: View {
    let label: String
    let isPressed: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(isPressed ? AppTheme.onAccent : AppTheme.secondary)
            .frame(width: 36, height: 36)
            .background(isPressed ? AppTheme.accent : AppTheme.selection)
            .cornerRadius(6)
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

struct FaceButtonsView: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Buttons")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.muted)
                .padding(.bottom, 8)
            
            VStack(spacing: 4) {
                FaceButton(label: "Y", isPressed: gamepadManager.getButtonState(.buttonY) > 0.5, color: .yellow)
                HStack(spacing: 4) {
                    FaceButton(label: "X", isPressed: gamepadManager.getButtonState(.buttonX) > 0.5, color: .blue)
                    Color.clear.frame(width: 36, height: 36)
                    FaceButton(label: "B", isPressed: gamepadManager.getButtonState(.buttonB) > 0.5, color: .red)
                }
                FaceButton(label: "A", isPressed: gamepadManager.getButtonState(.buttonA) > 0.5, color: .green)
            }
        }
    }
}

struct FaceButton: View {
    let label: String
    let isPressed: Bool
    let color: ButtonColor
    
    enum ButtonColor {
        case red, green, blue, yellow
        
        var hex: String {
            switch self {
            case .red: return "#B04E3E"
            case .green: return "#35754F"
            case .blue: return "#516E90"
            case .yellow: return "#8C6512"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isPressed ? Color(hex: color.hex) : AppTheme.selection)
                .frame(width: 36, height: 36)
            
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isPressed ? AppTheme.onAccent : Color(hex: color.hex))
        }
        .frame(width: 36, height: 36)
        .overlay {
            Circle()
                .stroke(Color(hex: color.hex), lineWidth: 2)
                .blur(radius: 3)
                .frame(width: 40, height: 40)
                .opacity(isPressed ? 1 : 0)
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

struct StickView: View {
    let label: String
    let x: Float
    let y: Float
    var isPressed = false
    
    var isActive: Bool {
        abs(x) > 0.1 || abs(y) > 0.1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppTheme.muted)
            
            ZStack {
                // 外圈
                Circle()
                    .stroke(isPressed ? AppTheme.accent : AppTheme.border, lineWidth: isPressed ? 4 : 2)
                    .frame(width: 72, height: 72)
                
                // 十字辅助线
                Path { path in
                    path.move(to: CGPoint(x: 36, y: 0))
                    path.addLine(to: CGPoint(x: 36, y: 72))
                    path.move(to: CGPoint(x: 0, y: 36))
                    path.addLine(to: CGPoint(x: 72, y: 36))
                }
                .stroke(AppTheme.border.opacity(0.3), lineWidth: 1)
                .frame(width: 72, height: 72)
                
                // 摇杆指示点
                Circle()
                    .fill(isActive ? AppTheme.accent : AppTheme.muted)
                    .frame(width: 16, height: 16)
                    .offset(
                        x: CGFloat(x) * 28,
                        y: CGFloat(-y) * 28
                    )
                
                // 激活时的外发光
                if isActive {
                    Circle()
                        .stroke(AppTheme.accent, lineWidth: 2)
                        .blur(radius: 3)
                        .frame(width: 20, height: 20)
                        .offset(
                            x: CGFloat(x) * 28,
                            y: CGFloat(-y) * 28
                        )
                }
            }
            .frame(width: 72, height: 72)
        }
    }
}

struct SmallButton: View {
    let label: String
    let isPressed: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(isPressed ? AppTheme.onAccent : AppTheme.secondary)
            .frame(width: 64, height: 24)
            .background(isPressed ? AppTheme.accent : AppTheme.border)
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}
