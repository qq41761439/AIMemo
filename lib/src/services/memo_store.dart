import '../models/period_type.dart';
import '../models/summary_record.dart';
import '../models/task_record.dart';

abstract class MemoStore {
  Future<void> close();

  Future<int> addTask({
    required String title,
    required String content,
    required List<String> tags,
  });

  Future<void> updateTask({
    required int taskId,
    required String title,
    required String content,
    required List<String> tags,
    required DateTime createdAt,
    DateTime? completedAt,
  });

  Future<List<TaskRecord>> listTasks({List<String> tagNames = const []});

  Future<List<TaskRecord>> listTasksForPeriod({
    required DateTime start,
    required DateTime end,
    List<String> tagNames = const [],
  });

  Future<void> setTaskCompleted(int taskId, bool completed);

  Future<void> deleteTask(int taskId);

  Future<void> restoreTask(int taskId);

  Future<List<String>> listTags();

  Future<double?> getActionPaneWidth();

  Future<void> saveActionPaneWidth(double width);

  Future<String?> getAppSetting(String key);

  Future<void> saveAppSetting(String key, String value);

  Future<String> getTemplate(PeriodType type);

  Future<void> saveTemplate(PeriodType type, String content);

  Future<void> resetTemplate(PeriodType type);

  Future<int> insertSummary({
    required PeriodType periodType,
    required String periodLabel,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<String> tagFilter,
    required List<int> taskIds,
    required String prompt,
    required String output,
  });

  Future<List<SummaryRecord>> listSummaries();
}
