import 'package:aimemo/src/app.dart';
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
        ],
        child: const AIMemoApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('AIMemo'), findsOneWidget);
    expect(find.text('标签'), findsWidgets);
    expect(find.text('添加任务'), findsWidgets);
  });

  testWidgets('model settings button shows unconfigured state', (tester) async {
    final database = await _pumpApp(
      tester,
      modelSettings: const ModelSettings(
        mode: ModelMode.custom,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
        hasApiKey: false,
      ),
      openSummary: true,
    );

    expect(find.text('模型：未配置'), findsOneWidget);

    await database.close();
  });

  testWidgets('model settings button shows custom state', (tester) async {
    final database = await _pumpApp(
      tester,
      modelSettings: const ModelSettings(
        mode: ModelMode.custom,
        baseUrl: 'https://example.test/v1',
        model: 'custom-model',
        hasApiKey: true,
      ),
      openSummary: true,
    );

    expect(find.text('模型：自定义'), findsOneWidget);

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
      ),
      openSummary: true,
    );

    expect(find.text('模型：官方托管'), findsOneWidget);

    await database.close();
  });
}

Future<AppDatabase> _pumpApp(
  WidgetTester tester, {
  AppDatabase? database,
  MemoryApiKeyVault? apiKeyVault,
  ModelSettings? modelSettings,
  bool openSummary = false,
}) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  tester.view.physicalSize = const Size(1200, 800);
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
