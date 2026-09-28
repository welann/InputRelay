# InputRelay

将游戏手柄转化为 Mac 的精确输入设备 - 用手柄控制你的 Mac

<div align="center">

![Platform](https://img.shields.io/badge/platform-macOS%2014.0+-blue)
![Swift](https://img.shields.io/badge/swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

</div>

## ✨ 特性

- 🎮 **手柄支持** - 完整支持冰原狼 4 代及其他标准 HID 游戏手柄
- 🖱️ **鼠标模拟** - 摇杆精确控制鼠标移动，可调节灵敏度和加速曲线
- ⌨️ **键盘映射** - 将手柄按键映射为任意键盘快捷键
- 🎯 **应用适配** - 为不同应用自动切换配置文件
- 🎨 **精美界面** - 深色主题，手柄状态实时可视化
- ⚡ **低延迟** - 高性能输入处理，延迟小于 16ms
- 🔧 **高度自定义** - 完全自定义按键映射和摇杆行为

## 📸 截图

_即将添加_

## 🚀 快速开始

### 安装

#### 方式 1: 下载预编译版本（推荐）

1. 前往 [Releases](https://github.com/yourusername/InputRelay/releases) 页面
2. 下载最新的 `InputRelay.dmg`
3. 打开 DMG 文件，将 InputRelay 拖入 Applications 文件夹

#### 方式 2: 从源码构建

```bash
# 克隆仓库
git clone https://github.com/yourusername/InputRelay.git
cd InputRelay

# 构建（会生成 .app bundle）
./build.sh release

# 运行
open .build/InputRelay.app
```

### 首次使用

1. 启动 InputRelay
2. 系统会提示授予**辅助功能权限**（必需）
3. 前往 **系统设置 > 隐私与安全性 > 辅助功能**，启用 InputRelay
4. 连接手柄
5. 菜单栏图标变为绿色表示已就绪 ✅

## 🎮 使用说明

### 基础操作

**菜单栏控制**
- 点击菜单栏图标查看当前配置
- 快速切换不同配置文件
- 暂停/恢复映射
- 打开设置窗口

**创建配置**
1. 点击"打开设置"
2. 在"配置管理"标签中点击"新建配置"
3. 为配置命名（例如："浏览器专用"）
4. 添加应用匹配规则（例如：Safari、Chrome）
5. 配置按键映射

### 默认映射示例

**浏览器配置**
```
左摇杆    → 鼠标移动
右摇杆    → 页面滚动
L2        → 鼠标左键
R2        → 鼠标右键
A         → Enter (确认)
B         → Esc (取消)
X         → ⌘T (新标签)
Y         → ⌘R (刷新)
L1        → ⌘[ (后退)
R1        → ⌘] (前进)
```

**视频播放器配置**
```
A         → Space (播放/暂停)
B         → Esc (退出全屏)
L1        → ← (快退)
R1        → → (快进)
L2        → ↓ (音量减)
R2        → ↑ (音量加)
```

### 高级功能

**摇杆设置**
- **灵敏度**: 0.1 - 5.0（推荐 1.0 - 2.0）
- **死区**: 0.0 - 0.5（推荐 0.15）
- **加速曲线**: 线性 / 加速 / 精确

**自定义脚本**

将按键映射到 Shell 命令或 AppleScript：

```bash
# 锁定屏幕
pmset displaysleepnow

# 截图
screencapture -c

# 调节音量
osascript -e "set volume 5"
```

## 🛠️ 技术栈

- **Swift 6.0** - 现代化的 Swift 语言
- **SwiftUI** - 原生 macOS 界面
- **IOKit** - 手柄 HID 设备通信
- **CoreGraphics** - 鼠标和键盘事件模拟
- **AppKit** - 菜单栏集成和应用监听
- **Carbon** - 虚拟键码定义

无外部依赖，完全使用 macOS 原生框架。

## 📚 文档

- [用户指南](docs/USER_GUIDE.md) - 详细的使用说明
- [开发文档](docs/DEVELOPMENT.md) - 开发者指南
- [架构设计](docs/ARCHITECTURE.md) - 系统架构说明

## 🤝 贡献

欢迎贡献代码、报告问题或提出建议！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 🐛 问题反馈

遇到问题？请在 [Issues](https://github.com/yourusername/InputRelay/issues) 页面报告。

提交 Issue 时请包含：
- macOS 版本
- InputRelay 版本
- 手柄型号
- 详细的问题描述
- 复现步骤

## 📝 路线图

- [ ] v1.0.0 - 基础功能
  - [x] 手柄输入检测
  - [x] 鼠标/键盘模拟
  - [x] 配置文件管理
  - [x] 应用自动切换
  - [x] SwiftUI 界面
  
- [ ] v1.1.0 - 增强功能
  - [ ] 手柄振动反馈
  - [ ] 宏录制功能
  - [ ] 配置云同步 (iCloud)
  - [ ] 社区预设库
  
- [ ] v1.2.0 - 高级功能
  - [ ] 手势识别（双击、长按等）
  - [ ] 多手柄支持
  - [ ] 统计和分析
  - [ ] 插件系统

## 🌟 致谢

- 灵感来源于各类游戏手柄映射工具
- 感谢所有贡献者和测试者

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 💡 常见问题

**Q: 支持哪些手柄？**  
A: 支持所有标准 HID 游戏手柄，包括 Xbox、PlayStation、Switch Pro Controller 和冰原狼系列。

**Q: 为什么需要辅助功能权限？**  
A: macOS 要求应用获得辅助功能权限才能模拟键盘和鼠标输入。

**Q: 输入延迟有多少？**  
A: 目标延迟小于 16ms（60 FPS）。实际延迟取决于系统负载和手柄硬件。

**Q: 会与游戏冲突吗？**  
A: 某些游戏会独占手柄输入。建议在玩游戏时暂停 InputRelay。

**Q: 可以同时使用键盘鼠标吗？**  
A: 可以！InputRelay 不会禁用原有的键盘鼠标输入。

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️**

Made with ❤️ by [Your Name]

</div>
