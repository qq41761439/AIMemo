# AIMemo iOS/Android 实现补充规范

记录时间：2026-05-14

## 1. 定位与范围

AIMemo 移动 App 先做原生 iOS 和 Android。iOS 使用 SwiftUI，Android 使用 Kotlin、Jetpack Compose 和 Material 3。

移动 App 的产品结构、页面清单、交互和视觉以 [移动端产品文档](product-document-app.md) 为准。本文件只补充平台实现、可访问性、状态反馈和验收要求；当两份文档冲突时，以 `product-document-app.md` 为准。

移动 App 当前页面范围：

- 登录/注册合一页
- Onboarding 引导页
- Tasks 主页面
- Task 编辑页
- Task 详情页（可选）
- Profile / 我的页面
- Settings 页面
- Summary 入口页面
- Summary 生成结果页
- Summary 历史列表页

## 2. 设计基准

- 设计基准屏幕：iPhone 13 / 14 / 15 竖屏，390 x 844 pt。
- App 视觉：白底、圆角卡片、柔和阴影、紫色渐变按钮。
- 文案和排版要面向国际化，避免只适配中文长度。
- Android 可以使用 Material 3 控件实现，但视觉结果应贴近移动端产品文档，而不是旧绿色品牌 token。

## 3. 字体与尺寸

固定字号以移动端产品文档为准：

| 元素 | 字号 | 字重 / 风格 |
| --- | --- | --- |
| 页面标题 | 22 pt | Semibold / Bold |
| Tab / Section Header | 16 pt | Semibold |
| 输入框标签 | 14 pt | Medium |
| 输入框内容 | 16 pt | Regular |
| Toggle 文案 | 16 pt | Medium |
| 按钮文字 | 16 pt | Semibold / Bold |
| Delete 按钮 | 14 pt | Medium |
| Placeholder | 16 pt | Regular |
| 辅助信息 / Subtext | 12 pt | Regular |
| 标签文字 | 14 pt | Medium |

其他要求：

- 行高：1.3-1.4 倍字体大小。
- 按钮高度：至少 44 pt / dp。
- Tag 标签高度：24-28 pt / dp。
- iOS 使用 SF Pro 和系统 Dynamic Type。
- Android 使用 Roboto 和 Material 3 type scale，但字号要贴近上表。
- 不使用负字距；列表和按钮文字不能溢出容器。

## 4. 页面实现要点

### 4.1 登录/注册合一页

- 支持邮箱/密码登录。
- 支持忘记密码入口。
- 第三方登录为可选能力。
- 登录、注册、忘记密码和第三方登录都需要 loading、success、error 和 disabled 状态。

### 4.2 Onboarding

- 展示 Tasks / AI Summary 核心能力。
- 支持跳过。
- 插图、标题、简短描述和下一步按钮要适配 390 x 844 pt 基准屏。

### 4.3 Tasks

- 主页面展示 Active / Upcoming / Completed 三个分组。
- 标签筛选栏展示 All / Product / Client / Study / Personal 等筛选项，具体标签可来自真实数据。
- 任务列表展示一行标题，以及一行标签 + 开始时间 / 结束时间。
- 多标签任务列表移除额外图标，避免干扰文本扫描。
- 底部快速添加任务按钮进入新增或编辑流程。

### 4.4 Task 编辑与详情

- Task 编辑页字段：Title、Notes、Tags、Start Time。
- 提供 Mark as completed 开关、Delete task 按钮和 Save Changes 按钮。
- Delete task 使用红色警告文字，并要求二次确认或可撤销反馈。
- Task 详情页为可选页面，展示标题、标签、日期和备注，并可勾选完成。
- 任务详情只展示具体日期；具体时间仅在 Task 编辑页或详情页展示。

### 4.5 Profile / 我的

- 展示账户信息、头像、通知、帮助与反馈。
- 使用简洁卡片布局和紫色点缀。
- Profile 不替代 Settings；更细的账户设置、同步、隐私与帮助入口放在 Settings。

