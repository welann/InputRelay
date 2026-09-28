import SwiftUI

/// 手柄按键指示器
/// 显示单个按键的状态（按下/未按下）
struct ButtonIndicator: View {
    let label: String
    let isPressed: Bool
    var size: CGFloat = 40
    let action: () -> Void

    init(label: String, isPressed: Bool, size: CGFloat = 40, action: @escaping () -> Void = {}) {
        self.label = label
        self.isPressed = isPressed
        self.size = size
        self.action = action
    }
    
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // 背景圆形
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            // 按键标签
            Text(label)
                .font(.system(size: size >= 56 ? 12 : 16, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .stroke(accentColor, lineWidth: 2)
                .blur(radius: 4)
                .frame(width: size + 8, height: size + 8)
                .opacity(isPressed ? 1 : 0)
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            action()
        }
        .help("点击编辑 \(label) 按键映射")
    }
    
    private var backgroundColor: Color {
        if isPressed {
            return AppTheme.accent
        } else {
            return AppTheme.inset
        }
    }
    
    private var textColor: Color {
        if isPressed {
            return AppTheme.onAccent
        } else {
            return AppTheme.text
        }
    }
    
    private var accentColor: Color {
        AppTheme.accent
    }
}

/// 摇杆指示器
/// 显示摇杆的当前位置
struct StickIndicator: View {
    let label: String
    let x: Float
    let y: Float
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 外圈
                Circle()
                    .stroke(AppTheme.border, lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                // 十字线
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 0))
                    path.addLine(to: CGPoint(x: 40, y: 80))
                    path.move(to: CGPoint(x: 0, y: 40))
                    path.addLine(to: CGPoint(x: 80, y: 40))
                }
                .stroke(AppTheme.border, lineWidth: 1)
                .frame(width: 80, height: 80)
                
                // 当前位置指示点
                Circle()
                    .fill(isActive ? activeColor : inactiveColor)
                    .frame(width: 16, height: 16)
                    .offset(
                        x: CGFloat(x) * 32,
                        y: CGFloat(-y) * 32
                    )
                
                // 外发光（活动时）
                if isActive {
                    Circle()
                        .stroke(activeColor, lineWidth: 2)
                        .blur(radius: 3)
                        .frame(width: 20, height: 20)
                        .offset(
                            x: CGFloat(x) * 32,
                            y: CGFloat(-y) * 32
                        )
                }
            }
            .frame(width: 80, height: 80)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.secondary)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            action()
        }
        .help("点击配置 \(label)")
    }
    
    private var isActive: Bool {
        abs(x) > 0.1 || abs(y) > 0.1
    }
    
    private var activeColor: Color {
        AppTheme.accent
    }
    
    private var inactiveColor: Color {
        AppTheme.muted
    }
}
