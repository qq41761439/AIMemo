# AIMemo 移动端产品文档（v1.0）

记录时间：2026-05-14

## 1️⃣ 基本信息

* **目标用户**：全球用户，iOS / Android 移动端
* **实现方向**：

  * iOS 使用 SwiftUI
  * Android 使用 Kotlin、Jetpack Compose 和 Material 3
* **设计基准屏幕**：iPhone 13 / 14 / 15 竖屏

  * 尺寸：390 × 844 pt
  * 长宽比：约 9:19.5
* **风格**：

  * 白底、圆角卡片
  * 柔和阴影
  * 紫色渐变按钮为主视觉点缀
  * 国际化可读，字体规范

## 2️⃣ 字体规范（固定值）

| 元素                   | 字号 (pt) | 字重 / 风格         | 备注                                              |
| -------------------- | ------- | --------------- | ----------------------------------------------- |
| 页面标题                 | 22      | Semibold / Bold | 顶部标题                                            |
| Tab / Section Header | 15      | Semibold        | Tasks / Summary / Upcoming / Active / Completed |
| 输入框标签                | 14      | Medium          | Title / Notes / Tags / Start Time               |
| 输入框内容                | 16      | Regular         | 用户输入                                            |
| Toggle 文案            | 16      | Medium          | Mark as completed                               |
| 按钮文字                 | 16      | Semibold / Bold | Save Changes / Generate Summary                 |
| Delete 按钮            | 14      | Medium          | 红色警告文字                                          |
| Placeholder / 占位文字   | 16      | Regular         | 灰色提示                                            |
| 辅助信息 / Subtext       | 12      | Regular         | 例如任务数量、日期                                       |
| 标签文字                 | 13      | Medium          | 背景圆角小卡片                                         |

* 行高：1.3–1.4 倍字体大小
* 按钮高度：≥44pt
* Tag 标签高度：20–28pt，Task 列表内标签使用更紧凑的浅紫底样式
* iOS 使用 SF Pro 和系统 Dynamic Type
* Android 使用 Roboto 和 Material 3 type scale，但字号要贴近上表
* 不使用负字距；列表和按钮文字不能溢出容器

## 3️⃣ 页面清单与功能

### 3.1 登录/注册合一页

* 功能：

  * 首版使用 AIMemo 后端邮箱验证码登录，登录态用于同步、总结生成和额度查询
  * 支持第三方登录（可选，后续接入）
  * 忘记密码（后续接入）
  * 登录、注册、忘记密码和第三方登录都需要 loading、success、error 和 disabled 状态
* 风格：

  * 白底、紫色渐变按钮
  * 简洁国际化设计

### 3.2 Onboarding 引导页

* 功能：

  * 展示核心功能（Tasks / AI Summary）
  * 支持跳过
  * 图片或远程内容加载时展示明确 loading 状态
* 风格：

  * 简洁插图 + 标题 + 简短描述 + 下一步按钮
  * 适配 390 × 844 pt 基准屏

### 3.3 Tasks 主页面

* 功能：

  * 显示 Upcoming / Active / Completed 三个任务分组
  * Upcoming 默认收起，Active 和 Completed 默认展开
  * 标签筛选栏：All / Product / Client / Study / Personal
  * 任务列表：

    * 一行标题
    * 一行标签 + 开始时间 / 结束时间
    * 多标签支持
  * 底部快速添加任务按钮
  * 支持空状态、loading、error 和刷新反馈
* 字号及风格严格按上表

### 3.4 Task 编辑页

* 功能：

  * 编辑 Title / Notes / Tags / Start Time
  * Mark as completed 开关
  * Delete task 按钮
  * Save Changes 按钮
  * Save 和 Delete 都需要 loading、success、error 和 disabled 状态
* 字体规范如上
* 竖屏比例 390×844 pt

### 3.5 Task 详情页（可选）

* 功能：

  * 查看任务标题、标签、日期、备注
  * 可勾选完成
* 统一 Task 编辑页风格

### 3.6 Profile / 我的页面

* 功能：

  * 账户信息、头像、通知、帮助与反馈
  * 展示本月可用免费总结额度，样式参考 `assets/prototypes/main-profile.png`
  * Profile 不替代 Settings；更细的账户设置、同步、隐私与帮助入口放在 Settings
* 简洁卡片布局，紫色点缀

### 3.7 Settings 页面

* 功能：

  * 账户设置、同步选项、隐私与帮助
  * 不把桌面端自定义模型 API Key 配置作为移动 App 首版主流程，除非后续产品文档明确加入
* 风格统一

### 3.8 Summary 模块

#### 3.8.1 Summary 入口页面

