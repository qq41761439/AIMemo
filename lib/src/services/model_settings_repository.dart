import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/app_run_mode.dart';
import '../models/model_settings.dart';
import '../models/period_type.dart';
import 'memo_store.dart';
import 'sync_api_client.dart';

abstract class ApiKeyVault {
  Future<String?> readApiKey();

  Future<void> saveApiKey(String apiKey);

  Future<void> deleteApiKey();

  Future<HostedSession?> readHostedSession();

  Future<void> saveHostedSession(HostedSession session);

  Future<void> deleteHostedSession();
}

class SecureApiKeyVault implements ApiKeyVault {
  const SecureApiKeyVault({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    ),
  }) : _storage = storage;

  static const _apiKeyKey = 'aimemo_llm_api_key';
  static const _hostedAccessTokenKey = 'aimemo_hosted_access_token';
  static const _hostedRefreshTokenKey = 'aimemo_hosted_refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readApiKey() async {
    final value = await _storage.read(key: _apiKeyKey);
    return value?.trim().isEmpty == true ? null : value;
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  @override
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }

  @override
  Future<HostedSession?> readHostedSession() async {
    final accessToken = await _storage.read(key: _hostedAccessTokenKey);
    final refreshToken = await _storage.read(key: _hostedRefreshTokenKey);
    if (accessToken == null ||
        accessToken.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty) {
      return null;
    }
    return HostedSession(
      accessToken: accessToken.trim(),
      refreshToken: refreshToken.trim(),
    );
  }

  @override
  Future<void> saveHostedSession(HostedSession session) async {
    await _storage.write(
      key: _hostedAccessTokenKey,
      value: session.accessToken,
    );
    await _storage.write(
      key: _hostedRefreshTokenKey,
      value: session.refreshToken,
    );
  }

  @override
  Future<void> deleteHostedSession() async {
    await _storage.delete(key: _hostedAccessTokenKey);
    await _storage.delete(key: _hostedRefreshTokenKey);
  }
}

class MemoryApiKeyVault implements ApiKeyVault {
  String? _apiKey;
  HostedSession? _hostedSession;

  @override
  Future<String?> readApiKey() async => _apiKey;

  @override
  Future<void> saveApiKey(String apiKey) async {
    _apiKey = apiKey;
  }

  @override
  Future<void> deleteApiKey() async {
    _apiKey = null;
  }

  @override
  Future<HostedSession?> readHostedSession() async => _hostedSession;

  @override
  Future<void> saveHostedSession(HostedSession session) async {
    _hostedSession = session;
  }

  @override
  Future<void> deleteHostedSession() async {
    _hostedSession = null;
  }
}

class ModelSettingsRepository {
  const ModelSettingsRepository({
    required MemoStore store,
    required ApiKeyVault apiKeyVault,
    http.Client? httpClient,
    Duration secureStorageTimeout = const Duration(seconds: 8),
  })  : _store = store,
        _apiKeyVault = apiKeyVault,
        _httpClient = httpClient,
        _secureStorageTimeout = secureStorageTimeout;

  static const _modeKey = 'model_mode';
  static const _baseUrlKey = 'model_base_url';
  static const _modelKey = 'model_name';
  static const _hasApiKeyKey = 'model_has_api_key';
  static const _hostedBaseUrlKey = 'hosted_base_url';
  static const _hasHostedSessionKey = 'hosted_has_session';
  static const _appRunModeKey = 'app_run_mode';

  final MemoStore _store;
  final ApiKeyVault _apiKeyVault;
  final http.Client? _httpClient;
  final Duration _secureStorageTimeout;

  Future<ModelSettings> load() async {
    final defaults = ModelSettings.defaults();
    final hasApiKey = await _store.getAppSetting(_hasApiKeyKey);
    return ModelSettings(
      mode: ModelMode.fromValue(await _store.getAppSetting(_modeKey)),
      baseUrl: (await _store.getAppSetting(_baseUrlKey)) ?? defaults.baseUrl,
      model: (await _store.getAppSetting(_modelKey)) ?? defaults.model,
      hasApiKey: hasApiKey == 'true',
      hostedBaseUrl: (await _store.getAppSetting(_hostedBaseUrlKey)) ??
          defaults.hostedBaseUrl,
      hasHostedSession:
          await _store.getAppSetting(_hasHostedSessionKey) == 'true',
    );
  }

  Future<AppRunMode?> loadAppRunMode() async {
    return AppRunMode.fromValue(await _store.getAppSetting(_appRunModeKey));
  }

  Future<void> saveAppRunMode(AppRunMode mode) async {
    await _store.saveAppSetting(_appRunModeKey, mode.value);
  }

