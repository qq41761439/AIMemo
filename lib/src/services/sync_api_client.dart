import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task_record.dart';
import 'task_body.dart';

class SyncConfig {
  const SyncConfig({
    required this.baseUrl,
    required this.accessToken,
  });

  final String baseUrl;
  final String accessToken;

  String get normalizedBaseUrl => baseUrl.trim().replaceAll(RegExp(r'/+$'), '');

  Map<String, String> get authHeaders => {
        'authorization': 'Bearer ${accessToken.trim()}',
      };

  Map<String, String> get jsonHeaders => {
        ...authHeaders,
        'content-type': 'application/json',
      };
}

class SyncApiClient {
  SyncApiClient({
    required SyncConfig config,
    http.Client? httpClient,
    Future<SyncConfig?> Function()? refreshConfig,
  })  : _config = config,
        _httpClient = httpClient ?? http.Client(),
        _refreshConfig = refreshConfig;

  SyncConfig _config;
  final http.Client _httpClient;
  final Future<SyncConfig?> Function()? _refreshConfig;

  Future<SyncPullResult> pull({
    DateTime? updatedAfter,
    int limit = 200,
  }) async {
    final response = await _request((config) {
      final uri = Uri.parse('${config.normalizedBaseUrl}/tasks').replace(
        queryParameters: {
          if (updatedAfter != null)
            'updatedAfter': updatedAfter.toUtc().toIso8601String(),
          'limit': limit.toString(),
        },
      );
      return _httpClient.get(uri, headers: config.authHeaders);
    });
    _throwForError(response, '拉取任务失败');

    final body = _decodeJsonObject(response);
    final items = body['items'];
    if (items is! List) {
      throw const SyncException('AIMemo 后端返回格式无效。');
    }
    return SyncPullResult(
      tasks:
          items.map((item) => _parseRemoteTask(_asJsonObject(item))).toList(),
    );
  }

  Future<TaskRecord> pushCreate(TaskRecord task) async {
    final response = await _request((config) {
      final uri = Uri.parse('${config.normalizedBaseUrl}/tasks');
      return _httpClient.post(
        uri,
        headers: config.jsonHeaders,
        body: jsonEncode(_taskPayload(task, includeClientId: true)),
      );
    });
    _throwForError(response, '创建任务失败');
    return _taskFromResponse(response);
  }

  Future<TaskRecord> pushUpdate(TaskRecord task) async {
    final cloudId = task.cloudId?.trim();
    if (cloudId == null || cloudId.isEmpty) {
      return pushCreate(task);
    }
    final response = await _request((config) {
      final uri = Uri.parse('${config.normalizedBaseUrl}/tasks/$cloudId');
      return _httpClient.patch(
        uri,
        headers: config.jsonHeaders,
        body: jsonEncode(_taskPayload(task)),
      );
    });
    _throwForError(response, '更新任务失败');
    return _taskFromResponse(response);
  }

  Future<TaskRecord> pushDelete(TaskRecord task) async {
    final cloudId = task.cloudId?.trim();
    if (cloudId == null || cloudId.isEmpty) {
      throw const SyncException('无法删除云端任务：缺少 cloudId。');
    }
    final response = await _request((config) {
      final uri = Uri.parse('${config.normalizedBaseUrl}/tasks/$cloudId');
      return _httpClient.delete(uri, headers: config.authHeaders);
    });
    _throwForError(response, '删除任务失败');
    return _taskFromResponse(response);
  }

  Future<http.Response> _request(
    Future<http.Response> Function(SyncConfig config) send,
  ) async {
    http.Response response;
    try {
      response = await send(_config);
    } on http.ClientException catch (error) {
      throw SyncException('无法连接 AIMemo 后端。${error.message}');
    } catch (error) {
      throw SyncException('无法请求 AIMemo 后端。$error');
    }
    if (response.statusCode != 401 || _refreshConfig == null) {
      return response;
    }

    final refreshed = await _refreshConfig();
    if (refreshed == null) {
      return response;
    }
    _config = refreshed;
    try {
      return await send(_config);
    } on http.ClientException catch (error) {
      throw SyncException('无法连接 AIMemo 后端。${error.message}');
    } catch (error) {
      throw SyncException('无法请求 AIMemo 后端。$error');
    }
  }

  TaskRecord _taskFromResponse(http.Response response) {
    final body = _decodeJsonObject(response);
    return _parseRemoteTask(_asJsonObject(body['task']));
  }

  TaskRecord _parseRemoteTask(Map<String, Object?> json) {
    final id = _stringField(json, 'id');
    final body = _stringField(json, 'body');
    final draft = taskDraftFromBody(body);
    final clientId = (json['clientId'] as String?)?.trim();
    return TaskRecord(
      id: 0,
      title: draft.title,
      content: draft.content,
      tags: _stringListField(json, 'tags'),
      createdAt: _dateField(json, 'createdAt').toLocal(),
      updatedAt: _dateField(json, 'updatedAt').toLocal(),
      completedAt: _nullableDateField(json, 'completedAt')?.toLocal(),
      deletedAt: _nullableDateField(json, 'deletedAt')?.toLocal(),
      cloudId: id,
      clientId: clientId == null || clientId.isEmpty ? 'cloud-$id' : clientId,
      syncStatus: TaskSyncStatus.synced,
    );
  }

  Map<String, Object?> _taskPayload(
    TaskRecord task, {
    bool includeClientId = false,
  }) {
    return {
      'body': taskBodyFromRecord(task),
      'tags': task.tags,
      'isCompleted': task.isCompleted,
      'createdAt': task.createdAt.toUtc().toIso8601String(),
      'completedAt': task.completedAt?.toUtc().toIso8601String(),
      if (includeClientId) 'clientId': task.clientId,
    };
  }

  void _throwForError(http.Response response, String fallback) {
    if (response.statusCode == 401) {
      throw const SyncAuthException('登录状态已失效，请重新登录 AIMemo。');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw SyncException('$fallback：${_errorMessage(response)}');
  }

  Map<String, Object?> _decodeJsonObject(http.Response response) {
    try {
      return _asJsonObject(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (_) {
      throw const SyncException('AIMemo 后端返回格式无效。');
    }
  }

  Map<String, Object?> _asJsonObject(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map<String, Object?>) {
      return value;
    }
    throw const SyncException('AIMemo 后端返回格式无效。');
  }

  String _stringField(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw const SyncException('AIMemo 后端返回格式无效。');
  }

  List<String> _stringListField(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! List) {
      throw const SyncException('AIMemo 后端返回格式无效。');
    }
    return value.whereType<String>().map((tag) => tag.trim()).where(
      (tag) {
        return tag.isNotEmpty;
      },
    ).toList();
  }

  DateTime _dateField(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! String) {
      throw const SyncException('AIMemo 后端返回格式无效。');
    }
    return DateTime.parse(value);
  }

  DateTime? _nullableDateField(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw const SyncException('AIMemo 后端返回格式无效。');
    }
    return DateTime.parse(value);
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final error = body is Map<String, dynamic> ? body['error'] : null;
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}
    return '状态码 ${response.statusCode}。';
  }
}

class SyncPullResult {
  const SyncPullResult({required this.tasks});

  final List<TaskRecord> tasks;
}

class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SyncAuthException extends SyncException {
  const SyncAuthException(super.message);
}
