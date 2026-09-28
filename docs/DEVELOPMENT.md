# 开发指南

## 🔧 开发环境设置

### 必需工具

- **Swift 工具链**: 6.0 或更高版本
  - CommandLineTools: `xcode-select --install`
  - 或完整的 Xcode（从 Mac App Store 安装）
- **Git**: 用于版本控制
- **macOS 14.0+**: 开发和测试

### 验证环境

```bash
# 检查 Swift 版本
swift --version
# 应显示: Swift version 6.x

# 检查工具链
xcode-select -p
# 应显示工具链路径

# 克隆仓库
git clone https://github.com/yourusername/InputRelay.git
cd InputRelay
```

## 📦 构建项目

### 快速构建

```bash
# Debug 构建（默认，保留调试符号）
./build.sh

# Release 构建（优化，体积更小）
./build.sh release

# 查看生成的 .app
ls -lh .build/InputRelay.app/Contents/MacOS/InputRelay
```

### 手动构建步骤

如果需要更细粒度的控制：

```bash
# 1. 仅编译二进制文件（不打包）
swift build -c release

# 2. 查看二进制位置
swift build -c release --show-bin-path
# 输出: .build/arm64-apple-macosx/release

# 3. 运行二进制（不需要 .app bundle）
.build/arm64-apple-macosx/release/InputRelay
```

### 构建脚本详解

`build.sh` 执行以下步骤：

1. 使用 `swift build` 编译源码
2. 创建标准 `.app` bundle 目录结构
3. 复制可执行文件到 `Contents/MacOS/`
4. 复制 `Info.plist` 和资源文件
5. 复制编译产物中的 `.bundle` 资源
6. 进行 ad-hoc 代码签名

## 🧪 测试

### 运行应用

```bash
# 启动应用（直接显示主窗口，同时显示 Dock 和菜单栏入口）
open .build/InputRelay.app

# 或直接运行二进制
.build/arm64-apple-macosx/debug/InputRelay
```

### 调试技巧

**查看日志输出**:

```bash
# 运行并查看控制台日志
.build/arm64-apple-macosx/debug/InputRelay 2>&1 | tee /tmp/inputrelay.log
```

**权限问题**:

- 首次运行需要授予辅助功能权限
- 每次重新构建后，签名会改变，可能需要重新授权
- 在系统设置中移除旧条目，重新添加

**手柄连接测试**:

```bash
# 检查 HID 设备
ioreg -p IOUSB -w0 | grep -i gamepad
```

### 单元测试

测试包含手柄事件、权限刷新、双屏鼠标、映射冲突、键盘录入和组合键发送。

```bash
# 运行测试
swift test

# 测试覆盖率
swift test --enable-code-coverage
```

## 🏗️ 项目结构

```
InputRelay/
├── InputRelay/               # 主代码目录
│   ├── Sources/              # Swift 源文件
│   │   ├── App/              # 应用入口和菜单栏
│   │   ├── Core/             # 核心引擎（手柄、鼠标、键盘）
│   │   ├── Models/           # 数据模型
│   │   ├── Views/            # SwiftUI 视图
│   │   └── Utilities/        # 工具类
│   └── Resources/            # 资源文件
│       ├── Info.plist        # 应用元数据
│       └── Presets/          # 预设配置
├── Package.swift             # Swift Package 清单
├── build.sh                  # 构建脚本
└── docs/                     # 文档
```

## 📝 编码规范

### Swift 风格

- 使用 Swift 标准库命名约定
- 类型名使用 `PascalCase`
- 变量和函数使用 `camelCase`
- 私有成员添加 `private` 修饰符
- 使用 `// MARK:` 组织代码

### 并发安全

本项目使用 **Swift 6 严格并发检查**：

- 主线程 UI 类使用 `@MainActor`
- GameController 回调通过主队列处理；持续摇杆操作由主 RunLoop 定时采样
- 避免在 `deinit` 中访问 actor 隔离属性
- 使用 `Task { @MainActor in ... }` 跨隔离域调用

### 注释

- 为复杂逻辑添加注释
- 公开 API 使用文档注释 `///`
- 解释"为什么"而不是"做什么"

### 示例

```swift
/// 手柄管理器 - 负责检测和监听手柄输入
@MainActor
final class GamepadManager: ObservableObject {
    @Published private(set) var isConnected = false
    
    // MARK: - Controller Setup
    
    func start() {
        // 映射需要在其他应用位于前台时继续读取输入。
        GCController.shouldMonitorBackgroundEvents = true
        // ...
    }
}
```

