import { PrismaClient } from '@prisma/client';

import type { DataStore } from './store.js';
import type {
  CreateSummaryInput,
  CreateTaskInput,
  EmailLoginCode,
  QuotaRecord,
  RefreshSession,
  SummaryRecord,
  TaskRecord,
  UpdateTaskInput,
  User,
} from './types.js';

export class PrismaStore implements DataStore {
  constructor(private readonly prisma = new PrismaClient()) {}

  async saveEmailCode(
    email: string,
    codeHash: string,
    expiresAt: Date,
  ): Promise<void> {
    await this.prisma.emailLoginCode.upsert({
      where: { email },
      update: { codeHash, expiresAt, attempts: 0 },
      create: { email, codeHash, expiresAt },
    });
  }

  async getEmailCode(email: string): Promise<EmailLoginCode | null> {
    return this.prisma.emailLoginCode.findUnique({ where: { email } });
  }

  async incrementEmailCodeAttempts(email: string): Promise<void> {
    await this.prisma.emailLoginCode.updateMany({
      where: { email },
      data: { attempts: { increment: 1 } },
    });
  }

  async deleteEmailCode(email: string): Promise<void> {
    await this.prisma.emailLoginCode.deleteMany({ where: { email } });
  }

  async findOrCreateUserByEmail(email: string): Promise<User> {
    return this.prisma.user.upsert({
      where: { email },
      update: {},
      create: { email },
    });
  }

  async findOrCreateUserByWechat(input: {
    openId: string;
    unionId?: string | null;
  }): Promise<User> {
    return this.prisma.user.upsert({
      where: { wechatOpenId: input.openId },
      update: { wechatUnionId: input.unionId ?? undefined },
      create: {
        wechatOpenId: input.openId,
        wechatUnionId: input.unionId ?? null,
      },
    });
  }

  async findUserById(userId: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id: userId } });
  }

  async saveRefreshSession(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<RefreshSession> {
    return this.prisma.refreshSession.create({ data: input });
  }

  async getRefreshSession(tokenHash: string): Promise<RefreshSession | null> {
    return this.prisma.refreshSession.findUnique({ where: { tokenHash } });
  }

  async deleteRefreshSession(tokenHash: string): Promise<void> {
    await this.prisma.refreshSession.deleteMany({ where: { tokenHash } });
  }

  async getQuota(
    userId: string,
    period: string,
    limit: number,
  ): Promise<QuotaRecord> {
    const quota = await this.prisma.usageQuota.upsert({
      where: { userId_period: { userId, period } },
      update: { limit },
      create: { userId, period, limit, used: 0 },
    });
    return toQuota(quota.period, quota.limit, quota.used);
  }

  async incrementQuota(
    userId: string,
    period: string,
    limit: number,
  ): Promise<QuotaRecord> {
    const quota = await this.prisma.usageQuota.upsert({
      where: { userId_period: { userId, period } },
      update: { limit, used: { increment: 1 } },
      create: { userId, period, limit, used: 1 },
    });
    return toQuota(quota.period, quota.limit, quota.used);
  }

  async listTasks(
    userId: string,
    options: { updatedAfter?: Date; limit?: number } = {},
  ): Promise<TaskRecord[]> {
    return this.prisma.task.findMany({
      where: {
        userId,
        updatedAt: options.updatedAfter ? { gt: options.updatedAfter } : undefined,
      },
      orderBy: { updatedAt: 'desc' },
      take: options.limit ?? 100,
    });
  }

  async createTask(userId: string, input: CreateTaskInput): Promise<TaskRecord> {
    const clientId = cleanClientId(input.clientId);
    if (clientId) {
      const existing = await this.prisma.task.findFirst({
        where: { userId, clientId },
      });
      if (existing) {
        return existing;
      }
    }

    const now = new Date();
    return this.prisma.task.create({
      data: {
        userId,
        body: input.body,
        tags: cleanTags(input.tags),
        isCompleted: input.isCompleted,
        createdAt: input.createdAt,
        completedAt:
          input.completedAt ?? (input.isCompleted ? now : null),
        clientId,
      },
    });
  }

  async updateTask(
    userId: string,
    taskId: string,
    input: UpdateTaskInput,
  ): Promise<TaskRecord | null> {
    const existing = await this.prisma.task.findFirst({
      where: { id: taskId, userId, deletedAt: null },
    });
    if (!existing) {
      return null;
    }
    const isCompleted = input.isCompleted ?? existing.isCompleted;
    return this.prisma.task.update({
      where: { id: taskId },
      data: {
        body: input.body,
        tags: input.tags ? cleanTags(input.tags) : undefined,
        isCompleted: input.isCompleted,
        createdAt: input.createdAt,
        completedAt:
          input.completedAt !== undefined
            ? input.completedAt
            : isCompleted && !existing.completedAt
              ? new Date()
              : !isCompleted
                ? null
                : undefined,
      },
    });
  }

  async softDeleteTask(userId: string, taskId: string): Promise<TaskRecord | null> {
    const existing = await this.prisma.task.findFirst({
      where: { id: taskId, userId, deletedAt: null },
    });
    if (!existing) {
      return null;
    }
    return this.prisma.task.update({
      where: { id: taskId },
      data: { deletedAt: new Date() },
    });
  }

  async listTags(userId: string): Promise<string[]> {
    const tasks = await this.prisma.task.findMany({
      where: { userId, deletedAt: null },
      select: { tags: true, updatedAt: true },
      orderBy: { updatedAt: 'desc' },
    });
    const latest = new Map<string, number>();
    for (const task of tasks) {
      for (const tag of task.tags) {
        latest.set(tag, Math.max(latest.get(tag) ?? 0, task.updatedAt.getTime()));
      }
    }
    return [...latest.entries()]
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .map(([tag]) => tag);
  }

  async createSummary(
    userId: string,
    input: CreateSummaryInput,
  ): Promise<SummaryRecord> {
    return this.prisma.summary.create({
      data: {
        userId,
        periodType: input.periodType,
        periodLabel: input.periodLabel,
        periodStart: input.periodStart,
        periodEnd: input.periodEnd,
        tags: cleanTags(input.tags),
        output: input.output,
        model: input.model,
      },
    }) as Promise<SummaryRecord>;
  }

  async listSummaries(userId: string, limit = 50): Promise<SummaryRecord[]> {
    return this.prisma.summary.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    }) as Promise<SummaryRecord[]>;
  }
}

function toQuota(period: string, limit: number, used: number): QuotaRecord {
  return {
    period,
    limit,
    used,
    remaining: Math.max(0, limit - used),
  };
}

function cleanTags(tags: string[]): string[] {
  return [...new Set(tags.map((tag) => tag.trim()).filter(Boolean))];
}

function cleanClientId(clientId?: string | null): string | null {
  const clean = clientId?.trim();
  return clean ? clean : null;
}
