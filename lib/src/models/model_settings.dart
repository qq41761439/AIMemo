enum ModelMode {
  custom('custom'),
  hosted('hosted');

  const ModelMode(this.value);

  final String value;

  static ModelMode fromValue(String? value) {
    return ModelMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ModelMode.custom,
    );
  }
}

class ModelSettings {
  const ModelSettings({
    required this.mode,
    required this.baseUrl,
    required this.model,
    required this.hasApiKey,
  });

  factory ModelSettings.defaults() {
    return const ModelSettings(
      mode: ModelMode.custom,
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o-mini',
      hasApiKey: false,
    );
  }

  final ModelMode mode;
  final String baseUrl;
  final String model;
  final bool hasApiKey;

  bool get isCustomConfigured {
    return mode == ModelMode.custom &&
        hasApiKey &&
        baseUrl.trim().isNotEmpty &&
        model.trim().isNotEmpty;
  }

  String get statusLabel {
    return switch (mode) {
      ModelMode.hosted => '官方托管',
      ModelMode.custom => isCustomConfigured ? model.trim() : '未配置',
    };
  }

  ModelSettings copyWith({
    ModelMode? mode,
    String? baseUrl,
    String? model,
    bool? hasApiKey,
  }) {
    return ModelSettings(
      mode: mode ?? this.mode,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      hasApiKey: hasApiKey ?? this.hasApiKey,
    );
  }
}
