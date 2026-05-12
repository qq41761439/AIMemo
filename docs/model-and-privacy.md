# AIMemo 模型服务与隐私

## 配置模型服务

打开 AIMemo 后，进入“总结”页，点击标题右侧的“模型”按钮。

选择“使用自己的模型服务”时，填写 OpenAI-compatible 服务的 `API Key`、`Base URL` 和 `Model`。例如：

```text
Base URL: https://api.openai.com/v1
Model: gpt-4o-mini
```

也可以直接填写本机 CLIProxyAPI 参数。注意不要填写管理面板页面地址 `http://localhost:8317/management.html#/`，应填写 OpenAI-compatible API 地址：

```text
Base URL: http://127.0.0.1:8317/v1
Model: CLIProxyAPI 管理页里配置的模型名或别名
API Key: CLIProxyAPI 配置中的 api-keys 值
```

## 自定义模型模式

- 桌面客户端会直接请求 `{Base URL}/chat/completions`，不需要本地 Node 代理。
- `API Key` 会保存到系统安全存储。
- `Base URL`、`Model` 和“是否已保存密钥”的状态会保存到本地 SQLite 的 `app_settings`。
- 应用打开总结页时不会主动读取钥匙串，只有保存、清除密钥或生成总结需要真实密钥时才访问系统安全存储。
- macOS 桌面版会把 API Key 写入系统钥匙串。若钥匙串暂时无响应，模型设置保存会超时并在弹窗里显示错误，不会一直停留在保存中。

## 官方托管模型模式

选择“使用官方模型”时，登录后即可免费生成总结。当前本地开发版会使用内置后端地址：

```text
http://127.0.0.1:8787
```

验证码会打印在后端控制台。验证成功后，模型设置会显示已登录状态，生成总结会请求后端的 `/summaries/generate`。

官方托管模式的 access token 与 refresh token 会保存到系统安全存储，默认 30 天过期；后端地址和“是否已登录”的状态会保存到本地 SQLite。当前客户端遇到登录过期会提示重新登录，自动 refresh 和额度展示会在后续补齐。

## 数据和隐私

- 桌面版任务、标签、模板、总结历史和右侧栏宽度保存在本机 SQLite。
- Web 预览版只存在浏览器运行时内存中，刷新会清空。
- 自定义模型模式下，AIMemo 会在生成总结时直接把 prompt 发送给用户配置的模型服务。
- 官方托管模式生成总结时会把 prompt 发送到 AIMemo 后端，由后端调用模型并保存总结输出、周期、标签、模型等元数据。
- 后端不保存完整 prompt 快照。
- API Key 只应保存在系统安全存储或服务端环境变量中，不要写入 SQLite、README、测试或 git。

## 生成总结失败排查

进入“总结”页点击“模型”按钮，检查是否已经配置模型服务。

自定义模型模式：

- 确认 `Base URL` 是 OpenAI-compatible API 地址，例如 `https://api.openai.com/v1` 或 `http://127.0.0.1:8317/v1`。
- 确认模型名和 API Key 可用。
- 确认模型服务网络可达。

官方托管模式：

- 检查后端地址是否正确。
- 检查后端服务是否已启动。
- 检查邮箱验证码登录是否完成。
- 检查后端是否配置了托管模型服务密钥。
