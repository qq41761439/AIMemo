# AIMemo

AIMemo 是一个待办 + 周期总结工具。桌面端和移动端使用 Flutter 构建，支持任务、标签、提示词模板和总结历史；用户可以直连自定义 OpenAI-compatible 模型服务，也可以通过 AIMemo 后端使用官方托管模型。

当前桌面版以本地 SQLite 为主；后端提供邮箱验证码登录、微信小程序登录、云端任务、云端总结历史、免费额度和服务端模型代理能力。多端账号、桌面端与微信小程序数据同步、云端数据模型和阶段计划见 [产品与技术规划](docs/product-and-technology-plan.md)。iOS/Android 移动 App 主线已切回 Flutter 双端实现，App 产品、页面和视觉以 [移动端产品文档](docs/product-document-app.md) 与 [Flutter 移动组件系统](docs/mobile-component-system.md) 为准。

## 当前状态

记录时间：2026-05-15

- Flutter 桌面主界面、任务管理、标签筛选、模板编辑、总结生成入口和总结历史已完成。
- 任务列表只有存在可用标签时才显示标签筛选条，避免无标签任务出现空标签提示。
- 标签筛选选中态使用紧凑描边高亮，不显示勾选图标，减少横向占用。
- 点击任务会直接进入编辑表单，不再经过单独的查看任务页面。
- 保存任务修改后会继续停留在当前编辑表单，方便连续调整。
- 任务列表和总结历史支持下拉刷新；登录同步模式会同步云端任务，官方托管历史会重新拉取云端总结。
- 移动端标签筛选、任务卡片标签和记录表单候选标签使用紧凑展示，避免标签过多时撑乱页面。
- 移动端记录表单支持在短屏和键盘场景下滚动填写任务内容、标签和提交按钮，点击空白处会收起键盘。
- Flutter 移动端 Tasks 页面支持点击 Active、Upcoming 和 Completed 分组标题展开或收起对应任务列表。
- Flutter 移动端登录后、Tasks 下拉刷新和生成 Summary 前会同步云端任务，确保桌面端输入的任务先出现在 iOS/Android App 再参与总结。
- Flutter 移动端 Summary 生成固定走 AIMemo 后端托管模型，不提供 App 端自填 API Key；“我的”页展示当月免费额度。
- Flutter 移动端 Debug/Test 默认连接本地后端：iOS 模拟器使用 `http://127.0.0.1:8787`，Android 模拟器使用 `http://10.0.2.2:8787`；Release 默认连接线上 Render 后端。
- 任务支持设置开始时间；任务列表中未完成任务按开始时间倒序，已完成任务按完成时间倒序。
- 周期总结会纳入与所选周期有交集的任务，包括周期前开始但周期内完成或仍未完成的任务。
- macOS 桌面版已接入 SQLite；Web 预览版使用内存 demo 数据。
- iOS/Android Flutter mobile shell 已接入；手机平台进入独立移动端入口、主题、导航和组件系统，桌面/Web 继续使用现有工作台。
- 原生 Android Compose 工程暂停保留，不作为当前移动端主线继续投入。
- 移动 App 新视觉以白底、圆角卡片、柔和阴影、紫色渐变按钮和国际化可读排版为主。
- 移动 App 顶部栏、分区标题和首屏间距已按 390 × 844 基准屏收紧，保持 16pt 区块层级和更高内容密度。
- Windows 桌面工程、Inno Setup 安装脚本和 GitHub Actions 构建流程已接入。
- 自定义模型服务由桌面客户端直连，真实 API Key 保存在系统安全存储。
- 打开桌面应用时会先让用户选择“本地运行”或“登录同步”；登录同步复用 AIMemo 官方账号的邮箱验证码登录。
- 官方托管模式支持登录状态自动刷新、免费额度展示和云端总结历史查看，并与登录同步入口共用同一套账号会话。
- 原生 Android Debug 包默认连接本机后端 `http://10.0.2.2:8787`；Release 包默认连接 `https://aimemo-backend.onrender.com`，但该工程仅作历史探索保留。
- 后端已支持 Resend API 和 SMTP 邮件发送；Render 免费档建议优先配置 `RESEND_*`，否则邮箱验证码仍会只打印在后端日志。开发和联调时也可以直接输入 `1234` 作为万能验证码登录。
- 模型设置支持在官方模型和自定义模型之间保存切换；已登录官方账号时选择官方模型并完成会立即生效。
- 桌面 SQLite 任务已记录 `clientId`、`cloudId`、`syncStatus` 和 `updatedAt` 同步元数据；后端任务创建支持 `clientId` 幂等去重。
- 登录同步模式已接入桌面任务自动同步：启动后同步一次，运行中每 5 分钟同步本地新增、更新、软删除和云端增量变更。
- `backend/` 独立 API 服务已接入邮箱登录、微信小程序登录、云端任务、云端总结、额度和官方托管模型代理。
- 本地后端可用 Docker Postgres + Prisma Studio 稳定查看用户记录。

