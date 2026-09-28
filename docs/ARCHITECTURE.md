# InputRelay 架构文档

## 系统架构

### 整体架构

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Layer                     │
│  ┌──────────┐  ┌──────────┐  ┌─────────────────┐   │
│  │ MenuBar  │  │  Main    │  │   Settings      │   │
│  │ Manager  │  │  Window  │  │   Views         │   │
│  └──────────┘  └──────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                  Business Logic                      │
│  ┌──────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │Configuration │  │  Gamepad    │  │Permission │  │
│  │   Engine     │  │  Manager    │  │ Manager   │  │
│  └──────────────┘  └─────────────┘  └───────────┘  │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                  System Layer                        │
│  ┌──────────────┐  ┌─────────────┐  ┌───────────┐  │
│  │   IOKit      │  │CoreGraphics │  │NSWorkspace│  │
│  │   (HID)      │  │  (Events)   │  │  (Apps)   │  │
│  └──────────────┘  └─────────────┘  └───────────┘  │
└─────────────────────────────────────────────────────┘
```

## 核心组件

### 1. GamepadManager

**职责**: 手柄输入检测和事件分发

**关键类**:
- `GamepadManager`: 主管理类
- `GamepadEvent`: 手柄事件模型
- `GamepadButton`: 按键枚举

**工作流程**:
```
1. IOHIDManager 初始化
2. 设置设备匹配规则 (Vendor ID / Product ID)
3. 注册输入回调
4. 解析 HID 值 → GamepadEvent
5. 通知订阅者
```

**关键方法**:
```swift
func startMonitoring()
func stopMonitoring()
func setEventHandler(_ handler: @escaping (GamepadEvent) -> Void)
func getButtonState(_ button: GamepadButton) -> Float
```

### 2. MouseSimulator

**职责**: 鼠标操作模拟

**关键方法**:
```swift
func moveMouse(dx: Float, dy: Float)
func clickMouse(_ button: MouseButton)
func scrollWheel(deltaX: Float, deltaY: Float)
```

**实现细节**:
- 使用 CGEvent 创建鼠标事件
- 通过 CGEventPost 发送到系统
- 需要辅助功能权限

### 3. KeyboardSimulator

**职责**: 键盘快捷键模拟

**关键方法**:
```swift
func pressKey(_ keyCode: Int, modifiers: ModifierFlags)
func typeText(_ text: String)
```

**实现细节**:
- 使用 CGEvent(keyboardEventSource:...)
- 支持修饰键组合
- 模拟 keyDown + keyUp 事件

### 4. ConfigurationEngine

**职责**: 配置管理和自动切换

**关键类**:
- `Profile`: 配置文件模型
- `ButtonMapping`: 按键映射
- `AppRule`: 应用匹配规则

**工作流程**:
```
1. 加载本地配置文件
2. 监听前台应用变化
3. 匹配应用规则
4. 激活对应配置
5. 应用按键映射
```

**配置切换逻辑**:
```swift
前台应用变化
    ↓
遍历所有 Profile
    ↓
检查 appRules 是否匹配
    ↓
    Yes → 激活该 Profile
    ↓
    No → 使用全局配置
```

### 5. PermissionManager

**职责**: 系统权限检查和请求

**权限类型**:
- 辅助功能 (Accessibility) - **必需**
- 输入监控 (Input Monitoring) - 可选

**检查流程**:
```swift
AXIsProcessTrusted() // macOS API
    ↓
    false → 引导用户打开系统设置
    ↓
    true → 继续运行
```

## 数据流

### 输入处理流程

```
手柄按键按下
    ↓
IOHIDManager 回调
    ↓
GamepadManager 解析事件
    ↓
ConfigurationEngine 查找映射
    ↓
根据映射类型分发:
    ├─ KeyboardShortcut → KeyboardSimulator
    ├─ MouseAction → MouseSimulator
    └─ CustomScript → Shell 执行
    ↓
系统接收模拟事件
```

### 摇杆处理流程

```
摇杆移动 (analog value)
    ↓
应用死区过滤
    ↓
应用加速曲线
    ↓
计算速度增量
    ↓
MouseSimulator.moveMouse(dx, dy)
    ↓
鼠标指针移动
```

## 配置文件格式

### Profile JSON 结构

```json
{
  "id": "uuid",
  "name": "配置名称",
  "mappings": [
    {
      "id": "uuid",
      "button": "buttonA",
      "action": {
        "keyboardShortcut": {
          "keyCode": 36,
          "modifiers": {
            "rawValue": 8
          }
        }
      },
      "enabled": true
    }
  ],
  "appRules": [
    {
      "appName": "Safari"
    },
    {
      "bundleID": "com.apple.Safari"
    }
  ],
  "stickSettings": {
    "leftStickMode": "mouse",
    "rightStickMode": "scroll",
    "deadzone": 0.15,
    "sensitivity": 1.0,
    "accelerationCurve": "linear"
  },
  "isActive": false
}
```

## 性能考虑

### 1. 输入延迟优化

- 使用高优先级 DispatchQueue
- 限制事件频率到 60Hz
- 避免主线程阻塞

### 2. 内存管理

- 弱引用避免循环引用
- 及时释放 HID 设备
- 配置文件按需加载

### 3. CPU 占用

- 闲置时不处理事件
- 使用高效的事件过滤
- 避免频繁的配置切换

## 安全性

### 1. 权限最小化

- 仅请求必要的辅助功能权限
- 不请求全盘访问权限

### 2. 沙盒兼容

- 使用 App Group 共享配置
- 符合 macOS 安全要求

### 3. 脚本安全

- 自定义脚本默认禁用
- 执行前显示警告
- 限制脚本权限

## 扩展性

### 添加新的输入设备

1. 在 `GamepadButton` 添加新按键
2. 在 `GamepadManager` 添加解析逻辑
3. 更新 UI 可视化

### 添加新的映射类型

1. 扩展 `MappingAction` 枚举
2. 实现对应的 Simulator
3. 在 `ConfigurationEngine` 添加分发逻辑
4. 更新 UI 编辑器

### 添加新的应用规则

1. 扩展 `AppRule` 枚举
2. 在 `ConfigurationEngine` 添加匹配逻辑
3. 更新 UI 规则编辑器

## 测试策略

### 单元测试

- GamepadEvent 解析
- 配置文件序列化/反序列化
- 应用规则匹配逻辑

### 集成测试

- 手柄连接/断开
- 配置自动切换
- 映射执行

### UI 测试

- 配置创建/编辑/删除
- 映射编辑器
- 权限引导流程

## 已知限制

1. **手柄兼容性**: 仅支持标准 HID 游戏手柄
2. **权限要求**: 必须授予辅助功能权限
3. **游戏冲突**: 某些游戏会独占手柄输入
4. **系统事件**: 无法模拟某些系统级快捷键

## 未来优化

1. **性能**: 使用 Metal 加速输入处理
2. **兼容性**: 支持更多手柄型号
3. **功能**: 添加振动反馈支持
4. **云端**: 配置文件 iCloud 同步
