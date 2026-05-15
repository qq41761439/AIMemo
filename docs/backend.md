# AIMemo 后端服务指南

后端位于 `backend/`，用于承接桌面端、小程序和 Flutter App 的统一账号、云端任务、云端总结历史、免费额度和服务端模型代理。

## 本地启动

```bash
cd backend
npm install
cp .env.example .env
npm run db:up
npm run prisma:generate
npm run prisma:push
npm run dev
```

本地开发默认 `DATA_STORE=prisma`，使用 `backend/docker-compose.yml` 启动的本地 Postgres 持久化保存用户、任务、总结、登录会话和额度。邮箱验证码会打印到后端控制台；后端默认监听 `127.0.0.1:8787`。

登录 token 默认 30 天过期：`ACCESS_TOKEN_TTL=30d`，`REFRESH_TOKEN_DAYS=30`。

后端会在 `npm run dev` 的终端打印接口响应体日志，便于本地联调；`accessToken`、`refreshToken`、验证码和密钥类字段会自动脱敏。

如果端口已被旧服务占用，先结束旧进程再重新运行。

## 本地 Postgres

```bash
cd backend
npm run db:up
```

确认 `backend/.env` 里的 `DATABASE_URL` 是：

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

如果要让邮箱验证码真正发到用户邮箱，推荐优先配置 Resend API。因为 Render 免费 Web Service 不能访问 SMTP 常用端口 `25`、`465`、`587`，但可以正常请求 HTTPS API。

Resend API 配置：

```text
RESEND_API_KEY=re_xxxxxxxxx
RESEND_FROM=AIMemo <onboarding@resend.dev>
```

如果你后续升级到 Render 付费实例，也可以改用 SMTP：

```text
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=mailer@example.com
SMTP_PASS=真实 SMTP 密码或授权码
SMTP_FROM=AIMemo <mailer@example.com>
SMTP_SECURE=false
```

本地开发不再提供后端内存数据源；如果 `DATA_STORE` 未设置，也会默认使用 `prisma`。

微信小程序登录需要配置：

```text
WECHAT_MINI_PROGRAM_APP_ID=小程序 AppID
WECHAT_MINI_PROGRAM_APP_SECRET=小程序 AppSecret
```

如果未配置 `RESEND_API_KEY` / `RESEND_FROM`，且也未配置 `SMTP_HOST` / `SMTP_FROM`，后端会回退到控制台模式，验证码只打印在日志里。

开发和联调时，邮箱验证码也支持直接输入 `1234` 登录，方便在没有邮件服务的环境里快速验证流程。即使 Resend/SMTP 配置错误导致邮件投递失败，后端也会保留已生成的验证码并返回成功，用户仍可继续输入 `1234` 或从后端日志读取真实验证码完成登录。

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
   - `RESEND_API_KEY`
   - `RESEND_FROM`
   - `SMTP_HOST`
   - `SMTP_USER`
   - `SMTP_PASS`
   - `SMTP_FROM`
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

- Render 免费档推荐使用 Resend API，不要优先走 SMTP。
- 只有在 Render 已配置 `RESEND_API_KEY` 和 `RESEND_FROM`，或者服务升级为付费实例并正确配置 SMTP 后，邮箱验证码才会真实发送。
- 如果邮件配置没配好，后端会回退到 `ConsoleEmailSender`，验证码仍然只会打印在 Render 日志里。
- Resend 的 `onboarding@resend.dev` 只适合测试，并且通常只能发到 Resend 账号自己的邮箱；要发给其他用户，需要在 Resend 验证你自己的域名。
- `sync: false` 的密钥只会在 Blueprint 首次创建时提示输入；后续新增这类变量时，需要在 Render 控制台里手动补。
- 免费版更适合演示和自测，不适合正式生产环境。

### 客户端如何接到 Render 后端

当前仓库默认官方后端地址已经指向：

```text
https://aimemo-backend.onrender.com
```

新安装的客户端会默认使用这个地址。若你在本机联调开发环境，需要手动切回：

```text
http://127.0.0.1:8787
```

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
