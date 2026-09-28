# InputRelay 开发指南

## 开发环境设置

### 必需工具

- Xcode 16.0 或更高版本
- Swift 6.0 或更高版本
- macOS 14.0 (Sonoma) 或更高版本

### 克隆项目

```bash
git clone https://github.com/yourusername/InputRelay.git
cd InputRelay
```

### 构建项目

#### 使用 Swift Package Manager

```bash
# 调试构建
swift build

# 发布构建
swift build -c release

# 运行
swift run
```

## 项目结构

```
InputRelay/
├── Sources/
│   ├── App/                    # 应用程序入口
│   ├── Core/                   # 核心业务逻辑
│   ├── Models/                 # 数据模型
│   ├── Views/                  # SwiftUI 视图
│   ├── Utilities/              # 工具类
│   └── Resources/              # 资源文件
├── docs/                       # 文档
├── Package.swift               # SPM 配置
└── README.md
```

## 编码规范

### Swift 风格

遵循 Swift API Design Guidelines

```swift
// 命名
class GamepadManager { }          // UpperCamelCase for types
let activeProfile: Profile        // lowerCamelCase for properties
func startMonitoring() { }        // lowerCamelCase for functions
```

## 测试

```bash
# 运行所有测试
swift test

# 运行特定测试
swift test --filter GamepadManagerTests
```

## 构建和发布

### 创建 Release 构建

```bash
swift build -c release
```

### 代码签名

需要 Apple Developer 账号和有效的代码签名证书。

## 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交更改
4. 推送到分支
5. 开启 Pull Request

## 资源链接

- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [IOKit HID Documentation](https://developer.apple.com/documentation/iokit)
