import 'dart:async';
import 'dart:convert';

import 'package:aimemo/src/models/model_settings.dart';
import 'package:aimemo/src/models/period_type.dart';
import 'package:aimemo/src/services/app_database.dart';
import 'package:aimemo/src/services/model_settings_repository.dart';
import 'package:aimemo/src/services/template_renderer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(pathOverride: inMemoryDatabasePath);
  });

  tearDown(() async {
    await database.close();
  });

  test('creates task and reuses tags', () async {
    await database.addTask(
      title: '写日报',
      content: '整理今天完成事项',
      tags: ['工作', '复盘'],
    );
    await database.addTask(
      title: '读书',
      content: '看 Flutter 文档',
      tags: ['学习', '复盘'],
    );

    final tags = await database.listTags();
    expect(tags, containsAll(['工作', '学习', '复盘']));

    final filtered = await database.listTasks(tagNames: ['复盘']);
    expect(filtered, hasLength(2));
  });

  test('creates task with selected start time', () async {
    final startTime = DateTime(2026, 5, 12, 10, 30);

    await database.addTask(
      title: '预约任务',
      content: '',
      tags: const [],
      createdAt: startTime,
    );

    final tasks = await database.listTasks();
    expect(tasks.single.createdAt, startTime);
  });

  test('lists most recently associated tags first', () async {
    await database.addTask(
      title: '先添加',
      content: '',
      tags: const ['旧标签'],
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await database.addTask(
      title: '后添加',
      content: '',
      tags: const ['新标签'],
    );

    final tags = await database.listTags();
    expect(tags.take(2), ['新标签', '旧标签']);
  });

  test('moves reused tag to the front', () async {
    await database.addTask(
      title: '先添加',
      content: '',
      tags: const ['旧标签'],
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await database.addTask(
      title: '后添加',
      content: '',
      tags: const ['新标签'],
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await database.addTask(
      title: '再次关联旧标签',
      content: '',
      tags: const ['旧标签'],
    );

    final tags = await database.listTags();
    expect(tags.take(2), ['旧标签', '新标签']);
  });

  test('hides tags that no active task uses', () async {
    final deletedTaskId = await database.addTask(
      title: '待删除任务',
      content: '',
      tags: const ['临时标签'],
    );
    await database.addTask(
      title: '保留任务',
      content: '',
      tags: const ['保留标签'],
    );

    await database.deleteTask(deletedTaskId);

    final tags = await database.listTags();
    expect(tags, contains('保留标签'));
    expect(tags, isNot(contains('临时标签')));
  });

  test('tag filters match any selected tag', () async {
    await database.addTask(
      title: '工作任务',
      content: '',
      tags: const ['工作'],
    );
    await database.addTask(
      title: '学习任务',
      content: '',
      tags: const ['学习'],
    );
    await database.addTask(
      title: '生活任务',
      content: '',
      tags: const ['生活'],
    );

    final filtered = await database.listTasks(tagNames: ['工作', '学习']);
    expect(filtered.map((task) => task.title), containsAll(['工作任务', '学习任务']));
    expect(filtered.map((task) => task.title), isNot(contains('生活任务')));
  });

  test('complete, uncomplete, and delete task', () async {
    final id = await database.addTask(
      title: '测试任务',
      content: '',
      tags: const [],
    );

    await database.setTaskCompleted(id, true);
    var tasks = await database.listTasks();
    expect(tasks.single.completedAt, isNotNull);

    await database.setTaskCompleted(id, false);
    tasks = await database.listTasks();
    expect(tasks.single.completedAt, isNull);

    await database.deleteTask(id);
    tasks = await database.listTasks();
    expect(tasks, isEmpty);

    await database.restoreTask(id);
    tasks = await database.listTasks();
    expect(tasks.single.title, '测试任务');
  });

  test('updates task details and tags', () async {
    final id = await database.addTask(
      title: '旧标题',
      content: '旧内容',
      tags: const ['工作'],
    );

    await database.updateTask(
      taskId: id,
      title: '新标题',
      content: '新内容',
      tags: const ['学习', '复盘'],
      createdAt: DateTime(2026, 5, 8, 9, 30),
      completedAt: DateTime(2026, 5, 8, 18),
    );

    final tasks = await database.listTasks();
    expect(tasks.single.title, '新标题');
    expect(tasks.single.content, '新内容');
    expect(tasks.single.tags, ['复盘', '学习']);
    expect(tasks.single.createdAt, DateTime(2026, 5, 8, 9, 30));
    expect(tasks.single.completedAt, DateTime(2026, 5, 8, 18));

    final filtered = await database.listTasks(tagNames: ['工作']);
    expect(filtered, isEmpty);
  });

  test('completed tasks sink below open tasks', () async {
    final firstId = await database.addTask(
      title: '先创建但已完成',
      content: '',
      tags: const [],
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await database.addTask(
      title: '后创建但未完成',
      content: '',
      tags: const [],
    );

    await database.setTaskCompleted(firstId, true);

    final tasks = await database.listTasks();
    expect(tasks.first.title, '后创建但未完成');
    expect(tasks.last.title, '先创建但已完成');
  });

  test('sorts open tasks by start time and completed tasks by completion time',
      () async {
    final olderOpenId = await database.addTask(
      title: '较早开始未完成',
      content: '',
      tags: const [],
      createdAt: DateTime(2026, 5, 12, 9),
    );
    final newerOpenId = await database.addTask(
      title: '较晚开始未完成',
      content: '',
      tags: const [],
      createdAt: DateTime(2026, 5, 12, 11),
    );
    final newerCompletedId = await database.addTask(
      title: '较晚完成',
      content: '',
      tags: const [],
      createdAt: DateTime(2026, 5, 12, 8),
    );
    final olderCompletedId = await database.addTask(
      title: '较早完成',
      content: '',
      tags: const [],
      createdAt: DateTime(2026, 5, 12, 12),
    );

    await database.updateTask(
      taskId: newerCompletedId,
      title: '较晚完成',
      content: '',
      tags: const [],
      createdAt: DateTime(2026, 5, 12, 8),
      completedAt: DateTime(2026, 5, 12, 18),
    );
    await database.updateTask(
      taskId: olderCompletedId,
      title: '较早完成',
      content: '',
      tags: const [],
      createdAt: DateTime(2026, 5, 12, 12),
      completedAt: DateTime(2026, 5, 12, 17),
    );

    final tasks = await database.listTasks();
    expect(
      tasks.map((task) => task.id),
      [newerOpenId, olderOpenId, newerCompletedId, olderCompletedId],
    );
  });

  test('saves templates and summary history', () async {
    await database.saveTemplate(PeriodType.daily, '模板 {tasks}');
    expect(await database.getTemplate(PeriodType.daily), '模板 {tasks}');

    final summaryId = await database.insertSummary(
      periodType: PeriodType.daily,
      periodLabel: '2026-05-09',
      periodStart: DateTime(2026, 5, 9),
      periodEnd: DateTime(2026, 5, 10),
      tagFilter: const ['工作'],
      taskIds: const [1, 2],
      prompt: defaultSummaryTemplate,
      output: '今天完成了核心设计。',
    );

    final summaries = await database.listSummaries();
    expect(summaryId, greaterThan(0));
    expect(summaries.single.output, '今天完成了核心设计。');
    expect(summaries.single.tagFilter, ['工作']);
  });

  test('uses period-specific default templates', () async {
    expect(await database.getTemplate(PeriodType.daily), contains('今天做完了什么'));
    expect(await database.getTemplate(PeriodType.weekly), contains('本周已完成任务'));
    expect(await database.getTemplate(PeriodType.monthly), contains('本月最重要'));
    expect(await database.getTemplate(PeriodType.yearly), contains('年度完成'));
    expect(await database.getTemplate(PeriodType.custom),
        contains('{period_days}'));
  });

  test('saves app layout settings', () async {
    expect(await database.getActionPaneWidth(), isNull);

    await database.saveActionPaneWidth(640);

    expect(await database.getActionPaneWidth(), 640.0);
  });

  test('saves model settings without writing API key to SQLite', () async {
    final vault = MemoryApiKeyVault();
    final repository = ModelSettingsRepository(
      store: database,
      apiKeyVault: vault,
    );

    await repository.save(
      mode: ModelMode.custom,
      baseUrl: 'https://example.test/v1',
      model: 'custom-model',
      hostedBaseUrl: 'http://127.0.0.1:8787',
      apiKey: 'placeholder-token',
    );

    final settings = await repository.load();
    expect(settings.mode, ModelMode.custom);
    expect(settings.baseUrl, 'https://example.test/v1');
    expect(settings.model, 'custom-model');
    expect(settings.hasApiKey, isTrue);

    final db = await database.database;
    final rows = await db.query('app_settings');
    expect(rows.toString(), isNot(contains('placeholder-token')));
    expect(await vault.readApiKey(), 'placeholder-token');
  });

  test('loads model settings without reading secure API key storage', () async {
    final repository = ModelSettingsRepository(
      store: database,
      apiKeyVault: _HangingApiKeyVault(),
      secureStorageTimeout: const Duration(milliseconds: 10),
    );

    await database.saveAppSetting('model_mode', ModelMode.custom.value);
    await database.saveAppSetting('model_base_url', 'https://example.test/v1');
    await database.saveAppSetting('model_name', 'custom-model');
    await database.saveAppSetting('model_has_api_key', 'true');

    final settings = await repository.load();
    expect(settings.mode, ModelMode.custom);
    expect(settings.baseUrl, 'https://example.test/v1');
    expect(settings.model, 'custom-model');
    expect(settings.hasApiKey, isTrue);
  });

  test('logs in hosted model without writing tokens to SQLite', () async {
    final vault = MemoryApiKeyVault();
    final requests = <String>[];
    final repository = ModelSettingsRepository(
      store: database,
      apiKeyVault: vault,
      httpClient: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path == '/auth/email/start') {
          expect(body['email'], 'user@example.com');
          return http.Response('{"ok":true}', 200);
        }
        expect(request.url.path, '/auth/email/verify');
        expect(body['code'], '123456');
        return http.Response(
          '{"accessToken":"access-token","refreshToken":"refresh-token"}',
          200,
        );
      }),
    );

    await repository.startHostedEmailLogin(
      hostedBaseUrl: 'https://backend.example.test',
      email: 'user@example.com',
    );
    await repository.verifyHostedEmailLogin(
      hostedBaseUrl: 'https://backend.example.test',
      email: 'user@example.com',
      code: '123456',
    );

    final settings = await repository.load();
    expect(settings.hostedBaseUrl, 'https://backend.example.test');
    expect(settings.hasHostedSession, isTrue);
    expect(await vault.readHostedSession(), isNotNull);
    expect(requests, [
      'POST /auth/email/start',
      'POST /auth/email/verify',
    ]);

    final db = await database.database;
    final rows = await db.query('app_settings');
    expect(rows.toString(), isNot(contains('access-token')));
    expect(rows.toString(), isNot(contains('refresh-token')));
  });

  test('times out when secure model key storage hangs', () async {
    final repository = ModelSettingsRepository(
      store: database,
      apiKeyVault: _HangingApiKeyVault(),
      secureStorageTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      repository.save(
        mode: ModelMode.custom,
        baseUrl: 'http://127.0.0.1:8317/v1',
        model: 'gpt-5.4-mini',
        hostedBaseUrl: 'http://127.0.0.1:8787',
        apiKey: 'placeholder-token',
      ),
      throwsA(isA<ModelSettingsException>()),
    );
  });
}

class _HangingApiKeyVault implements ApiKeyVault {
  @override
  Future<String?> readApiKey() => Completer<String?>().future;

  @override
  Future<void> saveApiKey(String apiKey) => Completer<void>().future;

  @override
  Future<void> deleteApiKey() => Completer<void>().future;

  @override
  Future<HostedSession?> readHostedSession() =>
      Completer<HostedSession?>().future;

  @override
  Future<void> saveHostedSession(HostedSession session) =>
      Completer<void>().future;

  @override
  Future<void> deleteHostedSession() => Completer<void>().future;
}
