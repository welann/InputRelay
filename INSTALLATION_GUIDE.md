# InputRelay 安装和使用指南

## 🚀 快速开始

### 系统要求

- **操作系统**: macOS 14.0 (Sonoma) 或更高版本
- **处理器**: Apple Silicon (M1/M2/M3) 或 Intel
- **手柄**: 支持 HID 标准的游戏手柄（Xbox、PlayStation、Switch Pro Controller、冰原狼等）

### 安装步骤

#### 方式 1: 下载预编译版本（推荐）

1. 前往 [Releases](https://github.com/yourusername/InputRelay/releases) 页面
2. 下载最新的 `InputRelay.dmg`
3. 双击打开 DMG 文件
4. 将 InputRelay 图标拖入 Applications 文件夹
5. 在 Finder 中打开 Applications，双击 InputRelay
6. 如果出现"无法验证开发者"提示：
   - 右键点击 InputRelay
   - 选择"打开"
   - 点击"打开"确认

#### 方式 2: 从源码构建

**前提条件**:
- 安装 Xcode 或 CommandLineTools
- Swift 6.0 或更高版本

**步骤**:

```bash
# 1. 克隆仓库
git clone https://github.com/yourusername/InputRelay.git
cd InputRelay

# 2. 使用 Xcode 构建（推荐）
open Package.swift
# 在 Xcode 中按 ⌘+B 构建
# 或选择 Product → Run

# 3. 或使用命令行（需要解决 SDK 版本问题）
swift build -c release

# 4. 运行
.build/release/InputRelay
```

**如果遇到 SDK 版本问题**:

```bash
# 更新 CommandLineTools
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install

# 或切换到 Xcode 工具链
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## ⚙️ 首次配置

### 1. 授予辅助功能权限（必需）

InputRelay 首次启动时会自动引导你授权：

1. 点击"打开系统设置"按钮
2. 系统设置会自动跳转到"隐私与安全性"
3. 在左侧选择"辅助功能"
4. 找到 InputRelay，打开开关 ✅
5. 返回 InputRelay，点击"重新检查"

**手动授权步骤**:

```
系统设置 → 隐私与安全性 → 辅助功能 → 启用 InputRelay
```

### 2. 连接手柄

1. 通过蓝牙或 USB 连接手柄
2. 手柄连接成功后，菜单栏图标会变为绿色 🟢
3. 按任意按键测试连接

### 3. 选择配置

InputRelay 提供了几个预设配置：

- **全局默认** - 适用于所有应用的通用配置
- **浏览器专用** - 优化网页浏览体验
- **视频播放器** - 针对视频播放的快捷键

点击菜单栏图标，选择一个配置开始使用。

## 🎮 基础使用

### 默认映射（全局配置）

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
摇杆控制
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
左摇杆       → 鼠标移动
右摇杆       → 页面滚动

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
按键映射
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
A (下方)     → Enter (确认)
B (右方)     → Esc (取消)
X (左方)     → 无映射
Y (上方)     → 无映射

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
肩键和扳机
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
L1 (左肩键)   → 无映射
R1 (右肩键)   → 无映射
L2 (左扳机)   → 鼠标左键
R2 (右扳机)   → 鼠标右键

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
方向键
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
↑            → 上箭头
↓            → 下箭头
←            → 左箭头
→            → 右箭头

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
特殊按键
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select       → 无映射
Start        → 无映射
```

### 浏览器配置映射

专为网页浏览优化：

```
A            → Enter (确认链接)
B            → Esc (取消/关闭)
X            → ⌘T (新标签)
Y            → ⌘R (刷新)
L1           → ⌘[ (后退)
R1           → ⌘] (前进)
L2           → 鼠标左键 (点击链接)
R2           → 鼠标右键 (右键菜单)
```

### 视频播放器配置

专为视频播放优化：

```
A            → Space (播放/暂停)
B            → Esc (退出全屏)
L1           → ← (后退 5 秒)
R1           → → (前进 5 秒)
L2           → ↓ (音量减)
R2           → ↑ (音量加)
```

## 🔧 自定义配置

### 创建新配置

1. 点击菜单栏图标 → "打开设置"
2. 在"配置管理"标签点击"+ 新建配置"
3. 输入配置名称（例如："编辑器专用"）
4. 添加应用匹配规则

### 配置按键映射

1. 在手柄可视化面板中点击要配置的按键
2. 在弹出窗口中选择动作类型：
   - **键盘快捷键** - 按下物理键盘的组合键来录制
   - **鼠标操作** - 选择鼠标左键/右键/中键
   - **自定义脚本** - 输入 Shell 命令或 AppleScript

3. 点击"保存"

### 调整摇杆设置

1. 在配置编辑器中找到"摇杆设置"
2. 调整参数：
   - **灵敏度**: 0.5 - 3.0（推荐 1.0 - 1.5）
   - **死区**: 0.0 - 0.5（推荐 0.15）
   - **加速曲线**:
     - 线性 - 恒定速度
     - 加速 - 小动作慢，大动作快
     - 精确 - 全程低速，适合精细操作

### 配置应用规则

让配置自动在特定应用中生效：

1. 在配置编辑器中找到"应用匹配规则"
2. 点击"添加规则"
3. 输入应用名称（例如：Safari）或 Bundle ID
4. 当切换到该应用时，配置会自动激活

**常用应用 Bundle ID**:

```
Safari          → com.apple.Safari
Chrome          → com.google.Chrome
Firefox         → org.mozilla.firefox
VSCode          → com.microsoft.VSCode
IINA            → com.colliderli.iina
QuickTime       → com.apple.QuickTimePlayerX
```

## 💡 使用技巧

### 临时暂停映射

- 点击菜单栏图标 → "暂停映射"
- 或设置快捷键（在设置中）
- 再次点击恢复

### 快速切换配置

- 点击菜单栏图标
- 最近使用的 3 个配置会显示在顶部
- 点击即可切换

### 导出和导入配置

```bash
# 配置文件位置
~/Library/Application Support/InputRelay/Profiles/

# 导出配置
cp ~/Library/Application\ Support/InputRelay/Profiles/my-config.json ~/Desktop/

# 导入配置
cp ~/Desktop/my-config.json ~/Library/Application\ Support/InputRelay/Profiles/
```

### 自定义脚本示例

**锁定屏幕**:
```bash
pmset displaysleepnow
```

**截图到剪贴板**:
```bash
screencapture -c
```

**调节音量到 50%**:
```applescript
osascript -e "set volume output volume 50"
```

**打开应用**:
```bash
open -a "Visual Studio Code"
```

## 🐛 常见问题

### 手柄无法识别

**症状**: 菜单栏图标显示红色 🔴

**解决方案**:
1. 确认手柄已正确连接（蓝牙或 USB）
2. 在系统设置中检查蓝牙连接状态
3. 尝试断开并重新连接手柄
4. 重启 InputRelay
5. 某些手柄可能需要特定驱动（查看手柄说明书）

### 按键没有响应

**症状**: 按下手柄按键，没有任何动作

**检查清单**:
- [ ] 是否授予了辅助功能权限
- [ ] 当前配置是否启用了该按键的映射
- [ ] 映射是否有误（例如键码错误）
- [ ] 是否在"暂停"状态

**调试方法**:
1. 打开设置窗口
2. 查看手柄可视化面板
3. 按下按键，确认按键被识别（按键会高亮）
4. 如果识别但无效果，检查权限和映射

### 鼠标移动太快/太慢

**调整方法**:
1. 打开配置编辑器
2. 找到"摇杆设置"
3. 调整"灵敏度"滑块
   - 降低灵敏度 → 移动变慢
   - 提高灵敏度 → 移动变快

### 有死区，小幅移动不响应

**调整方法**:
1. 打开摇杆设置
2. 调整"死区"滑块
   - 降低死区 → 更灵敏，但可能有漂移
   - 提高死区 → 减少漂移，但需要更大幅度

### 与游戏冲突

**症状**: 玩游戏时手柄被 InputRelay 占用

**解决方案**:
1. 在玩游戏前点击"暂停映射"
2. 或在游戏的配置中添加规则，将所有按键映射为"无动作"
3. 或退出 InputRelay

### CPU 占用过高

**可能原因**:
- 摇杆轮询频率过高
- 同时运行多个配置

**解决方案**:
1. 降低摇杆灵敏度
2. 关闭不需要的配置
3. 检查是否有死循环的自定义脚本

## 🔐 隐私和安全

### InputRelay 会收集什么数据？

**完全不会！** InputRelay 是完全离线运行的应用：

- ❌ 不会联网
- ❌ 不会收集任何使用数据
- ❌ 不会上传配置文件
- ❌ 不会追踪你的操作

### 为什么需要辅助功能权限？

辅助功能权限允许 InputRelay：
- 模拟鼠标移动和点击
- 模拟键盘按键
- 监听前台应用切换

这些是手柄映射功能的核心需求。macOS 要求所有此类应用获得该权限。

### 配置文件存储在哪里？

```
~/Library/Application Support/InputRelay/
├── Profiles/           # 配置文件
├── Settings.json       # 全局设置
└── Logs/              # 日志文件（如果启用）
```

所有数据都存储在本地，你拥有完全控制权。

## 📞 获取帮助

### 报告问题

1. 前往 [GitHub Issues](https://github.com/yourusername/InputRelay/issues)
2. 点击"New Issue"
3. 提供以下信息：
   - macOS 版本
   - InputRelay 版本
   - 手柄型号
   - 详细的问题描述
   - 复现步骤

### 功能建议

我们欢迎任何改进建议！请在 Issues 中标注 `enhancement` 标签。

### 社区讨论

- [GitHub Discussions](https://github.com/yourusername/InputRelay/discussions)
- [Discord 服务器](#)（即将开放）

---

**祝你使用愉快！🎮**
