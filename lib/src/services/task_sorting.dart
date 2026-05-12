import '../models/task_record.dart';

int compareTasksForList(TaskRecord a, TaskRecord b) {
  if (a.isCompleted != b.isCompleted) {
    return a.isCompleted ? 1 : -1;
  }
  if (a.isCompleted) {
    return b.completedAt!.compareTo(a.completedAt!);
  }
  return b.createdAt.compareTo(a.createdAt);
}

const taskListSqlOrder =
    'CASE WHEN t.completed_at IS NULL THEN 0 ELSE 1 END ASC, '
    'CASE WHEN t.completed_at IS NULL THEN t.created_at ELSE t.completed_at END DESC';
