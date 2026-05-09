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
const _sidebar = Color(0xFFEFF2ED);
const _border = Color(0xFFDDE2DC);
const _accent = Color(0xFF2F6F5E);
const _warning = Color(0xFF9A5B13);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final workspaceWidth =
                constraints.maxWidth < 1120 ? 1120.0 : constraints.maxWidth;

            return ColoredBox(
              color: _faint,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: workspaceWidth,
                  height: constraints.maxHeight,
                  child: const Row(
                    children: [
                      SizedBox(width: 260, child: _Sidebar()),
                      VerticalDivider(width: 1),
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

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTags = ref.watch(taskTagFilterProvider);
    final tags = ref.watch(tagListProvider);

    return Container(
      color: _sidebar,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.checklist_rtl,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AIMemo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('待办、标签和周期总结', style: _captionStyle(context)),
          const SizedBox(height: 26),
          const _SectionLabel('标签筛选'),
          const SizedBox(height: 10),
          FilterChip(
            label: const Text('全部任务'),
            selected: selectedTags.isEmpty,
            onSelected: (_) {
              ref.read(taskTagFilterProvider.notifier).state = <String>{};
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tags.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyHint(text: '添加任务后会出现标签。');
                }
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                  ),
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

class _TaskListPane extends ConsumerWidget {
  const _TaskListPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final selectedTags = ref.watch(taskTagFilterProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('任务列表', style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              if (selectedTags.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(taskTagFilterProvider.notifier).state = <String>{};
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('清除筛选'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text('未完成任务优先显示，已完成会自动下沉。', style: _captionStyle(context)),
          const SizedBox(height: 16),
          Expanded(
            child: tasks.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyHint(text: '还没有任务，先从右侧添加一个。');
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                  color: Color(0x0F101410),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) async {
                await ref
                    .read(appDatabaseProvider)
                    .setTaskCompleted(task.id, value ?? false);
                ref.invalidate(taskListProvider);
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: completed ? _muted : _ink,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.content.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: completed ? _muted : const Color(0xFF3F4742),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
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
                      _StatusPill(completed: completed),
                      for (final tag in task.tags)
                        Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '删除任务',
              onPressed: () async {
                await ref.read(appDatabaseProvider).deleteTask(task.id);
                ref.invalidate(taskListProvider);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPane extends StatelessWidget {
  const _ActionPane();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _panel,
      child: const DefaultTabController(
        length: 4,
        child: Column(
          children: [
            SizedBox(height: 4),
            TabBar(
              tabs: [
                Tab(icon: Icon(Icons.add_task), text: '添加'),
                Tab(icon: Icon(Icons.auto_awesome_outlined), text: '总结'),
                Tab(icon: Icon(Icons.tune), text: '模板'),
                Tab(icon: Icon(Icons.history), text: '历史'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AddTaskPanel(),
                  _SummaryPanel(),
                  _TemplatePanel(),
                  _HistoryPanel(),
                ],
              ),
            ),
          ],
        ),
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagListProvider);

    return _PanelPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeader(
            icon: Icons.add_task,
            title: '添加任务',
            subtitle: '记录事项，标签用逗号分隔。',
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
            decoration: const InputDecoration(
              labelText: '标签',
              hintText: '工作, 学习, 生活',
            ),
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
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add),
            label: const Text('添加任务'),
          ),
        ],
      ),
    );
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
      await ref.read(appDatabaseProvider).addTask(
            title: _titleController.text,
            content: _contentController.text,
            tags: _parseTags(_tagsController.text),
          );
      _titleController.clear();
      _contentController.clear();
      _tagsController.clear();
      ref.invalidate(taskListProvider);
      ref.invalidate(tagListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已添加。')),
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
}

class _SummaryPanel extends ConsumerStatefulWidget {
  const _SummaryPanel();

  @override
  ConsumerState<_SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends ConsumerState<_SummaryPanel> {
  PeriodType _periodType = PeriodType.daily;
  final Set<String> _selectedTags = <String>{};
  bool _isGenerating = false;
  String? _latestSummary;
  String? _error;

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
          DropdownButtonFormField<PeriodType>(
            initialValue: _periodType,
            decoration: const InputDecoration(labelText: '周期'),
            items: [
              for (final type in PeriodType.values)
                DropdownMenuItem(value: type, child: Text(type.title)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _periodType = value);
              }
            },
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
      final range = periodRangeFor(_periodType, DateTime.now());
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
      final prompt = renderSummaryPrompt(
        template: template,
        periodType: _periodType,
        tasks: tasks,
        tags: selectedTags,
      );
      final summary = await ref.read(summaryApiClientProvider).generateSummary(
            period: _periodType.placeholderName,
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
          DropdownButtonFormField<PeriodType>(
            initialValue: _periodType,
            decoration: const InputDecoration(labelText: '周期'),
            items: [
              for (final type in PeriodType.values)
                DropdownMenuItem(value: type, child: Text(type.title)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = completed ? _muted : _warning;
    final background =
        completed ? const Color(0xFFE9ECE7) : const Color(0xFFF5EBDD);

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        completed ? '已完成' : '进行中',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
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
