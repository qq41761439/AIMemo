# AIMemo Flutter Mobile Component System

记录时间：2026-05-15

## 目标

AIMemo 移动端主线切回 Flutter 双端实现，iOS 和 Android 共用同一套 mobile shell、主题 token、导航和组件。桌面/Web 继续使用现有 Flutter 工作台，移动端不再沿用旧的窄屏桌面布局。

移动端视觉和交互以 `docs/product-document-app.md` 与 `assets/prototypes/` 为验收标准。

## Design Tokens

- 背景：`#FCFBFF`，页面保持白底和轻微紫色环境感。
- 主视觉：紫色渐变 `#5B2DE1 -> #8B5CF6`，用于主按钮、完成勾选和关键强调。
- 文本：主文本 `#080C1B`，辅助文本 `#6F7488`，危险色 `#E51B2A`，成功色 `#23B26B`。
- 圆角：小组件 10，常规控件 14，卡片 18。
- 阴影：轻柔下投影，避免重阴影和深色容器。
- 字号：页面标题 22，按钮 16，Task 顶部 Tab/任务标题/分区标题 15 semibold，标签与日期 13，辅助信息 12；只有品牌 hero 与关键数字允许小幅放大。
- 触控：按钮、图标按钮和可点列表项不低于 44 pt。
- 顶部留白：使用可用屏高分档适配，短屏收紧，常规屏正常，长屏适度舒展；不得用单一大固定值撑开首屏。
- 390 × 844 基准屏首屏应优先露出筛选栏和首个内容卡片，避免顶部栏、hero 或登录品牌区占用过多垂直空间。
- Task 页面卡片、任务行、标签和底部 quick add 使用紧凑视觉密度，同时保留足够可点触控区域。
- Task 任务卡片偏好轻量独立卡片：浅边框、极轻阴影、常规圆角，单行视觉高度目标不超过 52 pt，避免厚重嵌套卡片感。
- Task 任务卡片内标签显示在标题前方，超过两个标签时用 `+N` 计数收纳。

## Base Components

- `MobileScreen`：移动页面框架，负责安全区、顶部栏、滚动、键盘场景和底部操作区。
- `SoftCard`：统一白底/浅紫底卡片，承载分组、表单、菜单和状态。
- `GradientButton`：移动端主操作按钮，内置 loading/disabled 状态。
- `PillChip`：标签、筛选、周期选择统一胶囊组件。
- `StatusCard`：loading、empty、error、success 的统一状态展示。
- `SectionTitle`：区块标题和右侧操作入口。

## Business Components

- Tasks：顶部 Tasks/Summary 切换、标签筛选、Upcoming/Active/Completed 分组、独立任务卡片、底部快速添加栏。
- Task Edit：Task、Tags、Start Time、完成开关、删除确认、固定底部 Save Changes；表单使用无区域外框的行内参数布局，Task 第一行为标题、后续行为备注。
- Summary：AI Summary Hero、报告类型选择、标签范围、预览指标、结果内容、修改输入、Copy/Share、历史页内展开。
- Profile/Settings：账户卡、同步状态、菜单组、退出登录。

## Implementation Rules

- 移动端入口在 `AIMemoApp` 内按真实 iOS/Android 平台分流到 `MobileAIMemoApp`；桌面/Web 保持现有 `HomePage`。
- 不在移动端首版加入桌面端 local-only 选择、自定义模型 API Key 或复杂离线编辑同步。
- 移动端页面必须优先复用现有 Flutter `TaskRecord`、`SummaryRecord`、`PeriodType`、`MemoStore` 和 Riverpod provider。
- 新移动 UI 不修改 `native/android` Compose 工程；该工程暂停保留。
- 所有新增移动页面必须覆盖 loading、error、empty、disabled 或 success 中适用的状态。

## Acceptance

- 390 x 844 基准屏无页面级横向滚动。
- 文本不溢出按钮、标签、卡片和列表行。
- 键盘弹出时输入框与主提交按钮可继续使用。
- 删除任务必须二次确认或提供撤销入口。
- Summary 历史点击后在当前列表展开，不跳详情页。
