import 'dart:convert';

import 'package:aimemo/src/app.dart';
import 'package:aimemo/src/models/app_run_mode.dart';
import 'package:aimemo/src/models/model_settings.dart';
import 'package:aimemo/src/models/period_type.dart';
import 'package:aimemo/src/mobile/mobile_components.dart';
import 'package:aimemo/src/providers.dart';
import 'package:aimemo/src/services/app_database.dart';
import 'package:aimemo/src/services/in_memory_memo_store.dart';
import 'package:aimemo/src/services/memo_store.dart';
import 'package:aimemo/src/services/model_settings_repository.dart';
import 'package:aimemo/src/services/summary_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  testWidgets('Flutter mobile shell opens auth and tasks flow', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = InMemoryMemoStore();
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiKeyVaultProvider.overrideWithValue(apiKeyVault),
          modelSettingsRepositoryProvider.overrideWithValue(repository),
          appRunModeProvider.overrideWith((ref) async => AppRunMode.local),
        ],
        child: const AIMemoApp(forceMobileShell: true),
      ),
    );
    await _pumpFrame(tester);

    expect(find.text('Organize tasks into clear progress'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.widgetWithText(GradientButton, 'Send code'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Verification code'),
      '123456',
    );
    await tester.tap(find.text('Log in'));
    await _pumpFrame(tester);

    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Summary'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, 'Quick add a task...'),
      'Mobile shell task',
    );
    await tester.tap(find.byIcon(Icons.send_rounded));
    await _pumpFrame(tester);

    expect(find.text('Mobile shell task'), findsOneWidget);
  });

  testWidgets('Flutter mobile task sections collapse when tapped',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = InMemoryMemoStore();
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiKeyVaultProvider.overrideWithValue(apiKeyVault),
          modelSettingsRepositoryProvider.overrideWithValue(repository),
          appRunModeProvider.overrideWith((ref) async => AppRunMode.local),
        ],
        child: const AIMemoApp(forceMobileShell: true),
      ),
    );
    await _pumpFrame(tester);

    await tester.tap(find.text('Skip'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.widgetWithText(GradientButton, 'Send code'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Verification code'),
      '123456',
    );
    await tester.tap(find.text('Log in'));
    await _pumpFrame(tester);
    final taskId = await database.addTask(
      title: 'Collapsible active task',
      content: '',
      tags: const ['Product'],
    );
    ProviderScope.containerOf(tester.element(find.byType(AIMemoApp)))
        .invalidate(taskListProvider);
    await _pumpFrame(tester);

    expect(find.text('Collapsible active task'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.byKey(ValueKey('mobile-task-$taskId-tag-Product')),
          )
          .dx,
      lessThan(tester.getTopLeft(find.text('Collapsible active task')).dx),
    );
    expect(find.textContaining('Already started'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Upcoming')).dy,
      lessThan(tester.getTopLeft(find.text('Active')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Active')).dy,
      lessThan(tester.getTopLeft(find.text('Completed')).dy),
    );
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNWidgets(2));

    final activeHeader = find.byKey(
      const ValueKey('task-section-Active-header'),
    );
    expect(activeHeader, findsOneWidget);
    await tester.tap(activeHeader);
    await tester.pump();

    expect(find.text('Collapsible active task'), findsNothing);

    await tester.tap(activeHeader);
    await tester.pump();

    expect(find.text('Collapsible active task'), findsOneWidget);
  });

  testWidgets('Flutter mobile summary uses hosted backend API', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = InMemoryMemoStore();
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
    );
    addTearDown(database.close);

    Uri? requestedUri;
    Map<String, Object?>? requestBody;
    final summaryClient = SummaryApiClient(
      httpClient: MockClient((request) async {
        requestedUri = request.url;
        requestBody = jsonDecode(request.body) as Map<String, Object?>;
        expect(request.headers['authorization'], 'Bearer hosted-token');
        return http.Response(
          jsonEncode({'summary': 'LLM mobile report'}),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiKeyVaultProvider.overrideWithValue(apiKeyVault),
          modelSettingsRepositoryProvider.overrideWithValue(repository),
          summaryApiClientProvider.overrideWithValue(summaryClient),
          appRunModeProvider.overrideWith((ref) async => AppRunMode.local),
        ],
        child: const AIMemoApp(forceMobileShell: true),
      ),
    );
    await _pumpFrame(tester);

    await tester.tap(find.text('Skip'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.widgetWithText(GradientButton, 'Send code'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Verification code'),
      '123456',
    );
    await tester.tap(find.text('Log in'));
    await _pumpFrame(tester);
    await database.addTask(
      title: 'Prepare investor update',
      content: 'Summarize completed product milestones.',
      tags: const ['Product'],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    ProviderScope.containerOf(tester.element(find.byType(AIMemoApp)))
        .invalidate(taskListProvider);
    await _pumpFrame(tester);
    await tester.tap(find.text('Summary').first);
    await _pumpFrame(tester);
    await tester.tap(find.text('Generate Summary').last);
    await _pumpFrame(tester);
    await tester.tap(find.text('Generate Summary').last);
    await _pumpFrame(tester);

    expect(
      requestedUri,
      Uri.parse('http://127.0.0.1:8787/summaries/generate'),
    );
    expect(
      requestBody?['prompt'].toString(),
      contains('Prepare investor update'),
    );
    expect(find.text('LLM mobile report'), findsOneWidget);
  });

  testWidgets('Flutter mobile shell keeps top spacing compact on short phones',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tester.view.physicalSize = const Size(390, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          appRunModeProvider.overrideWith((ref) async => AppRunMode.local),
        ],
        child: const AIMemoApp(forceMobileShell: true),
      ),
    );
    await _pumpFrame(tester);

    expect(
      tester.getTopLeft(find.text('Organize tasks into clear progress')).dy,
      lessThan(250),
    );

    await tester.tap(find.text('Skip'));
    await _pumpFrame(tester);
    expect(tester.getTopLeft(find.text('AIMemo')).dy, lessThan(130));
  });

  testWidgets('Flutter mobile baseline screen uses compact type hierarchy',
      (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = InMemoryMemoStore();
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
    );
    addTearDown(database.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          apiKeyVaultProvider.overrideWithValue(apiKeyVault),
          modelSettingsRepositoryProvider.overrideWithValue(repository),
          appRunModeProvider.overrideWith((ref) async => AppRunMode.local),
        ],
        child: const AIMemoApp(forceMobileShell: true),
      ),
    );
    await _pumpFrame(tester);

    await tester.tap(find.text('Skip'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.tap(find.widgetWithText(GradientButton, 'Send code'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, 'Verification code'),
      '123456',
    );
    await tester.tap(find.text('Log in'));
    await _pumpFrame(tester);

    final tabStyles = tester
        .widgetList<Text>(find.text('Tasks'))
        .map((text) => text.style)
        .whereType<TextStyle>()
        .toList();
    expect(tabStyles, isNotEmpty);
    expect(tabStyles.any((style) => style.fontSize == 15), isTrue);
    expect(
      tabStyles.where((style) => style.fontSize != null),
      everyElement(
        predicate<TextStyle>((style) => style.fontSize! < 20),
      ),
    );

    final activeTitle = tester.widget<Text>(find.text('Active'));
    expect(activeTitle.style?.fontSize, 15);
    expect(tester.getTopLeft(find.text('All')).dy, lessThan(125));
    expect(tester.getTopLeft(find.text('Upcoming')).dy, lessThan(170));
    expect(
      tester.getTopLeft(find.text('Upcoming')).dy,
      lessThan(tester.getTopLeft(find.text('Active')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Active')).dy,
      lessThan(tester.getTopLeft(find.text('Completed')).dy),
    );
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('mobile task list hides empty tag prompt when no tags exist',
      (tester) async {
    final database = await _pumpApp(
      tester,
      viewSize: const Size(320, 568),
    );

    await _pumpFrame(tester);

    expect(find.text('添加任务后会出现标签。'), findsNothing);
    expect(tester.takeException(), isNull);

    await database.close();
  });

  testWidgets('task tag filter uses outlined selection without checkmark',
      (tester) async {
    final database = InMemoryMemoStore();
    await database.addTask(
      title: '整理标签样式',
      content: '',
      tags: const ['界面'],
    );

    await _pumpApp(tester, database: database);
    await _pumpFrame(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AIMemoApp)),
    );
    container
      ..invalidate(taskListProvider)
      ..invalidate(tagListProvider)
      ..read(taskTagFilterProvider.notifier).state = {'界面'};
    await _pumpFrame(tester);

    final selectedChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, '界面'),
    );
    expect(selectedChip.selected, isTrue);
    expect(selectedChip.showCheckmark, isFalse);
    expect(selectedChip.avatar, isNull);

    await database.close();
  });

  testWidgets('mobile task tag filter uses a single-row horizontal scroller',
      (tester) async {
    final database = InMemoryMemoStore();
    await database.addTask(
      title: '手机筛选标签任务',
      content: '',
      tags: const ['移动一', '移动二', '移动三', '移动四', '移动五', '移动六'],
    );

    await _pumpApp(
      tester,
      database: database,
      viewSize: const Size(390, 844),
    );
    await _pumpFrame(tester);

    final scrollerFinder =
        find.byKey(const ValueKey('mobile-task-tag-filter-scroll'));
    expect(scrollerFinder, findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-task-tag-filter-wrap')),
        findsNothing);
    expect(tester.getSize(scrollerFinder).height, lessThanOrEqualTo(34));

    final scrollView = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: scrollerFinder,
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(scrollView.scrollDirection, Axis.horizontal);

    await tester.drag(scrollerFinder, const Offset(-220, 0));
    await tester.pump();
    expect(find.text('移动六'), findsOneWidget);

    await database.close();
  });

  testWidgets('desktop task tag filter keeps wrapping layout', (tester) async {
    final database = InMemoryMemoStore();
    await database.addTask(
      title: '桌面筛选标签任务',
      content: '',
      tags: const ['桌面一', '桌面二', '桌面三'],
    );

    await _pumpApp(
      tester,
      database: database,
      viewSize: const Size(1200, 800),
    );
    await _pumpFrame(tester);

    expect(find.byKey(const ValueKey('desktop-task-tag-filter-wrap')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-task-tag-filter-scroll')),
      findsNothing,
    );

    await database.close();
  });

  testWidgets('mobile task tile condenses extra tags behind a count',
      (tester) async {
    final database = InMemoryMemoStore();
    final taskId = await database.addTask(
      title: '多标签手机任务',
      content: '',
      tags: const ['前一', '前二', '第三', '第四', '第五'],
    );

    await _pumpApp(
      tester,
      database: database,
      viewSize: const Size(390, 844),
    );
    await _pumpFrame(tester);

    expect(find.byKey(ValueKey('task-$taskId-tag-前一')), findsOneWidget);
    expect(find.byKey(ValueKey('task-$taskId-tag-前二')), findsOneWidget);
    expect(find.byKey(ValueKey('task-$taskId-tag-第三')), findsNothing);
    expect(find.byKey(ValueKey('task-$taskId-tag-overflow')), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);

    await database.close();
  });

  testWidgets('mobile task form suggestions scroll horizontally and append tag',
      (tester) async {
    final database = InMemoryMemoStore();
    await database.addTask(
      title: '候选标签来源',
      content: '',
      tags: const ['候选甲', '候选乙', '候选丙', '候选丁', '候选戊'],
    );

    await _pumpApp(
      tester,
      database: database,
      viewSize: const Size(390, 844),
    );
    await tester.tap(find.text('记录'));
    await _pumpFrame(tester);

    final scrollerFinder =
        find.byKey(const ValueKey('mobile-task-form-tag-scroll'));
    expect(scrollerFinder, findsOneWidget);
    expect(
        find.byKey(const ValueKey('desktop-task-form-tag-wrap')), findsNothing);
    final scrollView = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: scrollerFinder,
        matching: find.byType(SingleChildScrollView),
      ),
    );
    expect(scrollView.scrollDirection, Axis.horizontal);

    final scrollable = find.descendant(
      of: scrollerFinder,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(ActionChip, '候选丙'),
      120,
      scrollable: scrollable,
    );
    await tester.tap(find.widgetWithText(ActionChip, '候选丙'));
    await tester.pump();

    final tagField = tester.widget<TextField>(
      find.widgetWithText(TextField, '标签'),
    );
    expect(tagField.controller?.text, contains('候选丙'));

    await database.close();
  });

  testWidgets('task pull-to-refresh reloads task data', (tester) async {
    final database = InMemoryMemoStore();

    await _pumpApp(tester, database: database);
    await _pumpFrame(tester);

    expect(find.text('下拉同步任务'), findsNothing);

    await database.addTask(
      title: '下拉同步任务',
      content: '',
      tags: const ['同步'],
    );
    final refresh = tester.widget<RefreshIndicator>(
      find.byKey(const ValueKey('task-list-refresh')),
    );

    await refresh.onRefresh();
    await _pumpFrame(tester);

    expect(find.text('下拉同步任务'), findsOneWidget);

    await database.close();
  });

  testWidgets('task tap opens edit form directly', (tester) async {
    final database = InMemoryMemoStore();
    await database.addTask(
      title: '直接编辑任务',
      content: '不经过查看页',
      tags: const ['界面'],
    );

    await _pumpApp(tester, database: database);
    await _pumpFrame(tester);

    await tester.tap(find.text('直接编辑任务'));
    await _pumpFrame(tester);

    expect(find.text('编辑任务'), findsOneWidget);
    expect(find.text('保存修改'), findsOneWidget);
    expect(find.text('查看任务'), findsNothing);
    expect(find.text('查看当前任务的完整内容。'), findsNothing);

    await database.close();
  });

  testWidgets('saving task edits keeps edit form open', (tester) async {
    final database = InMemoryMemoStore();
    await database.addTask(
      title: '继续编辑任务',
      content: '保存后停留',
      tags: const ['界面'],
    );

    await _pumpApp(tester, database: database);
    await _pumpFrame(tester);

    await tester.tap(find.text('继续编辑任务'));
    await _pumpFrame(tester);
    await tester.enterText(
      find.widgetWithText(TextField, '任务内容'),
      '继续编辑任务\n保存后仍然停留',
    );
    await tester.tap(find.text('保存修改'));
    await _pumpFrame(tester);

    expect(find.text('编辑任务'), findsOneWidget);
    expect(find.text('保存修改'), findsOneWidget);
    expect(find.text('添加任务'), findsNothing);
    expect(find.widgetWithText(TextField, '任务内容'), findsOneWidget);

    await database.close();
  });

  testWidgets('mobile add task form keeps fields focusable on short screens',
      (tester) async {
    final database = await _pumpApp(
      tester,
      viewSize: const Size(390, 430),
    );

    await tester.tap(find.text('记录'));
    await _pumpFrame(tester);

    await tester.tap(find.widgetWithText(TextField, '任务内容'));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'task body input');

    await tester.tap(find.widgetWithText(TextField, '标签'));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'task tags input');

    await tester.tapAt(const Offset(24, 24));
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel,
        isNot('task tags input'));

    expect(tester.takeException(), isNull);

    await database.close();
  });

  testWidgets('history pull-to-refresh reloads summary data', (tester) async {
    final database = InMemoryMemoStore();

    await _pumpApp(tester, database: database);
    await tester.tap(find.widgetWithText(Tab, '历史'));
    await _pumpFrame(tester);

    expect(find.text('日报 · refresh-2026-05-12'), findsNothing);

    await database.insertSummary(
      periodType: PeriodType.daily,
      periodLabel: 'refresh-2026-05-12',
      periodStart: DateTime(2026, 5, 12),
      periodEnd: DateTime(2026, 5, 13),
      tagFilter: const ['同步'],
      taskIds: const [],
      prompt: 'prompt',
      output: '刷新后的历史内容',
    );
    final refresh = tester.widget<RefreshIndicator>(
      find.byKey(const ValueKey('history-refresh')),
    );

    await refresh.onRefresh();
    await _pumpFrame(tester);

    expect(find.text('日报 · refresh-2026-05-12'), findsOneWidget);

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

    expect(find.textContaining('官方托管'), findsOneWidget);

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

    expect(find.textContaining('官方托管'), findsOneWidget);

    await database.close();
  });

  testWidgets(
      'model settings switches from custom to hosted when already signed in',
      (tester) async {
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
      initialSettings: const ModelSettings(
        mode: ModelMode.custom,
        baseUrl: 'https://example.test/v1',
        model: 'custom-model',
        hasApiKey: true,
        hostedBaseUrl: 'http://127.0.0.1:8787',
        hasHostedSession: true,
      ),
    );

    await _pumpApp(
      tester,
      database: database,
      apiKeyVault: apiKeyVault,
      modelSettingsRepository: repository,
      openSummary: true,
    );

    expect(find.text('custom-model'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.storage_outlined));
    await _pumpFrame(tester);
    await tester.tap(find.text('使用官方模型'));
    await _pumpFrame(tester);
    await tester.tap(find.text('完成'));
    await _pumpFrame(tester);

    expect(find.textContaining('官方托管'), findsOneWidget);

    await database.close();
  });

  testWidgets('model settings switches from hosted back to custom',
      (tester) async {
    final database = AppDatabase(pathOverride: inMemoryDatabasePath);
    final apiKeyVault = MemoryApiKeyVault();
    final repository = _FakeHostedLoginRepository(
      store: database,
      apiKeyVault: apiKeyVault,
      initialSettings: const ModelSettings(
        mode: ModelMode.hosted,
        baseUrl: 'https://example.test/v1',
        model: 'custom-model',
        hasApiKey: true,
        hostedBaseUrl: 'http://127.0.0.1:8787',
        hasHostedSession: true,
      ),
    );

    await _pumpApp(
      tester,
      database: database,
      apiKeyVault: apiKeyVault,
      modelSettingsRepository: repository,
      openSummary: true,
    );

    expect(find.textContaining('官方托管'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.storage_outlined));
    await _pumpFrame(tester);
    await tester.tap(find.text('使用自己的模型服务'));
    await _pumpFrame(tester);
    await tester.tap(find.text('保存'));
    await _pumpFrame(tester);

    expect(find.text('custom-model'), findsOneWidget);

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
    ModelSettings? initialSettings,
  }) : _settings = initialSettings ?? ModelSettings.defaults();

  ModelSettings _settings;

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
  Future<Map<String, Object?>?> requestHostedConfig() async {
    if (!_settings.hasHostedSession) {
      return null;
    }
    return {
      'mode': 'hosted',
      'hosted_base_url': _settings.hostedBaseUrl.trim().isEmpty
          ? ModelSettings.defaults().hostedBaseUrl
          : _settings.hostedBaseUrl,
      'access_token': 'hosted-token',
    };
  }

  @override
  Future<HostedQuota?> loadHostedQuota() async {
    if (!_settings.hasHostedSession) {
      return null;
    }
    return const HostedQuota(
      period: '2026-05',
      limit: 30,
      used: 8,
      remaining: 22,
    );
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
      hasApiKey: apiKey != null && apiKey.trim().isNotEmpty
          ? true
          : _settings.hasApiKey,
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

Future<MemoStore> _pumpApp(
  WidgetTester tester, {
  MemoStore? database,
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
