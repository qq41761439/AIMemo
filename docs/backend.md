# AIMemo 后端服务指南

后端位于 `backend/`，用于承接桌面端、小程序和 Flutter App 的统一账号、云端任务、云端总结历史、免费额度和服务端模型代理。

## 本地启动

```bash
cd backend
npm install
cp .env.example .env
npm run prisma:generate
npm run dev
```

本地开发默认 `DATA_STORE=memory`，不需要先启动 Postgres；邮箱验证码会打印到后端控制台，重启后登录码、会话和云端数据会清空。后端默认监听 `127.0.0.1:8787`。

登录 token 默认 30 天过期：`ACCESS_TOKEN_TTL=30d`，`REFRESH_TOKEN_DAYS=30`。

如果端口已被旧服务占用，先结束旧进程再重新运行。

## 使用 Postgres 持久化

如果要稳定查看后端用户记录，把后端切到本地 Postgres 持久化模式：

```bash
cd backend
npm run db:up
```

然后把 `backend/.env` 里的 `DATA_STORE` 改成 `prisma`，确认 `DATABASE_URL` 是：

```text
DATABASE_URL=postgresql://aimemo:aimemo@localhost:5432/aimemo
```

首次启用或模型变更后同步数据库结构，再启动后端：

```bash
npm run prisma:push
npm run dev
```

查看用户记录：

```bash
npm run users:list
```

打开 Prisma Studio：

```bash
npm run db:studio
```

浏览器中查看 `User`、`Task`、`Summary`、`RefreshSession` 和 `UsageQuota` 表。

## 环境变量

生产环境需要配置 Postgres：

```text
NODE_ENV=production
HOST=0.0.0.0
DATA_STORE=prisma
DATABASE_URL=postgresql://user:password@host:5432/aimemo
AUTH_SECRET=一段足够长的随机字符串
LLM_BASE_URL=https://api.deepseek.com
LLM_API_KEY=真实模型服务密钥
LLM_MODEL=deepseek-v4-flash
FREE_MONTHLY_SUMMARY_LIMIT=30
```

如果本地开发也需要持久化后端数据，可以把 `.env` 里的 `DATA_STORE` 改为 `prisma`，并提供可连接且已同步结构的 `DATABASE_URL`；仓库内的 `backend/docker-compose.yml` 已经提供了本地 Postgres。

微信小程序登录需要配置：

```text
WECHAT_MINI_PROGRAM_APP_ID=小程序 AppID
WECHAT_MINI_PROGRAM_APP_SECRET=小程序 AppSecret
```

上线前需要把控制台验证码替换为真实邮件服务。

## 部署到 Render

仓库根目录已经提供 `render.yaml`，会创建：

- 一个 Node Web Service：`aimemo-backend`
- 一个 Render Postgres：`aimemo-postgres`

当前 Blueprint 默认使用：

- 服务区域：`singapore`
- Web Service 规格：`free`
- Postgres 规格：`free`

当前仓库已经切到免费版 Blueprint，适合先试跑。但要注意 Render 当前免费档限制（最近核对时间：2026-05-13）：

- 免费 Web Service 在 15 分钟没有入站请求后会休眠，下次请求可能要等待大约 1 分钟冷启动。
- 免费 Postgres 会在创建 30 天后过期，不适合长期保留 AIMemo 用户和任务数据。
- 免费 Web Service 不能使用 `preDeployCommand`，所以仓库里把 Prisma schema 同步放进了 `buildCommand`。

### Render 部署步骤

1. 把代码推到你的 GitHub 仓库。
2. 登录 Render，点击 `New` -> `Blueprint`。
3. 连接仓库，选择这个项目。
4. 确认 Render 识别仓库根目录的 `render.yaml`。
5. 在首次创建时填写 `sync: false` 的环境变量：
   - `LLM_API_KEY`
   - `WECHAT_MINI_PROGRAM_APP_ID`
   - `WECHAT_MINI_PROGRAM_APP_SECRET`
6. 点击创建，等待 Render 自动执行 build、`prisma generate`、`prisma db push` 和启动服务。
7. 部署完成后，用 Render 分配的服务地址访问：

```text
https://你的服务名.onrender.com/health
```

如果返回 `{"ok":true}`，说明基础部署成功。

### Blueprint 当前行为

- `rootDir: backend`：只在 `backend/` 相关改动时触发这个服务重新构建。
- `buildCommand`：安装依赖、生成 Prisma Client、编译 TypeScript 到 `dist/`，然后执行 `prisma db push` 把 schema 同步到 Render Postgres。
- `healthCheckPath: /health`：让 Render 用后端健康接口判断是否可接流量。
- `DATABASE_URL`：自动引用 `aimemo-postgres` 的连接串，不需要手填。
- `AUTH_SECRET`：由 Render 自动生成随机值。

### 部署后的注意事项

- 当前邮箱验证码仍然由 `ConsoleEmailSender` 打到后端日志，不会真的发到用户邮箱。
- 也就是说，部署到 Render 后，邮箱登录仍然需要你去 Render 日志里查看验证码。
- 如果要让真实用户通过邮箱登录，下一步需要接入真实邮件服务，例如 Resend、Postmark、SendGrid 或自建 SMTP 方案。
- `sync: false` 的密钥只会在 Blueprint 首次创建时提示输入；后续新增这类变量时，需要在 Render 控制台里手动补。
- 免费版更适合演示和自测，不适合正式生产环境。

### 客户端如何接到 Render 后端

部署完成后，把桌面端“官方模型服务地址”改成你的 Render 地址，例如：

```text
https://aimemo-backend.onrender.com
```

当前桌面端默认仍然指向本机开发地址 `http://127.0.0.1:8787`，这是为了本地开发方便；线上使用时需要手动改成 Render 地址。

## 托管模型配置

如果要用“官方托管模型”生成总结，后端需要配置托管模型服务。默认后端模型服务为 DeepSeek：

```text
LLM_BASE_URL=https://api.deepseek.com
LLM_MODEL=deepseek-v4-flash
```

本地 macOS 开发建议把真实密钥保存到系统钥匙串。后端会在 `LLM_API_KEY` 为空时读取 service `AIMemo Backend LLM API Key`、account `deepseek` 的密钥；如果密钥缺失，用户侧只会看到“官方托管模型暂不可用”，后端日志会提示具体缺少的配置。

## API

后端第一版 API：

- `POST /auth/email/start`：发送邮箱验证码。
- `POST /auth/email/verify`：验证邮箱验证码，返回 access token 和 refresh token。
- `POST /auth/wechat/mini-program/login`：微信小程序登录。
- `POST /auth/refresh`：刷新 token。
- `GET /me`、`GET /me/quota`：获取当前用户和免费额度。
- `GET /tasks`、`POST /tasks`、`PATCH /tasks/:id`、`DELETE /tasks/:id`：云端任务 CRUD，删除为软删除。`POST /tasks` 可传 `clientId`，同一用户重复提交相同 `clientId` 时返回已存在的云端任务，避免同步重试造成重复任务。
- `GET /tags`：只返回仍有关联任务的标签，并按最近关联任务靠前排序。
- `POST /summaries/generate`：后端调用固定模型生成总结，成功后扣减本月免费次数。
- `GET /summaries`：获取云端总结历史。
- `GET /client/config`：获取客户端可展示的开关和免费额度。

后端只把真实模型 API Key 保存在服务端环境变量中。`/summaries/generate` 会用请求中的 prompt 调模型，但云端历史只保存总结输出和周期、标签、模型等元数据，不保存完整 prompt 快照。
