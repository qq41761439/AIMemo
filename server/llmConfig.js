export function resolveLlmConfig({
  body = {},
  env = process.env,
  cliProxyConfig = null,
} = {}) {
  const requestConfig = body.llm_config;
  if (requestConfig != null) {
    return resolveRequestLlmConfig(requestConfig);
  }

  const apiKey = cleanString(env.LLM_API_KEY) ?? cliProxyConfig?.apiKey;
  const baseUrl =
    cleanString(env.LLM_BASE_URL) ??
    cliProxyConfig?.baseUrl ??
    'https://api.openai.com/v1';
  const model =
    cleanString(env.LLM_MODEL) ??
    (cliProxyConfig == null ? 'gpt-4o-mini' : 'gpt-5.4-mini');

  if (!apiKey) {
    return {
      ok: false,
      statusCode: 500,
      error: 'LLM_API_KEY is not configured',
    };
  }

  return {
    ok: true,
    apiKey,
    baseUrl,
    model,
  };
}

export function renderPrompt(body) {
  const template = typeof body.template === 'string' ? body.template : '';
  const tasks = typeof body.tasks === 'string' ? body.tasks : '';
  const period = typeof body.period === 'string' ? body.period : '';
  const periodDays = Number.isFinite(Number(body.period_days))
    ? String(Number(body.period_days))
    : '';
  const tags = Array.isArray(body.tags) && body.tags.length > 0
    ? body.tags.join('、')
    : '全部标签';

  return template
    .replaceAll('{tasks}', tasks)
    .replaceAll('{period}', period)
    .replaceAll('{period_days}', periodDays)
    .replaceAll('{tags}', tags);
}

function resolveRequestLlmConfig(config) {
  if (typeof config !== 'object' || config == null) {
    return {
      ok: false,
      statusCode: 400,
      error: 'LLM config is invalid',
    };
  }

  const mode = cleanString(config.mode);
  if (mode === 'hosted') {
    return {
      ok: false,
      statusCode: 501,
      error: 'HOSTED_LLM_NOT_AVAILABLE',
    };
  }

  if (mode !== 'custom') {
    return {
      ok: false,
      statusCode: 400,
      error: 'LLM config mode is invalid',
    };
  }

  const apiKey = cleanString(config.api_key);
  const baseUrl = cleanString(config.base_url);
  const model = cleanString(config.model);
  if (!apiKey) {
    return {
      ok: false,
      statusCode: 500,
      error: 'LLM_API_KEY is not configured',
    };
  }
  if (!baseUrl || !model) {
    return {
      ok: false,
      statusCode: 400,
      error: 'LLM config is incomplete',
    };
  }

  return {
    ok: true,
    apiKey,
    baseUrl,
    model,
  };
}

function cleanString(value) {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : undefined;
}
