import 'dart:async';
import 'dart:developer' as developer;

import '../models/task_record.dart';
import 'app_database.dart';
import 'sync_api_client.dart';

class SyncCoordinator {
  SyncCoordinator({
    required this.database,
    required this.client,
  });

  final AppDatabase database;
  final SyncApiClient client;
  Future<SyncResult>? _activeSync;

  Future<SyncResult> sync() {
    final activeSync = _activeSync;
    if (activeSync != null) {
      return activeSync;
    }
    final run = _sync().whenComplete(() => _activeSync = null);
    _activeSync = run;
    return run;
  }

  Future<SyncResult> _sync() async {
    final result = SyncResult();
    await _pushLocalChanges(result);
    await _pullRemoteChanges(result);
    return result;
  }

  Future<void> _pushLocalChanges(SyncResult result) async {
    final pendingTasks = await database.listPendingSyncTasks();
    for (final task in pendingTasks) {
      try {
        switch (task.syncStatus) {
          case TaskSyncStatus.pendingCreate:
            if (task.deletedAt != null) {
              await database.markTaskSynced(taskId: task.id);
              result.discarded++;
              continue;
            }
            final remoteTask = await client.pushCreate(task);
            await database.markTaskSynced(
              taskId: task.id,
              cloudId: remoteTask.cloudId,
              updatedAt: remoteTask.updatedAt,
              deletedAt: remoteTask.deletedAt,
            );
            result.uploaded++;
            break;

          case TaskSyncStatus.pendingUpdate:
            final remoteTask = await client.pushUpdate(task);
            await database.markTaskSynced(
              taskId: task.id,
              cloudId: remoteTask.cloudId,
              updatedAt: remoteTask.updatedAt,
              deletedAt: remoteTask.deletedAt,
            );
            result.updated++;
            break;

          case TaskSyncStatus.pendingDelete:
            if (task.cloudId == null || task.cloudId!.trim().isEmpty) {
              await database.markTaskSynced(taskId: task.id);
              result.discarded++;
              continue;
            }
            final remoteTask = await client.pushDelete(task);
            await database.markTaskSynced(
              taskId: task.id,
              cloudId: remoteTask.cloudId,
              updatedAt: remoteTask.updatedAt,
              deletedAt: remoteTask.deletedAt ?? task.deletedAt,
            );
            result.deleted++;
            break;

          case TaskSyncStatus.conflict:
            result.conflicts++;
            break;

          case TaskSyncStatus.synced:
            continue;
        }
      } catch (error, stackTrace) {
        result.errors++;
        developer.log(
          'Failed to push task ${task.clientId}.',
          name: 'SyncCoordinator',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _pullRemoteChanges(SyncResult result) async {
    final lastSyncAt = await database.getLastTaskSyncAt();
    final pullResult = await client.pull(updatedAfter: lastSyncAt);
    var applyErrors = 0;
    DateTime? newestRemoteUpdate = lastSyncAt;

    for (final remoteTask in pullResult.tasks) {
      if (newestRemoteUpdate == null ||
          remoteTask.updatedAt.isAfter(newestRemoteUpdate)) {
        newestRemoteUpdate = remoteTask.updatedAt;
      }
      try {
        final applied = await database.applyRemoteTask(remoteTask);
        switch (applied) {
          case TaskRemoteApplyResult.inserted:
            result.downloaded++;
          case TaskRemoteApplyResult.updated:
            result.updated++;
          case TaskRemoteApplyResult.deleted:
            result.deleted++;
          case TaskRemoteApplyResult.conflict:
            result.conflicts++;
          case TaskRemoteApplyResult.unchanged:
            break;
        }
      } catch (error, stackTrace) {
        applyErrors++;
        result.errors++;
        developer.log(
          'Failed to apply remote task ${remoteTask.cloudId}.',
          name: 'SyncCoordinator',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (applyErrors == 0 &&
        newestRemoteUpdate != null &&
        (lastSyncAt == null || newestRemoteUpdate.isAfter(lastSyncAt))) {
      await database.saveLastTaskSyncAt(newestRemoteUpdate);
    }
  }
}

class SyncResult {
  SyncResult({
    this.uploaded = 0,
    this.downloaded = 0,
    this.updated = 0,
    this.deleted = 0,
    this.discarded = 0,
    this.conflicts = 0,
    this.errors = 0,
  });

  int uploaded;
  int downloaded;
  int updated;
  int deleted;
  int discarded;
  int conflicts;
  int errors;

  bool get hasChanges {
    return uploaded + downloaded + updated + deleted + discarded > 0;
  }

  @override
  String toString() {
    final parts = <String>[];
    if (uploaded > 0) parts.add('上传 $uploaded');
    if (downloaded > 0) parts.add('下载 $downloaded');
    if (updated > 0) parts.add('更新 $updated');
    if (deleted > 0) parts.add('删除 $deleted');
    if (discarded > 0) parts.add('清理 $discarded');
    if (conflicts > 0) parts.add('冲突 $conflicts');
    if (errors > 0) parts.add('错误 $errors');
    return parts.isEmpty ? '无变更' : parts.join('，');
  }
}
