import 'package:aimemo/src/app.dart';
import 'package:aimemo/src/models/app_run_mode.dart';
import 'package:aimemo/src/models/model_settings.dart';
import 'package:aimemo/src/providers.dart';
import 'package:aimemo/src/services/app_database.dart';
import 'package:aimemo/src/services/model_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('AIMemo home renders primary panes', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    final apiKeyVault = MemoryApiKeyVault();
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiKeyVaultProvider.overrideWithValue(apiKeyVault),
          appRunModeProvider.overrideWith((ref) async => AppRunMode.local),
        ],
        child: const AIMemoApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('AIMemo'), findsOneWidget);
    expect(find.text('标签'), findsWidgets);
    expect(find.text('添加任务'), findsWidgets);
    expect(find.text('任务内容'), findsOneWidget);
    expect(find.text('标题'), findsNothing);
  });

  testWidgets('AIMemo home uses mobile navigation on narrow screens',
      (tester) async {
    final database = await _pumpApp(
      tester,
      viewSize: const Size(390, 844),
    );

    expect(find.text('任务'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('总结'), findsOneWidget);
    expect(find.text('历史'), findsOneWidget);
    expect(find.text('任务内容'), findsNothing);

    await tester.tap(find.text('记录'));
    await _pumpFrame(tester);

    expect(find.text('添加任务'), findsWidgets);
    expect(find.text('任务内容'), findsOneWidget);

    await database.close();
  });

  testWidgets('startup page lets users choose local mode', (tester) async {
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
    );

    await _pumpApp(
      tester,
      database: database,
      apiKeyVault: apiKeyVault,
      modelSettingsRepository: repository,
      skipStartup: false,
    );
    await _pumpFrame(tester);

    expect(find.text('选择这台设备的使用方式'), findsOneWidget);
    expect(find.text('本地运行'), findsOneWidget);
    expect(find.text('登录同步'), findsOneWidget);

    await tester.tap(find.text('本地运行'));
    await _pumpFrame(tester);

    expect(find.text('添加任务'), findsWidgets);
    expect(find.text('选择这台设备的使用方式'), findsNothing);

    await database.close();
  });

  testWidgets('startup login uses hosted account flow', (tester) async {
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
    );

    await _pumpApp(
      tester,
      database: database,
      apiKeyVault: apiKeyVault,
      modelSettingsRepository: repository,
      skipStartup: false,
    );
    await _pumpFrame(tester);

    await tester.tap(find.text('登录同步'));
    await _pumpFrame(tester);
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.tap(find.text('发送验证码'));
    await _pumpFrame(tester);
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('登录并同步'));
    await _pumpFrame(tester);

    expect(find.text('添加任务'), findsWidgets);
    expect(find.text('登录并同步'), findsNothing);

    await database.close();
  });

  testWidgets('model settings button shows unconfigured state', (tester) async {
    final database = await _pumpApp(
      tester,
      modelSettings: const ModelSettings(
        mode: ModelMode.custom,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
        hasApiKey: false,
        hostedBaseUrl: 'http://127.0.0.1:8787',
        hasHostedSession: false,
      ),
      openSummary: true,
    );

    expect(find.text('未配置'), findsOneWidget);

    await database.close();
  });

  testWidgets('model settings button shows custom model name', (tester) async {
    final database = await _pumpApp(
      tester,
      modelSettings: const ModelSettings(
        mode: ModelMode.custom,
        baseUrl: 'https://example.test/v1',
        model: 'custom-model',
        hasApiKey: true,
        hostedBaseUrl: 'http://127.0.0.1:8787',
        hasHostedSession: false,
      ),
      openSummary: true,
    );

    expect(find.text('custom-model'), findsOneWidget);

    await database.close();
  });

  testWidgets('model settings button shows hosted state', (tester) async {
    final database = await _pumpApp(
      tester,
      modelSettings: const ModelSettings(
        mode: ModelMode.hosted,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
        hasApiKey: false,
        hostedBaseUrl: 'http://127.0.0.1:8787',
        hasHostedSession: true,
      ),
      openSummary: true,
    );

    expect(find.text('官方托管'), findsOneWidget);

    await database.close();
  });

  testWidgets('hosted login shows signed-in settings page', (tester) async {
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
    );

    await _pumpApp(
      tester,
      database: database,
      apiKeyVault: apiKeyVault,
      modelSettingsRepository: repository,
      openSummary: true,
    );

    await tester.tap(find.byIcon(Icons.storage_outlined));
    await _pumpFrame(tester);
    await tester.tap(find.text('使用官方模型'));
    await _pumpFrame(tester);
    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.tap(find.text('发送验证码'));
    await _pumpFrame(tester);
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('登录/注册'));
    await _pumpFrame(tester);

    expect(find.text('官方托管模型已登录'), findsOneWidget);
    expect(find.text('登录/注册'), findsNothing);
    expect(find.widgetWithText(TextField, '验证码'), findsNothing);

    await tester.tap(find.text('完成'));
    await _pumpFrame(tester);

    expect(find.text('官方托管'), findsOneWidget);

    await database.close();
  });
}