### 4.6 Settings

- 展示账户设置、同步选项、隐私与帮助。
- 不把桌面端自定义模型 API Key 配置作为移动 App 首版主流程，除非产品文档后续明确加入。

### 4.7 Summary

Summary 入口页面：

- 展示 AI Summary Hero 卡片。
- 展示 Generate Summary 按钮。
- 支持 Daily / Weekly / Monthly / Custom 报告类型选择。
- 点击生成进入 Summary 生成结果页。
- 点击历史进入 Summary 历史列表页。

Summary 生成结果页：

- 展示生成内容。
- 支持通过输入框对话修改。
- 提供满意确认按钮。
- 结果结构包含 What I completed、Key outcomes、Next steps 和 Included tasks。
- 提供 Copy / Share 操作。

Summary 历史列表页：

- 支持 Daily / Weekly / Monthly / Custom 类型切换。
- 记录默认收起，展示任务数量、日期和摘要。
- 点击记录在当前页面展开完整内容，不跳转详情页。
- 历史页不再展示 Generate Summary 按钮。

## 5. 平台适配

### 5.1 iOS

- 根结构优先使用 `NavigationStack`。
- 列表可使用 `List` 或自定义列表。
- 编辑任务可使用 sheet 或全屏页面。
- 标题、返回、sheet 高度、键盘避让遵守 iOS 习惯。
- 重要确认、完成任务和生成成功可使用轻量 haptic。
- 支持 Dynamic Type，不因文字放大导致按钮文字溢出。

### 5.2 Android

- 使用 Kotlin、Jetpack Compose 和 Material 3。
- 根结构优先使用 Compose Navigation。
- 顶部栏、按钮、输入框、Tab、Snackbar 等使用 Material 3 组件承载。
- 不使用系统动态取色覆盖移动端产品文档的紫色主视觉。
- 支持系统返回键：sheet 或弹窗先关闭，再返回上一页。
- 反馈使用 Snackbar、Toast 或页面内状态，保持 Material 交互习惯。

## 6. 状态与反馈

所有主要操作必须覆盖：

- idle
- loading
- success
- error
- disabled

错误信息应靠近发生错误的控件。全局错误可以用 Snackbar，但表单验证错误不只放在页面顶部。

需要明确 loading 状态的页面和操作：

- 登录/注册
- Onboarding 图片或远程内容加载
- Tasks 列表
- Task 保存和删除
- Profile
- Settings
- Summary 生成
- Summary 对话修改
- Summary 历史

删除任务必须二次确认或提供撤销入口。删除成功后任务从可见列表移除，标签筛选随任务关联刷新。

## 7. 可访问性与响应式

- 正文对比度至少满足 WCAG AA。
- Icon-only 按钮必须有无障碍标签。
- 不用颜色单独表达错误、成功、选中或警告。
- 支持屏幕阅读器的合理阅读顺序。
- 支持横竖屏和折叠屏窄态。
- 不允许页面主体横向滚动；只有标签筛选这类局部控件可以横向滚动。
- 键盘弹出时输入框和提交按钮不能被遮挡。
- 所有操作按钮触控目标至少 44 pt / dp。

## 8. 验收清单

设计稿至少覆盖：

- 登录/注册
- Onboarding
- Tasks 空状态
- Tasks 列表
- Task 编辑
- Task 详情（如果启用）
- Profile / 我的
- Settings
- Summary 入口
- Summary 生成结果
- Summary 历史列表

尺寸至少覆盖：

- 390 x 844 pt 基准屏
- 小屏手机
- 常规 Android 手机
- 大屏手机或折叠屏窄态

实现验收：

- 无页面级横向滚动。
- 文字不溢出容器。
- 键盘弹出时输入和提交按钮可用。
- 所有主要操作有 loading、error 和 success 状态。
- iOS 和 Android 都遵守各自平台返回、弹层、触控和字体规则。
- 与 `product-document-app.md` 冲突时，已按移动端产品文档调整。
