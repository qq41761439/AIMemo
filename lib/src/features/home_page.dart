import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/period_type.dart';
import '../models/task_record.dart';
import '../providers.dart';
import '../services/period_utils.dart';
import '../services/template_renderer.dart';

const _ink = Color(0xFF202622);
const _muted = Color(0xFF68716A);
const _faint = Color(0xFFF4F5F2);
const _panel = Color(0xFFFFFFFF);
const _border = Color(0xFFDDE2DC);
const _accent = Color(0xFF2F6F5E);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final workspaceWidth =
                constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;

            return ColoredBox(
              color: _faint,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: workspaceWidth,
                  height: constraints.maxHeight,
                  child: const Row(
                    children: [
                      Expanded(child: _TaskListPane()),
                      VerticalDivider(width: 1),
                      SizedBox(width: 440, child: _ActionPane()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TaskListPane extends ConsumerWidget {
  const _TaskListPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final tags = ref.watch(tagListProvider);
    final selectedTags = ref.watch(taskTagFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TaskPaneHeader(),
          const SizedBox(height: 16),
          _TaskFilterBar(selectedTags: selectedTags, tags: tags),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyHint(text: '还没有任务，先从右侧添加一个。');
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) =>
                      _TaskTile(task: items[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorText(error.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPaneHeader extends StatelessWidget {
  const _TaskPaneHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.checklist_rtl,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AIMemo', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 3),
                  Text('待办、标签和周期总结', style: _captionStyle(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskFilterBar extends ConsumerWidget {
  const _TaskFilterBar({
    required this.selectedTags,
    required this.tags,
  });

  final Set<String> selectedTags;
  final AsyncValue<List<String>> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 10),
              child: _SectionLabel('标签'),
            ),
            Expanded(
              child: tags.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Text('添加任务后会出现标签。', style: _captionStyle(context));
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: selectedTags.isEmpty,
                        onSelected: (_) {
                          ref.read(taskTagFilterProvider.notifier).state =
                              <String>{};
                        },
                      ),
                      for (final tag in items)
                        FilterChip(
                          label: Text(tag),
                          selected: selectedTags.contains(tag),
                          onSelected: (selected) {
                            final next = {...selectedTags};
                            selected ? next.add(tag) : next.remove(tag);
                            ref.read(taskTagFilterProvider.notifier).state =
                                next;
                          },
                        ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => _ErrorText(error.toString()),
              ),
            ),
            if (selectedTags.isNotEmpty) ...[
              const SizedBox(width: 10),
              IconButton(
                tooltip: '清除筛选',
                onPressed: () {
                  ref.read(taskTagFilterProvider.notifier).state = <String>{};
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final TaskRecord task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completed = task.isCompleted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFF8F9F7) : _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed ? const Color(0xFFE3E6E1) : _border,
        ),
        boxShadow: completed
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A101410),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Checkbox(
                value: task.isCompleted,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (value) async {
                  final completed = value ?? false;
                  await ref
                      .read(appDatabaseProvider)
                      .setTaskCompleted(task.id, completed);
                  final completedAt = completed ? DateTime.now() : null;
                  final selectedTask = ref.read(selectedTaskProvider);
                  if (selectedTask?.id == task.id) {
                    ref.read(selectedTaskProvider.notifier).state =
                        selectedTask!.copyWith(
                      completedAt: completedAt,
                      clearCompletedAt: !completed,
                    );
                  }
                  final editingTask = ref.read(editingTaskProvider);
                  if (editingTask?.id == task.id) {
                    ref.read(editingTaskProvider.notifier).state =
                        editingTask!.copyWith(
                      completedAt: completedAt,
                      clearCompletedAt: !completed,
                    );
                  }
                  ref.invalidate(taskListProvider);
                },
              ),
            ),
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(editingTaskProvider.notifier).state = null;
                    ref.read(selectedTaskProvider.notifier).state = task;
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: completed ? _muted : _ink,
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '创建 ${compactDateTime(task.createdAt)}',
                            style: _captionStyle(context),
                          ),
                          if (task.completedAt != null)
                            Text(
                              '完成 ${compactDateTime(task.completedAt!)}',
                              style: _captionStyle(context),
                            ),
                          for (final tag in task.tags) _TaskTagPill(tag),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                tooltip: '编辑任务',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  ref.read(selectedTaskProvider.notifier).state = task;
                  ref.read(editingTaskProvider.notifier).state = task;
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                tooltip: '删除任务',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final database = ref.read(appDatabaseProvider);
                  await database.deleteTask(task.id);
                  final selectedTask = ref.read(selectedTaskProvider);
                  if (selectedTask?.id == task.id) {
                    ref.read(selectedTaskProvider.notifier).state = null;
                  }
                  final editingTask = ref.read(editingTaskProvider);
                  if (editingTask?.id == task.id) {
                    ref.read(editingTaskProvider.notifier).state = null;
                  }
                  final availableTags = (await database.listTags()).toSet();
                  final selectedTags = ref.read(taskTagFilterProvider);
                  final nextSelectedTags = selectedTags
                      .where((tag) => availableTags.contains(tag))
                      .toSet();
                  if (nextSelectedTags.length != selectedTags.length) {
                    ref.read(taskTagFilterProvider.notifier).state =
                        nextSelectedTags;
                  }
                  ref.invalidate(taskListProvider);
                  ref.invalidate(tagListProvider);
                },
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTagPill extends StatelessWidget {
  const _TaskTagPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _ink,
                fontSize: 11,
                height: 1.1,
              ),
        ),
      ),
    );
  }
}

class _ActionPane extends ConsumerStatefulWidget {
  const _ActionPane();

  @override
  ConsumerState<_ActionPane> createState() => _ActionPaneState();
}

class _ActionPaneState extends ConsumerState<_ActionPane>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTask = ref.watch(selectedTaskProvider);
    final editingTask = ref.watch(editingTaskProvider);
    final firstTabLabel = editingTask != null
        ? '编辑'
        : selectedTask != null
            ? '查看'
            : '添加';
    final firstTabIcon = editingTask != null
        ? Icons.edit_outlined
        : selectedTask != null
            ? Icons.visibility_outlined
            : Icons.add_task;

    ref.listen<TaskRecord?>(selectedTaskProvider, (_, next) {
      if (next != null) {
        _tabController.animateTo(0);
      }
    });
    ref.listen<TaskRecord?>(editingTaskProvider, (_, next) {
      if (next != null) {
        _tabController.animateTo(0);
      }
    });

    return Container(
      color: _panel,
      child: Column(
        children: [
          const SizedBox(height: 4),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: Icon(firstTabIcon),
                text: firstTabLabel,
              ),
              const Tab(icon: Icon(Icons.auto_awesome_outlined), text: '总结'),
              const Tab(icon: Icon(Icons.tune), text: '模板'),
              const Tab(icon: Icon(Icons.history), text: '历史'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AddTaskPanel(),
                _SummaryPanel(),
                _TemplatePanel(),
                _HistoryPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskPanel extends ConsumerStatefulWidget {
  const _AddTaskPanel();

  @override
  ConsumerState<_AddTaskPanel> createState() => _AddTaskPanelState();
}

class _AddTaskPanelState extends ConsumerState<_AddTaskPanel> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  int? _loadedEditingTaskId;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editingTask = ref.watch(editingTaskProvider);
    final selectedTask = ref.watch(selectedTaskProvider);
    if (editingTask == null && selectedTask != null) {
      _syncEditingTask(null);
      return _TaskViewPanel(task: selectedTask);
    }

    final tags = ref.watch(tagListProvider);
    _syncEditingTask(editingTask);
    final isEditing = editingTask != null;

    return _PanelPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: isEditing ? Icons.edit_outlined : Icons.add_task,
            title: isEditing ? '编辑任务' : '添加任务',
            subtitle: isEditing ? '修改标题、内容和标签。' : '记录事项，标签用逗号分隔。',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: '标题'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(labelText: '内容'),
            minLines: 5,
            maxLines: 8,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(labelText: '标签'),
          ),
          const SizedBox(height: 12),
          tags.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in items)
                  ActionChip(
                    label: Text(tag),
                    onPressed: () => _appendTag(tag),
                  ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Spacer(),
          Row(
            children: [
              if (isEditing) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelEditing,
                    icon: const Icon(Icons.close),
                    label: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(isEditing ? '保存修改' : '添加任务'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _syncEditingTask(TaskRecord? task) {
    if (_loadedEditingTaskId == task?.id) {
      return;
    }
    _loadedEditingTaskId = task?.id;

    if (task == null) {
      _titleController.clear();
      _contentController.clear();
      _tagsController.clear();
      return;
    }

    _titleController.text = task.title;
    _contentController.text = task.content;
    _tagsController.text = task.tags.join(', ');
  }

  void _appendTag(String tag) {
    final current = _parseTags(_tagsController.text);
    if (!current
        .map((item) => item.toLowerCase())
        .contains(tag.toLowerCase())) {
      current.add(tag);
      _tagsController.text = current.join(', ');
    }
  }

  Future<void> _submit() async {
    try {
      final editingTask = ref.read(editingTaskProvider);
      final title = _titleController.text;
      final content = _contentController.text;
      final taskTags = _parseTags(_tagsController.text);
      if (editingTask == null) {
        await ref.read(appDatabaseProvider).addTask(
              title: title,
              content: content,
              tags: taskTags,
            );
      } else {
        await ref.read(appDatabaseProvider).updateTask(
              taskId: editingTask.id,
              title: title,
              content: content,
              tags: taskTags,
            );
      }
      _titleController.clear();
      _contentController.clear();
      _tagsController.clear();
      if (editingTask == null) {
        ref.read(selectedTaskProvider.notifier).state = null;
      } else {
        ref.read(selectedTaskProvider.notifier).state = editingTask.copyWith(
          title: title.trim(),
          content: content.trim(),
          tags: taskTags,
        );
      }
      ref.read(editingTaskProvider.notifier).state = null;
      ref.invalidate(taskListProvider);
      ref.invalidate(tagListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(editingTask == null ? '任务已添加。' : '任务已更新。')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  void _cancelEditing() {
    ref.read(editingTaskProvider.notifier).state = null;
  }
}

class _TaskViewPanel extends ConsumerWidget {
  const _TaskViewPanel({required this.task});

  final TaskRecord task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PanelPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.visibility_outlined,
            title: '查看任务',
            subtitle: '查看当前任务的完整内容。',
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: task.isCompleted ? _muted : _ink,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  const SizedBox(height: 14),
                  const _SectionLabel('内容'),
                  const SizedBox(height: 6),
                  SelectableText(
                    task.content.trim().isEmpty ? '无内容' : task.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: task.content.trim().isEmpty
                              ? _muted
                              : const Color(0xFF3F4742),
                        ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionLabel('标签'),
                  const SizedBox(height: 8),
                  if (task.tags.isEmpty)
                    Text('无标签', style: _captionStyle(context))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in task.tags) _TaskTagPill(tag),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const _SectionLabel('时间'),
                  const SizedBox(height: 8),
                  _TaskMetaLine(
                    icon: Icons.calendar_today_outlined,
                    text: '创建 ${compactDateTime(task.createdAt)}',
                  ),
                  if (task.completedAt != null) ...[
                    const SizedBox(height: 6),
                    _TaskMetaLine(
                      icon: Icons.task_alt,
                      text: '完成 ${compactDateTime(task.completedAt!)}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(selectedTaskProvider.notifier).state = null;
                    ref.read(editingTaskProvider.notifier).state = null;
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('新建任务'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ref.read(editingTaskProvider.notifier).state = task;
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑任务'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskMetaLine extends StatelessWidget {
  const _TaskMetaLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: _muted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: _captionStyle(context))),
      ],
    );
  }
}

class _SummaryPanel extends ConsumerStatefulWidget {
  const _SummaryPanel();

  @override
  ConsumerState<_SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends ConsumerState<_SummaryPanel> {
  PeriodType _periodType = PeriodType.daily;
  late PeriodRange _selectedRange;
  final Set<String> _selectedTags = <String>{};
  bool _isGenerating = false;
  String? _latestSummary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedRange = periodRangeFor(_periodType, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagListProvider);

    return _PanelPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.auto_awesome_outlined,
            title: '生成总结',
            subtitle: '按周期和标签收集任务，交给模型复盘。',
          ),
          const SizedBox(height: 16),
          _SummaryRangeSelector(
            periodType: _periodType,
            range: _selectedRange,
            onPeriodChanged: _changePeriod,
            onPickRange: _pickDateRange,
            onReset: _resetDateRange,
          ),
          const SizedBox(height: 14),
          const _SectionLabel('标签过滤'),
          const SizedBox(height: 8),
          tags.when(
            data: (items) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('全部标签'),
                  selected: _selectedTags.isEmpty,
                  onSelected: (_) => setState(_selectedTags.clear),
                ),
                for (final tag in items)
                  FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    onSelected: (selected) {
                      setState(() {
                        selected
                            ? _selectedTags.add(tag)
                            : _selectedTags.remove(tag);
                      });
                    },
                  ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _ErrorText(error.toString()),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generate,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGenerating ? '生成中' : '生成总结'),
          ),
          const SizedBox(height: 18),
          if (_error != null) _ErrorText(_error!),
          if (_latestSummary != null) ...[
            Row(
              children: [
                Text('最新总结', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: '复制总结',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _latestSummary!));
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _faint,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(_latestSummary!),
                ),
              ),
            ),
          ] else
            const Expanded(
              child: _EmptyHint(text: '选择周期和标签后生成总结。'),
            ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final database = ref.read(appDatabaseProvider);
      final range = _selectedRange;
      final selectedTags = _selectedTags.toList()..sort();
      final tasks = await database.listTasksForPeriod(
        start: range.start,
        end: range.end,
        tagNames: selectedTags,
      );

      if (tasks.isEmpty) {
        throw Exception('当前周期没有可总结任务。');
      }

      final template = await database.getTemplate(_periodType);
      final periodText = '${_periodType.placeholderName}（${range.label}）';
      final prompt = renderSummaryPrompt(
        template: template,
        periodType: _periodType,
        tasks: tasks,
        tags: selectedTags,
        periodText: periodText,
      );
      final summary = await ref.read(summaryApiClientProvider).generateSummary(
            period: periodText,
            tags: selectedTags,
            tasks: formatTasksForPrompt(tasks),
            template: template,
            prompt: prompt,
          );

      await database.insertSummary(
        periodType: _periodType,
        periodLabel: range.label,
        periodStart: range.start,
        periodEnd: range.end,
        tagFilter: selectedTags,
        taskIds: tasks.map((task) => task.id).toList(),
        prompt: prompt,
        output: summary,
      );

      ref.invalidate(summaryHistoryProvider);
      if (!mounted) {
        return;
      }
      setState(() => _latestSummary = summary);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _changePeriod(PeriodType value) {
    setState(() {
      _periodType = value;
      if (value == PeriodType.custom) {
        _selectedRange = PeriodRange(
          start: _selectedRange.start,
          end: _selectedRange.end,
          label: dateRangeLabel(_selectedRange.start, _selectedRange.end),
        );
      } else {
        _selectedRange = periodRangeFor(value, DateTime.now());
      }
    });
  }

  void _resetDateRange() {
    setState(() {
      _selectedRange = periodRangeFor(_periodType, DateTime.now());
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final minDate = DateTime(2000);
    final maxDate = DateTime(now.year + 5, 12, 31);

    if (_periodType == PeriodType.custom) {
      final initialEnd = _selectedRange.end.subtract(const Duration(days: 1));
      final picked = await showRangePickerDialog(
        context: context,
        minDate: minDate,
        maxDate: maxDate,
        displayedDate: _selectedRange.start,
        selectedRange: DateTimeRange(
          start: _selectedRange.start,
          end: initialEnd,
        ),
        initialPickerType: PickerType.days,
      );
      if (picked == null || !mounted) {
        return;
      }

      final start = _dateOnly(picked.start);
      final end = _dateOnly(picked.end).add(const Duration(days: 1));
      setState(() {
        _selectedRange = PeriodRange(
          start: start,
          end: end,
          label: dateRangeLabel(start, end),
        );
      });
      return;
    }

    final picked = await showDatePickerDialog(
      context: context,
      minDate: minDate,
      maxDate: maxDate,
      displayedDate: _selectedRange.start,
      selectedDate: _selectedRange.start,
      initialPickerType: switch (_periodType) {
        PeriodType.monthly => PickerType.months,
        PeriodType.yearly => PickerType.years,
        _ => PickerType.days,
      },
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedRange = periodRangeFor(_periodType, picked);
    });
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class _TemplatePanel extends ConsumerStatefulWidget {
  const _TemplatePanel();

  @override
  ConsumerState<_TemplatePanel> createState() => _TemplatePanelState();
}

class _TemplatePanelState extends ConsumerState<_TemplatePanel> {
  final _controller = TextEditingController();
  PeriodType _periodType = PeriodType.daily;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PanelPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.tune,
            title: '模板配置',
            subtitle: '支持 {period}、{tasks}、{tags}。',
          ),
          const SizedBox(height: 16),
          _TemplatePeriodSelector(
            value: _periodType,
            onChanged: (value) {
              setState(() {
                _periodType = value;
                _loaded = false;
              });
              _loadTemplate();
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: _loaded,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: '提示词模板',
                hintText: '{period} {tasks} {tags}',
              ),
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loaded ? _reset : null,
                  icon: const Icon(Icons.restore),
                  label: const Text('恢复默认'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loaded ? _save : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存模板'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _loadTemplate() async {
    final content =
        await ref.read(appDatabaseProvider).getTemplate(_periodType);
    if (!mounted) {
      return;
    }
    setState(() {
      _controller.text = content;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await ref.read(appDatabaseProvider).saveTemplate(
          _periodType,
          _controller.text,
        );
    ref.invalidate(templateProvider(_periodType));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模板已保存。')),
      );
    }
  }

  Future<void> _reset() async {
    await ref.read(appDatabaseProvider).resetTemplate(_periodType);
    await _loadTemplate();
    ref.invalidate(templateProvider(_periodType));
  }
}

class _HistoryPanel extends ConsumerWidget {
  const _HistoryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(summaryHistoryProvider);

    return _PanelPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.history,
            title: '总结历史',
            subtitle: '生成后的总结会自动保存在这里。',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: summaries.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyHint(text: '生成的总结会保存在这里。');
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final tags = item.tagFilter.isEmpty
                        ? '全部标签'
                        : item.tagFilter.join('、');
                    return ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                          '${item.periodType.title} · ${item.periodLabel}'),
                      subtitle:
                          Text('$tags · ${compactDateTime(item.createdAt)}'),
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: '复制总结',
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: item.output));
                            },
                            icon: const Icon(Icons.copy_all_outlined),
                          ),
                        ),
                        SelectableText(item.output),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorText(error.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelPadding extends StatelessWidget {
  const _PanelPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE4ECE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 19, color: _accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(subtitle, style: _captionStyle(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRangeSelector extends StatelessWidget {
  const _SummaryRangeSelector({
    required this.periodType,
    required this.range,
    required this.onPeriodChanged,
    required this.onPickRange,
    required this.onReset,
  });

  final PeriodType periodType;
  final PeriodRange range;
  final ValueChanged<PeriodType> onPeriodChanged;
  final VoidCallback onPickRange;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<PeriodType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: PeriodType.daily, label: Text('日')),
                ButtonSegment(value: PeriodType.weekly, label: Text('周')),
                ButtonSegment(value: PeriodType.monthly, label: Text('月')),
                ButtonSegment(value: PeriodType.yearly, label: Text('年')),
                ButtonSegment(value: PeriodType.custom, label: Text('自定义')),
              ],
              selected: {periodType},
              onSelectionChanged: (selected) {
                onPeriodChanged(selected.first);
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('日期区间', style: _captionStyle(context)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    range.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: '重置日期区间',
                  visualDensity: VisualDensity.compact,
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt, size: 20),
                ),
                IconButton(
                  tooltip: '选择日期区间',
                  visualDensity: VisualDensity.compact,
                  onPressed: onPickRange,
                  icon: const Icon(Icons.date_range_outlined, size: 20),
                ),
              ],
            ),
            Text(
              _rangeHint(periodType),
              style: _captionStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  String _rangeHint(PeriodType type) {
    return switch (type) {
      PeriodType.daily => '选择任意日期后汇总当天任务。',
      PeriodType.weekly => '选择任意日期后自动汇总所在周。',
      PeriodType.monthly => '选择月份后汇总整月任务。',
      PeriodType.yearly => '选择年份后汇总全年任务。',
      PeriodType.custom => '选择开始和结束日期后汇总自定义区间。',
    };
  }
}

class _TemplatePeriodSelector extends StatelessWidget {
  const _TemplatePeriodSelector({
    required this.value,
    required this.onChanged,
  });

  final PeriodType value;
  final ValueChanged<PeriodType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('总结类型', style: _captionStyle(context)),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PeriodType>(
                  value: value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(8),
                  dropdownColor: _panel,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                      ),
                  items: [
                    for (final type in PeriodType.values)
                      DropdownMenuItem(
                        value: type,
                        child: Text(type.title),
                      ),
                  ],
                  onChanged: (next) {
                    if (next != null) {
                      onChanged(next);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: _ink,
            letterSpacing: 0,
          ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _muted),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
    );
  }
}

TextStyle? _captionStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodySmall?.copyWith(color: _muted);
}

List<String> _parseTags(String value) {
  final seen = <String>{};
  final result = <String>[];
  for (final tag in value
      .split(RegExp(r'[,，]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)) {
    final key = tag.toLowerCase();
    if (seen.add(key)) {
      result.add(tag);
    }
  }
  return result;
}
