import cors from '@fastify/cors';
import Fastify, { type FastifyInstance, type FastifyRequest } from 'fastify';
import { z } from 'zod';

import { AuthService } from './auth.js';
import type { AppConfig } from './config.js';
import { loadConfig } from './config.js';
import type { EmailSender } from './email.js';
import { ConsoleEmailSender } from './email.js';
import { AppError, badRequest, notFound, quotaExceeded, unauthorized } from './errors.js';
import { InMemoryStore } from './inMemoryStore.js';
import type { LlmClient } from './llm.js';
import { OpenAiCompatibleClient } from './llm.js';
import type { DataStore } from './store.js';
import { currentQuotaPeriod, quotaDto } from './store.js';
import type { TaskRecord, User } from './types.js';
import type { WechatClient } from './wechat.js';
import { WechatApiClient } from './wechat.js';

const emailSchema = z.object({ email: z.string().email() });
const emailVerifySchema = emailSchema.extend({ code: z.string().min(4).max(12) });
const refreshSchema = z.object({ refreshToken: z.string().min(16) });
const wechatLoginSchema = z.object({ code: z.string().min(1) });
const periodTypeSchema = z.enum(['daily', 'weekly', 'monthly', 'yearly', 'custom']);
const taskInputSchema = z.object({
  body: z.string().trim().min(1).max(20000),
  tags: z.array(z.string().trim().min(1).max(50)).default([]),
  isCompleted: z.boolean().default(false),
  createdAt: z.string().datetime().optional(),
  completedAt: z.string().datetime().nullable().optional(),
  clientId: z.string().trim().min(1).max(120).nullable().optional(),
});
const taskPatchSchema = taskInputSchema.partial();
const summaryGenerateSchema = z.object({
  periodType: periodTypeSchema,
  periodLabel: z.string().trim().min(1).max(120),
  periodStart: z.string().datetime(),
  periodEnd: z.string().datetime(),
  tags: z.array(z.string().trim().min(1).max(50)).default([]),
  tasks: z.string().trim().min(1).max(100000),
  prompt: z.string().trim().min(1).max(120000),
});

export type ServerDependencies = {
  config?: AppConfig;
  store?: DataStore;
  emailSender?: EmailSender;
  llmClient?: LlmClient;
  wechatClient?: WechatClient;
};

