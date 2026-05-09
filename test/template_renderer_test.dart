import 'package:aimemo/src/models/period_type.dart';
import 'package:aimemo/src/models/task_record.dart';
import 'package:aimemo/src/services/template_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renders supported placeholders', () {
    final prompt = renderSummaryPrompt(
      template: '请总结{period}：\n{tasks}\n标签：{tags}',
      periodType: PeriodType.daily,
      tags: ['工作'],
      tasks: [
        TaskRecord(
          id: 1,
          title: '完成需求设计',
          content: '整理待办和日报生成流程',
          tags: const ['工作'],
          createdAt: DateTime(2026, 5, 9, 10, 30),
          completedAt: DateTime(2026, 5, 9, 12),
        ),
      ],
    );

    expect(prompt, contains('今天'));
    expect(prompt, contains('[完成] 完成需求设计'));
    expect(prompt, contains('整理待办和日报生成流程'));
    expect(prompt, contains('标签：工作'));
  });

  test('uses all tags fallback when no tag filter is selected', () {
    final prompt = renderSummaryPrompt(
      template: '{tags}',
      periodType: PeriodType.weekly,
      tags: const [],
      tasks: const [],
    );

    expect(prompt, '全部标签');
  });
}