  Future<SyncConfig?> loadSyncConfig() async {
    final settings = await load();
    final baseUrl = settings.hostedBaseUrl.trim();
    if (!settings.hasHostedSession || baseUrl.isEmpty) {
      return null;
    }
    final session = await _readHostedSession();
    if (session == null || session.accessToken.trim().isEmpty) {
      await _store.saveAppSetting(_hasHostedSessionKey, 'false');
      return null;
    }
    return SyncConfig(
      baseUrl: baseUrl,
      accessToken: session.accessToken.trim(),
    );
  }

  Future<SyncConfig?> refreshSyncConfig() async {
    final settings = await load();
    final baseUrl = settings.hostedBaseUrl.trim();
    if (baseUrl.isEmpty) {
      await _store.saveAppSetting(_hasHostedSessionKey, 'false');
      return null;
    }
    final session = await _refreshHostedSession(baseUrl);
    if (session == null) {
      return null;
    }
    return SyncConfig(
      baseUrl: baseUrl,
      accessToken: session.accessToken.trim(),
    );
  }

  Future<void> save({
    required ModelMode mode,
    required String baseUrl,
    required String model,
    required String hostedBaseUrl,
    String? apiKey,
  }) async {
    await _store.saveAppSetting(_modeKey, mode.value);
    await _store.saveAppSetting(_baseUrlKey, baseUrl.trim());
    await _store.saveAppSetting(_modelKey, model.trim());
    await _store.saveAppSetting(_hostedBaseUrlKey, hostedBaseUrl.trim());

    final cleanApiKey = apiKey?.trim();
    if (cleanApiKey != null && cleanApiKey.isNotEmpty) {
      await _secureStorageOperation(
        () => _apiKeyVault.saveApiKey(cleanApiKey),
        timeoutMessage: '保存模型密钥超时，请检查 macOS 钥匙串权限后重试。',
      );
      await _store.saveAppSetting(_hasApiKeyKey, 'true');
    }
  }

  Future<void> startHostedEmailLogin({
    required String hostedBaseUrl,
    required String email,
  }) async {
    final baseUrl = hostedBaseUrl.trim();
    final cleanEmail = email.trim();
    if (baseUrl.isEmpty) {
      throw const ModelSettingsException('官方模型服务地址未配置。');
    }
    if (cleanEmail.isEmpty) {
      throw const ModelSettingsException('请先填写邮箱。');
    }
    await _postHostedJson(
      hostedBaseUrl: baseUrl,
      path: '/auth/email/start',
      body: {'email': cleanEmail},
    );
    await _store.saveAppSetting(_hostedBaseUrlKey, baseUrl);
  }

  Future<void> verifyHostedEmailLogin({
    required String hostedBaseUrl,
    required String email,
    required String code,
  }) async {
    final baseUrl = hostedBaseUrl.trim();
    final cleanEmail = email.trim();
    final cleanCode = code.trim();
    if (baseUrl.isEmpty) {
      throw const ModelSettingsException('官方模型服务地址未配置。');
    }
    if (cleanEmail.isEmpty || cleanCode.isEmpty) {
      throw const ModelSettingsException('请填写邮箱和验证码。');
    }
    final body = await _postHostedJson(
      hostedBaseUrl: baseUrl,
      path: '/auth/email/verify',
      body: {'email': cleanEmail, 'code': cleanCode},
    );
    final accessToken = body['accessToken'];
    final refreshToken = body['refreshToken'];
    if (accessToken is! String ||
        accessToken.trim().isEmpty ||
        refreshToken is! String ||
        refreshToken.trim().isEmpty) {
      throw const ModelSettingsException('登录失败：后端返回格式无效。');
    }
    await _secureStorageOperation(
      () => _apiKeyVault.saveHostedSession(
        HostedSession(
          accessToken: accessToken.trim(),
          refreshToken: refreshToken.trim(),
        ),
      ),
      timeoutMessage: '保存登录状态超时，请检查 macOS 钥匙串权限后重试。',
    );
    await _store.saveAppSetting(_hostedBaseUrlKey, baseUrl);
    await _store.saveAppSetting(_hasHostedSessionKey, 'true');
  }

  Future<void> clearHostedSession() async {
    await _secureStorageOperation(
      () => _apiKeyVault.deleteHostedSession(),
      timeoutMessage: '清除登录状态超时，请检查 macOS 钥匙串权限后重试。',
    );
    await _store.saveAppSetting(_hasHostedSessionKey, 'false');
  }

  Future<void> clearApiKey() async {
    await _secureStorageOperation(
      () => _apiKeyVault.deleteApiKey(),
      timeoutMessage: '清除模型密钥超时，请检查 macOS 钥匙串权限后重试。',
    );
    await _store.saveAppSetting(_hasApiKeyKey, 'false');
  }

