import 'dart:convert';

import 'package:http/http.dart' as http;

class SummaryApiClient {
  SummaryApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<String> generateSummary({
    required String period,
    required List<String> tags,
    required String tasks,
    required String template,
    required String prompt,
    int? periodDays,
    Map<String, Object?>? llmConfig,
  }) async {
    final config = _resolveConfig(llmConfig);
    final uri = Uri.parse(
      '${config.baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
    );
    final http.Response response;
    try {
      response = await _httpClient.post(
        uri,
        headers: {
          'authorization': 'Bearer ${config.apiKey}',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': config.model,
          'messages': [
            {
              'role': 'system',
              'content': '你是一个严谨、清晰的个人工作复盘助手。请用中文输出自然、可执行的总结。',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.4,
        }),
      );
    } on http.ClientException catch (error) {
      throw SummaryApiException(_networkErrorMessage(error));
    } catch (error) {
      throw SummaryApiException('生成失败：无法请求模型服务。$error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SummaryApiException(_modelErrorMessage(response));
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const SummaryApiException('模型服务返回格式无效。');
    }
    final choices = body['choices'];
    final choice = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = choice is Map<String, dynamic> ? choice['message'] : null;
    final summary = message is Map<String, dynamic> ? message['content'] : null;
    if (summary is! String || summary.trim().isEmpty) {
      throw const SummaryApiException('模型服务没有返回有效总结。');
    }
    return summary.trim();
  }

  _ResolvedLlmConfig _resolveConfig(Map<String, Object?>? llmConfig) {
    if (llmConfig == null) {
      throw const SummaryApiException(
        '生成失败：请先在“模型”里配置 API Key、Base URL 和 Model。',
      );
    }

    if (llmConfig['mode'] == 'hosted') {
      throw const SummaryApiException(
        '生成失败：AIMemo 官方托管模型将通过正式后端提供，目前暂未开放。请先使用自定义模型服务。',
      );
    }

    final apiKey = _cleanConfigValue(llmConfig['api_key']);
    final baseUrl = _cleanConfigValue(llmConfig['base_url']);
    final model = _cleanConfigValue(llmConfig['model']);
    if (apiKey == null || baseUrl == null || model == null) {
      throw const SummaryApiException(
        '生成失败：请先在“模型”里配置 API Key、Base URL 和 Model。',
      );
    }
    return _ResolvedLlmConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
    );
  }

  String? _cleanConfigValue(Object? value) {
    if (value is! String) {
      return null;
    }
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  String _networkErrorMessage(http.ClientException error) {
    final message = error.message;
    if (message.contains('Connection refused') ||
        message.contains('Failed to connect') ||
        message.contains('Connection reset') ||
        message.contains('Connection closed')) {
      return '生成失败：无法连接模型服务。请检查 Base URL 是否正确，或确认网络可以访问该模型服务。';
    }
    if (message.contains('Operation not permitted')) {
      return '生成失败：应用没有网络访问权限，请重新构建并打开 macOS 应用。';
    }
    return '生成失败：无法连接模型服务。$message';
  }

  String _modelErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) {
          return '生成失败：模型服务请求失败。$message';
        }
      }
      if (error is String && error.trim().isNotEmpty) {
        return '生成失败：模型服务请求失败。$error';
      }
    } catch (_) {}
    return '生成失败：模型服务请求失败，状态码 ${response.statusCode}。${response.body}';
  }
}

class _ResolvedLlmConfig {
  const _ResolvedLlmConfig({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  });

  final String apiKey;
  final String baseUrl;
  final String model;
}

class SummaryApiException implements Exception {
  const SummaryApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
