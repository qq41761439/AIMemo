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
    FlutterSecureStorage storage = const FlutterSecureStorage(),
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
  })  : _store = store,
        _apiKeyVault = apiKeyVault;

  static const _modeKey = 'model_mode';
  static const _baseUrlKey = 'model_base_url';
  static const _modelKey = 'model_name';

  final MemoStore _store;
  final ApiKeyVault _apiKeyVault;

  Future<ModelSettings> load() async {
    final defaults = ModelSettings.defaults();
    final apiKey = await _apiKeyVault.readApiKey();
    return ModelSettings(
      mode: ModelMode.fromValue(await _store.getAppSetting(_modeKey)),
      baseUrl: (await _store.getAppSetting(_baseUrlKey)) ?? defaults.baseUrl,
      model: (await _store.getAppSetting(_modelKey)) ?? defaults.model,
      hasApiKey: apiKey?.trim().isNotEmpty == true,
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
      await _apiKeyVault.saveApiKey(cleanApiKey);
    }
  }

  Future<void> clearApiKey() async {
    await _apiKeyVault.deleteApiKey();
  }

  Future<Map<String, Object?>?> requestConfig() async {
    final settings = await load();
    if (settings.mode == ModelMode.hosted) {
      return const {'mode': 'hosted'};
    }

    final apiKey = await _apiKeyVault.readApiKey();
    if (apiKey == null ||
        apiKey.trim().isEmpty ||
        settings.baseUrl.trim().isEmpty ||
        settings.model.trim().isEmpty) {
      return null;
    }

    return {
      'mode': 'custom',
      'api_key': apiKey.trim(),
      'base_url': settings.baseUrl.trim(),
      'model': settings.model.trim(),
    };
  }
}
