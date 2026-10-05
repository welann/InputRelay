# InputRelay 安装指南

## 📋 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- 支持的手柄：
  - 冰原狼 4 代
  - Xbox 系列手柄
  - PlayStation DualShock / DualSense
  - macOS GameController 可识别的其他扩展游戏手柄

## 🚀 安装方式

### 方式 1: 下载预编译版本（推荐）

1. 前往 [Releases](https://github.com/yourusername/InputRelay/releases) 页面
2. 下载最新的 `InputRelay.dmg`
3. 打开 DMG 文件
4. 将 InputRelay 拖入 Applications 文件夹
5. 首次打开时，右键点击并选择"打开"以绕过 Gatekeeper

### 方式 2: 从源码构建

**前提条件**:
- Swift 工具链（CommandLineTools 或完整 Xcode 均可）
- macOS 14+ SDK

**步骤**:

```bash
# 1. 克隆仓库
git clone https://github.com/yourusername/InputRelay.git
cd InputRelay

# 2. 运行构建脚本（会编译并打包成 .app）
./build.sh release

# 3. 打开应用
open .build/InputRelay.app
```

构建脚本会：
- 使用 `swift build -c release` 编译二进制文件
- 组装标准 `.app` bundle 结构
- 复制 Info.plist 和资源文件
- 进行临时 ad-hoc 签名（方便本机授权辅助功能）

**疑难解答**：如果构建失败，检查 Swift 版本是否匹配 SDK：

```bash
swift --version
# 应显示 Swift 6.x

# 如果版本不匹配，可以尝试更新 CommandLineTools：
# softwareupdate --list
# softwareupdate --install "Command Line Tools for Xcode-XX.X"
```

## ⚙️ 首次配置

### 1. 授予辅助功能权限（必需）

InputRelay 启动时直接显示浅色主窗口，窗口内提示尚未授予的权限：

1. 点击"打开系统设置"按钮
2. 系统设置会自动跳转到"隐私与安全性"
3. 在左侧选择"辅助功能"
4. 找到 InputRelay，打开开关 ✅

**手动授权步骤**（如果自动引导失败）：

1. 打开"系统设置"
2. 进入"隐私与安全性" → "辅助功能"
3. 点击左下角的锁图标解锁
4. 点击 "+" 按钮
5. 找到并添加 InputRelay
6. 确保其开关处于打开状态；应用会每秒刷新，切回窗口时也会重新检测

若系统设置已开启而应用仍显示未授权，请在“高级设置”点击“定位当前应用”，确认授权的是正在运行的 `.app`。重新构建或替换临时签名应用后，移除旧条目并重新添加，再重启 InputRelay。无需额外授予输入监控权限来读取标准手柄。

> ⚠️ **重要**: InputRelay 必须获得辅助功能权限才能模拟键盘和鼠标操作。没有此权限，应用无法正常工作。

### 2. 连接手柄

1. 通过蓝牙或 USB 连接你的游戏手柄
2. 打开主窗口的“手柄状态”，检查设备名称和按键反馈
3. 多模式设备请选择 Xbox / XInput 模式；按键显示为 LB / RB、LT / RT、View / Menu

### 3. 选择或创建配置

InputRelay 预置了两个配置：

- **全局配置**: 适用于所有应用的通用映射
- **浏览器专用**: 针对 Safari/Chrome/Firefox 优化的映射

**创建新配置**:

1. 点击菜单栏图标 → "打开设置"
2. 在"配置管理"标签中点击"新建配置"
3. 为配置命名（例如："视频剪辑"）
4. 添加应用匹配规则（应用名称或 Bundle ID）
5. 配置按键映射

## 🎮 基础使用

### 快速开始

1. 启动 InputRelay（直接显示主窗口，保留菜单栏入口，不显示 Dock 图标）
2. 连接手柄（图标变为彩色）
3. 手柄输入会自动转换为键盘/鼠标操作

### 菜单栏控制

- **单击图标**: 打开快捷菜单
- **绿色图标**: 手柄已连接，映射已启用
- **灰色图标**: 手柄未连接或映射已暂停

### 暂停/恢复映射

在菜单中选择"暂停映射"（或按 ⌘P）可以临时禁用所有手柄映射，方便在玩游戏时切换。

## 🔧 高级配置

### 摇杆设置

在配置编辑界面可以调整：

- **左/右摇杆模式**: 鼠标移动、滚轮、禁用
- **灵敏度**: 0.1 - 5.0（推荐 1.0 - 2.0）
- **死区**: 0.0 - 0.5（推荐 0.15，避免漂移）
- **加速曲线**: 
  - 线性：恒定速度
  - 加速：小动作慢，大动作快
  - 精确：全程低速，适合精细操作

### 应用自动切换

配置文件可以绑定到特定应用，InputRelay 会在切换应用时自动激活对应配置：

1. 编辑配置
2. 添加"应用规则"
3. 输入应用名称（如"Safari"）或 Bundle ID（如"com.apple.Safari"）

当你切换到匹配的应用时，配置会自动生效。

### 自定义脚本

高级用户可以将按键映射到 Shell 命令或 AppleScript：

```bash
# 锁定屏幕
pmset displaysleepnow

# 截图
screencapture -c

# 调节音量
osascript -e "set volume 5"
```

## ❓ 常见问题

### Q: 手柄连接但无响应？

1. 确认已授予辅助功能权限
2. 检查菜单栏图标是否为绿色
3. 确认映射未被暂停
4. 尝试断开重连手柄

### Q: 与游戏冲突？

某些游戏会独占手柄输入。建议：
- 玩游戏时暂停 InputRelay 映射
- 或临时退出 InputRelay

### Q: 如何完全卸载？

```bash
# 1. 退出 InputRelay
# 2. 删除应用
rm -rf /Applications/InputRelay.app

# 3. 删除配置文件（可选）
rm -rf ~/Library/Application\ Support/InputRelay

# 4. 在系统设置中移除辅助功能权限
```

### Q: 能同时使用键盘鼠标吗？

可以！InputRelay 不会禁用原有的键盘鼠标输入。

### Q: 支持多个手柄吗？

当前版本仅支持一个手柄。多手柄支持计划在未来版本添加。

## 🆘 获取帮助

- 查看 [用户指南](docs/USER_GUIDE.md)
- 报告问题: [GitHub Issues](https://github.com/yourusername/InputRelay/issues)
- 查看 [FAQ](README.md#常见问题)

## 🔄 更新

### 检查更新

InputRelay 会在启动时检查新版本（需要网络连接）。

### 手动更新

1. 下载新版本
2. 退出旧版本
3. 用新版本替换旧 .app 文件
4. 重新打开

**注意**: 如果重新构建后辅助功能权限失效，需要：
1. 在系统设置中移除旧的 InputRelay 条目
2. 重新添加新构建的版本

### 稳定签名与 SDK 选择

默认使用本地 ad-hoc 签名。若已有代码签名证书，可在构建时指定同一签名身份，减少更新后重新授权的问题：

```bash
CODE_SIGN_IDENTITY="你的代码签名证书名称" ./build.sh release
```

如果当前 Command Line Tools 的 macOS 27 SDK 缺少 `SwiftUIMacros` 插件，可以使用已安装的 macOS 26.5 SDK：

```bash
INPUTRELAY_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk ./build.sh release
```
