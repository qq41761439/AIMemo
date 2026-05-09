# AIMemo

AIMemo 是一个本地优先的待办 + 周期总结工具。它用 Flutter 做桌面客户端，支持任务、标签、模板和总结历史，并通过一个轻量 LLM 代理生成日报、周报、月报和年报。

第一版面向个人使用：任务和总结保存在本机，服务端只负责转发总结请求，不保存用户数据。

## 当前状态

记录时间：2026-05-09

- 当前版本已经完成 Flutter 主界面、任务管理、标签筛选、模板编辑、总结生成入口和总结历史展示。
- 主界面采用桌面工具布局：左侧为 AIMemo 标识、任务列表和标签过滤，右侧为添加任务、生成总结、模板设置和历史记录。
- 任务完成后会自动下沉；任务列表不再单独显示“进行中 / 已完成”标签，勾选框就是完成状态。
- 多标签筛选使用“或”关系：选中“工作”和“学习”时，会显示任一标签命中的任务。
- Web 预览版使用内存数据，并内置 demo 任务和一条总结历史，方便直接看界面；刷新后数据会恢复为 demo 状态。
- macOS 桌面版的数据层已接入 SQLite，等待本机 Xcode 环境完成后继续验收持久化。
- LLM 代理服务已经有基础实现，需要配置 `server/.env` 后才能真实调用模型。

下一步建议：

- Xcode 安装完成后运行 `flutter run -d macos`，验证桌面端 SQLite 持久化。
- 配置 LLM 代理的 `LLM_API_KEY`、`LLM_BASE_URL` 和 `LLM_MODEL`，测试真实总结生成。
- 继续微调桌面端视觉细节，尤其是下拉、标签和右侧表单区域的一致性。

## 功能

- 任务管理：添加任务、勾选完成、删除任务，记录创建时间和完成时间。
- 标签管理：任务可绑定多个标签，任务列表和总结生成都支持按标签过滤。
- 周期总结：支持日报、周报、月报、年报，按当前本地时间自动收集周期内任务。
- 提示词模板：每个周期可单独配置模板，支持 `{tasks}`、`{period}`、`{tags}`。
- 总结历史：生成后的总结自动保存，可查看和复制。
- 本地存储：macOS 桌面版使用 SQLite；Web 预览版使用内存数据，仅用于看界面和交互。
- LLM 代理：Node.js/Fastify 服务兼容 OpenAI 风格 `/chat/completions`。

## 技术栈

- Flutter + Dart
- Riverpod
- SQLite：`sqflite_common_ffi`
- Node.js + Fastify
- OpenAI-compatible LLM API

## 本机环境

本机已安装 Flutter：

```bash
flutter --version
```

当前使用中国镜像源：

```bash
PUB_HOSTED_URL=https://pub.flutter-io.cn
FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

这些配置已经写入 `~/.zprofile` 和 `~/.zshrc`。如果新终端找不到 `flutter`，执行：

```bash
source ~/.zshrc
```

## 运行 Web 预览

Web 版适合先看界面，不做持久化。刷新页面后任务会丢失。

```bash
flutter pub get
flutter run -d chrome --web-port 5173
```

打开：

```text
http://localhost:5173
```

## 运行 macOS 桌面版

macOS 桌面版会使用本地 SQLite 保存数据。

```bash
flutter pub get
flutter run -d macos
```

如果 `flutter doctor` 提示 Xcode 不完整，先从 App Store 安装 Xcode，然后执行：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

如果提示 CocoaPods 缺失：

```bash
brew install cocoapods
```

## 启动 LLM 代理

```bash
cd server
npm install
cp .env.example .env
```

编辑 `server/.env`：

```bash
LLM_API_KEY=你的模型 API Key
LLM_BASE_URL=https://api.openai.com/v1
LLM_MODEL=gpt-4o-mini
```

启动服务：

```bash
npm run dev
```

默认接口：

```text
http://localhost:8787/api/generate-summary
```

客户端默认连接 `http://localhost:8787`。如需切换代理地址：

```bash
flutter run -d macos --dart-define=AIMEMO_API_BASE_URL=http://localhost:8787
```

## 测试和检查

```bash
flutter analyze
flutter test
```

服务端检查：

```bash
cd server
npm audit --audit-level=moderate
node --check server.js
```

## 项目结构

```text
lib/
  main.dart
  src/
    app.dart
    features/home_page.dart
    models/
    providers.dart
    services/
server/
  server.js
  .env.example
test/
web/
macos/
```

关键文件：

- `lib/src/features/home_page.dart`：主界面和交互。
- `lib/src/services/app_database.dart`：桌面端 SQLite 数据层。
- `lib/src/services/in_memory_memo_store.dart`：Web 预览内存数据层。
- `lib/src/services/template_renderer.dart`：模板变量渲染。
- `server/server.js`：LLM 代理服务。

## 数据和隐私

- 桌面版任务、标签、模板、总结历史保存在本机 SQLite。
- Web 预览版只存在浏览器运行时内存中，刷新会清空。
- LLM 代理只在生成总结时接收 prompt 并转发给模型，不落库任务或总结内容。
- 不要提交 `server/.env`，里面包含模型 API Key。

## 常见问题

### Web 能用，macOS 跑不起来

通常是 Xcode 没装完整。执行：

```bash
flutter doctor
```

按提示补 Xcode、CocoaPods 或授权步骤。

### 生成总结失败

先确认代理服务正在运行：

```bash
curl http://localhost:8787/health
```

再检查 `server/.env` 是否配置了 `LLM_API_KEY`、`LLM_BASE_URL` 和 `LLM_MODEL`。

### Flutter 下载慢

确认当前 shell 有镜像源：

```bash
echo $PUB_HOSTED_URL
echo $FLUTTER_STORAGE_BASE_URL
```

如果为空：

```bash
source ~/.zshrc
```
