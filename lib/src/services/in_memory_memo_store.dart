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
  final Map<String, DateTime> _tagTouchedAt = <String, DateTime>{};
  final Map<String, String> _settings = <String, String>{};
  final Map<PeriodType, String> _templates = {
    for (final type in PeriodType.values) type: defaultSummaryTemplateFor(type),
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

    final cleanTags = _cleanTags(tags);
    _touchTags(cleanTags);

    final task = TaskRecord(
      id: _nextTaskId++,
      title: cleanTitle,
      content: content.trim(),
      tags: cleanTags,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    return task.id;
  }

  @override
  Future<void> updateTask({
    required int taskId,
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('任务标题不能为空。');
    }

    final index = _tasks
        .indexWhere((task) => task.id == taskId && task.deletedAt == null);
    if (index == -1) {
      return;
    }
    final task = _tasks[index];
    final cleanTags = _cleanTags(tags);
    _touchTags(cleanTags);
    _tasks[index] = TaskRecord(
      id: task.id,
      title: cleanTitle,
      content: content.trim(),
      tags: cleanTags,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      deletedAt: task.deletedAt,
    );
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
  Future<void> restoreTask(int taskId) async {
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
    );
    _touchTags(task.tags);
  }

  @override
  Future<List<String>> listTags() async {
    final seen = <String>{};
    final tags = <String>[];
    final tasks = _tasks.where((task) => task.deletedAt == null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final task in tasks) {
      for (final tag in task.tags) {
        if (seen.add(tag.toLowerCase())) {
          tags.add(tag);
        }
      }
    }
    tags.sort((a, b) {
      final touchedCompare = (_tagTouchedAt[b.toLowerCase()] ?? DateTime(0))
          .compareTo(_tagTouchedAt[a.toLowerCase()] ?? DateTime(0));
      if (touchedCompare != 0) {
        return touchedCompare;
      }
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return tags;
  }

  @override
  Future<double?> getActionPaneWidth() async {
    return double.tryParse(_settings['action_pane_width'] ?? '');
  }

  @override
  Future<void> saveActionPaneWidth(double width) async {
    _settings['action_pane_width'] = width.toString();
  }

  @override
  Future<String> getTemplate(PeriodType type) async {
    final content = _templates[type] ?? defaultSummaryTemplateFor(type);
    if (isLegacyDefaultSummaryTemplate(content)) {
      final defaultTemplate = defaultSummaryTemplateFor(type);
      _templates[type] = defaultTemplate;
      return defaultTemplate;
    }
    return content;
  }

  @override
  Future<void> saveTemplate(PeriodType type, String content) async {
    _templates[type] = content;
  }

  @override
  Future<void> resetTemplate(PeriodType type) async {
    _templates[type] = defaultSummaryTemplateFor(type);
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

  void _touchTags(List<String> tags) {
    for (final tag in tags) {
      _tagTouchedAt[tag.toLowerCase()] = DateTime.now();
    }
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
    for (final task in _tasks) {
      for (final tag in task.tags) {
        final key = tag.toLowerCase();
        final existing = _tagTouchedAt[key];
        if (existing == null || task.createdAt.isAfter(existing)) {
          _tagTouchedAt[key] = task.createdAt;
        }
      }
    }

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
