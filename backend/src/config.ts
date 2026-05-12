import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';

export type DataStoreMode = 'memory' | 'prisma';

export type AppConfig = {
  nodeEnv: string;
  host: string;
  port: number;
  dataStore: DataStoreMode;
  authSecret: string;
  accessTokenTtl: string;
  refreshTokenDays: number;
  emailCodeTtlMinutes: number;
  monthlySummaryLimit: number;
  llmBaseUrl: string;
  llmApiKey: string;
  llmModel: string;
  wechatMiniProgramAppId: string;
  wechatMiniProgramAppSecret: string;
};

const defaultLlmKeychainService = 'AIMemo Backend LLM API Key';
const defaultLlmKeychainAccount = 'deepseek';

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  if (env === process.env) {
    loadDotEnvFile(env);
  }
  const nodeEnv = env.NODE_ENV ?? 'development';
  return {
    nodeEnv,
    host: env.HOST ?? (nodeEnv === 'production' ? '0.0.0.0' : '127.0.0.1'),
    port: parseInt(env.PORT ?? '8787', 10),
    dataStore: parseDataStore(env.DATA_STORE, nodeEnv),
    authSecret: env.AUTH_SECRET ?? 'dev-only-change-me',
    accessTokenTtl: env.ACCESS_TOKEN_TTL ?? '30d',
    refreshTokenDays: parseInt(env.REFRESH_TOKEN_DAYS ?? '30', 10),
    emailCodeTtlMinutes: parseInt(env.EMAIL_CODE_TTL_MINUTES ?? '10', 10),
    monthlySummaryLimit: parseInt(env.FREE_MONTHLY_SUMMARY_LIMIT ?? '30', 10),
    llmBaseUrl: env.LLM_BASE_URL ?? 'https://api.deepseek.com',
    llmApiKey: resolveLlmApiKey(env),
    llmModel: env.LLM_MODEL ?? 'deepseek-v4-flash',
    wechatMiniProgramAppId: env.WECHAT_MINI_PROGRAM_APP_ID ?? '',
    wechatMiniProgramAppSecret: env.WECHAT_MINI_PROGRAM_APP_SECRET ?? '',
  };
}

function resolveLlmApiKey(env: NodeJS.ProcessEnv): string {
  const configured = cleanEnvValue(env.LLM_API_KEY);
  if (configured && !isPlaceholderApiKey(configured)) {
    return configured;
  }
  return readMacosKeychainSecret(env);
}

function readMacosKeychainSecret(env: NodeJS.ProcessEnv): string {
  if (
    env.LLM_API_KEY_KEYCHAIN_DISABLED === 'true' ||
    process.platform !== 'darwin'
  ) {
    return '';
  }
  const service =
    cleanEnvValue(env.LLM_API_KEY_KEYCHAIN_SERVICE) ??
    defaultLlmKeychainService;
  const account =
    cleanEnvValue(env.LLM_API_KEY_KEYCHAIN_ACCOUNT) ??
    defaultLlmKeychainAccount;
  try {
    return execFileSync(
      '/usr/bin/security',
      ['find-generic-password', '-s', service, '-a', account, '-w'],
      {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore'],
      },
    ).trim();
  } catch (_) {
    return '';
  }
}

function cleanEnvValue(value: string | undefined): string | null {
  const clean = value?.trim();
  return clean ? clean : null;
}

function isPlaceholderApiKey(value: string): boolean {
  return value === 'replace-with-real-provider-key';
}

function parseDataStore(
  value: string | undefined,
  nodeEnv: string,
): DataStoreMode {
  const normalized = value?.trim().toLowerCase();
  if (!normalized) {
    return nodeEnv === 'production' ? 'prisma' : 'memory';
  }
  if (['memory', 'in-memory', 'in_memory'].includes(normalized)) {
    return 'memory';
  }
  if (['prisma', 'postgres', 'postgresql'].includes(normalized)) {
    return 'prisma';
  }
  throw new Error(`Unsupported DATA_STORE value: ${value}`);
}

function loadDotEnvFile(env: NodeJS.ProcessEnv): void {
  if (!existsSync('.env')) {
    return;
  }
  const lines = readFileSync('.env', 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }
    const match = /^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/.exec(trimmed);
    if (!match) {
      continue;
    }
    const [, key, rawValue] = match;
    if (env[key] !== undefined) {
      continue;
    }
    env[key] = stripQuotes(rawValue.trim());
  }
}

function stripQuotes(value: string): string {
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }
  return value;
}
