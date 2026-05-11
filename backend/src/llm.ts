import type { AppConfig } from './config.js';
import { badRequest, AppError } from './errors.js';

export type GenerateSummaryInput = {
  prompt: string;
};

export type LlmClient = {
  generateSummary(input: GenerateSummaryInput): Promise<string>;
  modelName(): string;
};

export class OpenAiCompatibleClient implements LlmClient {
  constructor(private readonly config: AppConfig) {}

  modelName(): string {
    return this.config.llmModel;
  }

  async generateSummary(input: GenerateSummaryInput): Promise<string> {
    if (!this.config.llmApiKey) {
      throw badRequest(
        'AIMemo 后端尚未配置托管模型，请设置 LLM_API_KEY 后重启后端。',
        'llm_not_configured',
      );
    }
    const uri = `${this.config.llmBaseUrl.replace(/\/+$/, '')}/chat/completions`;
    const response = await fetch(uri, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${this.config.llmApiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: this.config.llmModel,
        messages: [
          {
            role: 'system',
            content: '你是一个严谨、清晰的个人工作复盘助手。请用中文输出自然、可执行的总结。',
          },
          { role: 'user', content: input.prompt },
        ],
        temperature: 0.4,
      }),
    });
    const body = (await response.json().catch(() => null)) as {
      choices?: Array<{ message?: { content?: string } }>;
      error?: { message?: string } | string;
    } | null;
    if (!response.ok) {
      const error =
        typeof body?.error === 'string' ? body.error : body?.error?.message;
      throw new AppError(
        502,
        error ?? '模型服务请求失败。',
        'llm_request_failed',
      );
    }
    const summary = body?.choices?.[0]?.message?.content?.trim();
    if (!summary) {
      throw new AppError(502, '模型服务没有返回有效总结。', 'llm_invalid_response');
    }
    return summary;
  }
}
