import { describe, expect, test } from 'vitest';

import { loadConfig, type AppConfig } from '../src/config.js';
import {
  ConsoleEmailSender,
  ResendEmailSender,
  SmtpEmailSender,
  createEmailSender,
} from '../src/email.js';
import { OpenAiCompatibleClient, type LlmClient } from '../src/llm.js';
import { createServer } from '../src/server.js';
import type { WechatClient } from '../src/wechat.js';
import { TestStore } from './testStore.js';

describe('AIMemo backend API', () => {
  test('logs in with email code and returns current user quota', async () => {
    const { app, login } = await testApp();
    const session = await login('User@Example.COM');

    const response = await app.inject({
      method: 'GET',
      url: '/me',
      headers: bearer(session.accessToken),
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      user: {
        email: 'user@example.com',
        bindings: { email: true, wechat: false },
      },
      quota: { limit: 30, used: 0, remaining: 30 },
    });
    await app.close();
  });

  test('uses Prisma store by default during local development', () => {
    const localConfig = loadConfig({
      NODE_ENV: 'development',
      AUTH_SECRET: 'test-secret',
      LLM_API_KEY_KEYCHAIN_DISABLED: 'true',
    });
    expect(localConfig.dataStore).toBe('prisma');
  });

  test('allows the universal login code 1234', async () => {
    const { app } = await testApp();

    const started = await app.inject({
      method: 'POST',
      url: '/auth/email/start',
      payload: { email: 'user@example.com' },
    });
    expect(started.statusCode).toBe(200);

    const verified = await app.inject({
      method: 'POST',
      url: '/auth/email/verify',
      payload: { email: 'user@example.com', code: '1234' },
    });

    expect(verified.statusCode).toBe(200);
    expect(verified.json()).toMatchObject({
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
      user: { email: 'user@example.com' },
    });
    await app.close();
  });

  test('allows universal login code when email delivery fails', async () => {
    const app = await createServer({
      config: testConfig(),
      store: new TestStore(),
      emailSender: {
        async sendLoginCode() {
          throw new Error('email delivery failed');
        },
      },
      llmClient: fakeLlm('测试总结。'),
    });

    const started = await app.inject({
      method: 'POST',
      url: '/auth/email/start',
      payload: { email: 'user@example.com' },
    });
    expect(started.statusCode).toBe(200);

    const verified = await app.inject({
      method: 'POST',
      url: '/auth/email/verify',
      payload: { email: 'user@example.com', code: '1234' },
    });

    expect(verified.statusCode).toBe(200);
    expect(verified.json()).toMatchObject({
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
      user: { email: 'user@example.com' },
    });
    await app.close();
  });

  test('defaults hosted model provider to DeepSeek', () => {
    const config = loadConfig({
      NODE_ENV: 'test',
      AUTH_SECRET: 'test-secret',
      LLM_API_KEY_KEYCHAIN_DISABLED: 'true',
    });

    expect(config.llmBaseUrl).toBe('https://api.deepseek.com');
    expect(config.llmModel).toBe('deepseek-v4-flash');
    expect(config.llmApiKey).toBe('');
  });

  test('defaults login tokens to one month', () => {
    const config = loadConfig({
      NODE_ENV: 'test',
      AUTH_SECRET: 'test-secret',
      LLM_API_KEY_KEYCHAIN_DISABLED: 'true',
    });

    expect(config.accessTokenTtl).toBe('30d');
    expect(config.refreshTokenDays).toBe(30);
  });

  test('uses SMTP email sender when SMTP env is configured', () => {
    const config = loadConfig({
      NODE_ENV: 'test',
      AUTH_SECRET: 'test-secret',
      SMTP_HOST: 'smtp.example.com',
      SMTP_PORT: '465',
      SMTP_USER: 'mailer',
      SMTP_PASS: 'secret',
      SMTP_FROM: 'AIMemo <no-reply@example.com>',
      SMTP_SECURE: 'true',
      LLM_API_KEY_KEYCHAIN_DISABLED: 'true',
    });

    expect(config.smtpHost).toBe('smtp.example.com');
    expect(config.smtpPort).toBe(465);
    expect(config.smtpSecure).toBe(true);
    expect(createEmailSender(config)).toBeInstanceOf(SmtpEmailSender);
  });

  test('uses Resend email sender when Resend env is configured', () => {
    const config = loadConfig({
      NODE_ENV: 'test',
      AUTH_SECRET: 'test-secret',
      RESEND_API_KEY: 're_test_123',
      RESEND_FROM: 'AIMemo <onboarding@resend.dev>',
      LLM_API_KEY_KEYCHAIN_DISABLED: 'true',
    });

    expect(config.resendApiKey).toBe('re_test_123');
    expect(config.resendFrom).toBe('AIMemo <onboarding@resend.dev>');
    expect(createEmailSender(config)).toBeInstanceOf(ResendEmailSender);
  });

  test('falls back to console email sender when SMTP env is missing', () => {
    const config = loadConfig({
      NODE_ENV: 'test',
      AUTH_SECRET: 'test-secret',
      LLM_API_KEY_KEYCHAIN_DISABLED: 'true',
    });

    expect(createEmailSender(config)).toBeInstanceOf(ConsoleEmailSender);
  });

  test('refreshes access tokens and rejects reused refresh token', async () => {
    const { app, login } = await testApp();
    const session = await login();

    const refreshed = await app.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: { refreshToken: session.refreshToken },
    });

    expect(refreshed.statusCode).toBe(200);
    expect(refreshed.json().accessToken).toEqual(expect.any(String));

    const reused = await app.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: { refreshToken: session.refreshToken },
    });

    expect(reused.statusCode).toBe(401);
    await app.close();
  });

  test('logs in from WeChat mini program', async () => {
    const wechatClient: WechatClient = {
      async loginMiniProgram(code) {
        expect(code).toBe('wx-code');
        return { openId: 'wechat-open-id', unionId: 'wechat-union-id' };
      },
    };
    const { app } = await testApp({ wechatClient });

    const response = await app.inject({
      method: 'POST',
      url: '/auth/wechat/mini-program/login',
      payload: { code: 'wx-code' },
    });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      accessToken: expect.any(String),
      user: { bindings: { email: false, wechat: true } },
    });
    await app.close();
  });

  test('creates, updates, soft deletes tasks and returns active tags only', async () => {
    const { app, login } = await testApp();
    const session = await login();

    const created = await app.inject({
      method: 'POST',
      url: '/tasks',
      headers: bearer(session.accessToken),
      payload: { body: '完成 AIMemo 后端', tags: ['工作'] },
    });
    const taskId = created.json().task.id as string;

    const updated = await app.inject({
      method: 'PATCH',
      url: `/tasks/${taskId}`,
      headers: bearer(session.accessToken),
      payload: { isCompleted: true, tags: ['工作', '后端'] },
    });

    expect(updated.statusCode).toBe(200);
    expect(updated.json().task).toMatchObject({
      isCompleted: true,
      tags: ['工作', '后端'],
    });

    const transient = await app.inject({
      method: 'POST',
      url: '/tasks',
      headers: bearer(session.accessToken),
      payload: { body: '临时任务', tags: ['临时'] },
    });
    await app.inject({
      method: 'DELETE',
      url: `/tasks/${transient.json().task.id}`,
      headers: bearer(session.accessToken),
    });

    const tags = await app.inject({
      method: 'GET',
      url: '/tags',
      headers: bearer(session.accessToken),
    });
    const tasks = await app.inject({
      method: 'GET',
      url: '/tasks',
      headers: bearer(session.accessToken),
    });

    expect(tags.json().items).toEqual(expect.arrayContaining(['工作', '后端']));
    expect(tags.json().items).not.toContain('临时');
    expect(tasks.json().items).toHaveLength(1);
    await app.close();
  });

  test('returns parser errors without converting them to internal errors', async () => {
    const { app, login } = await testApp();
    const session = await login();
    const created = await app.inject({
      method: 'POST',
      url: '/tasks',
      headers: bearer(session.accessToken),
      payload: { body: '待删任务', tags: [] },
    });

    const deleted = await app.inject({
      method: 'DELETE',
      url: `/tasks/${created.json().task.id}`,
      headers: {
        ...bearer(session.accessToken),
        'content-type': 'application/json',
      },
      payload: '',
    });

    expect(deleted.statusCode).toBe(400);
    expect(deleted.json()).toMatchObject({
      error: { code: 'FST_ERR_CTP_EMPTY_JSON_BODY' },
    });
    await app.close();
  });

  test('creates tasks idempotently by client id', async () => {
    const { app, login } = await testApp();
    const session = await login();
    const payload = {
      body: '同步本地任务',
      tags: ['同步'],
      clientId: 'desktop-client-task-1',
    };

    const first = await app.inject({
      method: 'POST',
      url: '/tasks',
      headers: bearer(session.accessToken),
      payload,
    });
    const second = await app.inject({
      method: 'POST',
      url: '/tasks',
      headers: bearer(session.accessToken),
      payload,
    });
    const tasks = await app.inject({
      method: 'GET',
      url: '/tasks',
      headers: bearer(session.accessToken),
    });

    expect(first.statusCode).toBe(200);
    expect(second.statusCode).toBe(200);
    expect(second.json().task.id).toBe(first.json().task.id);
    expect(second.json().task.clientId).toBe('desktop-client-task-1');
    expect(tasks.json().items).toHaveLength(1);
    await app.close();
  });

  test('generates summaries, stores output only, and consumes shared quota', async () => {
    const llmClient = fakeLlm('今天完成了后端接口。');
    const { app, login } = await testApp({
      config: { monthlySummaryLimit: 1 },
      llmClient,
    });
    const session = await login();

    const generated = await app.inject({
      method: 'POST',
      url: '/summaries/generate',
      headers: bearer(session.accessToken),
      payload: summaryPayload(),
    });

    expect(generated.statusCode).toBe(200);
    expect(generated.json()).toMatchObject({
      summary: '今天完成了后端接口。',
      quota: { limit: 1, used: 1, remaining: 0 },
    });

    const history = await app.inject({
      method: 'GET',
      url: '/summaries',
      headers: bearer(session.accessToken),
    });
    expect(history.json().items[0]).toMatchObject({
      output: '今天完成了后端接口。',
      model: 'test-model',
    });
    expect(JSON.stringify(history.json())).not.toContain('完整 prompt');

    const exceeded = await app.inject({
      method: 'POST',
      url: '/summaries/generate',
      headers: bearer(session.accessToken),
      payload: summaryPayload(),
    });
    expect(exceeded.statusCode).toBe(429);
    await app.close();
  });

  test('does not consume quota when model generation fails', async () => {
    const llmClient: LlmClient = {
      modelName: () => 'test-model',
      async generateSummary() {
        throw new Error('model down');
      },
    };
    const { app, login } = await testApp({ llmClient });
    const session = await login();

    const generated = await app.inject({
      method: 'POST',
      url: '/summaries/generate',
      headers: bearer(session.accessToken),
      payload: summaryPayload(),
    });
    const quota = await app.inject({
      method: 'GET',
      url: '/me/quota',
      headers: bearer(session.accessToken),
    });

    expect(generated.statusCode).toBe(500);
    expect(quota.json()).toMatchObject({ used: 0, remaining: 30 });
    await app.close();
  });

  test('explains missing hosted model backend config', async () => {
    const config = {
      ...loadConfig({ NODE_ENV: 'test', AUTH_SECRET: 'test-secret' }),
      llmApiKey: '',
    };
    const client = new OpenAiCompatibleClient(config);

    await expect(
      client.generateSummary({ prompt: '完整 prompt：请总结今天任务。' }),
    ).rejects.toMatchObject({
      statusCode: 400,
      code: 'llm_not_configured',
      message: expect.stringContaining('官方托管模型暂不可用'),
    });
  });
});

