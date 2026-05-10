import Fastify from 'fastify';
import cors from '@fastify/cors';
import fs from 'node:fs';
import 'dotenv/config';

import { renderPrompt, resolveLlmConfig } from './llmConfig.js';

const app = Fastify({ logger: true });

await app.register(cors, {
  origin: true,
});

app.get('/health', async () => ({ ok: true }));

app.post('/api/generate-summary', async (request, reply) => {
  const body = request.body ?? {};
  const prompt = typeof body.prompt === 'string'
    ? body.prompt
    : renderPrompt(body);

  if (!prompt.trim()) {
    return reply.code(400).send({ error: 'prompt is required' });
  }

  const llmConfig = resolveLlmConfig({
    body,
    cliProxyConfig: loadCliProxyConfig(),
  });
  if (!llmConfig.ok) {
    return reply.code(llmConfig.statusCode).send({ error: llmConfig.error });
  }

  const response = await fetch(`${llmConfig.baseUrl.replace(/\/$/, '')}/chat/completions`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${llmConfig.apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: llmConfig.model,
      messages: [
        {
          role: 'system',
          content: '你是一个严谨、清晰的个人工作复盘助手。请用中文输出自然、可执行的总结。',
        },
        { role: 'user', content: prompt },
      ],
      temperature: 0.4,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    request.log.error({ status: response.status, text }, 'LLM request failed');
    return reply.code(502).send({ error: 'LLM request failed', detail: text });
  }

  const data = await response.json();
  const summaryText = data?.choices?.[0]?.message?.content;
  if (typeof summaryText !== 'string' || !summaryText.trim()) {
    return reply.code(502).send({ error: 'LLM response is empty' });
  }

  return { summary_text: summaryText.trim() };
});

const port = Number(process.env.PORT ?? 8787);
const host = process.env.HOST ?? '127.0.0.1';

await app.listen({ port, host });

function loadCliProxyConfig() {
  const configPath =
    process.env.CLIPROXYAPI_CONFIG ?? '/opt/homebrew/etc/cliproxyapi.conf';
  if (!fs.existsSync(configPath)) {
    return null;
  }

  const content = fs.readFileSync(configPath, 'utf8');
  const portMatch = content.match(/^port:\s*(\d+)/m);
  const keyMatch = content.match(/api-keys:\s*\n(?:[ \t]+#[^\n]*\n)*[ \t]+-\s*["']?([^"'\s]+)["']?/m);
  if (keyMatch == null) {
    return null;
  }

  const cliProxyPort = portMatch?.[1] ?? '8317';
  return {
    apiKey: keyMatch[1],
    baseUrl: `http://127.0.0.1:${cliProxyPort}/v1`,
  };
}
