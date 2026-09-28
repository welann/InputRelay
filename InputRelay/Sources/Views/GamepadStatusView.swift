import SwiftUI

struct GamepadStatusView: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 连接状态
                VStack(spacing: 12) {
                    if gamepadManager.isConnected {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#6EE7B7"))
                                .font(.system(size: 24))
                            Text("手柄已连接")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#E5E7EB"))
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(Color(hex: "#F59E0B"))
                                .font(.system(size: 24))
                            Text("手柄未连接")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#E5E7EB"))
                        }
                        
                        Text("请连接冰原狼 4 代手柄或其他兼容设备")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#0A0D12"))
                .cornerRadius(12)
                
                // 手柄可视化
                GamepadVisualization(gamepadManager: gamepadManager)
                
                // 最后事件
                if let event = gamepadManager.lastEvent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最后事件")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        
                        HStack {
                            Text("按键:")
                                .foregroundColor(Color(hex: "#6B7280"))
                            Text(event.button.displayName)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(hex: "#38BDF8"))
                            
                            Spacer()
                            
                            Text("值:")
                                .foregroundColor(Color(hex: "#6B7280"))
                            Text(String(format: "%.2f", event.value))
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(hex: "#E5E7EB"))
                        }
                        .font(.system(size: 13))
                        .padding()
                        .background(Color(hex: "#0F131C"))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(hex: "#0A0D12"))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#05070C"))
    }
}

struct GamepadVisualization: View {
    @ObservedObject var gamepadManager: GamepadManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("手柄布局")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            ZStack {
                // 手柄轮廓
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#0F131C"))
                    .frame(width: 600, height: 300)
                
                // 左侧控制区
                HStack(spacing: 60) {
                    // 方向键
                    VStack {
                        Text("D-Pad")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#6B7280"))
                        
                        VStack(spacing: 4) {
                            ButtonIndicator(
                                label: "↑",
                                isPressed: gamepadManager.getButtonState(.dpadUp) > 0.5
                            )
                            HStack(spacing: 4) {
                                ButtonIndicator(
                                    label: "←",
                                    isPressed: gamepadManager.getButtonState(.dpadLeft) > 0.5
                                )
                                Color.clear.frame(width: 40, height: 40)
                                ButtonIndicator(
                                    label: "→",
                                    isPressed: gamepadManager.getButtonState(.dpadRight) > 0.5
                                )
                            }
                            ButtonIndicator(
                                label: "↓",
                                isPressed: gamepadManager.getButtonState(.dpadDown) > 0.5
                            )
                        }
                    }
                    
                    // 左摇杆
                    VStack {
                        Text("L-Stick")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#6B7280"))
                        
                        Circle()
                            .fill(Color(hex: "#161D2B"))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "#38BDF8"))
                                    .frame(width: 20, height: 20)
                            )
                    }
                    
                    Spacer()
                    
                    // 右摇杆
                    VStack {
                        Text("R-Stick")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#6B7280"))
                        
                        Circle()
                            .fill(Color(hex: "#161D2B"))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "#38BDF8"))
                                    .frame(width: 20, height: 20)
                            )
                    }
                    
                    // 面键
                    VStack {
                        Text("Buttons")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#6B7280"))
                        
                        VStack(spacing: 4) {
                            ButtonIndicator(
                                label: "Y",
                                isPressed: gamepadManager.getButtonState(.buttonY) > 0.5
                            )
                            HStack(spacing: 4) {
                                ButtonIndicator(
                                    label: "X",
                                    isPressed: gamepadManager.getButtonState(.buttonX) > 0.5
                                )
                                Color.clear.frame(width: 40, height: 40)
                                ButtonIndicator(
                                    label: "B",
                                    isPressed: gamepadManager.getButtonState(.buttonB) > 0.5
                                )
                            }
                            ButtonIndicator(
                                label: "A",
                                isPressed: gamepadManager.getButtonState(.buttonA) > 0.5
                            )
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                // 肩键和扳机
                VStack {
                    HStack {
                        VStack(spacing: 4) {
                            ButtonIndicator(label: "L1", isPressed: gamepadManager.getButtonState(.leftShoulder) > 0.5, size: 60)
                            ButtonIndicator(label: "L2", isPressed: gamepadManager.getButtonState(.leftTrigger) > 0.5, size: 60)
                        }
                        Spacer()
                        VStack(spacing: 4) {
                            ButtonIndicator(label: "R1", isPressed: gamepadManager.getButtonState(.rightShoulder) > 0.5, size: 60)
                            ButtonIndicator(label: "R2", isPressed: gamepadManager.getButtonState(.rightTrigger) > 0.5, size: 60)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // 中央按键
                    HStack(spacing: 20) {
                        ButtonIndicator(label: "Select", isPressed: gamepadManager.getButtonState(.selectButton) > 0.5, size: 60)
                        ButtonIndicator(label: "Start", isPressed: gamepadManager.getButtonState(.startButton) > 0.5, size: 60)
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(width: 600, height: 300)
        }
        .padding()
        .background(Color(hex: "#0A0D12"))
        .cornerRadius(12)
    }
}