async function testApp(options: {
  config?: Partial<AppConfig>;
  llmClient?: LlmClient;
  wechatClient?: WechatClient;
} = {}) {
  let latestCode = '';
  const config = {
    ...testConfig(),
    ...options.config,
  };
  const app = await createServer({
    config,
    store: new TestStore(),
    emailSender: {
      async sendLoginCode(_email, code) {
        latestCode = code;
      },
    },
    llmClient: options.llmClient ?? fakeLlm('测试总结。'),
    wechatClient: options.wechatClient,
  });

  const login = async (email = 'user@example.com') => {
    await app.inject({
      method: 'POST',
      url: '/auth/email/start',
      payload: { email },
    });
    const verified = await app.inject({
      method: 'POST',
      url: '/auth/email/verify',
      payload: { email, code: latestCode },
    });
    expect(verified.statusCode).toBe(200);
    return verified.json() as {
      accessToken: string;
      refreshToken: string;
    };
  };

  return { app, login };
}

function testConfig(): AppConfig {
  return {
    ...loadConfig({ NODE_ENV: 'test', AUTH_SECRET: 'test-secret' }),
    nodeEnv: 'test',
    authSecret: 'test-secret',
  };
}

function fakeLlm(summary: string): LlmClient {
  return {
    modelName: () => 'test-model',
    async generateSummary(input) {
      expect(input.prompt).toContain('完整 prompt');
      return summary;
    },
  };
}

function summaryPayload() {
  return {
    periodType: 'daily',
    periodLabel: '2026-05-11',
    periodStart: '2026-05-11T00:00:00.000Z',
    periodEnd: '2026-05-12T00:00:00.000Z',
    tags: ['工作'],
    tasks: '- 完成任务',
    prompt: '完整 prompt：请总结今天任务。',
  };
}

function bearer(token: string) {
  return { authorization: `Bearer ${token}` };
}
