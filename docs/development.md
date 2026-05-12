# AIMemo 开发与运行指南

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

Web 版适合先看界面，不做持久化。刷新页面后任务会恢复为 demo 状态。

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

## Windows 安装包

本仓库包含 Windows 桌面工程、Inno Setup 安装器脚本和 GitHub Actions 工作流。由于 Flutter 不能在 macOS 上交叉编译 Windows 桌面程序，Windows 安装包需要在 Windows 环境中构建。

### 在 GitHub Actions 生成安装包

推送 `v*` 标签，或在 GitHub Actions 页面手动运行 `Build Windows Installer` 工作流。构建完成后，在 workflow artifact 中下载：

```text
AIMemoSetup-版本号.exe
```

安装包会安装 AIMemo Windows 桌面版，并在安装完成后提供启动选项；安装界面会按系统语言自动显示简体中文或英文。

### 在 Windows 本地生成安装包

准备环境：

- Flutter stable
- Visual Studio 2022，包含 “Desktop development with C++”
- Inno Setup 6

在 PowerShell 中执行：

```powershell
flutter pub get
.\scripts\build_windows_installer.ps1
```

产物位置：

```text
dist\windows\AIMemoSetup-版本号.exe
```

## 测试和检查

Flutter：

```bash
flutter analyze
flutter test
flutter build macos
pkill -x aimemo || true
sleep 1
open build/macos/Build/Products/Release/aimemo.app
```

后端：

```bash
cd backend
npm run build
npm test
```

Windows 安装包检查需要在 Windows 环境执行：

```powershell
.\scripts\build_windows_installer.ps1
```

协作约定：Flutter app 变更验证通过后，需要继续执行 macOS Release build，并关闭旧 app 后打开新构建给用户确认。

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
windows/
installer/
  windows/
scripts/
test/
web/
macos/
backend/
  prisma/
  src/
  test/
docs/
```

关键文件：

- `lib/src/features/home_page.dart`：主界面和交互。
- `lib/src/services/app_database.dart`：桌面端 SQLite 数据层。
- `lib/src/services/in_memory_memo_store.dart`：Web 预览内存数据层。
- `lib/src/services/summary_api_client.dart`：OpenAI-compatible 模型请求客户端。
- `lib/src/services/template_renderer.dart`：模板变量渲染。
- `backend/src/server.ts`：多端后端 API 路由。
- `backend/prisma/schema.prisma`：Postgres 数据模型。

## 常见问题

### 默认模板更新后没有变化

已经保存过的自定义模板会保留用户版本。进入“总结”页展开“当前模板”，点击“恢复默认”，即可应用当前周期的新版默认模板。默认模板会按日报、周报、月报、年报和自定义总结分别提供不同结构；自定义总结会用 `{period_days}` 判断区间是否超过 7 天。

### Web 能用，macOS 跑不起来

通常是 Xcode 没装完整。执行：

```bash
flutter doctor
```

按提示补 Xcode、CocoaPods 或授权步骤。

### 后端依赖安装卡住

如果 `cd backend && npm install` 长时间没有输出，先确认是否有残留安装进程，再尝试指定镜像源：

```bash
npm install --registry=https://registry.npmmirror.com
```

如果卡在 Prisma、esbuild、Rollup 等原生依赖下载阶段，可以在当前 shell 临时走本机代理后重试：

```bash
export ALL_PROXY=http://127.0.0.1:7890
export all_proxy=http://127.0.0.1:7890
export HTTP_PROXY=http://127.0.0.1:7890
export http_proxy=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
```
