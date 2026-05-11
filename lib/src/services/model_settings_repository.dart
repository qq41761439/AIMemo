import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/model_settings.dart';
import 'memo_store.dart';

abstract class ApiKeyVault {
  Future<String?> readApiKey();

  Future<void> saveApiKey(String apiKey);

  Future<void> deleteApiKey();
}

class SecureApiKeyVault implements ApiKeyVault {
  const SecureApiKeyVault({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    ),
  }) : _storage = storage;

  static const _apiKeyKey = 'aimemo_llm_api_key';

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
}

class MemoryApiKeyVault implements ApiKeyVault {
  String? _apiKey;

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
}

class ModelSettingsRepository {
  const ModelSettingsRepository({
    required MemoStore store,
    required ApiKeyVault apiKeyVault,
    Duration secureStorageTimeout = const Duration(seconds: 8),
  })  : _store = store,
        _apiKeyVault = apiKeyVault,
        _secureStorageTimeout = secureStorageTimeout;

  static const _modeKey = 'model_mode';
  static const _baseUrlKey = 'model_base_url';
  static const _modelKey = 'model_name';
  static const _hasApiKeyKey = 'model_has_api_key';

  final MemoStore _store;
  final ApiKeyVault _apiKeyVault;
  final Duration _secureStorageTimeout;

  Future<ModelSettings> load() async {
    final defaults = ModelSettings.defaults();
    final hasApiKey = await _store.getAppSetting(_hasApiKeyKey);
    return ModelSettings(
      mode: ModelMode.fromValue(await _store.getAppSetting(_modeKey)),
      baseUrl: (await _store.getAppSetting(_baseUrlKey)) ?? defaults.baseUrl,
      model: (await _store.getAppSetting(_modelKey)) ?? defaults.model,
      hasApiKey: hasApiKey == 'true',
    );
  }

  Future<void> save({
    required ModelMode mode,
    required String baseUrl,
    required String model,
    String? apiKey,
  }) async {
    await _store.saveAppSetting(_modeKey, mode.value);
    await _store.saveAppSetting(_baseUrlKey, baseUrl.trim());
    await _store.saveAppSetting(_modelKey, model.trim());

    final cleanApiKey = apiKey?.trim();
    if (cleanApiKey != null && cleanApiKey.isNotEmpty) {
      await _secureStorageOperation(
        () => _apiKeyVault.saveApiKey(cleanApiKey),
        timeoutMessage: '保存模型密钥超时，请检查 macOS 钥匙串权限后重试。',
      );
      await _store.saveAppSetting(_hasApiKeyKey, 'true');
    }
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
      return const {'mode': 'hosted'};
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

class ModelSettingsException implements Exception {
  const ModelSettingsException(this.message);

  final String message;

  @override
  String toString() => message;
}
