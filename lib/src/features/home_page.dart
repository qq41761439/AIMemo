import 'dart:async';

import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/model_settings.dart';
import '../models/period_type.dart';
import '../models/task_record.dart';
import '../providers.dart';
import '../services/memo_store.dart';
import '../services/model_settings_repository.dart';
import '../services/period_utils.dart';
import '../services/template_renderer.dart';

const _ink = Color(0xFF202622);
const _muted = Color(0xFF68716A);
const _faint = Color(0xFFF4F5F2);
const _panel = Color(0xFFFFFFFF);
const _border = Color(0xFFDDE2DC);
const _accent = Color(0xFF2F6F5E);
const _accentSoft = Color(0xFFE4ECE7);
const _controlHeight = 40.0;
const _controlRadius = 6.0;
const _defaultActionPaneWidth = 520.0;
const _minActionPaneWidth = 380.0;
const _maxActionPaneWidth = 720.0;
const _minTaskPaneWidth = 420.0;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  double _actionPaneWidth = _defaultActionPaneWidth;
  late final MemoStore _database;
  Timer? _saveActionPaneWidthTimer;

  @override
  void initState() {
    super.initState();
    _database = ref.read(appDatabaseProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActionPaneWidth();
    });
  }

  @override
  void dispose() {
    _saveActionPaneWidthTimer?.cancel();
    unawaited(_database.saveActionPaneWidth(_actionPaneWidth));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final workspaceWidth =
                constraints.maxWidth < 980 ? 980.0 : constraints.maxWidth;
            final maxActionPaneWidth = _maxActionPaneWidthFor(workspaceWidth);
            final actionPaneWidth =
                _clampActionPaneWidth(_actionPaneWidth, maxActionPaneWidth);

            return ColoredBox(
              color: _faint,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: workspaceWidth,
                  height: constraints.maxHeight,
                  child: Row(
                    children: [
                      const Expanded(child: _TaskListPane()),
                      _PaneDivider(
                        onDragUpdate: (details) {
                          final nextWidth = _clampActionPaneWidth(
                            _actionPaneWidth - details.delta.dx,
                            maxActionPaneWidth,
                          );
                          setState(() {
                            _actionPaneWidth = nextWidth;
                          });
                          _scheduleActionPaneWidthSave(nextWidth);
                        },
                      ),
                      SizedBox(
                        width: actionPaneWidth,
                        child: const _ActionPane(),
                      ),
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

  double _maxActionPaneWidthFor(double workspaceWidth) {
    final availableWidth =
        workspaceWidth - _minTaskPaneWidth - _PaneDivider.width;
    return availableWidth
        .clamp(_minActionPaneWidth, _maxActionPaneWidth)
        .toDouble();
  }

  double _clampActionPaneWidth(double width, double maxWidth) {
    return width.clamp(_minActionPaneWidth, maxWidth).toDouble();
  }

  Future<void> _loadActionPaneWidth() async {
    final savedWidth = await _database.getActionPaneWidth();
    if (!mounted || savedWidth == null) {
      return;
    }
    setState(() => _actionPaneWidth = savedWidth);
  }

  void _scheduleActionPaneWidthSave(double width) {
    _saveActionPaneWidthTimer?.cancel();
    _saveActionPaneWidthTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_database.saveActionPaneWidth(width));
    });
  }
}

class _PaneDivider extends StatelessWidget {
  const _PaneDivider({required this.onDragUpdate});

  static const width = 10.0;

