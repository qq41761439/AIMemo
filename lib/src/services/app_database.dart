import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite_mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/period_type.dart';
import '../models/summary_record.dart';
import '../models/task_record.dart';
import 'memo_store.dart';
import 'template_renderer.dart';
import 'task_sorting.dart';

enum TaskRemoteApplyResult {
  inserted,
  updated,
  deleted,
  unchanged,
  conflict,
}

class AppDatabase implements MemoStore {
  AppDatabase({
    DatabaseFactory? factory,
    String? pathOverride,
  })  : _factory = factory ?? _defaultDatabaseFactory(),
        _pathOverride = pathOverride;

  final DatabaseFactory _factory;
  final String? _pathOverride;
  Database? _db;

  static DatabaseFactory _defaultDatabaseFactory() {
    if (Platform.isAndroid || Platform.isIOS) {
      return sqflite_mobile.databaseFactory;
    }
    return databaseFactoryFfi;
  }

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }

    final path = _pathOverride ?? await _defaultDbPath();
    final db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createAppSettingsTable(db);
          }
          if (oldVersion < 3) {
            await _migrateTasksForSync(db);
          }
        },
        onCreate: (db, version) async {
          await _createSchema(db);
          await _seedTemplates(db);
        },
      ),
    );
    _db = db;
    return db;
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<String> _defaultDbPath() async {
    final dir = await getApplicationSupportDirectory();
    final aimemoDir = Directory(p.join(dir.path, 'AIMemo'));
    if (!aimemoDir.existsSync()) {
      aimemoDir.createSync(recursive: true);
    }
    return p.join(aimemoDir.path, 'aimemo.sqlite');
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  completed_at TEXT,
  deleted_at TEXT,
  cloud_id TEXT,
  client_id TEXT NOT NULL UNIQUE,
  sync_status TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE task_tags (
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (task_id, tag_id)
)''');
    await db.execute('''
CREATE TABLE templates (
  period_type TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE summaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  period_type TEXT NOT NULL,
  period_label TEXT NOT NULL,
  period_start TEXT NOT NULL,
  period_end TEXT NOT NULL,
  tag_filter TEXT NOT NULL,
  task_ids TEXT NOT NULL,
  prompt TEXT NOT NULL,
  output TEXT NOT NULL,
  created_at TEXT NOT NULL
)''');
    await _createAppSettingsTable(db);
    await db.execute('CREATE INDEX idx_tasks_created_at ON tasks(created_at)');
    await db.execute('CREATE INDEX idx_tasks_updated_at ON tasks(updated_at)');
    await db.execute('CREATE INDEX idx_tasks_deleted_at ON tasks(deleted_at)');
    await db.execute('CREATE INDEX idx_tasks_cloud_id ON tasks(cloud_id)');
    await db.execute(
      'CREATE INDEX idx_tasks_sync_status ON tasks(sync_status)',
    );
    await db.execute('CREATE INDEX idx_tags_name ON tags(name)');
  }

  Future<void> _migrateTasksForSync(Database db) async {
    await db.execute('ALTER TABLE tasks ADD COLUMN updated_at TEXT');
    await db.execute('ALTER TABLE tasks ADD COLUMN cloud_id TEXT');
    await db.execute('ALTER TABLE tasks ADD COLUMN client_id TEXT');
    await db.execute(
      "ALTER TABLE tasks ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pendingCreate'",
    );

    final rows = await db.query(
      'tasks',
      columns: ['id', 'created_at', 'completed_at', 'deleted_at'],
    );
    for (final row in rows) {
      final id = row['id'] as int;
      final updatedAt = (row['deleted_at'] ??
          row['completed_at'] ??
          row['created_at']) as String;
      await db.update(
        'tasks',
        {
          'updated_at': updatedAt,
          'client_id': _existingTaskClientId(id),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_client_id ON tasks(client_id)',
    );
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_updated_at '
        'ON tasks(updated_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_cloud_id '
        'ON tasks(cloud_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_sync_status '
        'ON tasks(sync_status)');
  }

  Future<void> _createAppSettingsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
  }

  Future<void> _seedTemplates(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final type in PeriodType.values) {
      await db.insert('templates', {
        'period_type': type.value,
        'content': defaultSummaryTemplateFor(type),
        'updated_at': now,
      });
    }
  }

  @override
  Future<int> addTask({
    required String title,
    required String content,
    required List<String> tags,
    DateTime? createdAt,
  }) async {
    final db = await database;
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('任务标题不能为空。');
    }

    return db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final taskId = await txn.insert('tasks', {
        'title': cleanTitle,
        'content': content.trim(),
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'updated_at': now,
        'client_id': _newClientId(),
        'sync_status': TaskSyncStatus.pendingCreate.value,
      });
      await _replaceTaskTags(txn, taskId, tags);
      return taskId;
    });
  }

  @override
  Future<void> updateTask({
    required int taskId,
    required String title,
    required String content,
    required List<String> tags,
    required DateTime createdAt,
    DateTime? completedAt,
  }) async {
    final db = await database;
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('任务标题不能为空。');
    }

    await db.transaction((txn) async {
      final existing = await txn.query(
        'tasks',
        columns: ['sync_status'],
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [taskId],
        limit: 1,
      );
      if (existing.isEmpty) {
        return;
      }
      final syncStatus = _nextMutationSyncStatus(
        existing.first['sync_status'] as String?,
      );
      final updatedRows = await txn.update(
        'tasks',
        {
          'title': cleanTitle,
          'content': content.trim(),
          'created_at': createdAt.toIso8601String(),
          'completed_at': completedAt?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': syncStatus.value,
        },
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [taskId],
      );
      if (updatedRows == 0) {
        return;
      }
      await _replaceTaskTags(txn, taskId, tags);
    });
  }

  @override
  Future<List<TaskRecord>> listTasks({List<String> tagNames = const []}) async {
    final db = await database;
    final rows = await _queryTaskRows(db, tagNames: tagNames);
    return _hydrateTasks(db, rows);
  }

  @override
  Future<List<TaskRecord>> listTasksForPeriod({
    required DateTime start,
    required DateTime end,
    List<String> tagNames = const [],
  }) async {
    final db = await database;
    final rows = await _queryTaskRows(
      db,
      tagNames: tagNames,
      start: start,
      end: end,
    );
    return _hydrateTasks(db, rows);
  }

  @override
  Future<void> setTaskCompleted(int taskId, bool completed) async {
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'tasks',
        columns: ['sync_status'],
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [taskId],
        limit: 1,
      );
      if (existing.isEmpty) {
        return;
      }
      await txn.update(
        'tasks',
        {
          'completed_at': completed ? DateTime.now().toIso8601String() : null,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': _nextMutationSyncStatus(
            existing.first['sync_status'] as String?,
          ).value,
        },
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [taskId],
      );
    });
  }

  @override
  Future<void> deleteTask(int taskId) async {
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'tasks',
        columns: ['sync_status'],
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (existing.isEmpty) {
        return;
      }
      await txn.update(
        'tasks',
        {
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': _nextDeleteSyncStatus(
            existing.first['sync_status'] as String?,
          ).value,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
    });
  }

  @override
  Future<void> restoreTask(int taskId) async {
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        'tasks',
        columns: ['sync_status'],
        where: 'id = ?',
        whereArgs: [taskId],
        limit: 1,
      );
      if (existing.isEmpty) {
        return;
      }
      await txn.update(
        'tasks',
        {
          'deleted_at': null,
          'updated_at': DateTime.now().toIso8601String(),
          'sync_status': _nextMutationSyncStatus(
            existing.first['sync_status'] as String?,
          ).value,
        },
        where: 'id = ?',
        whereArgs: [taskId],
      );
    });
  }

  @override
  Future<List<String>> listTags() async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
SELECT g.name
FROM tags g
JOIN task_tags tt ON tt.tag_id = g.id
JOIN tasks t ON t.id = tt.task_id
WHERE t.deleted_at IS NULL
GROUP BY g.id
ORDER BY g.created_at DESC, g.name COLLATE NOCASE ASC
''',
    );
    return rows.map((row) => row['name'] as String).toList();
  }

  @override
  Future<double?> getActionPaneWidth() async {
    return double.tryParse(await getAppSetting('action_pane_width') ?? '');
  }

  @override
  Future<void> saveActionPaneWidth(double width) async {
    await saveAppSetting('action_pane_width', width.toString());
  }

  @override
  Future<String?> getAppSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String;
  }

  @override
  Future<void> saveAppSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<String> getTemplate(PeriodType type) async {
    final db = await database;
    final rows = await db.query(
      'templates',
      columns: ['content'],
      where: 'period_type = ?',
      whereArgs: [type.value],
      limit: 1,
    );
    if (rows.isEmpty) {
      final defaultTemplate = defaultSummaryTemplateFor(type);
      await saveTemplate(type, defaultTemplate);
      return defaultTemplate;
    }
    final content = rows.first['content'] as String;
    if (isLegacyDefaultSummaryTemplate(content)) {
      final defaultTemplate = defaultSummaryTemplateFor(type);
      await saveTemplate(type, defaultTemplate);
      return defaultTemplate;
    }
    return content;
  }

  @override
  Future<void> saveTemplate(PeriodType type, String content) async {
    final db = await database;
    await db.insert(
      'templates',
      {
        'period_type': type.value,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> resetTemplate(PeriodType type) {
    return saveTemplate(type, defaultSummaryTemplateFor(type));
  }

  @override
  Future<int> insertSummary({
    required PeriodType periodType,
    required String periodLabel,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<String> tagFilter,
    required List<int> taskIds,
    required String prompt,
    required String output,
  }) async {
    final db = await database;
    return db.insert('summaries', {
      'period_type': periodType.value,
      'period_label': periodLabel,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'tag_filter': jsonEncode(tagFilter),
      'task_ids': jsonEncode(taskIds),
      'prompt': prompt,
      'output': output,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<SummaryRecord>> listSummaries() async {
    final db = await database;
    final rows = await db.query('summaries', orderBy: 'created_at DESC');
    return rows.map(SummaryRecord.fromDb).toList();
  }

  Future<List<TaskRecord>> listPendingSyncTasks() async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'sync_status != ?',
      whereArgs: [TaskSyncStatus.synced.value],
      orderBy: 'updated_at ASC',
    );
    return _hydrateTasks(db, rows);
  }

  Future<TaskRecord?> getTaskByCloudId(String cloudId) async {
    final cleanCloudId = cloudId.trim();
    if (cleanCloudId.isEmpty) {
      return null;
    }
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'cloud_id = ?',
      whereArgs: [cleanCloudId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return (await _hydrateTasks(db, rows)).single;
  }

  Future<TaskRecord?> getTaskByClientId(String clientId) async {
    final cleanClientId = clientId.trim();
    if (cleanClientId.isEmpty) {
      return null;
    }
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'client_id = ?',
      whereArgs: [cleanClientId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return (await _hydrateTasks(db, rows)).single;
  }

  Future<TaskRemoteApplyResult> applyRemoteTask(TaskRecord remoteTask) async {
    final db = await database;
    return db.transaction((txn) async {
      final localRows = await _queryRemoteMatch(txn, remoteTask);
      if (localRows.isEmpty) {
        final taskId = await txn.insert('tasks', {
          'title': remoteTask.title,
          'content': remoteTask.content,
          'created_at': remoteTask.createdAt.toIso8601String(),
          'updated_at': remoteTask.updatedAt.toIso8601String(),
          'completed_at': remoteTask.completedAt?.toIso8601String(),
          'deleted_at': remoteTask.deletedAt?.toIso8601String(),
          'cloud_id': remoteTask.cloudId,
          'client_id': remoteTask.clientId,
          'sync_status': TaskSyncStatus.synced.value,
        });
        await _replaceTaskTags(txn, taskId, remoteTask.tags);
        return remoteTask.deletedAt == null
            ? TaskRemoteApplyResult.inserted
            : TaskRemoteApplyResult.deleted;
      }

      final localRow = localRows.single;
      final localTask = TaskRecord.fromDb(
        localRow,
        await _taskTags(txn, localRow['id'] as int),
      );
      if (localTask.syncStatus != TaskSyncStatus.synced &&
          localTask.updatedAt.isAfter(remoteTask.updatedAt)) {
        await txn.update(
          'tasks',
          {'sync_status': TaskSyncStatus.conflict.value},
          where: 'id = ?',
          whereArgs: [localTask.id],
        );
        return TaskRemoteApplyResult.conflict;
      }

      final hasRemoteChanges =
          remoteTask.updatedAt.isAfter(localTask.updatedAt) ||
              localTask.cloudId != remoteTask.cloudId ||
              localTask.syncStatus != TaskSyncStatus.synced;
      if (!hasRemoteChanges) {
        return TaskRemoteApplyResult.unchanged;
      }

      await txn.update(
        'tasks',
        {
          'title': remoteTask.title,
          'content': remoteTask.content,
          'created_at': remoteTask.createdAt.toIso8601String(),
          'updated_at': remoteTask.updatedAt.toIso8601String(),
          'completed_at': remoteTask.completedAt?.toIso8601String(),
          'deleted_at': remoteTask.deletedAt?.toIso8601String(),
          'cloud_id': remoteTask.cloudId,
          'sync_status': TaskSyncStatus.synced.value,
        },
        where: 'id = ?',
        whereArgs: [localTask.id],
      );
      await _replaceTaskTags(txn, localTask.id, remoteTask.tags);
      return remoteTask.deletedAt == null
          ? TaskRemoteApplyResult.updated
          : TaskRemoteApplyResult.deleted;
    });
  }

  Future<void> markTaskSynced({
    required int taskId,
    String? cloudId,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) async {
    final db = await database;
    final updates = <String, Object?>{
      'sync_status': TaskSyncStatus.synced.value,
    };
    if (cloudId != null && cloudId.trim().isNotEmpty) {
      updates['cloud_id'] = cloudId.trim();
    }
    if (updatedAt != null) {
      updates['updated_at'] = updatedAt.toIso8601String();
    }
    if (deletedAt != null) {
      updates['deleted_at'] = deletedAt.toIso8601String();
    }
    await db.update(
      'tasks',
      updates,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<DateTime?> getLastTaskSyncAt() async {
    final value = await getAppSetting('task_last_sync_at');
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> saveLastTaskSyncAt(DateTime time) {
    return saveAppSetting('task_last_sync_at', time.toIso8601String());
  }

  Future<List<Map<String, Object?>>> _queryTaskRows(
    Database db, {
    List<String> tagNames = const [],
    DateTime? start,
    DateTime? end,
  }) {
    final cleanTags =
        _cleanTags(tagNames).map((tag) => tag.toLowerCase()).toList();
    final where = <String>['t.deleted_at IS NULL'];
    final args = <Object?>[];

    if (end != null) {
      where.add('t.created_at < ?');
      args.add(end.toIso8601String());
    }
    if (start != null) {
      where.add('(t.completed_at IS NULL OR t.completed_at >= ?)');
      args.add(start.toIso8601String());
    }

    if (cleanTags.isEmpty) {
      return db.rawQuery(
        'SELECT t.* FROM tasks t WHERE ${where.join(' AND ')} '
        'ORDER BY $taskListSqlOrder',
        args,
      );
    }

    final placeholders = List.filled(cleanTags.length, '?').join(', ');
    return db.rawQuery(
      '''
SELECT t.*
FROM tasks t
JOIN task_tags tt ON tt.task_id = t.id
JOIN tags g ON g.id = tt.tag_id
WHERE ${where.join(' AND ')} AND lower(g.name) IN ($placeholders)
GROUP BY t.id
ORDER BY $taskListSqlOrder
''',
      [...args, ...cleanTags],
    );
  }

  Future<List<TaskRecord>> _hydrateTasks(
    Database db,
    List<Map<String, Object?>> rows,
  ) async {
    final tasks = <TaskRecord>[];
    for (final row in rows) {
      final tags = await _taskTags(db, row['id'] as int);
      tasks.add(TaskRecord.fromDb(row, tags));
    }
    return tasks;
  }

  Future<List<String>> _taskTags(DatabaseExecutor executor, int taskId) async {
    final rows = await executor.rawQuery(
      '''
SELECT g.name
FROM tags g
JOIN task_tags tt ON tt.tag_id = g.id
WHERE tt.task_id = ?
ORDER BY g.created_at DESC, g.name COLLATE NOCASE ASC
''',
      [taskId],
    );
    return rows.map((row) => row['name'] as String).toList();
  }

  Future<List<Map<String, Object?>>> _queryRemoteMatch(
    DatabaseExecutor executor,
    TaskRecord remoteTask,
  ) async {
    final cloudId = remoteTask.cloudId?.trim();
    if (cloudId != null && cloudId.isNotEmpty) {
      final rows = await executor.query(
        'tasks',
        where: 'cloud_id = ?',
        whereArgs: [cloudId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return rows;
      }
    }

    final clientId = remoteTask.clientId.trim();
    if (clientId.isEmpty) {
      return const [];
    }
    return executor.query(
      'tasks',
      where: 'client_id = ?',
      whereArgs: [clientId],
      limit: 1,
    );
  }

  Future<void> _replaceTaskTags(
    DatabaseExecutor executor,
    int taskId,
    List<String> tags,
  ) async {
    await executor.delete(
      'task_tags',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );

    for (final tag in _cleanTags(tags)) {
      final tagId = await _getOrCreateTag(executor, tag);
      await executor.insert(
        'task_tags',
        {'task_id': taskId, 'tag_id': tagId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<int> _getOrCreateTag(DatabaseExecutor executor, String name) async {
    final now = DateTime.now().toIso8601String();
    final existing = await executor.query(
      'tags',
      columns: ['id'],
      where: 'lower(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await executor.update(
        'tags',
        {'created_at': now},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return existing.first['id'] as int;
    }

    return executor.insert('tags', {
      'name': name,
      'created_at': now,
    });
  }

  List<String> _cleanTags(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag
        in tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty)) {
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        result.add(tag);
      }
    }
    return result;
  }

  TaskSyncStatus _nextMutationSyncStatus(String? currentValue) {
    final current = TaskSyncStatus.fromValue(currentValue);
    return switch (current) {
      TaskSyncStatus.synced => TaskSyncStatus.pendingUpdate,
      TaskSyncStatus.pendingDelete => TaskSyncStatus.pendingUpdate,
      TaskSyncStatus.conflict => TaskSyncStatus.pendingUpdate,
      TaskSyncStatus.pendingCreate => TaskSyncStatus.pendingCreate,
      TaskSyncStatus.pendingUpdate => TaskSyncStatus.pendingUpdate,
    };
  }

  TaskSyncStatus _nextDeleteSyncStatus(String? currentValue) {
    final current = TaskSyncStatus.fromValue(currentValue);
    return switch (current) {
      TaskSyncStatus.pendingCreate => TaskSyncStatus.pendingCreate,
      _ => TaskSyncStatus.pendingDelete,
    };
  }

  String _newClientId() {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    return 'desktop-${DateTime.now().microsecondsSinceEpoch}-$random';
  }

  String _existingTaskClientId(int id) {
    return 'desktop-import-$id-${DateTime.now().microsecondsSinceEpoch}';
  }
}
