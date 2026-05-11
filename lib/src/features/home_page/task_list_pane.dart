part of '../home_page.dart';

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
                    ref.read(taskPaneFocusRequestProvider.notifier).state += 1;
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
                  ref.read(taskPaneFocusRequestProvider.notifier).state += 1;
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
