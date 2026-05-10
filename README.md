# AIMemo

AIMemo 是一个本地优先的待办 + 周期总结工具。它用 Flutter 做桌面客户端，支持任务、标签、模板和总结历史，并通过一个轻量 LLM 代理生成日报、周报、月报和年报。

第一版面向个人使用：任务和总结保存在本机，服务端只负责转发总结请求，不保存用户数据。

## 当前状态

记录时间：2026-05-10

- 当前版本已经完成 Flutter 主界面、任务管理、标签筛选、模板编辑、总结生成入口和总结历史展示。
- 主界面采用桌面工具布局：左侧为 AIMemo 标识、任务列表和标签过滤，右侧为添加任务、生成总结和历史记录；模板设置内嵌在生成总结页，右侧栏可拖拽调宽并记住宽度。
- 任务完成后会自动下沉；任务列表不再单独显示“进行中 / 已完成”标签，勾选框就是完成状态。
- 多标签筛选使用“或”关系：选中“工作”和“学习”时，会显示任一标签命中的任务。
- 标签列表只展示仍有关联任务的标签；任务新增或编辑时，关联到的标签会自动排到前面。
- 总结生成支持日、周、月、年和自定义日期区间；日/周/月/年会按所选日期自动换算对应范围。
- Web 预览版使用内存数据，并内置 demo 任务和一条总结历史，方便直接看界面；刷新后数据会恢复为 demo 状态。
- macOS 桌面版的数据层已接入 SQLite，并已在本机 Xcode 环境中完成启动验收；数据库和默认模板可正常初始化。
- LLM 代理服务已经有基础实现，需要配置 `server/.env` 后才能真实调用模型。

下一步建议：

- 在桌面端手动新增任务、重启应用后复查任务仍存在，完成一次端到端持久化验收。
- 配置 LLM 代理的 `LLM_API_KEY`、`LLM_BASE_URL` 和 `LLM_MODEL`，测试真实总结生成。
- 继续微调桌面端视觉细节，尤其是下拉、标签和右侧表单区域的一致性。

## 功能

- 任务管理：添加任务、勾选完成、删除任务，记录创建时间和完成时间；删除前会确认，删除后可撤销。
- 标签管理：任务可绑定多个标签，任务列表和总结生成都支持按标签过滤；无关联任务的标签不会展示。
- 周期总结：支持日报、周报、月报、年报和自定义总结，可用日/周/月/年/自定义日期区间收集任务；周期类型和日期区间紧凑地在同一行选择，点击日期按钮即可选择区间，生成后的最新总结在切换右侧页面后会保留。
- 提示词模板：每个周期可在生成总结页内单独配置模板，点击紧凑的模板标题行即可展开编辑，支持 `{tasks}`、`{period}`、`{period_days}`、`{tags}`；日报和周报默认只写已完成和下步计划，月报和年报默认包含更多复盘结构。
- 总结历史：生成后的总结自动保存，可查看和复制。
- 本地存储：macOS 桌面版使用 SQLite；Web 预览版使用内存数据，仅用于看界面和交互。
- LLM 代理：Node.js/Fastify 服务兼容 OpenAI 风格 `/chat/completions`；总结页可在应用内配置自定义模型服务，官方托管模型入口暂未开放。

## 技术栈

- Flutter + Dart
- Riverpod
- 日期选择：`date_picker_plus`
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

本机已安装 CocoaPods。若其他机器提示 CocoaPods 缺失：

```bash
brew install cocoapods
```

## 配置模型服务

生成总结需要先启动本地 LLM 代理，然后在应用内配置模型服务。

```bash
cd server
npm install
npm run dev
```

打开 AIMemo 后，进入“总结”页，点击标题右侧的“模型”按钮：

- 选择“使用自己的模型服务”时，填写 OpenAI 兼容服务的 `API Key`、`Base URL` 和 `Model`。例如 `https://api.openai.com/v1` 与 `gpt-4o-mini`。
- `API Key` 会保存到系统安全存储，`Base URL` 和 `Model` 会保存到本地 SQLite 的 `app_settings`。
- “使用 AIMemo 官方托管模型”目前只是占位入口，后续接入登录、额度和计费后开放；暂时没有自己模型的用户会看到未开放提示。

客户端默认连接 `http://localhost:8787`。如需切换代理地址：

```bash
flutter run -d macos --dart-define=AIMEMO_API_BASE_URL=http://localhost:8787
```

## 高级：用环境变量配置代理

AIMemo 的 Node 代理优先读取 `server/.env`。如果没有配置 `LLM_API_KEY`，它会自动尝试读取本机 CLIProxyAPI 配置：

```text
/opt/homebrew/etc/cliproxyapi.conf
```

因此本机已经运行 CLIProxyAPI 时，可以直接启动 AIMemo 代理；默认会转发到 `http://127.0.0.1:8317/v1`，模型默认使用 `gpt-5.4-mini`。

应用内“使用自己的模型服务”也可以直接填写 CLIProxyAPI 参数。注意不要填写管理面板页面地址
`http://localhost:8317/management.html#/`，应填写 OpenAI-compatible API 地址：

```text
Base URL: http://127.0.0.1:8317/v1
Model: CLIProxyAPI 管理页里配置的模型名或别名
API Key: CLIProxyAPI 配置中的 api-keys 值
```

macOS 桌面版会把 API Key 写入系统钥匙串。若钥匙串暂时无响应，模型设置保存会超时并在弹窗里显示错误，不会一直停留在保存中。

如果不用 CLIProxyAPI，或想手动指定模型服务，可以复制并编辑 `.env`：

```bash
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
cd server
npm run dev
```

默认接口：

```text
http://localhost:8787/api/generate-summary
```

## 测试和检查

```bash
flutter analyze
flutter test
flutter build macos
open build/macos/Build/Products/Release/aimemo.app
```

协作约定：功能验证通过后，需要继续执行 macOS build，并打开构建后的应用给用户确认。

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

- 桌面版任务、标签、模板、总结历史和右侧栏宽度保存在本机 SQLite。
- Web 预览版只存在浏览器运行时内存中，刷新会清空。
- LLM 代理只在生成总结时接收 prompt 并转发给模型，不落库任务或总结内容。
- 不要提交 `server/.env`，里面包含模型 API Key。

## 常见问题

### 默认模板更新后没有变化

已经保存过的自定义模板会保留用户版本。进入“总结”页展开“当前模板”，点击“恢复默认”，即可应用当前周期的新版默认模板。默认模板会按日报、周报、月报、年报和自定义总结分别提供不同结构；自定义总结会用 `{period_days}` 判断区间是否超过 7 天。

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

再进入“总结”页点击“模型”按钮，检查是否已经配置自定义模型服务。高级用法也可以检查 `server/.env` 是否配置了 `LLM_API_KEY`、`LLM_BASE_URL` 和 `LLM_MODEL`。

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
