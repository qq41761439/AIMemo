import 'dart:convert';

import 'period_type.dart';

class SummaryRecord {
  const SummaryRecord({
    required this.id,
    required this.periodType,
    required this.periodLabel,
    required this.periodStart,
    required this.periodEnd,
    required this.tagFilter,
    required this.taskIds,
    required this.prompt,
    required this.output,
    required this.createdAt,
  });

  final int id;
  final PeriodType periodType;
  final String periodLabel;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<String> tagFilter;
  final List<int> taskIds;
  final String prompt;
  final String output;
  final DateTime createdAt;

  factory SummaryRecord.fromDb(Map<String, Object?> row) {
    return SummaryRecord(
      id: row['id'] as int,
      periodType: PeriodType.fromValue(row['period_type'] as String),
      periodLabel: row['period_label'] as String,
      periodStart: DateTime.parse(row['period_start'] as String),
      periodEnd: DateTime.parse(row['period_end'] as String),
      tagFilter: (jsonDecode(row['tag_filter'] as String) as List<dynamic>)
          .cast<String>(),
      taskIds: (jsonDecode(row['task_ids'] as String) as List<dynamic>)
          .map((id) => id as int)
          .toList(),
      prompt: row['prompt'] as String,
      output: row['output'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
