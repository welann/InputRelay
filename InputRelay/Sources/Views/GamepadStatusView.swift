import SwiftUI

struct GamepadStatusView: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 连接状态卡片
                StatusCard(isConnected: gamepadManager.isConnected)
                
                // 手柄可视化
                GamepadVisualization(gamepadManager: gamepadManager)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#05070C"))
    }
}

// MARK: - 状态卡片（参考图1风格）

struct StatusCard: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(isConnected ? Color(hex: "#10B981").opacity(0.15) : Color(hex: "#6B7280").opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isConnected ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(isConnected ? "手柄已连接" : "手柄未连接")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#E5E7EB"))
                
                Text(isConnected ? "正在监听输入事件" : "请通过蓝牙或 USB 连接手柄")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#9CA3AF"))
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(hex: "#0F131C"))
        .cornerRadius(16)
    }
}

// MARK: - 手柄可视化（修复布局）

struct GamepadVisualization: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("手柄布局")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                // 手柄主体背景
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "#0F131C"))
                    .frame(height: 420)
                
                VStack(spacing: 0) {
                    // 顶部：肩键和扳机
                    HStack(spacing: 0) {
                        // 左侧肩键
                        VStack(spacing: 8) {
                            ShoulderButton(label: "L1", isPressed: gamepadManager.getButtonState(.leftShoulder) > 0.5)
                            ShoulderButton(label: "L2", isPressed: gamepadManager.getButtonState(.leftTrigger) > 0.5)
                        }
                        .padding(.leading, 40)
                        
                        Spacer()
                        
                        // 右侧肩键
                        VStack(spacing: 8) {
                            ShoulderButton(label: "R1", isPressed: gamepadManager.getButtonState(.rightShoulder) > 0.5)
                            ShoulderButton(label: "R2", isPressed: gamepadManager.getButtonState(.rightTrigger) > 0.5)
                        }
                        .padding(.trailing, 40)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // 中部：D-Pad、摇杆、按键
                    HStack(spacing: 40) {
                        // 左侧：D-Pad
                        DPadView(gamepadManager: gamepadManager)
                        
                        // 左摇杆
                        StickView(
                            label: "L-Stick",
                            x: gamepadManager.getStickAxes(isLeft: true).x,
                            y: gamepadManager.getStickAxes(isLeft: true).y
                        )
                        
                        Spacer()
                        
                        // 右摇杆
                        StickView(
                            label: "R-Stick",
                            x: gamepadManager.getStickAxes(isLeft: false).x,
                            y: gamepadManager.getStickAxes(isLeft: false).y
                        )
                        
                        // 右侧：ABXY 按键
                        FaceButtonsView(gamepadManager: gamepadManager)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // 底部：Select / Start
                    HStack(spacing: 24) {
                        SmallButton(label: "Select", isPressed: gamepadManager.getButtonState(.selectButton) > 0.5)
                        SmallButton(label: "Start", isPressed: gamepadManager.getButtonState(.startButton) > 0.5)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#0A0D12"))
        .cornerRadius(16)
    }
}

// MARK: - 子组件

struct ShoulderButton: View {
    let label: String
    let isPressed: Bool
    
    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundColor(isPressed ? Color(hex: "#05070C") : Color(hex: "#9CA3AF"))
            .frame(width: 56, height: 28)
            .background(isPressed ? Color(hex: "#38BDF8") : Color(hex: "#1E2636"))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isPressed ? Color(hex: "#38BDF8") : Color.clear, lineWidth: 2)
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
                .foregroundColor(Color(hex: "#6B7280"))
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
            .foregroundColor(isPressed ? Color(hex: "#05070C") : Color(hex: "#9CA3AF"))
            .frame(width: 36, height: 36)
            .background(isPressed ? Color(hex: "#38BDF8") : Color(hex: "#161D2B"))
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
                .foregroundColor(Color(hex: "#6B7280"))
                .padding(.bottom, 8)
            
            VStack(spacing: 4) {
                FaceButton(label: "Y", isPressed: gamepadManager.getButtonState(.buttonY) > 0.5, color: .blue)
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
        case red, green, blue
        
        var hex: String {
            switch self {
            case .red: return "#EF4444"
            case .green: return "#10B981"
            case .blue: return "#38BDF8"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isPressed ? Color(hex: color.hex) : Color(hex: "#161D2B"))
                .frame(width: 36, height: 36)
            
            if isPressed {
                Circle()
                    .stroke(Color(hex: color.hex), lineWidth: 2)
                    .blur(radius: 3)
                    .frame(width: 40, height: 40)
            }
            
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isPressed ? Color(hex: "#05070C") : Color(hex: "#9CA3AF"))
        }
        .scaleEffect(isPressed ? 1.15 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }
}

struct StickView: View {
    let label: String
    let x: Float
    let y: Float
    
    var isActive: Bool {
        abs(x) > 0.1 || abs(y) > 0.1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "#6B7280"))
            
            ZStack {
                // 外圈
                Circle()
                    .stroke(Color(hex: "#2D3748"), lineWidth: 2)
                    .frame(width: 72, height: 72)
                
                // 十字辅助线
                Path { path in
                    path.move(to: CGPoint(x: 36, y: 0))
                    path.addLine(to: CGPoint(x: 36, y: 72))
                    path.move(to: CGPoint(x: 0, y: 36))
                    path.addLine(to: CGPoint(x: 72, y: 36))
                }
                .stroke(Color(hex: "#2D3748").opacity(0.3), lineWidth: 1)
                .frame(width: 72, height: 72)
                
                // 摇杆指示点
                Circle()
                    .fill(isActive ? Color(hex: "#38BDF8") : Color(hex: "#4B5563"))
                    .frame(width: 16, height: 16)
                    .offset(
                        x: CGFloat(x) * 28,
                        y: CGFloat(-y) * 28
                    )
                
                // 激活时的外发光
                if isActive {
                    Circle()
                        .stroke(Color(hex: "#38BDF8"), lineWidth: 2)
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
            .foregroundColor(isPressed ? Color(hex: "#05070C") : Color(hex: "#9CA3AF"))
            .frame(width: 64, height: 24)
            .background(isPressed ? Color(hex: "#38BDF8") : Color(hex: "#1E2636"))
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}
