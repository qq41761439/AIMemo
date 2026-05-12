import 'dart:convert';

import 'package:aimemo/src/services/summary_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns generated summary text', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        expect(
            request.url.toString(), 'https://example.test/v1/chat/completions');
        expect(request.headers['authorization'], 'Bearer placeholder-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'custom-model');
        expect(body['temperature'], 0.4);
        final messages = body['messages'] as List<dynamic>;
        expect(messages, hasLength(2));
        expect(messages.last, {'role': 'user', 'content': '最终提示词'});

        return http.Response.bytes(
          utf8.encode(
            '{"choices":[{"message":{"content":"今天完成了核心任务。"}}]}',
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final summary = await client.generateSummary(
      periodType: 'daily',
      period: '今天',
      periodStart: DateTime.utc(2026, 5, 11),
      periodEnd: DateTime.utc(2026, 5, 12),
      tags: const [],
      tasks: '任务',
      template: '{tasks}',
      prompt: '最终提示词',
      periodDays: 1,
      llmConfig: const {
        'mode': 'custom',
        'api_key': 'placeholder-token',
        'base_url': 'https://example.test/v1',
        'model': 'custom-model',
      },
    );

    expect(summary, '今天完成了核心任务。');
  });

  test('trims trailing slash from base URL', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        expect(
            request.url.toString(), 'https://example.test/v1/chat/completions');

        return http.Response.bytes(
          utf8.encode(
            '{"choices":[{"message":{"content":"已使用自定义模型。"}}]}',
          ),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final summary = await client.generateSummary(
      periodType: 'daily',
      period: '今天',
      periodStart: DateTime.utc(2026, 5, 11),
      periodEnd: DateTime.utc(2026, 5, 12),
      tags: const [],
      tasks: '任务',
      template: '{tasks}',
      prompt: '最终提示词',
      llmConfig: const {
        'mode': 'custom',
        'api_key': 'placeholder-token',
        'base_url': 'https://example.test/v1/',
        'model': 'custom-model',
      },
    );

    expect(summary, '已使用自定义模型。');
  });

  test('explains missing custom model config', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        fail('request should not be sent without model config');
      }),
    );

    expect(
      () => client.generateSummary(
        periodType: 'daily',
        period: '今天',
        periodStart: DateTime.utc(2026, 5, 11),
        periodEnd: DateTime.utc(2026, 5, 12),
        tags: const [],
        tasks: '任务',
        template: '{tasks}',
        prompt: '任务',
      ),
      throwsA(
        isA<SummaryApiException>().having(
          (error) => error.message,
          'message',
          contains('配置模型服务或登录'),
        ),
      ),
    );
  });

  test('explains unreachable model service', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        throw http.ClientException('Connection refused', request.url);
      }),
    );

    expect(
      () => client.generateSummary(
        periodType: 'daily',
        period: '今天',
        periodStart: DateTime.utc(2026, 5, 11),
        periodEnd: DateTime.utc(2026, 5, 12),
        tags: const [],
        tasks: '任务',
        template: '{tasks}',
        prompt: '任务',
        llmConfig: const {
          'mode': 'custom',
          'api_key': 'placeholder-token',
          'base_url': 'https://example.test/v1',
          'model': 'custom-model',
        },
      ),
      throwsA(
        isA<SummaryApiException>().having(
          (error) => error.message,
          'message',
          contains('无法连接模型服务'),
        ),
      ),
    );
  });

  test('explains model service error', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        return http.Response(
          '{"error":{"message":"invalid api key"}}',
          401,
        );
      }),
    );

    expect(
      () => client.generateSummary(
        periodType: 'daily',
        period: '今天',
        periodStart: DateTime.utc(2026, 5, 11),
        periodEnd: DateTime.utc(2026, 5, 12),
        tags: const [],
        tasks: '任务',
        template: '{tasks}',
        prompt: '任务',
        llmConfig: const {
          'mode': 'custom',
          'api_key': 'bad-token',
          'base_url': 'https://example.test/v1',
          'model': 'custom-model',
        },
      ),
      throwsA(
        isA<SummaryApiException>().having(
          (error) => error.message,
          'message',
          contains('invalid api key'),
        ),
      ),
    );
  });

  test('returns hosted summary text', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://backend.example.test/summaries/generate',
        );
        expect(request.headers['authorization'], 'Bearer hosted-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['periodType'], 'daily');
        expect(body['periodLabel'], '今天');
        expect(body['periodStart'], '2026-05-11T00:00:00.000Z');
        expect(body['periodEnd'], '2026-05-12T00:00:00.000Z');
        expect(body['tags'], ['工作']);
        expect(body['tasks'], '任务');
        expect(body['prompt'], '任务');

        return http.Response.bytes(
          utf8.encode('{"summary":"已使用官方托管模型。"}'),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final summary = await client.generateSummary(
      periodType: 'daily',
      period: '今天',
      periodStart: DateTime.utc(2026, 5, 11),
      periodEnd: DateTime.utc(2026, 5, 12),
      tags: const ['工作'],
      tasks: '任务',
      template: '{tasks}',
      prompt: '任务',
      llmConfig: const {
        'mode': 'hosted',
        'hosted_base_url': 'https://backend.example.test',
        'access_token': 'hosted-token',
      },
    );

    expect(summary, '已使用官方托管模型。');
  });

  test('refreshes hosted config and retries once after unauthorized', () async {
    final seenTokens = <String>[];
    final client = SummaryApiClient(
      refreshHostedConfig: () async => const {
        'mode': 'hosted',
        'hosted_base_url': 'https://backend.example.test',
        'access_token': 'fresh-token',
      },
      httpClient: MockClient((request) async {
        seenTokens.add(request.headers['authorization'] ?? '');
        if (seenTokens.length == 1) {
          return http.Response.bytes(
            utf8.encode(
              '{"error":{"code":"unauthorized","message":"登录已过期。"}}',
            ),
            401,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response.bytes(
          utf8.encode('{"summary":"刷新后生成成功。"}'),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final summary = await client.generateSummary(
      periodType: 'daily',
      period: '今天',
      periodStart: DateTime.utc(2026, 5, 11),
      periodEnd: DateTime.utc(2026, 5, 12),
      tags: const [],
      tasks: '任务',
      template: '{tasks}',
      prompt: '任务',
      llmConfig: const {
        'mode': 'hosted',
        'hosted_base_url': 'https://backend.example.test',
        'access_token': 'expired-token',
      },
    );

    expect(summary, '刷新后生成成功。');
    expect(seenTokens, ['Bearer expired-token', 'Bearer fresh-token']);
  });

  test('explains hosted backend model config missing', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            '{"error":{"code":"llm_not_configured","message":"AIMemo 后端尚未配置托管模型。"}}',
          ),
          400,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    expect(
      () => client.generateSummary(
        periodType: 'daily',
        period: '今天',
        periodStart: DateTime.utc(2026, 5, 11),
        periodEnd: DateTime.utc(2026, 5, 12),
        tags: const [],
        tasks: '任务',
        template: '{tasks}',
        prompt: '任务',
        llmConfig: const {
          'mode': 'hosted',
          'hosted_base_url': 'https://backend.example.test',
          'access_token': 'hosted-token',
        },
      ),
      throwsA(
        isA<SummaryApiException>().having(
          (error) => error.message,
          'message',
          contains('官方托管模型暂不可用'),
        ),
      ),
    );
  });
}