  Future<Map<String, Object?>?> requestConfig() async {
    final settings = await load();
    if (settings.mode == ModelMode.hosted) {
      return requestHostedConfig();
    }

    final apiKey = await _secureStorageOperation(
      () => _apiKeyVault.readApiKey(),
      timeoutMessage: '读取模型密钥超时，请检查 macOS 钥匙串权限后重试。',
    );
    if (apiKey == null ||
        apiKey.trim().isEmpty ||
        settings.baseUrl.trim().isEmpty ||
        settings.model.trim().isEmpty) {
      await _store.saveAppSetting(_hasApiKeyKey, 'false');
      return null;
    }
    if (!settings.hasApiKey) {
      await _store.saveAppSetting(_hasApiKeyKey, 'true');
    }

    return {
      'mode': 'custom',
      'api_key': apiKey.trim(),
      'base_url': settings.baseUrl.trim(),
      'model': settings.model.trim(),
    };
  }

  Future<Map<String, Object?>?> requestHostedConfig() async {
    final settings = await load();
    final hostedSession = await _readHostedSession();
    if (hostedSession == null ||
        hostedSession.accessToken.trim().isEmpty ||
        settings.hostedBaseUrl.trim().isEmpty) {
      await _store.saveAppSetting(_hasHostedSessionKey, 'false');
      return null;
    }
    if (!settings.hasHostedSession) {
      await _store.saveAppSetting(_hasHostedSessionKey, 'true');
    }
    return {
      'mode': 'hosted',
      'hosted_base_url': settings.hostedBaseUrl.trim(),
      'access_token': hostedSession.accessToken.trim(),
    };
  }

  Future<Map<String, Object?>?> refreshHostedConfig() async {
    final settings = await load();
    if (settings.hostedBaseUrl.trim().isEmpty) {
      await _store.saveAppSetting(_hasHostedSessionKey, 'false');
      return null;
    }
    final session = await _refreshHostedSession(settings.hostedBaseUrl);
    if (session == null) {
      return null;
    }
    return {
      'mode': 'hosted',
      'hosted_base_url': settings.hostedBaseUrl.trim(),
      'access_token': session.accessToken.trim(),
    };
  }

  Future<HostedQuota?> loadHostedQuota() async {
    final body = await _getAuthorizedHostedJson(path: '/me/quota');
    return HostedQuota.fromJson(body);
  }

