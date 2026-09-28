# 贡献指南

首先，感谢你考虑为 InputRelay 做出贡献！🎉

## 📋 目录

- [行为准则](#行为准则)
- [我能做什么贡献？](#我能做什么贡献)
- [开发环境设置](#开发环境设置)
- [提交代码](#提交代码)
- [代码规范](#代码规范)
- [测试](#测试)
- [文档](#文档)

## 行为准则

参与本项目即表示你同意遵守我们的[行为准则](CODE_OF_CONDUCT.md)。请确保你的行为专业、尊重他人。

## 我能做什么贡献？

### 🐛 报告 Bug

发现问题？请[创建 Issue](https://github.com/yourusername/InputRelay/issues/new)，并包含：

- 清晰的标题和描述
- 重现步骤
- 预期行为 vs 实际行为
- macOS 版本和 InputRelay 版本
- 手柄型号
- 相关日志或截图

### ✨ 功能建议

有好主意？太棒了！请：

1. 先检查是否已有相关 Issue
2. 创建新 Issue，标注 `enhancement`
3. 详细描述你的想法和使用场景
4. 说明为什么这个功能有价值

### 🎨 改进 UI/UX

我们欢迎设计建议！请提供：

- 问题描述（当前设计的不足）
- 解决方案（你的建议）
- 模拟图或线框图（如果可能）

### 📝 改进文档

文档永远不嫌多！你可以：

- 修正拼写或语法错误
- 改进说明的清晰度
- 添加示例或教程
- 翻译文档到其他语言

### 🔧 提交代码

准备好贡献代码了吗？太好了！请继续阅读。

## 开发环境设置

### 前置要求

- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本
- Git
- 一个游戏手柄用于测试

### 设置步骤

1. **Fork 仓库**

   点击页面右上角的"Fork"按钮

2. **克隆你的 Fork**

   ```bash
   git clone https://github.com/YOUR_USERNAME/InputRelay.git
   cd InputRelay
   ```

3. **添加上游远程仓库**

   ```bash
   git remote add upstream https://github.com/yourusername/InputRelay.git
   ```

4. **打开项目**

   ```bash
   open Package.swift
   ```

   Xcode 会自动打开项目

5. **构建并运行**

   - 在 Xcode 中按 `⌘+B` 构建
   - 按 `⌘+R` 运行
   - 授予辅助功能权限（首次运行）

6. **连接手柄并测试**

## 提交代码

### 工作流程

1. **创建新分支**

   ```bash
   git checkout -b feature/your-feature-name
   # 或
   git checkout -b fix/your-bug-fix
   ```

   分支命名约定：
   - `feature/xxx` - 新功能
   - `fix/xxx` - Bug 修复
   - `docs/xxx` - 文档更新
   - `refactor/xxx` - 代码重构
   - `perf/xxx` - 性能优化

2. **进行更改**

   - 遵循[代码规范](#代码规范)
   - 保持提交小而专注
   - 写有意义的提交信息

3. **测试你的更改**

   ```bash
   # 构建
   swift build
   
   # 运行测试（如果有）
   swift test
   
   # 手动测试
   # - 连接手柄
   # - 测试你修改的功能
   # - 验证没有破坏现有功能
   ```

4. **提交更改**

   ```bash
   git add .
   git commit -m "feat: 添加 XXX 功能"
   ```

   提交信息格式：
   ```
   <type>: <subject>
   
   <body>
   
   <footer>
   ```

   类型（type）：
   - `feat`: 新功能
   - `fix`: Bug 修复
   - `docs`: 文档更新
   - `style`: 代码格式（不影响功能）
   - `refactor`: 重构
   - `perf`: 性能优化
   - `test`: 测试相关
   - `chore`: 构建/工具相关

5. **推送到你的 Fork**

   ```bash
   git push origin feature/your-feature-name
   ```

6. **创建 Pull Request**

   - 访问你的 Fork 页面
   - 点击"Compare & pull request"
   - 填写 PR 模板
   - 提交 PR

### Pull Request 指南

**好的 PR**：
- ✅ 解决一个明确的问题
- ✅ 有清晰的标题和描述
- ✅ 包含必要的测试
- ✅ 更新了相关文档
- ✅ 遵循代码规范
- ✅ 提交历史清晰

**PR 描述应包含**：
- 改动的动机和背景
- 如何测试这些改动
- 相关的 Issue 编号
- 截图或 GIF（如果是 UI 改动）

**PR 模板示例**：

```markdown
## 描述
简要描述这个 PR 做了什么。

## 动机和背景
为什么需要这个改动？解决了什么问题？

## 改动类型
- [ ] Bug 修复
- [ ] 新功能
- [ ] 性能优化
- [ ] 重构
- [ ] 文档更新

## 如何测试
1. 连接手柄
2. 打开设置
3. ...

## 相关 Issue
修复 #123

## 截图
（如果适用）

## 检查清单
- [ ] 我的代码遵循项目的代码规范
- [ ] 我已经进行了自我审查
- [ ] 我添加了必要的注释
- [ ] 我更新了相关文档
- [ ] 我的改动没有产生新的警告
- [ ] 我已经测试了我的改动
```

## 代码规范

### Swift 风格指南

我们遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)。

**基本原则**：

1. **命名**
   ```swift
   // ✅ 好的命名
   func processGamepadInput()
   let activeProfile: Profile
   var isConnected: Bool
   
   // ❌ 避免
   func process()
   let p: Profile
   var connected: Bool
   ```

2. **缩进和格式**
   - 使用 4 个空格缩进（不是 Tab）
   - 行宽限制在 120 字符
   - 运算符两侧加空格
   - 逗号后加空格

3. **类型**
   ```swift
   // ✅ 推断类型（当明显时）
   let name = "InputRelay"
   
   // ✅ 显式类型（当不明显时）
   let velocity: Float = calculateVelocity()
   ```

4. **可选值**
   ```swift
   // ✅ 使用 guard 提前返回
   guard let profile = currentProfile else {
       return
   }
   
   // ✅ 使用 if let 处理
   if let mapping = findMapping(for: button) {
       execute(mapping)
   }
   ```

5. **注释**
   ```swift
   /// 处理手柄按键事件
   /// 
   /// - Parameters:
   ///   - button: 被按下的按键
   ///   - isPressed: 按键状态
   /// - Returns: 是否成功处理
   func handleButton(_ button: GamepadButton, isPressed: Bool) -> Bool {
       // 实现...
   }
   ```

### 项目特定约定

1. **模型**
   - 使用 `struct` 而非 `class`（除非需要引用语义）
   - 实现 `Codable` 用于序列化
   - 添加必要的默认值

2. **视图**
   - 使用 SwiftUI
   - 小组件抽取为独立组件
   - 使用 `@State`, `@Binding` 等属性包装器

3. **核心逻辑**
   - 使用 `class` 实现单例或管理器
   - 遵循单一职责原则
   - 添加适当的错误处理

4. **异步代码**
   ```swift
   // ✅ 使用 async/await
   func loadProfile() async throws -> Profile {
       // ...
   }
   
   // ✅ 使用 Task
   Task {
       await processInput()
   }
   ```

## 测试

### 单元测试

```swift
import XCTest
@testable import InputRelay

final class CurveCalculatorTests: XCTestCase {
    func testLinearCurve() {
        let result = CurveCalculator.apply(0.5, curveType: .linear)
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }
    
    func testDeadzone() {
        let result = CurveCalculator.applyDeadzone(0.1, deadzone: 0.15)
        XCTAssertEqual(result, 0.0)
    }
}
```

### 手动测试清单

在提交 PR 前，请确保：

- [ ] 手柄能正确识别和连接
- [ ] 所有按键都能响应
- [ ] 摇杆移动流畅
- [ ] 配置切换正常工作
- [ ] UI 没有明显的错误或卡顿
- [ ] 在不同的应用中测试过
- [ ] 没有内存泄漏或崩溃

## 文档

### 代码注释

- 为公共 API 添加文档注释
- 对复杂逻辑添加解释性注释
- 避免不必要的注释（代码应该是自解释的）

### README 和指南

- 保持文档与代码同步
- 添加示例代码
- 包含截图或 GIF（如果适用）

### 翻译

我们欢迎文档翻译！请：

1. 在 `docs/` 目录下创建语言子目录（如 `docs/zh-CN/`）
2. 翻译主要文档文件
3. 更新主 README 中的语言链接

## 版本发布

版本号遵循[语义化版本](https://semver.org/)：

- **主版本号**: 不兼容的 API 改动
- **次版本号**: 向后兼容的新功能
- **修订号**: 向后兼容的问题修正

## 许可证

贡献到本项目的代码将采用 [MIT 许可证](LICENSE)。

---

## 需要帮助？

- 💬 在 [Discussions](https://github.com/yourusername/InputRelay/discussions) 提问
- 📧 发送邮件到 [email@example.com](mailto:email@example.com)
- 💬 加入 Discord 服务器（即将开放）

**再次感谢你的贡献！** 🙌
