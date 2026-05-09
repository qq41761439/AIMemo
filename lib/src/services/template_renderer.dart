import '../models/period_type.dart';
import '../models/task_record.dart';
import 'period_utils.dart';

const defaultSummaryTemplate = '''
请根据以下任务生成{period}总结：
{tasks}

生成总结时突出亮点、改进建议和下步计划。''';

String renderSummaryPrompt({
  required String template,
  required PeriodType periodType,
  required List<TaskRecord> tasks,
  required List<String> tags,
  String? periodLabel,
}) {
  return template
      .replaceAll('{tasks}', formatTasksForPrompt(tasks))
      .replaceAll('{period}', periodLabel ?? periodType.placeholderName)
      .replaceAll('{tags}', tags.isEmpty ? '全部标签' : tags.join('、'));
}

String formatTasksForPrompt(List<TaskRecord> tasks) {
  if (tasks.isEmpty) {
    return '无任务。';
  }

  return tasks.map((task) {
    final state = task.isCompleted ? '完成' : '未完成';
    final tags = task.tags.isEmpty ? '无标签' : task.tags.join('、');
    final content = task.content.trim().isEmpty ? '无内容' : task.content.trim();

    return [
      '- [$state] ${task.title}',
      '  内容：$content',
      '  标签：$tags',
      '  创建时间：${compactDateTime(task.createdAt)}',
      if (task.completedAt != null)
        '  完成时间：${compactDateTime(task.completedAt!)}',
    ].join('\n');
  }).join('\n\n');
}
