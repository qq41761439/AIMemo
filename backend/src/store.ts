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

export type DataStore = {
  saveEmailCode(email: string, codeHash: string, expiresAt: Date): Promise<void>;
  getEmailCode(email: string): Promise<EmailLoginCode | null>;
  incrementEmailCodeAttempts(email: string): Promise<void>;
  deleteEmailCode(email: string): Promise<void>;
  findOrCreateUserByEmail(email: string): Promise<User>;
  findOrCreateUserByWechat(input: {
    openId: string;
    unionId?: string | null;
  }): Promise<User>;
  findUserById(userId: string): Promise<User | null>;
  saveRefreshSession(input: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<RefreshSession>;
  getRefreshSession(tokenHash: string): Promise<RefreshSession | null>;
  deleteRefreshSession(tokenHash: string): Promise<void>;
  getQuota(userId: string, period: string, limit: number): Promise<QuotaRecord>;
  incrementQuota(userId: string, period: string, limit: number): Promise<QuotaRecord>;
  listTasks(
    userId: string,
    options?: { updatedAfter?: Date; limit?: number },
  ): Promise<TaskRecord[]>;
  createTask(userId: string, input: CreateTaskInput): Promise<TaskRecord>;
  updateTask(
    userId: string,
    taskId: string,
    input: UpdateTaskInput,
  ): Promise<TaskRecord | null>;
  softDeleteTask(userId: string, taskId: string): Promise<TaskRecord | null>;
  listTags(userId: string): Promise<string[]>;
  createSummary(
    userId: string,
    input: CreateSummaryInput,
  ): Promise<SummaryRecord>;
  listSummaries(userId: string, limit?: number): Promise<SummaryRecord[]>;
};

export function currentQuotaPeriod(now = new Date()): string {
  return `${now.getUTCFullYear()}-${String(now.getUTCMonth() + 1).padStart(
    2,
    '0',
  )}`;
}

export function quotaDto(record: QuotaRecord) {
  return {
    period: record.period,
    limit: record.limit,
    used: record.used,
    remaining: Math.max(0, record.limit - record.used),
  };
}