  final GestureDragUpdateCallback onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: onDragUpdate,
        child: SizedBox(
          width: width,
          child: Center(
            child: Container(
              width: 1,
              color: _border,
            ),
          ),
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
                onPressed: () => _deleteTask(context, ref),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTask(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定删除“${task.title}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

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
    ref.invalidate(taskListProvider);
    ref.invalidate(tagListProvider);
    await _pruneTaskTagFilter(ref, database);

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('任务已删除。'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            unawaited(_restoreTask(ref, database));
          },
        ),
      ),
    );
  }

  Future<void> _restoreTask(WidgetRef ref, MemoStore database) async {
    await database.restoreTask(task.id);
    ref.invalidate(taskListProvider);
    ref.invalidate(tagListProvider);
    await _pruneTaskTagFilter(ref, database);
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
    _tabController = TabController(length: 3, vsync: this);
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
              const Tab(icon: Icon(Icons.history), text: '历史'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _KeepAlivePane(child: _AddTaskPanel()),
                _KeepAlivePane(child: _SummaryPanel()),
                _KeepAlivePane(child: _HistoryPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeepAlivePane extends StatefulWidget {
  const _KeepAlivePane({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePane> createState() => _KeepAlivePaneState();
}

class _KeepAlivePaneState extends State<_KeepAlivePane>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
  bool _isSaving = false;

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
                    onPressed: _isSaving ? null : _cancelEditing,
                    icon: const Icon(Icons.close),
                    label: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(
                    _isSaving
                        ? '保存中'
                        : isEditing
                            ? '保存修改'
                            : '添加任务',
                  ),
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
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
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
      await _pruneTaskTagFilter(ref, ref.read(appDatabaseProvider));
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
  final _templateController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  bool _isGenerating = false;
  bool _templateLoaded = false;
  bool _templateExpanded = false;
  String _loadedTemplateContent = '';
  String? _latestSummary;
  String? _error;

  bool get _templateDirty =>
      _templateLoaded && _templateController.text != _loadedTemplateContent;

  @override
  void initState() {
    super.initState();
    _templateController.addListener(_handleTemplateChanged);
    _selectedRange = periodRangeFor(_periodType, DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplate();
    });
  }

  @override
  void dispose() {
    _templateController.removeListener(_handleTemplateChanged);
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagListProvider);
    final modelSettings = ref.watch(modelSettingsProvider);

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
          _ConfigRow(
            label: '模型配置',
            icon: Icons.settings_outlined,
            child: _ModelSettingsButton(
              settings: modelSettings,
              onPressed: () {
                unawaited(_openModelSettings());
              },
            ),
          ),
          const SizedBox(height: 10),
          _ConfigRow(
            label: '周期日期',
            icon: Icons.date_range_outlined,
            child: _SummaryRangeSelector(
              periodType: _periodType,
              range: _selectedRange,
              onPeriodChanged: (value) {
                unawaited(_changePeriod(value));
              },
              onPickRange: _pickDateRange,
            ),
          ),
          const SizedBox(height: 10),
          _ConfigRow(
            label: '模板',
            icon: Icons.tune,
            alignTop: _templateExpanded,
            child: _InlineTemplateEditor(
              periodType: _periodType,
              controller: _templateController,
              loaded: _templateLoaded,
              expanded: _templateExpanded,
              dirty: _templateDirty,
              onToggleExpanded: () {
                setState(() => _templateExpanded = !_templateExpanded);
              },
              onSave: () {
                unawaited(_saveTemplate());
              },
              onReset: () {
                unawaited(_resetTemplate());
              },
            ),
          ),
          const SizedBox(height: 10),
          _ConfigRow(
            label: '标签过滤',
            icon: Icons.filter_alt_outlined,
            alignTop: true,
            child: _SummaryTagFilter(
              tags: tags,
              selectedTags: _selectedTags,
              onPrune: _pruneSummaryTags,
              onSelectAll: () => setState(_selectedTags.clear),
              onTagSelected: (tag, selected) {
                setState(() {
                  selected ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                });
              },
            ),
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
                    _showSnackBar('总结已复制。');
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
    if (_templateDirty) {
      final shouldSave = await _confirmSaveTemplateBeforeGenerate();
      if (!shouldSave) {
        return;
      }
      await _saveTemplate(showMessage: false);
      if (!mounted) {
        return;
      }
    }
    setState(() {
      _isGenerating = true;
      _error = null;
      _latestSummary = null;
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
      final llmConfig =
          await ref.read(modelSettingsRepositoryProvider).requestConfig();
      final periodText = '${_periodType.placeholderName}（${range.label}）';
      final periodDays = range.end.difference(range.start).inDays;
      final prompt = renderSummaryPrompt(
        template: template,
        periodType: _periodType,
        tasks: tasks,
        tags: selectedTags,
        periodText: periodText,
        periodDays: periodDays,
      );
      final summary = await ref.read(summaryApiClientProvider).generateSummary(
            period: periodText,
            tags: selectedTags,
            tasks: formatTasksForPrompt(tasks),
            template: template,
            prompt: prompt,
            periodDays: periodDays,
            llmConfig: llmConfig,
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
      _showSnackBar('总结已生成并保存到历史。');
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

  Future<void> _openModelSettings() async {
    final repository = ref.read(modelSettingsRepositoryProvider);
    final settings = await repository.load();
    if (!mounted) {
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ModelSettingsDialog(
        initialSettings: settings,
        repository: repository,
      ),
    );
    if (saved == true && mounted) {
      ref.invalidate(modelSettingsProvider);
      _showSnackBar('模型设置已保存。');
    }
  }

  Future<void> _changePeriod(PeriodType value) async {
    if (value == _periodType) {
      return;
    }
    if (_templateDirty && !await _confirmDiscardTemplateChanges()) {
      return;
    }
    setState(() {
      _periodType = value;
      _templateLoaded = false;
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
    _loadTemplate();
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

  Future<void> _loadTemplate() async {
    final periodType = _periodType;
    final content = await ref.read(appDatabaseProvider).getTemplate(periodType);
    if (!mounted || _periodType != periodType) {
      return;
    }
    _replaceTemplateText(content);
    setState(() {
      _loadedTemplateContent = content;
      _templateLoaded = true;
    });
  }

  Future<void> _saveTemplate({bool showMessage = true}) async {
    await ref.read(appDatabaseProvider).saveTemplate(
          _periodType,
          _templateController.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _loadedTemplateContent = _templateController.text);
    ref.invalidate(templateProvider(_periodType));
    if (showMessage) {
      _showSnackBar('模板已保存。');
    }
  }

  Future<void> _resetTemplate() async {
    await ref.read(appDatabaseProvider).resetTemplate(_periodType);
    await _loadTemplate();
    ref.invalidate(templateProvider(_periodType));
    if (mounted) {
      _showSnackBar('模板已恢复默认。');
    }
  }

  void _handleTemplateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _replaceTemplateText(String content) {
    _templateController.removeListener(_handleTemplateChanged);
    _templateController.text = content;
    _templateController.addListener(_handleTemplateChanged);
  }

  void _pruneSummaryTags(List<String> tags) {
    if (_selectedTags.isEmpty) {
      return;
    }
    final availableTags = tags.toSet();
    final nextSelectedTags =
        _selectedTags.where((tag) => availableTags.contains(tag)).toSet();
    if (nextSelectedTags.length == _selectedTags.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedTags
          ..clear()
          ..addAll(nextSelectedTags);
      });
    });
  }

  Future<bool> _confirmDiscardTemplateChanges() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('模板还未保存'),
        content: const Text('切换总结类型会丢失当前模板编辑内容。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<bool> _confirmSaveTemplateBeforeGenerate() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('模板还未保存'),
        content: const Text('生成总结前需要先保存当前模板修改。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存并生成'),
          ),
        ],
      ),
    );
    return shouldSave == true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.icon,
    required this.child,
    this.alignTop = false,
  });

  final String label;
  final IconData icon;
  final Widget child;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 86,
          height: _controlHeight,
          child: Row(
            children: [
              Icon(icon, size: 17, color: _muted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _configLabelStyle(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _ModelSettingsButton extends StatelessWidget {
  const _ModelSettingsButton({
    required this.settings,
    required this.onPressed,
  });

  final AsyncValue<ModelSettings> settings;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = settings.when(
      data: (settings) => '模型：${settings.statusLabel}',
      loading: () => '模型：读取中',
      error: (_, __) => '模型：读取失败',
    );

    return SizedBox(
      height: _controlHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.storage_outlined, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: _configButtonStyle(context),
      ),
    );
  }
}

class _ModelSettingsDialog extends StatefulWidget {
  const _ModelSettingsDialog({
    required this.initialSettings,
    required this.repository,
  });

  final ModelSettings initialSettings;
  final ModelSettingsRepository repository;

  @override
  State<_ModelSettingsDialog> createState() => _ModelSettingsDialogState();
}

class _ModelSettingsDialogState extends State<_ModelSettingsDialog> {
  late ModelMode _mode;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  bool _saving = false;
  bool _clearingKey = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialSettings.mode;
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController(
      text: widget.initialSettings.baseUrl,
    );
    _modelController = TextEditingController(
      text: widget.initialSettings.model,
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedApiKey = widget.initialSettings.hasApiKey && !_clearingKey;
    final isCustom = _mode == ModelMode.custom;

    return AlertDialog(
      title: const Text('模型设置'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadioGroup<ModelMode>(
                groupValue: _mode,
                onChanged: _saving ? (_) {} : _changeMode,
                child: Column(
                  children: [
                    RadioListTile<ModelMode>(
                      value: ModelMode.custom,
                      enabled: !_saving,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('使用自己的模型服务'),
                      subtitle: const Text('兼容 OpenAI /chat/completions 的服务。'),
                    ),
                    RadioListTile<ModelMode>(
                      value: ModelMode.hosted,
                      enabled: !_saving,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('使用 AIMemo 官方托管模型'),
                      subtitle: const Text('暂未开放，后续支持登录和额度后使用。'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (isCustom) ...[
                TextField(
                  controller: _apiKeyController,
                  enabled: !_saving,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: hasSavedApiKey ? '已保存，留空则继续使用' : '输入 API Key',
                  ),
                ),
                if (hasSavedApiKey)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _clearApiKey,
                      icon: const Icon(Icons.key_off_outlined, size: 18),
                      label: const Text('清除已保存密钥'),
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _baseUrlController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _modelController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'gpt-4o-mini',
                  ),
                ),
              ] else
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _faint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      '官方托管模型暂未开放。本次先保留入口，之后接入登录、额度和计费后即可使用。',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('保存'),
        ),
      ],
    );
  }

  void _changeMode(ModelMode? mode) {
    if (mode == null) {
      return;
    }
    setState(() => _mode = mode);
  }

  Future<void> _clearApiKey() async {
    setState(() => _saving = true);
    await widget.repository.clearApiKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _clearingKey = true;
      _apiKeyController.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.repository.save(
      mode: _mode,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
      apiKey: _apiKeyController.text,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }
}

class _InlineTemplateEditor extends StatelessWidget {
  const _InlineTemplateEditor({
    required this.periodType,
    required this.controller,
    required this.loaded,
    required this.expanded,
    required this.dirty,
    required this.onToggleExpanded,
    required this.onSave,
    required this.onReset,
  });

  final PeriodType periodType;
  final TextEditingController controller;
  final bool loaded;
  final bool expanded;
  final bool dirty;
  final VoidCallback onToggleExpanded;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tooltip(
          message: expanded ? '收起模板' : '编辑模板',
          child: InkWell(
            onTap: onToggleExpanded,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(_controlRadius),
            child: Container(
              height: _controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(_controlRadius),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_outlined, size: 17, color: _muted),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '当前模板 · ${periodType.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _configControlStyle(context),
                    ),
                  ),
                  if (dirty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '未保存',
                      style: _configLabelStyle(context).copyWith(
                        color: _accent,
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: TextField(
              controller: controller,
              enabled: loaded,
              decoration: const InputDecoration(
                alignLabelWithHint: true,
                labelText: '提示词模板',
                hintText: '{period} {period_days} {tasks} {tags}',
              ),
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loaded ? onReset : null,
                  icon: const Icon(Icons.restore),
                  label: const Text('恢复默认'),
                  style: _configButtonStyle(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loaded && dirty ? onSave : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存模板'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, _controlHeight),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: _configControlStyle(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_controlRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SummaryTagFilter extends StatelessWidget {
  const _SummaryTagFilter({
    required this.tags,
    required this.selectedTags,
    required this.onPrune,
    required this.onSelectAll,
    required this.onTagSelected,
  });

  final AsyncValue<List<String>> tags;
  final Set<String> selectedTags;
  final ValueChanged<List<String>> onPrune;
  final VoidCallback onSelectAll;
  final void Function(String tag, bool selected) onTagSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _controlHeight),
      child: tags.when(
        data: (items) {
          onPrune(items);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ConfigFilterChip(
                label: '全部标签',
                selected: selectedTags.isEmpty,
                onSelected: (_) => onSelectAll(),
              ),
              for (final tag in items)
                _ConfigFilterChip(
                  label: tag,
                  selected: selectedTags.contains(tag),
                  onSelected: (selected) => onTagSelected(tag, selected),
                ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: _controlHeight,
          child: Center(child: LinearProgressIndicator()),
        ),
        error: (error, _) => _ErrorText(error.toString()),
      ),
    );
  }
}

class _ConfigFilterChip extends StatelessWidget {
  const _ConfigFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        avatar:
            selected ? const Icon(Icons.check, size: 14, color: _accent) : null,
        onSelected: onSelected,
        backgroundColor: _panel,
        selectedColor: _accentSoft,
        side: BorderSide(color: selected ? _accent : _border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
        ),
        labelStyle: _configControlStyle(context).copyWith(
          color: selected ? _accent : _ink,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('总结已复制。')),
                              );
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
            color: _accentSoft,
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
  });

  final PeriodType periodType;
  final PeriodRange range;
  final ValueChanged<PeriodType> onPeriodChanged;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 108,
          height: _controlHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _panel,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(_controlRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PeriodType>(
                  value: periodType,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(_controlRadius),
                  icon: const Icon(Icons.expand_more, size: 20),
                  style: _configControlStyle(context),
                  items: PeriodType.values
                      .map(
                        (type) => DropdownMenuItem<PeriodType>(
                          value: type,
                          child: Text(type.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onPeriodChanged(value);
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: '选择日期区间',
            child: SizedBox(
              height: _controlHeight,
              child: OutlinedButton(
                onPressed: onPickRange,
                style: _configButtonStyle(context,
                    alignment: Alignment.centerLeft),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        range.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _configControlStyle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

TextStyle _configControlStyle(BuildContext context) {
  return (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
    color: _ink,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
}

TextStyle _configLabelStyle(BuildContext context) {
  return (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
    color: _muted,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
}

ButtonStyle _configButtonStyle(
  BuildContext context, {
  AlignmentGeometry alignment = Alignment.center,
}) {
  return OutlinedButton.styleFrom(
    alignment: alignment,
    foregroundColor: _ink,
    backgroundColor: _panel,
    minimumSize: const Size(0, _controlHeight),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    side: const BorderSide(color: _border),
    textStyle: _configControlStyle(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_controlRadius),
    ),
  );
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

Future<void> _pruneTaskTagFilter(WidgetRef ref, MemoStore database) async {
  final availableTags = (await database.listTags()).toSet();
  final selectedTags = ref.read(taskTagFilterProvider);
  final nextSelectedTags =
      selectedTags.where((tag) => availableTags.contains(tag)).toSet();
  if (nextSelectedTags.length != selectedTags.length) {
    ref.read(taskTagFilterProvider.notifier).state = nextSelectedTags;
  }
}
