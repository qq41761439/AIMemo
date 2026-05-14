# AIMemo 移动端产品文档（v1.0）

## 1️⃣ 基本信息

* **目标用户**：全球用户，iOS / Android 移动端
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
| Tab / Section Header | 16      | Semibold        | Tasks / Summary / Active / Upcoming / Completed |
| 输入框标签                | 14      | Medium          | Title / Notes / Tags / Start Time               |
| 输入框内容                | 16      | Regular         | 用户输入                                            |
| Toggle 文案            | 16      | Medium          | Mark as completed                               |
| 按钮文字                 | 16      | Semibold / Bold | Save Changes / Generate Summary                 |
| Delete 按钮            | 14      | Medium          | 红色警告文字                                          |
| Placeholder / 占位文字   | 16      | Regular         | 灰色提示                                            |
| 辅助信息 / Subtext       | 12      | Regular         | 例如任务数量、日期                                       |
| 标签文字                 | 14      | Medium          | 背景圆角小卡片                                         |

* 行高：1.3–1.4 倍字体大小
* 按钮高度：≥44pt
* Tag 标签高度：24–28pt

## 3️⃣ 页面清单与功能

### 3.1 登录/注册合一页

* 功能：

  * 输入邮箱/密码登录
  * 支持第三方登录（可选）
  * 忘记密码
* 风格：

  * 白底、紫色渐变按钮
  * 简洁国际化设计

### 3.2 Onboarding 引导页

* 功能：

  * 展示核心功能（Tasks / AI Summary）
  * 支持跳过
* 风格：

  * 简洁插图 + 标题 + 简短描述 + 下一步按钮

### 3.3 Tasks 主页面

* 功能：

  * 显示 Active / Upcoming / Completed 三个任务分组
  * 标签筛选栏：All / Product / Client / Study / Personal
  * 任务列表：

    * 一行标题
    * 一行标签 + 开始时间 / 结束时间
    * 多标签支持
  * 底部快速添加任务按钮
* 字号及风格严格按上表

### 3.4 Task 编辑页

* 功能：

  * 编辑 Title / Notes / Tags / Start Time
  * Mark as completed 开关
  * Delete task 按钮
  * Save Changes 按钮
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
* 简洁卡片布局，紫色点缀

### 3.7 Settings 页面

* 功能：

  * 账户设置、同步选项、隐私与帮助
* 风格统一

### 3.8 Summary 模块

#### 3.8.1 Summary 入口页面

* Hero 卡片：AI Summary
* 生成按钮：Generate Summary
* 报告类型选择：Daily / Weekly / Monthly / Custom
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

## 5️⃣ UI 风格总览

* 白底 + 紫色渐变按钮
* 卡片圆角 12–16pt
* 标签圆角 8–12pt
* 阴影轻柔，视觉层次明显
* 国际化文本排版优化，可读性强
* 统一 iOS 风格，可适配 Android
