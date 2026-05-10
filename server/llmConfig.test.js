import assert from 'node:assert/strict';
import test from 'node:test';

import { resolveLlmConfig } from './llmConfig.js';

test('request custom config takes precedence', () => {
  const config = resolveLlmConfig({
    body: {
      llm_config: {
        mode: 'custom',
        api_key: 'request-key',
        base_url: 'https://example.test/v1',
        model: 'custom-model',
      },
    },
    env: {
      LLM_API_KEY: 'env-key',
      LLM_BASE_URL: 'https://env.test/v1',
      LLM_MODEL: 'env-model',
    },
  });

  assert.equal(config.ok, true);
  assert.equal(config.apiKey, 'request-key');
  assert.equal(config.baseUrl, 'https://example.test/v1');
  assert.equal(config.model, 'custom-model');
});

test('falls back to environment config', () => {
  const config = resolveLlmConfig({
    env: {
      LLM_API_KEY: 'env-key',
      LLM_BASE_URL: 'https://env.test/v1',
      LLM_MODEL: 'env-model',
    },
  });

  assert.equal(config.ok, true);
  assert.equal(config.apiKey, 'env-key');
  assert.equal(config.baseUrl, 'https://env.test/v1');
  assert.equal(config.model, 'env-model');
});

test('falls back to CLIProxyAPI config', () => {
  const config = resolveLlmConfig({
    env: {},
    cliProxyConfig: {
      apiKey: 'cli-key',
      baseUrl: 'http://127.0.0.1:8317/v1',
    },
  });

  assert.equal(config.ok, true);
  assert.equal(config.apiKey, 'cli-key');
  assert.equal(config.baseUrl, 'http://127.0.0.1:8317/v1');
  assert.equal(config.model, 'gpt-5.4-mini');
});

test('hosted mode returns a clear unavailable error', () => {
  const config = resolveLlmConfig({
    body: {
      llm_config: {
        mode: 'hosted',
      },
    },
  });

  assert.equal(config.ok, false);
  assert.equal(config.statusCode, 501);
  assert.equal(config.error, 'HOSTED_LLM_NOT_AVAILABLE');
});
