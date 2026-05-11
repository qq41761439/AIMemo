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
      period: '今天',
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
      period: '今天',
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
        period: '今天',
        tags: const [],
        tasks: '任务',
        template: '{tasks}',
        prompt: '任务',
      ),
      throwsA(
        isA<SummaryApiException>().having(
          (error) => error.message,
          'message',
          contains('配置 API Key、Base URL 和 Model'),
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
        period: '今天',
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
        period: '今天',
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

  test('explains unavailable hosted model', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        fail('request should not be sent for hosted model');
      }),
    );

    expect(
      () => client.generateSummary(
        period: '今天',
        tags: const [],
        tasks: '任务',
        template: '{tasks}',
        prompt: '任务',
        llmConfig: const {'mode': 'hosted'},
      ),
      throwsA(
        isA<SummaryApiException>().having(
          (error) => error.message,
          'message',
          contains('正式后端'),
        ),
      ),
    );
  });
}