## 🐛 常见问题

### 编译错误

**"SDK is not supported by the compiler"**

这通常是虚假报告，由沙盒阻止 clang 模块缓存导致。解决方案：

```bash
# 设置自定义缓存目录
export CLANG_MODULE_CACHE_PATH=/tmp/ir-cache/clang
export SWIFT_MODULE_CACHE_PATH=/tmp/ir-cache/swift

# 禁用 SwiftPM 嵌套沙盒
swift build --disable-sandbox
```

**"File not found: Resources"**

确保 `Package.swift` 的 `path` 指向 `InputRelay/`（不是 `InputRelay/Sources/`），
并且 `resources` 指向 `Resources/Presets`。

### 运行时问题

**手柄不响应**

1. 检查菜单栏图标颜色（绿色 = 已连接）
2. 确认辅助功能权限已授予
3. 在“手柄状态”检查设备是否被 GameController 识别；多模式设备切换至 Xbox / XInput 模式

**UI 不显示**

- 确认使用 `open .build/InputRelay.app` 启动
- 直接运行二进制文件可能无法加载 SwiftUI 资源

## 🚀 发布流程

### 创建 Release 构建

```bash
# 1. 更新版本号
# 编辑 InputRelay/Resources/Info.plist
#   CFBundleShortVersionString → "1.0.0"
#   CFBundleVersion → "1"

# 2. 构建 release 版本
./build.sh release

# 3. 验证构建产物
codesign -dv .build/InputRelay.app
file .build/InputRelay.app/Contents/MacOS/InputRelay

# 4. 测试应用
open .build/InputRelay.app
```

### 创建 DMG（可选）

```bash
# 创建磁盘映像
hdiutil create -volname "InputRelay" \
    -srcfolder .build/InputRelay.app \
    -ov -format UDZO \
    InputRelay-v1.0.0.dmg
```

### 代码签名（分发用）

对于公开分发，需要 Apple Developer 账号：

```bash
# 使用开发者证书签名
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    .build/InputRelay.app

# 公证（notarization）
xcrun notarytool submit InputRelay-v1.0.0.dmg \
    --apple-id "your@email.com" \
    --password "app-specific-password" \
    --team-id "TEAM_ID"
```

## 📚 相关资源

- [Swift Package Manager](https://swift.org/package-manager/)
- [IOKit 文档](https://developer.apple.com/documentation/iokit)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [HID 使用页表](https://usb.org/sites/default/files/hut1_3_0.pdf)

## 🤝 贡献

查看 [CONTRIBUTING.md](../CONTRIBUTING.md) 了解如何贡献代码。

## 输入与权限回归验证

```bash
swift test
```

测试使用系统提供的可写手柄快照，覆盖 Xbox 面键/肩键、方向键斜向和松开、独立模拟扳机、摇杆回中、持续采样、映射录入隔离、断连接管、旧配置兼容及权限授予/撤销刷新。真实设备连接、系统权限面板和合成输入仍需实机验证。

若 Command Line Tools 的 macOS 27 SDK 缺失 SwiftUI 宏插件，可指定本机已安装的 SDK：

```bash
swift test --sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk --disable-xctest \
  -Xswiftc -load-plugin-library \
  -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib
```

上述额外参数用于当前 Command Line Tools 的测试插件搜索路径问题，完整 Xcode 环境通常无需指定。在外层沙盒中构建时，可以设置 `INPUTRELAY_DISABLE_SANDBOX=1` 关闭 SwiftPM 的嵌套沙盒；不会关闭外层沙盒。

在外层沙盒内，若新版 `swiftbuild` 的 dSYM 生成任务返回 `Operation not permitted`，可设置 `INPUTRELAY_BUILD_SYSTEM=native` 使用 SwiftPM 的兼容构建后端。此次验证使用以下命令成功生成并校验 release 应用：

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/ModuleCache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/ModuleCache" \
INPUTRELAY_BUILD_SYSTEM=native \
INPUTRELAY_DISABLE_SANDBOX=1 \
INPUTRELAY_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk \
./build.sh release
```

若兼容构建后端提示 `no such module 'Testing'`，需要补充 Command Line Tools 自带的测试框架路径：

```bash
CLANG_MODULE_CACHE_PATH="$PWD/.build/ModuleCache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/ModuleCache" \
swift test --build-system native --disable-sandbox \
  --sdk /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk --disable-xctest \
  -Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -F -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xswiftc -load-plugin-library \
  -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib
```
