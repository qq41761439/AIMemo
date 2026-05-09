import '../models/period_type.dart';
import '../models/task_record.dart';
import 'period_utils.dart';

const defaultSummaryTemplate = defaultDailySummaryTemplate;

const legacyDefaultSummaryTemplates = {
  _previousDefaultSummaryTemplate,
  _separatedDefaultSummaryTemplate,
};

const defaultDailySummaryTemplate = '''
请根据以下任务生成{period}总结。

标签范围：{tags}

任务列表：
{tasks}

请只输出以下两部分：
1. 已完成
- 只写已完成任务。
- 简洁说明今天做完了什么。

2. 下步计划
- 只写未完成任务、需要继续推进的事项或明天要做的事。
- 不要把未完成任务写成已完成。''';

const defaultWeeklySummaryTemplate = '''
请根据以下任务生成{period}总结。

标签范围：{tags}

任务列表：
{tasks}

请只输出以下两部分：
1. 已完成
- 汇总本周已完成任务。
- 可以按主题归并，不要逐条机械罗列。

2. 下步计划
- 汇总未完成任务和下周需要继续推进的事项。
- 如有明显阻塞或风险，可以简短写在对应计划后面。
- 不要把未完成任务写成已完成。''';

const defaultMonthlySummaryTemplate = '''
请根据以下任务生成{period}总结。

标签范围：{tags}

任务列表：
{tasks}

请输出以下部分：
1. 本月完成
- 汇总已完成任务，按主题归类。
- 说明主要成果和推进进展。

2. 关键进展
- 提炼本月最重要的变化、突破或积累。

3. 问题与风险
- 基于未完成任务和任务内容，总结阻塞、延期或需要注意的问题。
- 没有明显问题可写“无”。

4. 下月计划
- 根据未完成任务和任务内容，整理下月要继续推进的事项。
- 不要把未完成任务写成已完成。''';

const defaultYearlySummaryTemplate = '''
请根据以下任务生成{period}总结。

标签范围：{tags}

任务列表：
{tasks}

请输出以下部分：
1. 年度完成
- 汇总全年已完成任务，按方向或主题归类。
- 突出主要成果，不要逐条罗列。

2. 重要进展
- 提炼今年最有价值的进展、能力积累或关键节点。

3. 未完成与遗留问题
- 根据未完成任务，总结仍需继续处理的事项。
- 不要把未完成任务写成已完成成果。

4. 经验复盘
- 总结做得好的地方和可以改进的地方。

5. 下一阶段计划
- 给出下一年或下一阶段的重点计划。''';

const defaultCustomSummaryTemplate = '''
请根据以下任务生成{period}总结。

标签范围：{tags}
日期区间天数：{period_days} 天

任务列表：
{tasks}

请根据自定义日期区间长度选择总结方式：
- 如果区间不超过 7 天，按周报风格输出。
- 如果区间超过 7 天，按月报风格输出。

周报风格只输出以下两部分：
1. 已完成
- 汇总区间内已完成任务。
- 可以按主题归并，不要逐条机械罗列。

2. 下步计划
- 汇总未完成任务和接下来需要继续推进的事项。
- 不要把未完成任务写成已完成。

月报风格输出以下部分：
1. 本期完成
- 汇总区间内已完成任务，按主题归类。
- 说明主要成果和推进进展。

2. 关键进展
- 提炼这段时间最重要的变化、突破或积累。

3. 问题与风险
- 基于未完成任务和任务内容，总结阻塞、延期或需要注意的问题。
- 没有明显问题可写“无”。

4. 下步计划
- 根据未完成任务和任务内容，整理后续要继续推进的事项。

通用要求：
- 已完成、本期完成、关键进展只能来自已完成任务。
- 下步计划主要来自未完成任务。
- 不要把未完成任务写成已完成成果。''';

const _separatedDefaultSummaryTemplate = '''
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

const _previousDefaultSummaryTemplate = '''
请根据以下任务生成{period}总结：
{tasks}

生成总结时突出亮点、改进建议和下步计划。''';

String defaultSummaryTemplateFor(PeriodType type) {
  return switch (type) {
    PeriodType.daily => defaultDailySummaryTemplate,
    PeriodType.weekly => defaultWeeklySummaryTemplate,
    PeriodType.monthly => defaultMonthlySummaryTemplate,
    PeriodType.yearly => defaultYearlySummaryTemplate,
    PeriodType.custom => defaultCustomSummaryTemplate,
  };
}

bool isLegacyDefaultSummaryTemplate(String template) {
  final cleanTemplate = template.trim();
  return legacyDefaultSummaryTemplates
      .any((legacyTemplate) => legacyTemplate.trim() == cleanTemplate);
}

String renderSummaryPrompt({
  required String template,
  required PeriodType periodType,
  required List<TaskRecord> tasks,
  required List<String> tags,
  String? periodText,
  int? periodDays,
}) {
  return template
      .replaceAll('{tasks}', formatTasksForPrompt(tasks))
      .replaceAll('{period}', periodText ?? periodType.placeholderName)
      .replaceAll('{period_days}', periodDays?.toString() ?? '')
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