* Hero 卡片：AI Summary
* 生成按钮：Generate Summary
* 报告类型选择：Daily / Weekly / Monthly / Custom
* 移动 App 首版只调用 AIMemo 后端托管模型生成总结，不展示自定义模型 API Key、Base URL 或 Model 配置
* Debug/Test 构建默认连接本地后端，iOS 模拟器使用 `http://127.0.0.1:8787`，Android 模拟器使用 `http://10.0.2.2:8787`；Release 构建默认连接线上后端
* 点击生成 → Summary 生成结果页
* 点击历史 → Summary 历史列表页

#### 3.8.2 Summary 生成结果页

* 显示生成的 Summary 内容
* 可通过输入框对话修改
* 满意确认按钮
* 结果结构：

  * What I completed
  * Key outcomes
  * Next steps
  * Included tasks
* Copy / Share 操作

#### 3.8.3 Summary 历史列表页

* 类型切换：Daily / Weekly / Monthly / Custom
* 列表记录：

  * 默认收起，显示任务数量、日期、摘要
  * 点击展开 → 显示完整内容（与生成结果页一致）
* 不再有 Generate Summary 按钮
* 不跳转详情页

## 4️⃣ 交互规范

* Task 列表按开始时间倒序显示未完成任务
* Completed 列表按结束时间倒序
* 多标签任务列表，图标移除
* 任务详情只展示具体日期，时间仅在 Task 编辑页或详情页显示
* Summary 历史列表点击展开在当前页面完成
* 所有操作按钮触控目标 ≥44pt
* 删除任务必须二次确认或提供撤销入口；删除成功后任务从可见列表移除，标签筛选随任务关联刷新

## 5️⃣ UI 风格总览

* 白底 + 紫色渐变按钮
* 卡片圆角 12–16pt
* 标签圆角 8–12pt
* 阴影轻柔，视觉层次明显
* 国际化文本排版优化，可读性强
* 统一 iOS 风格，可适配 Android
* Android 可以使用 Material 3 控件实现，但视觉结果应贴近本文档，而不是旧绿色品牌 token
* 不使用系统动态取色覆盖紫色主视觉

## 6️⃣ 平台实现规范

### 6.1 iOS

* 根结构优先使用 `NavigationStack`
* 列表可使用 `List` 或自定义列表
* 编辑任务可使用 sheet 或全屏页面
* 标题、返回、sheet 高度、键盘避让遵守 iOS 习惯
* 重要确认、完成任务和生成成功可使用轻量 haptic
* 支持 Dynamic Type，不因文字放大导致按钮文字溢出

### 6.2 Android

* 使用 Kotlin、Jetpack Compose 和 Material 3
* 根结构优先使用 Compose Navigation
* 顶部栏、按钮、输入框、Tab、Snackbar 等使用 Material 3 组件承载
* 支持系统返回键：sheet 或弹窗先关闭，再返回上一页
* 反馈使用 Snackbar、Toast 或页面内状态，保持 Material 交互习惯

## 7️⃣ 状态与反馈

所有主要操作必须覆盖：

* idle
* loading
* success
* error
* disabled

错误信息应靠近发生错误的控件。全局错误可以用 Snackbar，但表单验证错误不只放在页面顶部。

需要明确 loading 状态的页面和操作：

* 登录/注册
* Onboarding 图片或远程内容加载
* Tasks 列表
* Task 保存和删除
* Profile
* Settings
* Summary 生成
* Summary 对话修改
* Summary 历史

## 8️⃣ 可访问性与响应式

* 正文对比度至少满足 WCAG AA
* Icon-only 按钮必须有无障碍标签
* 不用颜色单独表达错误、成功、选中或警告
* 支持屏幕阅读器的合理阅读顺序
* 支持横竖屏和折叠屏窄态
* 不允许页面主体横向滚动；只有标签筛选这类局部控件可以横向滚动
* 键盘弹出时输入框和提交按钮不能被遮挡
* 所有操作按钮触控目标至少 44 pt / dp

## 9️⃣ 验收清单

设计稿至少覆盖：

* 登录/注册
* Onboarding
* Tasks 空状态
* Tasks 列表
* Task 编辑
* Task 详情（如果启用）
* Profile / 我的
* Settings
* Summary 入口
* Summary 生成结果
* Summary 历史列表

尺寸至少覆盖：

* 390 × 844 pt 基准屏
* 小屏手机
* 常规 Android 手机
* 大屏手机或折叠屏窄态

实现验收：

* 无页面级横向滚动
* 文字不溢出容器
* 键盘弹出时输入和提交按钮可用
* 所有主要操作有 loading、error 和 success 状态
* iOS 和 Android 都遵守各自平台返回、弹层、触控和字体规则
