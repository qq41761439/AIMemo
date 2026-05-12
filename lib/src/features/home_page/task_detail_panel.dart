part of '../home_page.dart';

class _AddTaskPanel extends ConsumerStatefulWidget {
  const _AddTaskPanel();

  @override
  ConsumerState<_AddTaskPanel> createState() => _AddTaskPanelState();
}

class _AddTaskPanelState extends ConsumerState<_AddTaskPanel> {
  final _bodyController = TextEditingController();
  final _tagsController = TextEditingController();
  final _bodyFocusNode = FocusNode(debugLabel: 'task body input');
  final _tagsFocusNode = FocusNode(debugLabel: 'task tags input');
  int? _loadedEditingTaskId;
  DateTime _createdAt = DateTime.now();
  DateTime? _completedAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _bodyController.dispose();
    _tagsController.dispose();
    _bodyFocusNode.dispose();
    _tagsFocusNode.dispose();
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
    final selectedTagKeys = _parseTags(_tagsController.text)
        .map((tag) => tag.toLowerCase())
        .toSet();

    return _PanelPadding(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactForm = constraints.maxHeight < 560;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.only(bottom: compactForm ? 28 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PanelHeader(
                        icon: isEditing ? Icons.edit_outlined : Icons.add_task,
                        title: isEditing ? '编辑任务' : '添加任务',
                        subtitle: isEditing ? '修改任务内容和标签。' : '记录事项，标签用逗号分隔。',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onTap: _bodyFocusNode.requestFocus,
                        onTapOutside: (_) => _dismissKeyboard(),
                        scrollPadding: _taskInputScrollPadding(context),
                        decoration: const InputDecoration(
                          labelText: '任务内容',
                          hintText: '第一行会显示在任务列表中',
                        ),
                        minLines: compactForm ? 3 : 6,
                        maxLines: compactForm ? 5 : 8,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TaskDateTimeButton(
                              label: '开始时间',
                              icon: Icons.schedule_outlined,
                              value: _createdAt,
                              emptyText: '选择开始时间',
                              onPressed: _pickCreatedAt,
                            ),
                          ),
                          if (isEditing) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TaskDateTimeButton(
                                label: '完成时间',
                                icon: Icons.check_circle_outline,
                                value: _completedAt,
                                emptyText: '未完成',
                                onPressed: _pickCompletedAt,
                                onClear: _completedAt == null
                                    ? null
                                    : () => setState(() => _completedAt = null),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tagsController,
                        focusNode: _tagsFocusNode,
                        textInputAction: TextInputAction.done,
                        onTap: _tagsFocusNode.requestFocus,
                        onTapOutside: (_) => _dismissKeyboard(),
                        scrollPadding: _taskInputScrollPadding(context),
                        decoration: const InputDecoration(labelText: '标签'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),
                      tags.when(
                        data: (items) {
                          final availableTags = items
                              .where(
                                (tag) => !selectedTagKeys
                                    .contains(tag.toLowerCase()),
                              )
                              .toList();
                          if (availableTags.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '可添加标签',
                                  style: _captionStyle(context)?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tag in availableTags)
                                      ActionChip(
                                        label: Text(tag),
                                        side: const BorderSide(color: _border),
                                        backgroundColor: _faint,
                                        onPressed: () => _appendTag(tag),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 18),
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
                              icon: Icon(
                                isEditing ? Icons.save_outlined : Icons.add,
                              ),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncEditingTask(TaskRecord? task) {
    if (_loadedEditingTaskId == task?.id) {
      return;
    }
    _loadedEditingTaskId = task?.id;

    if (task == null) {
      _bodyController.clear();
      _tagsController.clear();
      _createdAt = DateTime.now();
      _completedAt = null;
      return;
    }

    _bodyController.text = taskBodyFromRecord(task);
    _tagsController.text = task.tags.join(', ');
    _createdAt = task.createdAt;
    _completedAt = task.completedAt;
  }

  void _appendTag(String tag) {
    final current = _parseTags(_tagsController.text);
    if (!current
        .map((item) => item.toLowerCase())
        .contains(tag.toLowerCase())) {
      current.add(tag);
      setState(() {
        _tagsController.text = current.join(', ');
      });
    }
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final editingTask = ref.read(editingTaskProvider);
      final draft = taskDraftFromBody(_bodyController.text);
      final taskTags = _parseTags(_tagsController.text);
      final createdAt = _createdAt;
      final completedAt = _completedAt;
      if (completedAt != null && completedAt.isBefore(createdAt)) {
        throw ArgumentError('完成时间不能早于开始时间。');
      }
      if (editingTask == null) {
        await ref.read(appDatabaseProvider).addTask(
              title: draft.title,
              content: draft.content,
              tags: taskTags,
              createdAt: createdAt,
            );
      } else {
        await ref.read(appDatabaseProvider).updateTask(
              taskId: editingTask.id,
              title: draft.title,
              content: draft.content,
              tags: taskTags,
              createdAt: createdAt,
              completedAt: completedAt,
            );
      }
      _bodyController.clear();
      _tagsController.clear();
      _createdAt = DateTime.now();
      _completedAt = null;
      if (editingTask == null) {
        ref.read(selectedTaskProvider.notifier).state = null;
      } else {
        ref.read(selectedTaskProvider.notifier).state = editingTask.copyWith(
          title: draft.title,
          content: draft.content,
          tags: taskTags,
          createdAt: createdAt,
          completedAt: completedAt,
          clearCompletedAt: completedAt == null,
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
        final message = error is ArgumentError && error.message != null
            ? error.message.toString()
            : error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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

  Future<void> _pickCreatedAt() async {
    final picked = await _pickTaskDateTime(_createdAt);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _createdAt = picked);
  }

  Future<void> _pickCompletedAt() async {
    final picked = await _pickTaskDateTime(
      _completedAt ?? _createdAt,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _completedAt = picked);
  }

  Future<DateTime?> _pickTaskDateTime(DateTime initial) async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(DateTime.now().year + 5, 12, 31);
    final initialDate = initial.isBefore(firstDate)
        ? firstDate
        : initial.isAfter(lastDate)
            ? lastDate
            : initial;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null || !mounted) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

EdgeInsets _taskInputScrollPadding(BuildContext context) {
  return EdgeInsets.only(
    left: 20,
    top: 20,
    right: 20,
    bottom: MediaQuery.viewInsetsOf(context).bottom + 120,
  );
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
                  const _SectionLabel('任务内容'),
                  const SizedBox(height: 6),
                  SelectableText(
                    taskBodyFromRecord(task),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: task.isCompleted ? _muted : _ink,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
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
                    text: '开始 ${compactDateTime(task.createdAt)}',
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

class _TaskDateTimeButton extends StatelessWidget {
  const _TaskDateTimeButton({
    required this.label,
    required this.icon,
    required this.value,
    required this.emptyText,
    required this.onPressed,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final DateTime? value;
  final String emptyText;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final displayText = value == null ? emptyText : compactDateTime(value!);

    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(_controlRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_controlRadius),
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPressed,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: _accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: _configLabelStyle(context)),
                                const SizedBox(height: 2),
                                Text(
                                  displayText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _configControlStyle(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: '清空$label',
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
        ),
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
