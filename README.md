# AIMemo

AIMemo 是一个待办 + 周期总结工具。桌面端使用 Flutter 构建，支持任务、标签、提示词模板和总结历史；用户可以直连自定义 OpenAI-compatible 模型服务，也可以通过 AIMemo 后端使用官方托管模型。

当前桌面版以本地 SQLite 为主；后端提供邮箱验证码登录、微信小程序登录、云端任务、云端总结历史、免费额度和服务端模型代理能力。多端账号、桌面端与微信小程序数据同步、云端数据模型和阶段计划见 [产品与技术规划](docs/product-and-technology-plan.md)。

## 当前状态

记录时间：2026-05-12

- Flutter 桌面主界面、任务管理、标签筛选、模板编辑、总结生成入口和总结历史已完成。
- 任务支持设置开始时间；任务列表中未完成任务按开始时间倒序，已完成任务按完成时间倒序。
- 周期总结会纳入与所选周期有交集的任务，包括周期前开始但周期内完成或仍未完成的任务。
- macOS 桌面版已接入 SQLite；Web 预览版使用内存 demo 数据。
- Windows 桌面工程、Inno Setup 安装脚本和 GitHub Actions 构建流程已接入。
- 自定义模型服务由桌面客户端直连，真实 API Key 保存在系统安全存储。
- `backend/` 独立 API 服务已接入邮箱登录、微信小程序登录、云端任务、云端总结、额度和官方托管模型代理。
- 本地后端可用 Docker Postgres + Prisma Studio 稳定查看用户记录。

下一步重点：

- 完善桌面端官方托管模式的自动 refresh、额度展示和云端历史视图。
- 建立桌面 SQLite 与后端 Postgres 的同步闭环。
- 基于后端 API 实现微信小程序任务 + 总结体验。

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

后端服务：

```bash
cd backend
npm install
cp .env.example .env
npm run prisma:generate
npm run dev
```

后端使用本地 Postgres 持久化：

```bash
cd backend
npm run db:up
# 将 backend/.env 里的 DATA_STORE 改成 prisma
npm run prisma:push
npm run dev
```

查看后端用户记录：

```bash
cd backend
npm run users:list
npm run db:studio
```

## 文档

- [产品与技术规划](docs/product-and-technology-plan.md)：产品定位、多端同步、账号体系、路线图和风险原则。
- [开发与运行指南](docs/development.md)：本机环境、Web/macOS/Windows 运行、测试检查和项目结构。
- [后端服务指南](docs/backend.md)：后端启动、Postgres 持久化、用户记录查看、环境变量和 API。
- [模型服务与隐私](docs/model-and-privacy.md)：自定义模型、官方托管模型、密钥存储和数据隐私边界。

## 技术栈

- Flutter + Dart
- Riverpod
- `date_picker_plus`
- `sqflite_common_ffi`
- OpenAI-compatible LLM API
- Node.js + TypeScript + Fastify + Prisma + Postgres

## 常用检查

Flutter：

```bash
flutter analyze
flutter test
flutter build macos
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

## 关键文件

- `lib/src/features/home_page.dart`：主界面和交互入口。
- `lib/src/services/app_database.dart`：桌面端 SQLite 数据层。
- `lib/src/services/in_memory_memo_store.dart`：Web 预览内存数据层。
- `lib/src/services/summary_api_client.dart`：模型请求客户端。
- `lib/src/services/template_renderer.dart`：总结模板渲染。
- `backend/src/server.ts`：后端 API 路由。
- `backend/prisma/schema.prisma`：Postgres 数据模型。
