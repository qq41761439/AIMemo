import '../models/period_type.dart';
import '../models/summary_record.dart';
import '../models/task_record.dart';
import 'memo_store.dart';
import 'template_renderer.dart';
import 'task_sorting.dart';

class InMemoryMemoStore implements MemoStore {
  InMemoryMemoStore() {
    _seedDemoData();
  }

  final List<TaskRecord> _tasks = <TaskRecord>[];
  final List<SummaryRecord> _summaries = <SummaryRecord>[];
  final Map<PeriodType, String> _templates = {
    for (final type in PeriodType.values) type: defaultSummaryTemplate,
  };
  int _nextTaskId = 1;
  int _nextSummaryId = 1;

  @override
  Future<void> close() async {}

  @override
  Future<int> addTask({
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('任务标题不能为空。');
    }

    final task = TaskRecord(
      id: _nextTaskId++,
      title: cleanTitle,
      content: content.trim(),
      tags: _cleanTags(tags),
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    return task.id;
  }

  @override
  Future<List<TaskRecord>> listTasks({List<String> tagNames = const []}) async {
    final tags = _cleanTags(tagNames);
    return _filterTasks(tags: tags)..sort(compareTasksForList);
  }

  @override
  Future<List<TaskRecord>> listTasksForPeriod({
    required DateTime start,
    required DateTime end,
    List<String> tagNames = const [],
  }) async {
    final tags = _cleanTags(tagNames);
    return _filterTasks(tags: tags)
        .where((task) =>
            !task.createdAt.isBefore(start) && task.createdAt.isBefore(end))
        .toList()
      ..sort(compareTasksForList);
  }

  @override
  Future<void> setTaskCompleted(int taskId, bool completed) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }
    final task = _tasks[index];
    _tasks[index] = TaskRecord(
      id: task.id,
      title: task.title,
      content: task.content,
      tags: task.tags,
      createdAt: task.createdAt,
      completedAt: completed ? DateTime.now() : null,
      deletedAt: task.deletedAt,
    );
  }

  @override
  Future<void> deleteTask(int taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      return;
    }
    final task = _tasks[index];
    _tasks[index] = TaskRecord(
      id: task.id,
      title: task.title,
      content: task.content,
      tags: task.tags,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      deletedAt: DateTime.now(),
    );
  }

  @override
  Future<List<String>> listTags() async {
    final tags = <String>{};
    for (final task in _tasks.where((task) => task.deletedAt == null)) {
      tags.addAll(task.tags);
    }
    return tags.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  @override
  Future<String> getTemplate(PeriodType type) async {
    return _templates[type] ?? defaultSummaryTemplate;
  }

  @override
  Future<void> saveTemplate(PeriodType type, String content) async {
    _templates[type] = content;
  }

  @override
  Future<void> resetTemplate(PeriodType type) async {
    _templates[type] = defaultSummaryTemplate;
  }

  @override
  Future<int> insertSummary({
    required PeriodType periodType,
    required String periodLabel,
    required DateTime periodStart,
    required DateTime periodEnd,
    required List<String> tagFilter,
    required List<int> taskIds,
    required String prompt,
    required String output,
  }) async {
    final summary = SummaryRecord(
      id: _nextSummaryId++,
      periodType: periodType,
      periodLabel: periodLabel,
      periodStart: periodStart,
      periodEnd: periodEnd,
      tagFilter: List.unmodifiable(tagFilter),
      taskIds: List.unmodifiable(taskIds),
      prompt: prompt,
      output: output,
      createdAt: DateTime.now(),
    );
    _summaries.add(summary);
    return summary.id;
  }

  @override
  Future<List<SummaryRecord>> listSummaries() async {
    return [..._summaries]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<TaskRecord> _filterTasks({required List<String> tags}) {
    final tagKeys = tags.map((tag) => tag.toLowerCase()).toSet();
    return _tasks.where((task) {
      if (task.deletedAt != null) {
        return false;
      }
      if (tagKeys.isEmpty) {
        return true;
      }
      final taskTagKeys = task.tags.map((tag) => tag.toLowerCase()).toSet();
      return tagKeys.any(taskTagKeys.contains);
    }).toList();
  }

  List<String> _cleanTags(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag
        in tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty)) {
      final key = tag.toLowerCase();
      if (seen.add(key)) {
        result.add(tag);
      }
    }
    return result;
  }

  void _seedDemoData() {
    final now = DateTime.now();
    final todayMorning = DateTime(now.year, now.month, now.day, 9, 20);
    final yesterday = todayMorning.subtract(const Duration(days: 1));

    _tasks.addAll([
      TaskRecord(
        id: _nextTaskId++,
        title: '梳理 AIMemo 第一版交互',
        content: '确认任务列表、标签筛选、周期总结和模板配置的主流程。',
        tags: const ['工作', '产品'],
        createdAt: todayMorning,
        completedAt: todayMorning.add(const Duration(hours: 1, minutes: 10)),
      ),
      TaskRecord(
        id: _nextTaskId++,
        title: '补充日报生成 Prompt',
        content: '让总结突出亮点、风险、改进建议和下一步计划。',
        tags: const ['工作', 'AI'],
        createdAt: todayMorning.add(const Duration(hours: 2)),
      ),
      TaskRecord(
        id: _nextTaskId++,
        title: '检查 Xcode 安装进度',
        content: 'Xcode 完成后切到 macOS 桌面版，验证 SQLite 持久化。',
        tags: const ['工具', '环境'],
        createdAt: todayMorning.add(const Duration(hours: 3, minutes: 25)),
      ),
      TaskRecord(
        id: _nextTaskId++,
        title: '阅读 Flutter 桌面布局文档',
        content: '关注窗口尺寸、滚动容器和桌面端信息密度。',
        tags: const ['学习', 'Flutter'],
        createdAt: yesterday.add(const Duration(hours: 5)),
        completedAt: yesterday.add(const Duration(hours: 6, minutes: 30)),
      ),
      TaskRecord(
        id: _nextTaskId++,
        title: '整理本周复盘素材',
        content: '把产品推进、技术债和下周计划拆成三组。',
        tags: const ['复盘', '生活'],
        createdAt: yesterday.add(const Duration(hours: 8)),
      ),
    ]);

    _summaries.add(
      SummaryRecord(
        id: _nextSummaryId++,
        periodType: PeriodType.daily,
        periodLabel:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        periodStart: DateTime(now.year, now.month, now.day),
        periodEnd: DateTime(now.year, now.month, now.day + 1),
        tagFilter: const ['工作'],
        taskIds: const [1, 2],
        prompt: defaultSummaryTemplate,
        output:
            '今天主要推进了 AIMemo 第一版的产品交互和总结模板设计。亮点是任务、标签、周期总结的主链路已经清晰；下一步可以优先验证模型生成质量，并在桌面端完成本地持久化验收。',
        createdAt: now.subtract(const Duration(minutes: 20)),
      ),
    );
  }
}
