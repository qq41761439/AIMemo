export type AppConfig = {
  nodeEnv: string;
  port: number;
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

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  return {
    nodeEnv: env.NODE_ENV ?? 'development',
    port: parseInt(env.PORT ?? '8787', 10),
    authSecret: env.AUTH_SECRET ?? 'dev-only-change-me',
    accessTokenTtl: env.ACCESS_TOKEN_TTL ?? '15m',
    refreshTokenDays: parseInt(env.REFRESH_TOKEN_DAYS ?? '30', 10),
    emailCodeTtlMinutes: parseInt(env.EMAIL_CODE_TTL_MINUTES ?? '10', 10),
    monthlySummaryLimit: parseInt(env.FREE_MONTHLY_SUMMARY_LIMIT ?? '30', 10),
    llmBaseUrl: env.LLM_BASE_URL ?? 'https://api.openai.com/v1',
    llmApiKey: env.LLM_API_KEY ?? '',
    llmModel: env.LLM_MODEL ?? 'gpt-4o-mini',
    wechatMiniProgramAppId: env.WECHAT_MINI_PROGRAM_APP_ID ?? '',
    wechatMiniProgramAppSecret: env.WECHAT_MINI_PROGRAM_APP_SECRET ?? '',
  };
}
