import { randomUUID } from 'node:crypto';

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

export class InMemoryStore implements DataStore {
  private readonly users = new Map<string, User>();
  private readonly emailCodes = new Map<string, EmailLoginCode>();
  private readonly refreshSessions = new Map<string, RefreshSession>();
  private readonly tasks = new Map<string, TaskRecord>();
  private readonly summaries = new Map<string, SummaryRecord>();
  private readonly quotas = new Map<string, { period: string; limit: number; used: number }>();

  async saveEmailCode(
    email: string,
    codeHash: string,
    expiresAt: Date,
  ): Promise<void> {
    this.emailCodes.set(email, {
      email,
      codeHash,
      expiresAt,
      attempts: 0,
    });
  }

  async getEmailCode(email: string): Promise<EmailLoginCode | null> {
    return this.emailCodes.get(email) ?? null;
  }

  async incrementEmailCodeAttempts(email: string): Promise<void> {
    const record = this.emailCodes.get(email);
    if (record) {
      this.emailCodes.set(email, { ...record, attempts: record.attempts + 1 });
    }
  }

  async deleteEmailCode(email: string): Promise<void> {
    this.emailCodes.delete(email);
  }

  async findOrCreateUserByEmail(email: string): Promise<User> {
    const existing = [...this.users.values()].find((user) => user.email === email);
    if (existing) {
      return existing;
    }
    const now = new Date();
    const user: User = {
      id: randomUUID(),
      email,
      wechatOpenId: null,
      wechatUnionId: null,
      createdAt: now,
      updatedAt: now,
    };
    this.users.set(user.id, user);
    return user;
  }

  async findOrCreateUserByWechat(input: {
    openId: string;
    unionId?: string | null;
  }): Promise<User> {
    const existing = [...this.users.values()].find(
      (user) => user.wechatOpenId === input.openId,
    );
    if (existing) {
      return existing;
    }
    const now = new Date();
    const user: User = {
      id: randomUUID(),
      email: null,
      wechatOpenId: input.openId,
      wechatUnionId: input.unionId ?? null,
      createdAt: now,
      updatedAt: now,
    };
    this.users.set(user.id, user);
    return user;
  }

  async findUserById(userId: string): Promise<User | null> {
    return this.users.get(userId) ?? null;
  }

  async saveRefreshSession(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<RefreshSession> {
    const session = {
      id: randomUUID(),
      ...input,
    };
    this.refreshSessions.set(input.tokenHash, session);
    return session;
  }

  async getRefreshSession(tokenHash: string): Promise<RefreshSession | null> {
    return this.refreshSessions.get(tokenHash) ?? null;
  }

  async deleteRefreshSession(tokenHash: string): Promise<void> {
    this.refreshSessions.delete(tokenHash);
  }

  async getQuota(
    userId: string,
    period: string,
    limit: number,
  ): Promise<QuotaRecord> {
    const key = `${userId}:${period}`;
    const record = this.quotas.get(key) ?? { period, limit, used: 0 };
    this.quotas.set(key, { ...record, limit });
    return toQuota(record.period, limit, record.used);
  }

  async incrementQuota(
    userId: string,
    period: string,
    limit: number,
  ): Promise<QuotaRecord> {
    const key = `${userId}:${period}`;
    const record = this.quotas.get(key) ?? { period, limit, used: 0 };
    const next = { period, limit, used: record.used + 1 };
    this.quotas.set(key, next);
    return toQuota(period, limit, next.used);
  }

  async listTasks(
    userId: string,
    options: { updatedAfter?: Date; limit?: number } = {},
  ): Promise<TaskRecord[]> {
    return [...this.tasks.values()]
      .filter((task) => task.userId === userId)
      .filter((task) =>
        options.updatedAfter ? task.updatedAt > options.updatedAfter : true,
      )
      .sort((a, b) => b.updatedAt.getTime() - a.updatedAt.getTime())
      .slice(0, options.limit ?? 100);
  }

  async createTask(userId: string, input: CreateTaskInput): Promise<TaskRecord> {
    const clientId = cleanClientId(input.clientId);
    if (clientId) {
      const existing = [...this.tasks.values()].find(
        (task) => task.userId === userId && task.clientId === clientId,
      );
      if (existing) {
        return existing;
      }
    }

    const now = new Date();
    const isCompleted = input.isCompleted;
    const task: TaskRecord = {
      id: randomUUID(),
      userId,
      body: input.body,
      tags: cleanTags(input.tags),
      isCompleted,
      createdAt: input.createdAt ?? now,
      completedAt: input.completedAt ?? (isCompleted ? now : null),
      updatedAt: now,
      deletedAt: null,
      clientId,
    };
    this.tasks.set(task.id, task);
    return task;
  }

  async updateTask(
    userId: string,
    taskId: string,
    input: UpdateTaskInput,
  ): Promise<TaskRecord | null> {
    const existing = this.tasks.get(taskId);
    if (!existing || existing.userId !== userId || existing.deletedAt) {
      return null;
    }
    const isCompleted = input.isCompleted ?? existing.isCompleted;
    const task: TaskRecord = {
      ...existing,
      body: input.body ?? existing.body,
      tags: input.tags ? cleanTags(input.tags) : existing.tags,
      isCompleted,
      createdAt: input.createdAt ?? existing.createdAt,
      completedAt:
        input.completedAt !== undefined
          ? input.completedAt
          : isCompleted && !existing.completedAt
            ? new Date()
            : !isCompleted
              ? null
              : existing.completedAt,
      updatedAt: new Date(),
    };
    this.tasks.set(task.id, task);
    return task;
  }

  async softDeleteTask(userId: string, taskId: string): Promise<TaskRecord | null> {
    const existing = this.tasks.get(taskId);
    if (!existing || existing.userId !== userId || existing.deletedAt) {
      return null;
    }
    const task = { ...existing, deletedAt: new Date(), updatedAt: new Date() };
    this.tasks.set(task.id, task);
    return task;
  }

  async listTags(userId: string): Promise<string[]> {
    const firstSeen = new Map<string, number>();
    for (const task of this.tasks.values()) {
      if (task.userId !== userId || task.deletedAt) {
        continue;
      }
      for (const tag of task.tags) {
        const seen = firstSeen.get(tag) ?? 0;
        firstSeen.set(tag, Math.max(seen, task.updatedAt.getTime()));
      }
    }
    return [...firstSeen.entries()]
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .map(([tag]) => tag);
  }

  async createSummary(
    userId: string,
    input: CreateSummaryInput,
  ): Promise<SummaryRecord> {
    const summary: SummaryRecord = {
      id: randomUUID(),
      userId,
      ...input,
      tags: cleanTags(input.tags),
      createdAt: new Date(),
    };
    this.summaries.set(summary.id, summary);
    return summary;
  }

  async listSummaries(userId: string, limit = 50): Promise<SummaryRecord[]> {
    return [...this.summaries.values()]
      .filter((summary) => summary.userId === userId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, limit);
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
