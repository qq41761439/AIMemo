enum TaskSyncStatus {
  synced('synced'),
  pendingCreate('pendingCreate'),
  pendingUpdate('pendingUpdate'),
  pendingDelete('pendingDelete'),
  conflict('conflict');

  const TaskSyncStatus(this.value);

  final String value;

  static TaskSyncStatus fromValue(Object? value) {
    return TaskSyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskSyncStatus.pendingCreate,
    );
  }
}

class TaskRecord {
  TaskRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    DateTime? updatedAt,
    String? clientId,
    this.syncStatus = TaskSyncStatus.pendingCreate,
    this.completedAt,
    this.deletedAt,
    this.cloudId,
  })  : updatedAt = updatedAt ?? createdAt,
        clientId = clientId ?? 'local-$id';

  final int id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final String clientId;
  final String? cloudId;
  final TaskSyncStatus syncStatus;

  bool get isCompleted => completedAt != null;

  TaskRecord copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? deletedAt,
    String? clientId,
    String? cloudId,
    TaskSyncStatus? syncStatus,
  }) {
    return TaskRecord(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientId: clientId ?? this.clientId,
      cloudId: cloudId ?? this.cloudId,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory TaskRecord.fromDb(Map<String, Object?> row, List<String> tags) {
    return TaskRecord(
      id: row['id'] as int,
      title: row['title'] as String,
      content: row['content'] as String,
      tags: tags,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String),
      clientId: row['client_id'] as String,
      cloudId: row['cloud_id'] as String?,
      syncStatus: TaskSyncStatus.fromValue(row['sync_status']),
    );
  }
}
