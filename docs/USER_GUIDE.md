# InputRelay 用户指南

## 快速开始

### 1. 安装

下载最新版本的 InputRelay.dmg，将应用拖拽到 Applications 文件夹。

### 2. 首次启动

1. 打开 InputRelay
2. 允许辅助功能权限（必需）
3. 连接手柄
4. 开始使用

## 功能说明

### 菜单栏图标

- **绿色图标**: 手柄已连接，映射已启用
- **灰色图标**: 手柄未连接或映射已暂停

点击图标可以：
- 查看当前配置
- 快速切换配置
- 打开设置窗口
- 暂停/恢复映射
- 退出应用

### 配置管理

#### 创建新配置

1. 点击菜单栏图标 → 打开设置
2. 在"配置管理"标签中点击"新建配置"
3. 输入配置名称
4. 添加应用匹配规则（可选）
5. 配置按键映射

#### 应用匹配规则

配置可以自动在特定应用中激活：

- **应用名称匹配**: 例如 "Safari"
- **Bundle ID 匹配**: 例如 "com.apple.Safari"

当前台应用匹配任一规则时，该配置会自动激活。

### 按键映射

#### 映射类型

**1. 键盘快捷键**

将手柄按键映射为键盘快捷键，支持：
- 单个按键（A-Z, 0-9, 方向键等）
- 修饰键组合（⌘ Cmd, ⌥ Option, ⌃ Control, ⇧ Shift）

示例：
- A → Enter（确认）
- B → Esc（取消）
- X → ⌘T（新建标签）

**2. 鼠标操作**

- 左键
- 右键
- 中键
- 向上滚轮
- 向下滚轮

示例：
- L2 → 鼠标左键
- R2 → 鼠标右键

**3. 自定义脚本**

执行 Shell 命令或 AppleScript。

示例：
```bash
# 打开应用
open -a Safari

# 调节音量
osascript -e "set volume 5"

# 截图
screencapture -c
```

### 摇杆设置

#### 左摇杆 / 右摇杆

每个摇杆可以设置为：
- **鼠标移动**: 控制鼠标指针
- **滚轮**: 控制页面滚动
- **禁用**: 不响应输入

#### 灵敏度

控制摇杆移动速度，范围 0.1 - 5.0：
- **低 (0.5-1.0)**: 适合精确操作
- **中 (1.0-2.0)**: 日常使用
- **高 (2.0-5.0)**: 快速移动

#### 死区

防止摇杆漂移，范围 0.0 - 0.5：
- **小 (0.05-0.10)**: 灵敏但可能有漂移
- **中 (0.15-0.20)**: 推荐值
- **大 (0.25-0.50)**: 消除漂移但响应迟钝

#### 加速曲线

- **线性**: 恒定速度，精确控制
- **加速**: 小幅移动慢，大幅移动快
- **精确**: 全程低速，精细操作

## 常用配置

### 浏览器

```
左摇杆: 鼠标移动
右摇杆: 滚轮
L2: 左键
R2: 右键
A: Enter
B: Esc
X: ⌘T (新标签)
Y: ⌘R (刷新)
L1: ⌘[ (后退)
R1: ⌘] (前进)
```

### 视频播放器

```
A: Space (播放/暂停)
B: Esc (退出全屏)
L1: ← (快退)
R1: → (快进)
L2: ↓ (音量减)
R2: ↑ (音量加)
```

### 代码编辑器

```
A: Enter
B: Esc
X: ⌘/ (注释)
Y: ⌘S (保存)
L1: ⌘Z (撤销)
R1: ⌘⇧Z (重做)
L2: 鼠标左键
R2: 鼠标右键
```

## 故障排查

### 手柄无法识别

**症状**: 菜单栏图标显示灰色

**解决方案**:
1. 确认手柄已正确连接
2. 尝试重新插拔手柄
3. 检查手柄是否在其他应用中工作
4. 重启 InputRelay

### 映射不生效

**症状**: 按手柄按键没有反应

**解决方案**:
1. 检查辅助功能权限是否已授予
2. 确认当前配置已启用该映射
3. 查看"手柄状态"页面确认按键输入
4. 尝试重新创建映射

### 摇杆漂移

**症状**: 鼠标自动移动

**解决方案**:
1. 增大死区值（建议 0.15-0.25）
2. 清洁摇杆（使用压缩空气）
3. 检查手柄硬件是否有问题

### 输入延迟

**症状**: 按键响应慢

**解决方案**:
1. 关闭不需要的后台应用
2. 检查 CPU 占用
3. 降低灵敏度值
4. 使用有线连接（如果是无线手柄）

## 高级技巧

### 多配置工作流

为不同场景创建专用配置：
- 办公：邮件、文档、浏览器
- 娱乐：视频、音乐、照片
- 开发：编辑器、终端、浏览器

### 快捷操作脚本

常用脚本示例：

```bash
# 切换深色/浅色模式
osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to not dark mode'

# 锁定屏幕
pmset displaysleepnow

# 清空废纸篓
osascript -e 'tell application "Finder" to empty trash'

# 开启勿扰模式
shortcuts run "Toggle Focus"
```

### 配置备份

配置文件位置：
```
~/Library/Application Support/InputRelay/Profiles/
```

备份方法：
```bash
# 备份所有配置
cp -r ~/Library/Application\ Support/InputRelay/Profiles ~/Desktop/InputRelay-Backup

# 恢复配置
cp -r ~/Desktop/InputRelay-Backup/* ~/Library/Application\ Support/InputRelay/Profiles/
```

## 键盘符号说明

- ⌘ Command
- ⌥ Option (Alt)
- ⌃ Control
- ⇧ Shift
- ⎋ Escape
- ↩ Return (Enter)
- ⇥ Tab
- ⌫ Delete
- ← → ↑ ↓ 方向键

## 获取帮助

- 查看 [FAQ](https://github.com/yourusername/InputRelay/wiki/FAQ)
- 提交 [Issue](https://github.com/yourusername/InputRelay/issues)
- 加入社区讨论

## 更新日志

### v1.0.0 (2024-01-01)

- 初始版本发布
- 支持基础手柄输入
- 配置文件管理
- 应用自动切换
- 摇杆设置
