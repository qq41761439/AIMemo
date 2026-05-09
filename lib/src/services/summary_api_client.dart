import 'dart:convert';

import 'package:http/http.dart' as http;

class SummaryApiClient {
  SummaryApiClient({
    this.baseUrl = const String.fromEnvironment(
      'AIMEMO_API_BASE_URL',
      defaultValue: 'http://localhost:8787',
    ),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<String> generateSummary({
    required String period,
    required List<String> tags,
    required String tasks,
    required String template,
    required String prompt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/generate-summary');
    final response = await _httpClient.post(
      uri,
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'period': period,
        'tags': tags,
        'tasks': tasks,
        'template': template,
        'prompt': prompt,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SummaryApiException(
        '生成失败：${response.statusCode} ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final summary = body['summary_text'];
    if (summary is! String || summary.trim().isEmpty) {
      throw const SummaryApiException('服务端没有返回有效总结。');
    }
    return summary.trim();
  }
}

class SummaryApiException implements Exception {
  const SummaryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
