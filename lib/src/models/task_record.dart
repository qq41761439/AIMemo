class TaskRecord {
  const TaskRecord({
    required this.id,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.completedAt,
    this.deletedAt,
  });

  final int id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;

  bool get isCompleted => completedAt != null;

  TaskRecord copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? deletedAt,
  }) {
    return TaskRecord(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory TaskRecord.fromDb(Map<String, Object?> row, List<String> tags) {
    return TaskRecord(
      id: row['id'] as int,
      title: row['title'] as String,
      content: row['content'] as String,
      tags: tags,
      createdAt: DateTime.parse(row['created_at'] as String),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String),
    );
  }
}