export async function createServer(
  dependencies: ServerDependencies = {},
): Promise<FastifyInstance> {
  const config = dependencies.config ?? loadConfig();
  const store = dependencies.store ?? (await createDefaultStore(config));
  const auth = new AuthService(store, config);
  const emailSender = dependencies.emailSender ?? new ConsoleEmailSender();
  const llmClient = dependencies.llmClient ?? new OpenAiCompatibleClient(config);
  const wechatClient = dependencies.wechatClient ?? new WechatApiClient(config);

  const app = Fastify({ logger: config.nodeEnv !== 'test' });
  await app.register(cors, { origin: true });

  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof AppError) {
      if (error.code === 'llm_not_configured') {
        app.log.warn(
          'Hosted model is unavailable because LLM_API_KEY is not configured. ' +
            'Set LLM_API_KEY or store the key in macOS Keychain service ' +
            '"AIMemo Backend LLM API Key" with account "deepseek", then restart the backend.',
        );
      }
      return reply.status(error.statusCode).send({
        error: { code: error.code, message: error.message },
      });
    }
    if (error instanceof z.ZodError) {
      return reply.status(400).send({
        error: { code: 'validation_failed', message: error.issues[0]?.message },
      });
    }
    app.log.error(error);
    return reply.status(500).send({
      error: { code: 'internal_error', message: '服务暂时不可用。' },
    });
  });

  const requireUser = async (request: FastifyRequest): Promise<User> => {
    const authHeader = request.headers.authorization;
    const token = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!token) {
      throw unauthorized();
    }
    const userId = auth.verifyAccessToken(token);
    const user = await store.findUserById(userId);
    if (!user) {
      throw unauthorized();
    }
    return user;
  };

  app.get('/health', async () => ({ ok: true }));

  app.get('/client/config', async () => ({
    hostedModelAvailable: Boolean(config.llmApiKey),
    monthlyFreeSummaryLimit: config.monthlySummaryLimit,
    miniProgramEnabled: true,
  }));

  app.post('/auth/email/start', async (request) => {
    const { email } = emailSchema.parse(request.body);
    const code = await auth.startEmailLogin(email);
    await emailSender.sendLoginCode(email, code);
    return { ok: true };
  });

  app.post('/auth/email/verify', async (request) => {
    const { email, code } = emailVerifySchema.parse(request.body);
    const user = await auth.verifyEmailLogin(email, code);
    const tokens = await auth.issueTokens(user.id);
    return { ...tokens, user: userDto(user) };
  });

  app.post('/auth/wechat/mini-program/login', async (request) => {
    const { code } = wechatLoginSchema.parse(request.body);
    const login = await wechatClient.loginMiniProgram(code);
    const user = await store.findOrCreateUserByWechat(login);
    const tokens = await auth.issueTokens(user.id);
    return { ...tokens, user: userDto(user) };
  });

  app.post('/auth/refresh', async (request) => {
    const { refreshToken } = refreshSchema.parse(request.body);
    return auth.refresh(refreshToken);
  });

  app.get('/me', async (request) => {
    const user = await requireUser(request);
    const quota = await store.getQuota(
      user.id,
      currentQuotaPeriod(),
      config.monthlySummaryLimit,
    );
    return {
      user: userDto(user),
      quota: quotaDto(quota),
      config: {
        hostedModelAvailable: Boolean(config.llmApiKey),
        monthlyFreeSummaryLimit: config.monthlySummaryLimit,
      },
    };
  });

  app.get('/me/quota', async (request) => {
    const user = await requireUser(request);
    const quota = await store.getQuota(
      user.id,
      currentQuotaPeriod(),
      config.monthlySummaryLimit,
    );
    return quotaDto(quota);
  });

  app.get('/tasks', async (request) => {
    const user = await requireUser(request);
    const query = request.query as {
      updatedAfter?: string;
      limit?: string;
    };
    const updatedAfter = query.updatedAfter
      ? parseDate(query.updatedAfter, 'updatedAfter')
      : undefined;
    const tasks = await store.listTasks(user.id, {
      updatedAfter,
      limit: query.limit ? Math.min(parseInt(query.limit, 10), 200) : 100,
    });
    const visible = updatedAfter ? tasks : tasks.filter((task) => !task.deletedAt);
    return { items: visible.map(taskDto) };
  });

  app.post('/tasks', async (request) => {
    const user = await requireUser(request);
    const input = taskInputSchema.parse(request.body);
    const task = await store.createTask(user.id, {
      body: input.body,
      tags: input.tags,
      isCompleted: input.isCompleted,
      createdAt: input.createdAt ? new Date(input.createdAt) : undefined,
      completedAt:
        input.completedAt === undefined
          ? undefined
          : input.completedAt === null
            ? null
            : new Date(input.completedAt),
      clientId: input.clientId,
    });
    return { task: taskDto(task) };
  });

  app.patch('/tasks/:id', async (request) => {
    const user = await requireUser(request);
    const { id } = request.params as { id: string };
    const input = taskPatchSchema.parse(request.body);
    const task = await store.updateTask(user.id, id, {
      body: input.body,
      tags: input.tags,
      isCompleted: input.isCompleted,
      createdAt: input.createdAt ? new Date(input.createdAt) : undefined,
      completedAt:
        input.completedAt === undefined
          ? undefined
          : input.completedAt === null
            ? null
            : new Date(input.completedAt),
    });
    if (!task) {
      throw notFound('任务不存在。', 'task_not_found');
    }
    return { task: taskDto(task) };
  });

  app.delete('/tasks/:id', async (request) => {
    const user = await requireUser(request);
    const { id } = request.params as { id: string };
    const task = await store.softDeleteTask(user.id, id);
    if (!task) {
      throw notFound('任务不存在。', 'task_not_found');
    }
    return { task: taskDto(task) };
  });

  app.get('/tags', async (request) => {
    const user = await requireUser(request);
    return { items: await store.listTags(user.id) };
  });

  app.post('/summaries/generate', async (request) => {
    const user = await requireUser(request);
    const input = summaryGenerateSchema.parse(request.body);
    const period = currentQuotaPeriod();
    const quota = await store.getQuota(user.id, period, config.monthlySummaryLimit);
    if (quota.remaining <= 0) {
      throw quotaExceeded();
    }
    const summary = await llmClient.generateSummary({ prompt: input.prompt });
    const updatedQuota = await store.incrementQuota(
      user.id,
      period,
      config.monthlySummaryLimit,
    );
    if (updatedQuota.used > updatedQuota.limit) {
      throw quotaExceeded();
    }
    const record = await store.createSummary(user.id, {
      periodType: input.periodType,
      periodLabel: input.periodLabel,
      periodStart: parseDate(input.periodStart, 'periodStart'),
      periodEnd: parseDate(input.periodEnd, 'periodEnd'),
      tags: input.tags,
      output: summary,
      model: llmClient.modelName(),
    });
    return { summary: record.output, quota: quotaDto(updatedQuota) };
  });

  app.get('/summaries', async (request) => {
    const user = await requireUser(request);
    const query = request.query as { limit?: string };
    const records = await store.listSummaries(
      user.id,
      query.limit ? Math.min(parseInt(query.limit, 10), 100) : 50,
    );
    return { items: records.map(summaryDto) };
  });

  return app;
}

async function createDefaultStore(config: AppConfig): Promise<DataStore> {
  if (config.dataStore === 'memory') {
    return new InMemoryStore();
  }
  const { PrismaStore } = await import('./prismaStore.js');
  return new PrismaStore();
}

function parseDate(value: string, field: string): Date {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw badRequest(`${field} 不是有效日期。`, 'invalid_date');
  }
  return date;
}

function userDto(user: User) {
  return {
    id: user.id,
    email: user.email,
    bindings: {
      email: Boolean(user.email),
      wechat: Boolean(user.wechatOpenId),
    },
    createdAt: user.createdAt.toISOString(),
  };
}

function taskDto(task: TaskRecord) {
  return {
    id: task.id,
    body: task.body,
    tags: task.tags,
    isCompleted: task.isCompleted,
    createdAt: task.createdAt.toISOString(),
    completedAt: task.completedAt?.toISOString() ?? null,
    updatedAt: task.updatedAt.toISOString(),
    deletedAt: task.deletedAt?.toISOString() ?? null,
    clientId: task.clientId,
  };
}

function summaryDto(summary: {
  id: string;
  periodType: string;
  periodLabel: string;
  periodStart: Date;
  periodEnd: Date;
  tags: string[];
  output: string;
  model: string;
  createdAt: Date;
}) {
  return {
    id: summary.id,
    periodType: summary.periodType,
    periodLabel: summary.periodLabel,
    periodStart: summary.periodStart.toISOString(),
    periodEnd: summary.periodEnd.toISOString(),
    tags: summary.tags,
    output: summary.output,
    model: summary.model,
    createdAt: summary.createdAt.toISOString(),
  };
}
