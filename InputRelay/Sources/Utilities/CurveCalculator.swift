import Foundation

/// 速度曲线计算器
/// 将原始输入值转换为应用了加速曲线的输出值
struct CurveCalculator {
    
    enum CurveType: String, Codable, CaseIterable {
        case linear = "linear"           // 线性
        case accelerated = "accelerated" // 加速
        case precise = "precise"         // 精确
        
        var displayName: String {
            switch self {
            case .linear: return "线性"
            case .accelerated: return "加速"
            case .precise: return "精确"
            }
        }
        
        var description: String {
            switch self {
            case .linear: return "恒定速度，精确控制"
            case .accelerated: return "小幅移动慢，大幅移动快"
            case .precise: return "全程低速，精细操作"
            }
        }
    }
    
    /// 应用加速曲线
    /// - Parameters:
    ///   - value: 原始输入值 (-1.0 到 1.0)
    ///   - curveType: 曲线类型
    ///   - sensitivity: 灵敏度倍率
    /// - Returns: 处理后的值
    static func apply(_ value: Float, curveType: CurveType, sensitivity: Float = 1.0) -> Float {
        // 保留符号
        let sign = value < 0 ? Float(-1.0) : Float(1.0)
        let absValue = abs(value)
        
        // 应用曲线
        let curved: Float
        switch curveType {
        case .linear:
            curved = absValue
        case .accelerated:
            // 二次曲线：y = x^2
            // 小输入 → 小输出，大输入 → 更大输出
            curved = absValue * absValue
        case .precise:
            // 平方根曲线：y = sqrt(x)
            // 全程降低速度，但保持响应
            curved = sqrt(absValue)
        }
        
        // 应用灵敏度并恢复符号
        return sign * curved * sensitivity
    }
    
    /// 应用死区过滤
    /// - Parameters:
    ///   - value: 原始值
    ///   - deadzone: 死区大小 (0.0 - 0.5)
    /// - Returns: 过滤后的值
    static func applyDeadzone(_ value: Float, deadzone: Float) -> Float {
        let absValue = abs(value)
        
        // 在死区内返回 0
        guard absValue > deadzone else {
            return 0.0
        }
        
        // 重新映射到 0-1 范围
        // 这样死区边缘不会有突然的跳跃
        let sign = value < 0 ? Float(-1.0) : Float(1.0)
        let normalized = (absValue - deadzone) / (1.0 - deadzone)
        
        return sign * normalized
    }
    
    /// 完整的输入处理流程
    /// - Parameters:
    ///   - value: 原始摇杆值 (-1.0 到 1.0)
    ///   - deadzone: 死区
    ///   - curveType: 加速曲线
    ///   - sensitivity: 灵敏度
    /// - Returns: 最终处理后的值
    static func process(
        _ value: Float,
        deadzone: Float,
        curveType: CurveType,
        sensitivity: Float
    ) -> Float {
        // 1. 应用死区
        let filtered = applyDeadzone(value, deadzone: deadzone)
        
        // 2. 应用加速曲线和灵敏度
        let curved = apply(filtered, curveType: curveType, sensitivity: sensitivity)
        
        // 3. 限制在 -1.0 到 1.0 范围内
        return max(-1.0, min(1.0, curved))
    }
}
