import '../models/period_type.dart';
import '../models/task_record.dart';
import 'period_utils.dart';

const defaultSummaryTemplate = '''
请根据以下任务生成{period}总结。

写作要求：
- “完成事项”只总结已完成任务，说明做完了什么和产生了什么结果。
- “待办事项”只放未完成任务，说明还要做什么、是否有阻塞或风险。
- 不要把未完成任务写成已完成成果。
- 如果某个部分没有内容，可以写“无”。
- 输出简洁、具体、可执行，适合直接作为日报或周报使用。

任务列表：
{tasks}

请按以下结构输出：
1. 完成事项
2. 待办事项
3. 问题与风险
4. 下一步计划''';

String renderSummaryPrompt({
  required String template,
  required PeriodType periodType,
  required List<TaskRecord> tasks,
  required List<String> tags,
  String? periodText,
}) {
  return template
      .replaceAll('{tasks}', formatTasksForPrompt(tasks))
      .replaceAll('{period}', periodText ?? periodType.placeholderName)
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