  Future<List<HostedSummaryRecord>> listHostedSummaries({
    int limit = 50,
  }) async {
    final body = await _getAuthorizedHostedJson(
      path: '/summaries',
      queryParameters: {'limit': limit.toString()},
    );
    final items = body['items'];
    if (items is! List) {
      throw const ModelSettingsException('AIMemo 后端返回格式无效。');
    }
    return items
        .map((item) => HostedSummaryRecord.fromJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<Map<String, dynamic>> _getAuthorizedHostedJson({
    required String path,
    Map<String, String>? queryParameters,
  }) async {
    return _authorizedHostedJson(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _authorizedHostedJson({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, Object?>? body,
    bool allowRefresh = true,
  }) async {
    final settings = await load();
    final baseUrl = settings.hostedBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw const ModelSettingsException('官方模型服务地址未配置。');
    }

    final session = await _readHostedSession();
    if (session == null) {
      await _store.saveAppSetting(_hasHostedSessionKey, 'false');
      throw const ModelSettingsException('请先登录 AIMemo 官方托管模型。');
    }

    final response = await _requestHostedJsonResponse(
      method: method,
      hostedBaseUrl: baseUrl,
      path: path,
      queryParameters: queryParameters,
      headers: {'authorization': 'Bearer ${session.accessToken.trim()}'},
      body: body,
    );

    if (response.statusCode == 401 && allowRefresh) {
      final refreshed = await _refreshHostedSession(baseUrl);
      if (refreshed == null) {
        throw ModelSettingsException(_hostedErrorMessage(response));
      }
      return _authorizedHostedJson(
        method: method,
        path: path,
        queryParameters: queryParameters,
        body: body,
        allowRefresh: false,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ModelSettingsException(_hostedErrorMessage(response));
    }
    return _decodeHostedJson(response);
  }

  Future<HostedSession?> _readHostedSession() {
    return _secureStorageOperation(
      () => _apiKeyVault.readHostedSession(),
      timeoutMessage: '读取登录状态超时，请检查 macOS 钥匙串权限后重试。',
    );
  }

  Future<HostedSession?> _refreshHostedSession(String hostedBaseUrl) async {
    final session = await _readHostedSession();
    final refreshToken = session?.refreshToken.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _store.saveAppSetting(_hasHostedSessionKey, 'false');
      return null;
    }

    final response = await _requestHostedJsonResponse(
      method: 'POST',
      hostedBaseUrl: hostedBaseUrl,
      path: '/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await clearHostedSession();
      throw ModelSettingsException(_hostedErrorMessage(response));
    }

    final body = _decodeHostedJson(response);
    final accessToken = body['accessToken'];
    final nextRefreshToken = body['refreshToken'];
    if (accessToken is! String ||
        accessToken.trim().isEmpty ||
        nextRefreshToken is! String ||
        nextRefreshToken.trim().isEmpty) {
      throw const ModelSettingsException('刷新登录状态失败：后端返回格式无效。');
    }

    final refreshed = HostedSession(
      accessToken: accessToken.trim(),
      refreshToken: nextRefreshToken.trim(),
    );
    await _secureStorageOperation(
      () => _apiKeyVault.saveHostedSession(refreshed),
      timeoutMessage: '保存登录状态超时，请检查 macOS 钥匙串权限后重试。',
    );
    await _store.saveAppSetting(_hasHostedSessionKey, 'true');
    return refreshed;
  }

  Future<Map<String, dynamic>> _postHostedJson({
    required String hostedBaseUrl,
    required String path,
    required Map<String, Object?> body,
  }) async {
    final response = await _requestHostedJsonResponse(
      method: 'POST',
      hostedBaseUrl: hostedBaseUrl,
      path: path,
      body: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ModelSettingsException(_hostedErrorMessage(response));
    }
    return _decodeHostedJson(response);
  }

  Future<http.Response> _requestHostedJsonResponse({
    required String method,
    required String hostedBaseUrl,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    Map<String, Object?>? body,
  }) async {
    final client = _httpClient ?? http.Client();
    var uri = Uri.parse(
      '${hostedBaseUrl.replaceAll(RegExp(r'/+$'), '')}$path',
    );
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final requestHeaders = {
      'content-type': 'application/json',
      ...?headers,
    };
    final http.Response response;
    try {
      response = switch (method) {
        'GET' => await client.get(uri, headers: requestHeaders),
        'POST' => await client.post(
            uri,
            headers: requestHeaders,
            body: jsonEncode(body ?? const <String, Object?>{}),
          ),
        _ => throw const ModelSettingsException('不支持的 AIMemo 后端请求方法。'),
      };
    } on http.ClientException catch (error) {
      throw ModelSettingsException('无法连接 AIMemo 后端。${error.message}');
    } on ModelSettingsException {
      rethrow;
    } catch (error) {
      throw ModelSettingsException('无法请求 AIMemo 后端。$error');
    }
    return response;
  }

  Map<String, dynamic> _decodeHostedJson(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ModelSettingsException('AIMemo 后端返回格式无效。');
    }
  }

  String _hostedErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}
    return 'AIMemo 后端请求失败，状态码 ${response.statusCode}。';
  }

  Future<T> _secureStorageOperation<T>(
    Future<T> Function() operation, {
    required String timeoutMessage,
  }) async {
    try {
      return await operation().timeout(
        _secureStorageTimeout,
        onTimeout: () => throw ModelSettingsException(timeoutMessage),
      );
    } on ModelSettingsException {
      rethrow;
    } on TimeoutException {
      throw ModelSettingsException(timeoutMessage);
    } catch (error) {
      throw ModelSettingsException('模型密钥存储失败：$error');
    }
  }
}

class HostedSession {
  const HostedSession({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class HostedQuota {
  const HostedQuota({
    required this.period,
    required this.limit,
    required this.used,
    required this.remaining,
  });

  final String period;
  final int limit;
  final int used;
  final int remaining;

  factory HostedQuota.fromJson(Map<String, dynamic> json) {
    return HostedQuota(
      period: json['period'] as String,
      limit: json['limit'] as int,
      used: json['used'] as int,
      remaining: json['remaining'] as int,
    );
  }
}

class HostedSummaryRecord {
  const HostedSummaryRecord({
    required this.id,
    required this.periodType,
    required this.periodLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.tags,
    required this.output,
    required this.model,
    required this.createdAt,
  });

  final String id;
  final PeriodType periodType;
  final String periodLabel;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<String> tags;
  final String output;
  final String model;
  final DateTime createdAt;

  factory HostedSummaryRecord.fromJson(Map<String, dynamic> json) {
    return HostedSummaryRecord(
      id: json['id'] as String,
      periodType: PeriodType.fromValue(json['periodType'] as String),
      periodLabel: json['periodLabel'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String).toLocal(),
      periodEnd: DateTime.parse(json['periodEnd'] as String).toLocal(),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      output: json['output'] as String,
      model: json['model'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

class ModelSettingsException implements Exception {
  const ModelSettingsException(this.message);

  final String message;

  @override
  String toString() => message;
}
