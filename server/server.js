import Fastify from 'fastify';
import cors from '@fastify/cors';
import 'dotenv/config';

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

  const apiKey = process.env.LLM_API_KEY;
  const baseUrl = process.env.LLM_BASE_URL ?? 'https://api.openai.com/v1';
  const model = process.env.LLM_MODEL ?? 'gpt-4o-mini';

  if (!apiKey) {
    return reply.code(500).send({ error: 'LLM_API_KEY is not configured' });
  }

  const response = await fetch(`${baseUrl.replace(/\/$/, '')}/chat/completions`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model,
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

function renderPrompt(body) {
  const template = typeof body.template === 'string' ? body.template : '';
  const tasks = typeof body.tasks === 'string' ? body.tasks : '';
  const period = typeof body.period === 'string' ? body.period : '';
  const tags = Array.isArray(body.tags) && body.tags.length > 0
    ? body.tags.join('、')
    : '全部标签';

  return template
    .replaceAll('{tasks}', tasks)
    .replaceAll('{period}', period)
    .replaceAll('{tags}', tags);
}

const port = Number(process.env.PORT ?? 8787);
const host = process.env.HOST ?? '127.0.0.1';

await app.listen({ port, host });