Future<void> _pumpFrame(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 10; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _FakeHostedLoginRepository extends ModelSettingsRepository {
  _FakeHostedLoginRepository({
    required super.store,
    required super.apiKeyVault,
  });

  ModelSettings _settings = ModelSettings.defaults();

  @override
  Future<ModelSettings> load() async => _settings;

  @override
  Future<void> startHostedEmailLogin({
    required String hostedBaseUrl,
    required String email,
  }) async {}

  @override
  Future<void> verifyHostedEmailLogin({
    required String hostedBaseUrl,
    required String email,
    required String code,
  }) async {
    _settings = _settings.copyWith(hasHostedSession: true);
  }

  @override
  Future<void> save({
    required ModelMode mode,
    required String baseUrl,
    required String model,
    required String hostedBaseUrl,
    String? apiKey,
  }) async {
    _settings = _settings.copyWith(
      mode: mode,
      baseUrl: baseUrl,
      model: model,
      hostedBaseUrl: hostedBaseUrl,
      hasHostedSession:
          mode == ModelMode.hosted ? true : _settings.hasHostedSession,
    );
  }

  @override
  Future<void> clearHostedSession() async {
    _settings = _settings.copyWith(hasHostedSession: false);
  }

  @override
  Future<AppRunMode?> loadAppRunMode() async => _runMode;

  @override
  Future<void> saveAppRunMode(AppRunMode mode) async {
    _runMode = mode;
  }

  AppRunMode? _runMode;
}

Future<AppDatabase> _pumpApp(
  WidgetTester tester, {
  AppDatabase? database,
  MemoryApiKeyVault? apiKeyVault,
  ModelSettingsRepository? modelSettingsRepository,
  ModelSettings? modelSettings,
  bool openSummary = false,
  bool skipStartup = true,
  Size viewSize = const Size(1200, 800),
}) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final appDatabase =
      database ?? AppDatabase(pathOverride: inMemoryDatabasePath);
  final vault = apiKeyVault ?? MemoryApiKeyVault();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDatabase),
        apiKeyVaultProvider.overrideWithValue(vault),
        if (skipStartup)
          appRunModeProvider.overrideWith((ref) async => AppRunMode.local),
        if (modelSettingsRepository != null)
          modelSettingsRepositoryProvider.overrideWithValue(
            modelSettingsRepository,
          ),
        if (modelSettings != null)
          modelSettingsProvider.overrideWith((ref) async => modelSettings),
      ],
      child: const AIMemoApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  if (openSummary) {
    await tester.tap(find.widgetWithText(Tab, '总结'));
    await tester.pump(const Duration(milliseconds: 300));
    for (var i = 0; i < 10; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  return appDatabase;
}
