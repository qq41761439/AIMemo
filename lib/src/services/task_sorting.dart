import '../models/task_record.dart';

int compareTasksForList(TaskRecord a, TaskRecord b) {
  if (a.isCompleted != b.isCompleted) {
    return a.isCompleted ? 1 : -1;
  }
  return b.createdAt.compareTo(a.createdAt);
}

const taskListSqlOrder =
    'CASE WHEN t.completed_at IS NULL THEN 0 ELSE 1 END ASC, t.created_at DESC';
