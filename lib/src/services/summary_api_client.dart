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
    int? periodDays,
  }) async {
    final uri = Uri.parse('$baseUrl/api/generate-summary');
    final http.Response response;
    try {
      response = await _httpClient.post(
        uri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'period': period,
          'tags': tags,
          'tasks': tasks,
          'template': template,
          'prompt': prompt,
          if (periodDays != null) 'period_days': periodDays,
        }),
      );
    } on http.ClientException catch (error) {
      throw SummaryApiException(_networkErrorMessage(error));
    } catch (error) {
      throw SummaryApiException('生成失败：无法连接总结代理。$error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SummaryApiException(_serverErrorMessage(response));
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const SummaryApiException('服务端返回格式无效。');
    }
    final summary = body['summary_text'];
    if (summary is! String || summary.trim().isEmpty) {
      throw const SummaryApiException('服务端没有返回有效总结。');
    }
    return summary.trim();
  }

  String _networkErrorMessage(http.ClientException error) {
    final message = error.message;
    if (message.contains('Connection refused') ||
        message.contains('Failed to connect') ||
        message.contains('Connection reset') ||
        message.contains('Connection closed')) {
      return '生成失败：无法连接总结代理。请先在 server 目录运行 npm run dev。';
    }
    if (message.contains('Operation not permitted')) {
      return '生成失败：应用没有网络访问权限，请重新构建并打开 macOS 应用。';
    }
    return '生成失败：无法连接总结代理。$message';
  }

  String _serverErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      final detail = body['detail'];
      if (error == 'LLM_API_KEY is not configured') {
        return '生成失败：总结代理缺少 LLM_API_KEY，请配置 server/.env 后重启 npm run dev。';
      }
      if (error is String && detail is String && detail.trim().isNotEmpty) {
        return '生成失败：$error。$detail';
      }
      if (error is String) {
        return '生成失败：$error';
      }
    } catch (_) {
      // Fall through to the generic status/body message.
    }
    return '生成失败：${response.statusCode} ${response.body}';
  }
}

class SummaryApiException implements Exception {
  const SummaryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
