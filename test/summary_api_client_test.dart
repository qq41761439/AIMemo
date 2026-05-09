import 'dart:convert';

import 'package:aimemo/src/services/summary_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('returns generated summary text', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['prompt'], '最终提示词');
        expect(body['template'], '{tasks}');
        expect(body['tasks'], '任务');
        expect(body['period'], '今天');
        expect(body['tags'], isEmpty);

        return http.Response.bytes(
          utf8.encode('{"summary_text":"今天完成了核心任务。"}'),
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
    );

    expect(summary, '今天完成了核心任务。');
  });

  test('explains missing proxy service', () async {
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
      ),
      throwsA(
        isA<SummaryApiException>().having(
          (error) => error.message,
          'message',
          contains('请先在 server 目录运行 npm run dev'),
        ),
      ),
    );
  });

  test('explains missing LLM API key', () async {
    final client = SummaryApiClient(
      httpClient: MockClient((request) async {
        return http.Response('{"error":"LLM_API_KEY is not configured"}', 500);
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
          contains('请配置 server/.env'),
        ),
      ),
    );
  });
}