下一步重点：

- 完善桌面任务同步的冲突可视化、手动重试和大批量分页策略。
- 按移动端产品文档继续还原 Flutter iOS/Android App，并补齐移动端同步和 Summary 周边体验。

## 快速启动

Web 预览：

```bash
flutter pub get
flutter run -d chrome --web-port 5173
```

macOS 桌面版：

```bash
flutter pub get
flutter run -d macos
```

iOS/Android Flutter 移动端：

```bash
flutter pub get
flutter run -d ios
flutter run -d android
```

移动端主线开发请优先修改 `lib/src/mobile/`、`lib/src/mobile/mobile_components.dart` 和 `lib/src/mobile/mobile_theme.dart`，并参考 [Flutter 移动组件系统](docs/mobile-component-system.md)。`native/android/` 是暂停保留的 Compose 探索工程，除非专门处理历史原生 Android 包，否则不要作为移动端功能主线修改。

暂停保留的原生 Android App：

```bash
cd native/android
# 可选：在 local.properties 里设置 aimemo.backendBaseUrl 可覆盖 Debug/Release 后端地址
./gradlew assembleDebug
./gradlew test
```

原生 Android 工程使用 Kotlin、Jetpack Compose、Compose Navigation 和 Material 3，但当前只作为历史探索工程暂停保留。Debug 构建默认连接 Android 模拟器可访问的宿主机地址 `http://10.0.2.2:8787`，并通过 Debug 专用网络安全配置允许本地 HTTP；Release 构建默认连接 `https://aimemo-backend.onrender.com`。

首次打开桌面版时，可以选择“本地运行”直接使用本机 SQLite，也可以选择“登录同步”用邮箱验证码登录 AIMemo 账号。登录同步模式会复用官方账号会话同步任务数据；本地未同步改动会先上传，随后拉取云端增量变更。

后端服务：

```bash
cd backend
npm install
cp .env.example .env
npm run db:up
npm run prisma:generate
npm run prisma:push
npm run dev
```

后端开发环境默认使用本地 Postgres 持久化；查看后端用户记录：

```bash
cd backend
npm run users:list
npm run db:studio
```

部署到 Render：

```bash
# 仓库根目录已经提供 render.yaml
git push origin main
```

然后在 Render 里使用 Blueprint 部署，详情见 [后端服务指南](docs/backend.md#部署到-render)。

## 文档

- [产品文档](docs/product-document.md)：产品定位、目标用户、核心流程、功能规格、隐私边界和路线图。
- [移动端产品文档](docs/product-document-app.md)：iOS/Android App 页面清单、字体规范、交互规范、平台实现、状态反馈、可访问性和验收清单。
- [Flutter 移动组件系统](docs/mobile-component-system.md)：Flutter iOS/Android mobile shell 的 design tokens、基础组件、业务组件和验收规则。
- [产品与技术规划](docs/product-and-technology-plan.md)：产品定位、多端同步、账号体系、路线图和风险原则。
- [开发与运行指南](docs/development.md)：本机环境、Web/macOS/Windows 运行、测试检查和项目结构。
- [后端服务指南](docs/backend.md)：后端启动、Postgres 持久化、Render 部署、用户记录查看、环境变量和 API。
- [模型服务与隐私](docs/model-and-privacy.md)：自定义模型、官方托管模型、密钥存储和数据隐私边界。

## 技术栈

- Flutter + Dart
- Riverpod
- `date_picker_plus`
- `sqflite`
- `sqflite_common_ffi`
- SwiftUI
- Kotlin + Jetpack Compose + Material 3
- OpenAI-compatible LLM API
- Node.js + TypeScript + Fastify + Prisma + Postgres

## 常用检查

Flutter：

```bash
flutter analyze
flutter test
flutter build macos
```

原生 Android：

```bash
cd native/android
./gradlew test
./gradlew assembleDebug
```

后端：

```bash
cd backend
npm run build
npm test
```

Windows 安装包需要在 Windows 环境执行：

```powershell
.\scripts\build_windows_installer.ps1
```

macOS 开发版默认产物名为 `aimemo-dev.app`，生产版仍保持 `aimemo.app`，可以同时打开两份。

## 关键文件

- `lib/src/features/home_page.dart`：主界面和交互入口。
- `lib/src/mobile/`：Flutter iOS/Android 移动端入口、主题、组件和页面。
- `lib/src/services/app_database.dart`：桌面端 SQLite 数据层。
- `lib/src/services/in_memory_memo_store.dart`：Web 预览内存数据层。
- `lib/src/services/summary_api_client.dart`：模型请求客户端。
- `lib/src/services/template_renderer.dart`：总结模板渲染。
- `backend/src/server.ts`：后端 API 路由。
- `backend/prisma/schema.prisma`：Postgres 数据模型。
- `native/android/`：原生 Android App 工程。
