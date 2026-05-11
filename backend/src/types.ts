export type PeriodType = 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom';

export type User = {
  id: string;
  email: string | null;
  wechatOpenId: string | null;
  wechatUnionId: string | null;
  createdAt: Date;
  updatedAt: Date;
};

export type EmailLoginCode = {
  email: string;
  codeHash: string;
  expiresAt: Date;
  attempts: number;
};

export type RefreshSession = {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: Date;
};

export type TaskRecord = {
  id: string;
  userId: string;
  body: string;
  tags: string[];
  isCompleted: boolean;
  createdAt: Date;
  completedAt: Date | null;
  updatedAt: Date;
  deletedAt: Date | null;
};

export type SummaryRecord = {
  id: string;
  userId: string;
  periodType: PeriodType;
  periodLabel: string;
  periodStart: Date;
  periodEnd: Date;
  tags: string[];
  output: string;
  model: string;
  createdAt: Date;
};

export type QuotaRecord = {
  period: string;
  limit: number;
  used: number;
  remaining: number;
};

export type CreateTaskInput = {
  body: string;
  tags: string[];
  isCompleted: boolean;
  createdAt?: Date;
  completedAt?: Date | null;
};

export type UpdateTaskInput = Partial<CreateTaskInput>;

export type CreateSummaryInput = {
  periodType: PeriodType;
  periodLabel: string;
  periodStart: Date;
  periodEnd: Date;
  tags: string[];
  output: string;
  model: string;
};
