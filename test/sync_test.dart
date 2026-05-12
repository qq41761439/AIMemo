import 'dart:convert';

import 'package:aimemo/src/models/task_record.dart';
import 'package:aimemo/src/services/app_database.dart';
import 'package:aimemo/src/services/sync_api_client.dart';
import 'package:aimemo/src/services/sync_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('SyncApiClient', () {
    test('pushes task creates using backend task shape', () async {
      final client = SyncApiClient(
        config: const SyncConfig(
          baseUrl: 'https://backend.example.test/',
          accessToken: 'token',
        ),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), 'https://backend.example.test/tasks');
          expect(request.headers['authorization'], 'Bearer token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['body'], '写日报\n整理今天完成事项');
          expect(body['tags'], ['工作']);
          expect(body['isCompleted'], false);
          expect(body['clientId'], 'client-1');

          return _jsonResponse({
            'task': _remoteTaskJson(
              id: 'cloud-1',
              body: '写日报\n整理今天完成事项',
              tags: ['工作'],
              clientId: 'client-1',
              updatedAt: '2026-05-12T10:00:00.000Z',
            ),
          });
        }),
      );

      final task = await client.pushCreate(
        TaskRecord(
          id: 1,
          title: '写日报',
          content: '整理今天完成事项',
          tags: const ['工作'],
          createdAt: DateTime.utc(2026, 5, 12, 9),
          clientId: 'client-1',
        ),
      );

      expect(task.cloudId, 'cloud-1');
      expect(task.clientId, 'client-1');
      expect(task.title, '写日报');
      expect(task.content, '整理今天完成事项');
      expect(task.syncStatus, TaskSyncStatus.synced);
    });

    test('refreshes sync token once after unauthorized response', () async {
      var calls = 0;
      final client = SyncApiClient(
        config: const SyncConfig(
          baseUrl: 'https://backend.example.test',
          accessToken: 'expired-token',
        ),
        refreshConfig: () async => const SyncConfig(
          baseUrl: 'https://backend.example.test',
          accessToken: 'fresh-token',
        ),
        httpClient: MockClient((request) async {
          calls++;
          if (calls == 1) {
            expect(request.headers['authorization'], 'Bearer expired-token');
            return _jsonResponse(
              {
                'error': {'message': 'expired'},
              },
              statusCode: 401,
            );
          }
          expect(request.headers['authorization'], 'Bearer fresh-token');
          expect(request.url.queryParameters['limit'], '200');
          return _jsonResponse({'items': <Object?>[]});
        }),
      );

      final result = await client.pull();

      expect(result.tasks, isEmpty);
      expect(calls, 2);
    });
  });

  group('AppDatabase sync helpers', () {
    late AppDatabase database;

    setUp(() {
      sqfliteFfiInit();
      database = AppDatabase(pathOverride: inMemoryDatabasePath);
    });

    tearDown(() async {
      await database.close();
    });

    test('includes synced soft deletes in pending sync tasks', () async {
      final taskId = await database.addTask(
        title: '云端任务',
        content: '',
        tags: const [],
      );
      final remoteUpdatedAt = DateTime.utc(2026, 5, 12, 10);
      await database.markTaskSynced(
        taskId: taskId,
        cloudId: 'cloud-1',
        updatedAt: remoteUpdatedAt,
      );

      await database.deleteTask(taskId);
      final pending = await database.listPendingSyncTasks();

      expect(pending, hasLength(1));
      expect(pending.single.cloudId, 'cloud-1');
      expect(pending.single.deletedAt, isNotNull);
      expect(pending.single.syncStatus, TaskSyncStatus.pendingDelete);
    });

    test('applies remote deleted task and stores sync cursor', () async {
      final remoteUpdatedAt = DateTime.utc(2026, 5, 12, 12);
      final result = await database.applyRemoteTask(
        TaskRecord(
          id: 0,
          title: '远程任务',
          content: '',
          tags: const ['远程'],
          createdAt: DateTime.utc(2026, 5, 12, 9),
          updatedAt: remoteUpdatedAt,
          deletedAt: DateTime.utc(2026, 5, 12, 11),
          clientId: 'cloud-cloud-1',
          cloudId: 'cloud-1',
          syncStatus: TaskSyncStatus.synced,
        ),
      );
      await database.saveLastTaskSyncAt(remoteUpdatedAt);

      expect(result, TaskRemoteApplyResult.deleted);
      expect(await database.listTasks(), isEmpty);
      expect(await database.getLastTaskSyncAt(), remoteUpdatedAt);
    });
  });

  group('SyncCoordinator', () {
    late AppDatabase database;

    setUp(() {
      sqfliteFfiInit();
      database = AppDatabase(pathOverride: inMemoryDatabasePath);
    });

    tearDown(() async {
      await database.close();
    });

    test('pushes local create and stores cloud metadata', () async {
      final taskId = await database.addTask(
        title: '同步任务',
        content: '正文',
        tags: const ['工作'],
        createdAt: DateTime.utc(2026, 5, 12, 8),
      );
      final localTask = (await database.listTasks()).single;
      const remoteUpdatedAt = '2026-05-12T10:00:00.000Z';
      final coordinator = SyncCoordinator(
        database: database,
        client: SyncApiClient(
          config: const SyncConfig(
            baseUrl: 'https://backend.example.test',
            accessToken: 'token',
          ),
          httpClient: MockClient((request) async {
            if (request.method == 'POST') {
              expect(request.url.path, '/tasks');
              return _jsonResponse({
                'task': _remoteTaskJson(
                  id: 'cloud-1',
                  body: '同步任务\n正文',
                  tags: ['工作'],
                  clientId: localTask.clientId,
                  createdAt: '2026-05-12T08:00:00.000Z',
                  updatedAt: remoteUpdatedAt,
                ),
              });
            }
            expect(request.method, 'GET');
            return _jsonResponse({
              'items': [
                _remoteTaskJson(
                  id: 'cloud-1',
                  body: '同步任务\n正文',
                  tags: ['工作'],
                  clientId: localTask.clientId,
                  createdAt: '2026-05-12T08:00:00.000Z',
                  updatedAt: remoteUpdatedAt,
                ),
              ],
            });
          }),
        ),
      );

      final result = await coordinator.sync();
      final synced = await database.getTaskByClientId(localTask.clientId);

      expect(result.uploaded, 1);
      expect(result.errors, 0);
      expect(synced!.id, taskId);
      expect(synced.cloudId, 'cloud-1');
      expect(synced.syncStatus, TaskSyncStatus.synced);
      expect(await database.listPendingSyncTasks(), isEmpty);
      expect(
        (await database.getLastTaskSyncAt())!
            .isAtSameMomentAs(DateTime.parse(remoteUpdatedAt)),
        isTrue,
      );
    });

    test('pushes local soft delete instead of dropping tombstone', () async {
      final taskId = await database.addTask(
        title: '待删任务',
        content: '',
        tags: const [],
      );
      await database.markTaskSynced(
        taskId: taskId,
        cloudId: 'cloud-1',
        updatedAt: DateTime.utc(2026, 5, 12, 9),
      );
      await database.deleteTask(taskId);

      final coordinator = SyncCoordinator(
        database: database,
        client: SyncApiClient(
          config: const SyncConfig(
            baseUrl: 'https://backend.example.test',
            accessToken: 'token',
          ),
          httpClient: MockClient((request) async {
            if (request.method == 'DELETE') {
              expect(request.url.path, '/tasks/cloud-1');
              return _jsonResponse({
                'task': _remoteTaskJson(
                  id: 'cloud-1',
                  body: '待删任务',
                  tags: const [],
                  clientId: 'client-1',
                  updatedAt: '2026-05-12T10:00:00.000Z',
                  deletedAt: '2026-05-12T10:00:00.000Z',
                ),
              });
            }
            expect(request.method, 'GET');
            return _jsonResponse({'items': <Object?>[]});
          }),
        ),
      );

      final result = await coordinator.sync();
      final pending = await database.listPendingSyncTasks();

      expect(result.deleted, 1);
      expect(result.errors, 0);
      expect(pending, isEmpty);
      expect(await database.listTasks(), isEmpty);
    });
  });
}

http.Response _jsonResponse(
  Map<String, Object?> body, {
  int statusCode = 200,
}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    statusCode,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

Map<String, Object?> _remoteTaskJson({
  required String id,
  required String body,
  required List<String> tags,
  required String? clientId,
  String createdAt = '2026-05-12T09:00:00.000Z',
  String updatedAt = '2026-05-12T09:00:00.000Z',
  String? completedAt,
  String? deletedAt,
}) {
  return {
    'id': id,
    'body': body,
    'tags': tags,
    'isCompleted': completedAt != null,
    'createdAt': createdAt,
    'completedAt': completedAt,
    'updatedAt': updatedAt,
    'deletedAt': deletedAt,
    'clientId': clientId,
  };
}
