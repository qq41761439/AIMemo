import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/period_type.dart';
import '../models/summary_record.dart';
import '../models/task_record.dart';
import '../providers.dart';
import '../services/period_utils.dart';
import 'mobile_components.dart';
import 'mobile_theme.dart';

enum _MobileRoute {
  onboarding,
  auth,
  tasks,
  summary,
  taskEdit,
  profile,
  settings,
  summaryEntry,
  summaryResult,
  summaryHistory,
}

class MobileAIMemoApp extends StatelessWidget {
  const MobileAIMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIMemo',
      debugShowCheckedModeBanner: false,
      theme: buildMobileTheme(),
      home: const _MobileShell(),
    );
  }
}

class _MobileShell extends ConsumerStatefulWidget {
  const _MobileShell();

  @override
  ConsumerState<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<_MobileShell> {
  _MobileRoute _route = _MobileRoute.onboarding;
  TaskRecord? _editingTask;
  PeriodType _selectedPeriod = PeriodType.weekly;
  PeriodType _historyPeriod = PeriodType.weekly;
  Set<String> _summaryTags = <String>{};
  int? _expandedSummaryId;
  String? _latestSummaryOutput;
  bool _authenticated = false;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    return switch (_route) {
      _MobileRoute.onboarding => _OnboardingScreen(
          onSkip: _openAuth,
          onContinue: _openAuth,
        ),
      _MobileRoute.auth => _AuthScreen(
          onAuthenticated: () {
            setState(() {
              _authenticated = true;
              _route = _MobileRoute.tasks;
            });
          },
        ),
      _MobileRoute.tasks => _guarded(_TasksScreen(
          onOpenSummary: () => _go(_MobileRoute.summary),
          onOpenProfile: () => _go(_MobileRoute.profile),
          onEditTask: (task) {
            setState(() {
              _editingTask = task;
              _route = _MobileRoute.taskEdit;
            });
          },
        )),
      _MobileRoute.summary => _guarded(_SummaryMainScreen(
          onOpenTasks: () => _go(_MobileRoute.tasks),
          onOpenProfile: () => _go(_MobileRoute.profile),
          onGenerate: () => _go(_MobileRoute.summaryEntry),
          onHistory: () => _go(_MobileRoute.summaryHistory),
        )),
      _MobileRoute.taskEdit => _guarded(_TaskEditScreen(
          task: _editingTask,
          onBack: () => _go(_MobileRoute.tasks),
        )),
      _MobileRoute.profile => _guarded(_ProfileScreen(
          onBack: () => _go(_MobileRoute.tasks),
          onSettings: () => _go(_MobileRoute.settings),
          onHistory: () => _go(_MobileRoute.summaryHistory),
          onLogout: () {
            setState(() {
              _authenticated = false;
              _route = _MobileRoute.auth;
            });
          },
        )),
      _MobileRoute.settings => _guarded(_SettingsScreen(
          onBack: () => _go(_MobileRoute.profile),
          onLogout: () {
            setState(() {
              _authenticated = false;
              _route = _MobileRoute.auth;
            });
          },
        )),
      _MobileRoute.summaryEntry => _guarded(_SummaryEntryScreen(
          selectedPeriod: _selectedPeriod,
          selectedTags: _summaryTags,
          generating: _generating,
          onBack: () => _go(_MobileRoute.summary),
          onHistory: () => _go(_MobileRoute.summaryHistory),
          onSelectPeriod: (period) => setState(() {
            _selectedPeriod = period;
          }),
          onToggleTag: (tag) => setState(() {
            _summaryTags = {..._summaryTags};
            if (!_summaryTags.add(tag)) {
              _summaryTags.remove(tag);
            }
          }),
          onGenerate: _generateSummary,
        )),
      _MobileRoute.summaryResult => _guarded(_SummaryResultScreen(
          output: _latestSummaryOutput,
          onBack: () => _go(_MobileRoute.summaryEntry),
          onConfirm: () => _go(_MobileRoute.summaryHistory),
          onRefine: _generateSummary,
        )),
      _MobileRoute.summaryHistory => _guarded(_SummaryHistoryScreen(
          selectedPeriod: _historyPeriod,
          expandedSummaryId: _expandedSummaryId,
          onBack: () => _go(_MobileRoute.summary),
          onSelectPeriod: (period) => setState(() {
            _historyPeriod = period;
          }),
          onToggleExpanded: (summary) => setState(() {
            _expandedSummaryId =
                _expandedSummaryId == summary.id ? null : summary.id;
          }),
        )),
    };
  }

  Widget _guarded(Widget child) {
    if (!_authenticated) {
      return _AuthScreen(
        onAuthenticated: () {
          setState(() {
            _authenticated = true;
            _route = _MobileRoute.tasks;
          });
        },
      );
    }
    return child;
  }

  void _openAuth() {
    setState(() {
      _route = _MobileRoute.auth;
    });
  }

  void _go(_MobileRoute route) {
    setState(() {
      _route = route;
    });
  }

  Future<void> _generateSummary([String? refinement]) async {
    if (_generating) {
      return;
    }
    setState(() {
      _generating = true;
    });
    try {
      final store = ref.read(appDatabaseProvider);
      final range = periodRangeFor(_selectedPeriod, DateTime.now());
      final tasks = await store.listTasksForPeriod(
        start: range.start,
        end: range.end,
        tagNames: _summaryTags.toList(),
      );
      final output = _buildSummaryOutput(tasks, refinement);
      await store.insertSummary(
        periodType: _selectedPeriod,
        periodLabel: range.label,
        periodStart: range.start,
        periodEnd: range.end,
        tagFilter: _summaryTags.toList(),
        taskIds: tasks.map((task) => task.id).toList(),
        prompt: 'Mobile ${_selectedPeriod.title} summary',
        output: output,
      );
      ref.invalidate(summaryHistoryProvider);
      if (!mounted) {
        return;
      }
      setState(() {
        _latestSummaryOutput = output;
        _generating = false;
        _route = _MobileRoute.summaryResult;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _generating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Summary failed: $error')),
      );
    }
  }
}

class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({
    required this.onSkip,
    required this.onContinue,
  });

  final VoidCallback onSkip;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return MobileScreen(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      bottom: GradientButton(
        label: 'Get Started',
        icon: Icons.arrow_forward_rounded,
        onPressed: onContinue,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onSkip, child: const Text('Skip')),
          ),
          const SizedBox(height: 96),
          const _AIMemoMark(size: 112),
          const SizedBox(height: 32),
          Text(
            'Organize tasks into clear progress',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 36,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            'AIMemo keeps daily work lightweight, then turns completed tasks into useful AI summaries when you need them.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MobileTokens.muted,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 28),
          const _FeatureCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Tasks',
            message: 'Group active, upcoming, and completed work with tags.',
          ),
          const SizedBox(height: 14),
          const _FeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: 'AI Summary',
            message: 'Generate daily, weekly, monthly, or custom summaries.',
          ),
        ],
      ),
    );
  }
}

class _AuthScreen extends StatefulWidget {
  const _AuthScreen({required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScreen(
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
      child: Column(
        children: [
          const _AIMemoMark(size: 104),
          const SizedBox(height: 16),
          Text(
            'AIMemo',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Capture your work.\nTurn it into clear AI summaries.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MobileTokens.muted,
                ),
          ),
          const SizedBox(height: 32),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() {
                        _obscure = !_obscure;
                      }),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _comingSoon,
                    child: const Text('Forgot password?'),
                  ),
                ),
                if (_error != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: MobileTokens.danger,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                GradientButton(
                  label: 'Log in',
                  icon: Icons.auto_awesome_rounded,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),
                _AuthProviderButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  onTap: _comingSoon,
                ),
                const SizedBox(height: 10),
                _AuthProviderButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple_rounded,
                  onTap: _comingSoon,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Don't have an account?",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: MobileTokens.muted,
                    ),
              ),
              TextButton(onPressed: _comingSoon, child: const Text('Sign up')),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              TextButton(onPressed: _comingSoon, child: const Text('Privacy')),
              Text('•', style: Theme.of(context).textTheme.bodySmall),
              TextButton(onPressed: _comingSoon, child: const Text('Terms')),
              Text('•', style: Theme.of(context).textTheme.bodySmall),
              TextButton(
                onPressed: _comingSoon,
                child: const Text('How sync works'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Enter a valid email address.';
      });
      return;
    }
    if (password.isEmpty) {
      setState(() {
        _error = 'Enter your password.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
    widget.onAuthenticated();
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This option will be available soon.')),
    );
  }
}

class _TasksScreen extends ConsumerStatefulWidget {
  const _TasksScreen({
    required this.onOpenSummary,
    required this.onOpenProfile,
    required this.onEditTask,
  });

  final VoidCallback onOpenSummary;
  final VoidCallback onOpenProfile;
  final ValueChanged<TaskRecord> onEditTask;

  @override
  ConsumerState<_TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<_TasksScreen> {
  final _quickAddController = TextEditingController();
  String? _selectedTag;
  bool _adding = false;

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksValue = ref.watch(taskListProvider);
    final tagsValue = ref.watch(tagListProvider);
    return Scaffold(
      backgroundColor: MobileTokens.background,
      appBar: _MobileTopTabs(
        selected: 'Tasks',
        onTasks: () {},
        onSummary: widget.onOpenSummary,
        onProfile: widget.onOpenProfile,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: tasksValue.when(
            data: (tasks) {
              final filtered = _selectedTag == null
                  ? tasks
                  : tasks
                      .where((task) => task.tags.contains(_selectedTag))
                      .toList();
              final sections = _sectionTasks(filtered);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
                children: [
                  tagsValue.when(
                    data: (tags) => _TagFilterRow(
                      tags: _preferredTags(tags),
                      selectedTag: _selectedTag,
                      onSelected: (tag) => setState(() {
                        _selectedTag = tag;
                      }),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => StatusCard(
                      title: 'Could not load tags',
                      message: error.toString(),
                      icon: Icons.error_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _TaskSectionCard(
                    title: 'Active',
                    subtitle: 'Already started  ·  Needs attention',
                    tasks: sections.active,
                    tinted: true,
                    onEditTask: widget.onEditTask,
                    onToggleCompleted: _toggleCompleted,
                  ),
                  const SizedBox(height: 16),
                  _TaskSectionCard(
                    title: 'Upcoming',
                    tasks: sections.upcoming,
                    onEditTask: widget.onEditTask,
                    onToggleCompleted: _toggleCompleted,
                  ),
                  const SizedBox(height: 16),
                  _TaskSectionCard(
                    title: 'Completed',
                    tasks: sections.completed,
                    onEditTask: widget.onEditTask,
                    onToggleCompleted: _toggleCompleted,
                  ),
                  if (filtered.isEmpty) ...[
                    const SizedBox(height: 16),
                    const StatusCard(
                      title: 'No tasks yet',
                      message: 'Add one from the quick add bar below.',
                      icon: Icons.task_alt_rounded,
                    ),
                  ],
                ],
              );
            },
            loading: () => ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                SizedBox(height: 180),
                StatusCard(
                  title: 'Loading tasks',
                  message: 'Bringing your latest AIMemo data into view.',
                  loading: true,
                ),
              ],
            ),
            error: (error, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                StatusCard(
                  title: 'Could not load tasks',
                  message: error.toString(),
                  icon: Icons.error_outline_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _QuickAddBar(
          controller: _quickAddController,
          adding: _adding,
          onAdd: _addTask,
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(taskListProvider);
    ref.invalidate(tagListProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _addTask() async {
    final title = _quickAddController.text.trim();
    if (title.isEmpty || _adding) {
      return;
    }
    setState(() {
      _adding = true;
    });
    try {
      await ref.read(appDatabaseProvider).addTask(
        title: title,
        content: '',
        tags: const [],
      );
      _quickAddController.clear();
      ref.invalidate(taskListProvider);
      ref.invalidate(tagListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
        });
      }
    }
  }

  Future<void> _toggleCompleted(TaskRecord task) async {
    await ref.read(appDatabaseProvider).setTaskCompleted(
          task.id,
          !task.isCompleted,
        );
    ref.invalidate(taskListProvider);
    ref.invalidate(tagListProvider);
  }
}

class _TaskEditScreen extends ConsumerStatefulWidget {
  const _TaskEditScreen({
    required this.task,
    required this.onBack,
  });

  final TaskRecord? task;
  final VoidCallback onBack;

  @override
  ConsumerState<_TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<_TaskEditScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;
  late DateTime _startTime;
  late bool _completed;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.content ?? '');
    _tagsController = TextEditingController(text: task?.tags.join(', ') ?? '');
    _startTime = task?.createdAt ?? DateTime.now();
    _completed = task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    if (task == null) {
      return MobileScreen(
        title: 'Edit Task',
        onBack: widget.onBack,
        child: const StatusCard(
          title: 'Task not found',
          message: 'Return to Tasks and choose another item.',
        ),
      );
    }

    return MobileScreen(
      title: 'Edit Task',
      onBack: widget.onBack,
      bottom: GradientButton(
        label: 'Save Changes',
        loading: _saving,
        onPressed: () => _save(task),
      ),
      child: Column(
        children: [
          _EditCard(
            label: 'Title',
            child: TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Task title'),
            ),
          ),
          const SizedBox(height: 16),
          _EditCard(
            label: 'Notes',
            child: TextField(
              controller: _notesController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(hintText: 'Notes'),
            ),
          ),
          const SizedBox(height: 16),
          _EditCard(
            label: 'Tags',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    hintText: 'Product, Planning, Q3',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cleanTags(_tagsController.text)
                      .map(
                        (tag) => PillChip(
                          label: tag,
                          selected: true,
                          trailing: const Icon(Icons.close_rounded, size: 16),
                          onTap: () {
                            final tags = _cleanTags(_tagsController.text)
                                .where((item) => item != tag)
                                .toList();
                            setState(() {
                              _tagsController.text = tags.join(', ');
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _EditCard(
            label: 'Start Time',
            child: Row(
              children: [
                Expanded(
                  child: _TimeBox(
                    icon: Icons.calendar_month_rounded,
                    label: _formatMediumDate(_startTime),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeBox(
                    icon: Icons.schedule_rounded,
                    label: _formatTime(_startTime),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mark as completed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: _completed,
                  activeThumbColor: Colors.white,
                  activeTrackColor: MobileTokens.primary,
                  onChanged: (value) => setState(() {
                    _completed = value;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            onTap: _deleting ? null : () => _confirmDelete(task),
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: MobileTokens.danger,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _deleting ? 'Deleting...' : 'Delete task',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: MobileTokens.danger,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MobileTokens.danger,
                  ),
            ),
          ],
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Future<void> _save(TaskRecord task) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _error = 'Title is required.';
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(appDatabaseProvider).updateTask(
            taskId: task.id,
            title: title,
            content: _notesController.text.trim(),
            tags: _cleanTags(_tagsController.text),
            createdAt: _startTime,
            completedAt: _completed ? task.completedAt ?? DateTime.now() : null,
          );
      ref.invalidate(taskListProvider);
      ref.invalidate(tagListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task saved.')),
        );
        widget.onBack();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(TaskRecord task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This removes the task from visible lists.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _deleting = true;
    });
    await ref.read(appDatabaseProvider).deleteTask(task.id);
    ref.invalidate(taskListProvider);
    ref.invalidate(tagListProvider);
    if (mounted) {
      setState(() {
        _deleting = false;
      });
      widget.onBack();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              ref.read(appDatabaseProvider).restoreTask(task.id);
              ref.invalidate(taskListProvider);
              ref.invalidate(tagListProvider);
            },
          ),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) {
      return;
    }
    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        _startTime.hour,
        _startTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _startTime = DateTime(
        _startTime.year,
        _startTime.month,
        _startTime.day,
        time.hour,
        time.minute,
      );
    });
  }
}

class _SummaryMainScreen extends ConsumerWidget {
  const _SummaryMainScreen({
    required this.onOpenTasks,
    required this.onOpenProfile,
    required this.onGenerate,
    required this.onHistory,
  });

  final VoidCallback onOpenTasks;
  final VoidCallback onOpenProfile;
  final VoidCallback onGenerate;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(summaryHistoryProvider);
    return Scaffold(
      backgroundColor: MobileTokens.background,
      appBar: _MobileTopTabs(
        selected: 'Summary',
        onTasks: onOpenTasks,
        onSummary: () {},
        onProfile: onOpenProfile,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
          children: [
            _SummaryHeroCard(onGenerate: onGenerate),
            const SizedBox(height: 24),
            SectionTitle(
              title: 'Recent Summaries',
              trailing: TextButton(
                onPressed: onHistory,
                child: const Text('View all'),
              ),
            ),
            const SizedBox(height: 10),
            summaries.when(
              data: (items) {
                final recent = items.take(4).toList();
                if (recent.isEmpty) {
                  return const StatusCard(
                    title: 'No summaries yet',
                    message: 'Generate your first report from task history.',
                    icon: Icons.history_rounded,
                  );
                }
                return Column(
                  children: [
                    for (final summary in recent) ...[
                      _SummaryRow(summary: summary, onTap: onHistory),
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              },
              loading: () => const StatusCard(
                title: 'Loading summaries',
                message: 'Fetching recent summary history.',
                loading: true,
              ),
              error: (error, _) => StatusCard(
                title: 'Could not load summaries',
                message: error.toString(),
                icon: Icons.error_outline_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryEntryScreen extends ConsumerWidget {
  const _SummaryEntryScreen({
    required this.selectedPeriod,
    required this.selectedTags,
    required this.generating,
    required this.onBack,
    required this.onHistory,
    required this.onSelectPeriod,
    required this.onToggleTag,
    required this.onGenerate,
  });

  final PeriodType selectedPeriod;
  final Set<String> selectedTags;
  final bool generating;
  final VoidCallback onBack;
  final VoidCallback onHistory;
  final ValueChanged<PeriodType> onSelectPeriod;
  final ValueChanged<String> onToggleTag;
  final Future<void> Function([String? refinement]) onGenerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksValue = ref.watch(taskListProvider);
    final tagsValue = ref.watch(tagListProvider);
    return MobileScreen(
      title: 'Generate Summary',
      onBack: onBack,
      trailing: IconButton(
        tooltip: 'History',
        onPressed: onHistory,
        icon: const Icon(Icons.history_rounded),
      ),
      bottom: GradientButton(
        label: 'Generate Summary',
        icon: Icons.auto_awesome_rounded,
        loading: generating,
        onPressed: () => onGenerate(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftCard(
            color: MobileTokens.faint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to summarize?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                _PeriodChooser(
                  selected: selectedPeriod,
                  onSelect: onSelectPeriod,
                ),
                const SizedBox(height: 14),
                tagsValue.when(
                  data: (tags) => _TagChooser(
                    tags: tags,
                    selectedTags: selectedTags,
                    onToggle: onToggleTag,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(error.toString()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Text('Preview', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 8),
              const Icon(Icons.info_outline_rounded, color: MobileTokens.muted),
            ],
          ),
          const SizedBox(height: 14),
          tasksValue.when(
            data: (tasks) {
              final scoped = selectedTags.isEmpty
                  ? tasks
                  : tasks
                      .where(
                        (task) => task.tags.any(selectedTags.contains),
                      )
                      .toList();
              final completed = scoped.where((task) => task.isCompleted).length;
              return Row(
                children: [
                  Expanded(
                    child: _MetricCard(value: scoped.length, label: 'Tasks'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(value: completed, label: 'Completed'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      value: scoped.length - completed,
                      label: 'In Progress',
                    ),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => StatusCard(
              title: 'Preview unavailable',
              message: error.toString(),
            ),
          ),
          const SizedBox(height: 24),
          const SoftCard(
            color: MobileTokens.faint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryPromise(label: 'AI will analyze your tasks and'),
                _SummaryPromise(label: 'Summarize what you accomplished'),
                _SummaryPromise(label: 'Highlight key insights'),
                _SummaryPromise(label: 'Suggest next steps'),
              ],
            ),
          ),
          const SizedBox(height: 74),
        ],
      ),
    );
  }
}

class _SummaryResultScreen extends StatefulWidget {
  const _SummaryResultScreen({
    required this.output,
    required this.onBack,
    required this.onConfirm,
    required this.onRefine,
  });

  final String? output;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final Future<void> Function([String? refinement]) onRefine;

  @override
  State<_SummaryResultScreen> createState() => _SummaryResultScreenState();
}

class _SummaryResultScreenState extends State<_SummaryResultScreen> {
  final _refineController = TextEditingController();
  bool _refining = false;

  @override
  void dispose() {
    _refineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final output = widget.output ?? _emptySummaryOutput;
    return MobileScreen(
      title: 'Summary Result',
      onBack: widget.onBack,
      bottom: GradientButton(
        label: 'Looks Good',
        icon: Icons.check_rounded,
        onPressed: widget.onConfirm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Summary',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _SummaryContent(output: output),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied summary.')),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share sheet coming soon.')),
                    );
                  },
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SectionTitle(
            title: 'Modify',
            trailing: TextButton(
              onPressed: _refining ? null : _refine,
              child: Text(_refining ? 'Updating...' : 'Apply'),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _refineController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Ask AI to make it shorter, warmer, or more formal.',
            ),
          ),
          const SizedBox(height: 74),
        ],
      ),
    );
  }

  Future<void> _refine() async {
    final text = _refineController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() {
      _refining = true;
    });
    await widget.onRefine(text);
    if (mounted) {
      setState(() {
        _refining = false;
      });
    }
  }
}

class _SummaryHistoryScreen extends ConsumerWidget {
  const _SummaryHistoryScreen({
    required this.selectedPeriod,
    required this.expandedSummaryId,
    required this.onBack,
    required this.onSelectPeriod,
    required this.onToggleExpanded,
  });

  final PeriodType selectedPeriod;
  final int? expandedSummaryId;
  final VoidCallback onBack;
  final ValueChanged<PeriodType> onSelectPeriod;
  final ValueChanged<SummaryRecord> onToggleExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(summaryHistoryProvider);
    return MobileScreen(
      title: 'Summary History',
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final period in PeriodType.values) ...[
                  PillChip(
                    label: period.title,
                    selected: selectedPeriod == period,
                    onTap: () => onSelectPeriod(period),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          summaries.when(
            data: (items) {
              final filtered = items
                  .where((summary) => summary.periodType == selectedPeriod)
                  .toList();
              if (filtered.isEmpty) {
                return const StatusCard(
                  title: 'No history here',
                  message: 'Generated reports will appear in this list.',
                  icon: Icons.history_rounded,
                );
              }
              return Column(
                children: [
                  for (final summary in filtered) ...[
                    _HistorySummaryTile(
                      summary: summary,
                      expanded: expandedSummaryId == summary.id,
                      onTap: () => onToggleExpanded(summary),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
            loading: () => const StatusCard(
              title: 'Loading history',
              message: 'Fetching generated summaries.',
              loading: true,
            ),
            error: (error, _) => StatusCard(
              title: 'Could not load history',
              message: error.toString(),
              icon: Icons.error_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({
    required this.onBack,
    required this.onSettings,
    required this.onHistory,
    required this.onLogout,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onHistory;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return MobileScreen(
      title: 'Me',
      onBack: onBack,
      child: Column(
        children: [
          SoftCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: MobileTokens.primarySoft,
                  child: Icon(
                    Icons.person_rounded,
                    color: MobileTokens.primary,
                    size: 42,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AIMemo User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'user@example.com',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      const PillChip(
                        label: 'Synced',
                        selected: true,
                        trailing: Icon(
                          Icons.check_circle_rounded,
                          color: MobileTokens.success,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MenuGroup(
            rows: [
              _MenuRowData('Summary history', Icons.history_rounded, onHistory),
              _MenuRowData('Notifications & sync',
                  Icons.notifications_none_rounded, _comingSoon(context)),
              _MenuRowData(
                'Privacy & security',
                Icons.security_rounded,
                onSettings,
              ),
              _MenuRowData(
                  'Help', Icons.help_outline_rounded, _comingSoon(context)),
            ],
          ),
          const SizedBox(height: 16),
          _DangerButton(label: 'Sign out', onTap: onLogout),
        ],
      ),
    );
  }

  VoidCallback _comingSoon(BuildContext context) {
    return () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This setting is coming soon.')),
      );
    };
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    required this.onBack,
    required this.onLogout,
  });

  final VoidCallback onBack;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return MobileScreen(
      title: 'Settings',
      onBack: onBack,
      child: Column(
        children: [
          _MenuGroup(
            rows: [
              _MenuRowData('Account', Icons.person_outline_rounded,
                  _comingSoon(context)),
              _MenuRowData('Sync', Icons.sync_rounded, _comingSoon(context)),
              _MenuRowData(
                  'Privacy', Icons.privacy_tip_outlined, _comingSoon(context)),
              _MenuRowData(
                  'Language', Icons.language_rounded, _comingSoon(context)),
            ],
          ),
          const SizedBox(height: 16),
          _MenuGroup(
            rows: [
              _MenuRowData(
                'Help center',
                Icons.help_outline_rounded,
                _comingSoon(context),
              ),
              _MenuRowData(
                'Send feedback',
                Icons.feedback_outlined,
                _comingSoon(context),
              ),
              _MenuRowData(
                'About AIMemo',
                Icons.info_outline_rounded,
                _comingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DangerButton(label: 'Sign out', onTap: onLogout),
        ],
      ),
    );
  }

  VoidCallback _comingSoon(BuildContext context) {
    return () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This setting is coming soon.')),
      );
    };
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: MobileTokens.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: MobileTokens.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(message, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthProviderButton extends StatelessWidget {
  const _AuthProviderButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label),
      ),
    );
  }
}

class _MobileTopTabs extends StatelessWidget implements PreferredSizeWidget {
  const _MobileTopTabs({
    required this.selected,
    required this.onTasks,
    required this.onSummary,
    required this.onProfile,
  });

  final String selected;
  final VoidCallback onTasks;
  final VoidCallback onSummary;
  final VoidCallback onProfile;

  @override
  Size get preferredSize => const Size.fromHeight(112);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 112,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(38, 32, 24, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _TopTab(
              label: 'Tasks',
              active: selected == 'Tasks',
              onTap: onTasks,
            ),
            const SizedBox(width: 34),
            _TopTab(
              label: 'Summary',
              active: selected == 'Summary',
              onTap: onSummary,
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Profile',
              onPressed: onProfile,
              icon: const Icon(Icons.account_circle_outlined, size: 34),
            ),
          ],
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: MobileTokens.border),
      ),
    );
  }
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: active ? MobileTokens.ink : MobileTokens.muted,
                  ),
            ),
            const SizedBox(height: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? (label == 'Summary' ? 84 : 52) : 0,
              height: 3,
              decoration: BoxDecoration(
                color: active ? MobileTokens.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagFilterRow extends StatelessWidget {
  const _TagFilterRow({
    required this.tags,
    required this.selectedTag,
    required this.onSelected,
  });

  final List<String> tags;
  final String? selectedTag;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PillChip(
            label: 'All',
            selected: selectedTag == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 10),
          for (final tag in tags) ...[
            PillChip(
              label: tag,
              selected: selectedTag == tag,
              onTap: () => onSelected(tag),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _TaskSectionCard extends StatelessWidget {
  const _TaskSectionCard({
    required this.title,
    required this.tasks,
    required this.onEditTask,
    required this.onToggleCompleted,
    this.subtitle,
    this.tinted = false,
  });

  final String title;
  final String? subtitle;
  final List<TaskRecord> tasks;
  final bool tinted;
  final ValueChanged<TaskRecord> onEditTask;
  final ValueChanged<TaskRecord> onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: tinted ? MobileTokens.faint : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                    ),
              ),
              const SizedBox(width: 10),
              Container(
                constraints: const BoxConstraints(minWidth: 28),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: MobileTokens.primarySoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  tasks.length.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MobileTokens.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.keyboard_arrow_up_rounded),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: MobileTokens.border),
              borderRadius: BorderRadius.circular(MobileTokens.radius),
            ),
            child: Column(
              children: [
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: StatusCard(
                      title: 'Nothing here',
                      message: 'Tasks in this section will appear here.',
                    ),
                  )
                else
                  for (final task in tasks) ...[
                    _TaskRow(
                      task: task,
                      onTap: () => onEditTask(task),
                      onToggle: () => onToggleCompleted(task),
                    ),
                    if (task != tasks.last)
                      const Divider(height: 1, color: MobileTokens.border),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  final TaskRecord task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final date =
        task.isCompleted ? task.completedAt ?? task.updatedAt : task.createdAt;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(
          children: [
            IconButton(
              tooltip: task.isCompleted ? 'Mark incomplete' : 'Mark completed',
              onPressed: onToggle,
              icon: task.isCompleted
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: MobileTokens.gradient,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: Color(0xFFA9AEBC),
                      size: 30,
                    ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: task.isCompleted
                              ? const Color(0xFF8E93A3)
                              : MobileTokens.ink,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                  ),
                  if (task.tags.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        for (final tag in task.tags.take(3))
                          PillChip(label: tag, selected: true),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatShortDate(date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MobileTokens.muted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddBar extends StatelessWidget {
  const _QuickAddBar({
    required this.controller,
    required this.adding,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool adding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: MobileTokens.border),
          boxShadow: MobileTokens.softShadow,
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: MobileTokens.border),
              ),
              child: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onAdd(),
                decoration: const InputDecoration(
                  hintText: 'Quick add a task...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: adding ? null : onAdd,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: MobileTokens.gradient,
                  shape: BoxShape.circle,
                ),
                child: adding
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MobileTokens.radius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: MobileTokens.border),
          borderRadius: BorderRadius.circular(MobileTokens.radius),
        ),
        child: Row(
          children: [
            Icon(icon, color: MobileTokens.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.onGenerate});

  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: const Color(0xFFFAF7FF),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Summary',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 30,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Turn your tasks into clear progress updates.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: MobileTokens.muted,
                      ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Generate Summary',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: onGenerate,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const _SummaryGlyph(),
        ],
      ),
    );
  }
}

class _PeriodChooser extends StatelessWidget {
  const _PeriodChooser({
    required this.selected,
    required this.onSelect,
  });

  final PeriodType selected;
  final ValueChanged<PeriodType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final period in PeriodType.values)
          PillChip(
            label: period.title,
            selected: selected == period,
            onTap: () => onSelect(period),
          ),
      ],
    );
  }
}

class _TagChooser extends StatelessWidget {
  const _TagChooser({
    required this.tags,
    required this.selectedTags,
    required this.onToggle,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const StatusCard(
        title: 'All Tags',
        message: 'No saved tags yet. Summaries will include all tasks.',
        icon: Icons.sell_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              PillChip(
                label: tag,
                selected: selectedTags.contains(tag),
                onTap: () => onToggle(tag),
              ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 30,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: MobileTokens.muted,
                ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPromise extends StatelessWidget {
  const _SummaryPromise({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: MobileTokens.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary, required this.onTap});

  final SummaryRecord summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MobileTokens.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: MobileTokens.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.periodType.title} · ${summary.periodLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.taskIds.length} tasks · ${_formatShortDate(summary.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: MobileTokens.muted),
        ],
      ),
    );
  }
}

class _HistorySummaryTile extends StatelessWidget {
  const _HistorySummaryTile({
    required this.summary,
    required this.expanded,
    required this.onTap,
  });

  final SummaryRecord summary;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${summary.periodType.title} · ${summary.periodLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${summary.taskIds.length} tasks · Generated ${_formatShortDate(summary.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            summary.output.split('\n').first,
            maxLines: expanded ? null : 2,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (expanded) ...[
            const Divider(height: 24),
            _SummaryContent(output: summary.output),
          ],
        ],
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.output});

  final String output;

  @override
  Widget build(BuildContext context) {
    final sections = output
        .split('\n\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          Text(section, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.rows});

  final List<_MenuRowData> rows;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final row in rows) ...[
            ListTile(
              minVerticalPadding: 14,
              leading: Icon(row.icon, color: MobileTokens.primary),
              title: Text(row.label),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: row.onTap,
            ),
            if (row != rows.last)
              const Divider(height: 1, color: MobileTokens.border),
          ],
        ],
      ),
    );
  }
}

class _MenuRowData {
  const _MenuRowData(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.logout_rounded, color: MobileTokens.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MobileTokens.danger,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIMemoMark extends StatelessWidget {
  const _AIMemoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: MobileTokens.gradient,
          borderRadius: BorderRadius.circular(size * 0.24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x335B2DE1),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: size * 0.48,
        ),
      ),
    );
  }
}

class _SummaryGlyph extends StatelessWidget {
  const _SummaryGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MobileTokens.border),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, color: MobileTokens.primary),
          SizedBox(height: 10),
          Icon(Icons.check_circle_outline_rounded, color: MobileTokens.primary),
          SizedBox(height: 10),
          Icon(Icons.bar_chart_rounded, color: MobileTokens.primary),
        ],
      ),
    );
  }
}

class _TaskSections {
  const _TaskSections({
    required this.active,
    required this.upcoming,
    required this.completed,
  });

  final List<TaskRecord> active;
  final List<TaskRecord> upcoming;
  final List<TaskRecord> completed;
}

_TaskSections _sectionTasks(List<TaskRecord> tasks) {
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  final visible = tasks.where((task) => task.deletedAt == null).toList();
  visible.sort((a, b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }
    final aDate = a.isCompleted ? a.completedAt ?? a.updatedAt : a.createdAt;
    final bDate = b.isCompleted ? b.completedAt ?? b.updatedAt : b.createdAt;
    return bDate.compareTo(aDate);
  });
  return _TaskSections(
    active: visible.where((task) {
      final taskDay = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );
      return !task.isCompleted && !taskDay.isAfter(day);
    }).toList(),
    upcoming: visible.where((task) {
      final taskDay = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );
      return !task.isCompleted && taskDay.isAfter(day);
    }).toList(),
    completed: visible.where((task) => task.isCompleted).toList(),
  );
}

List<String> _preferredTags(List<String> tags) {
  const preferred = ['Product', 'Client', 'Study', 'Personal'];
  return [...preferred, ...tags]
      .where((tag) => tag.trim().isNotEmpty)
      .toSet()
      .toList();
}

List<String> _cleanTags(String input) {
  return input
      .split(RegExp('[,，]'))
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .toList();
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatMediumDate(DateTime date) {
  return '${_formatShortDate(date)}, ${date.year}';
}

String _formatTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _buildSummaryOutput(List<TaskRecord> tasks, String? refinement) {
  final completed = tasks.where((task) => task.isCompleted).toList();
  final pending = tasks.where((task) => !task.isCompleted).toList();
  final completedText = completed.isEmpty
      ? 'No completed tasks in this range yet.'
      : completed.map((task) => '- ${task.title}').join('\n');
  final outcomes = completed.isEmpty
      ? 'Keep capturing work so AIMemo can produce a richer report.'
      : 'You completed ${completed.length} task${completed.length == 1 ? '' : 's'} and kept progress visible across your task list.';
  final next = pending.isEmpty
      ? 'No open tasks remain for this period.'
      : pending.take(4).map((task) => '- ${task.title}').join('\n');
  final included = tasks.isEmpty
      ? 'No tasks were included.'
      : tasks.take(8).map((task) => '- ${task.title}').join('\n');
  final instruction = refinement == null || refinement.trim().isEmpty
      ? ''
      : '\n\nModification note\n${refinement.trim()}';
  return '''
What I completed
$completedText

Key outcomes
$outcomes

Next steps
$next

Included tasks
$included$instruction
'''
      .trim();
}

const _emptySummaryOutput = '''
What I completed
No generated summary is available yet.

Key outcomes
Generate a report to see AI output here.

Next steps
Return to Generate Summary and create a report.

Included tasks
No tasks were included.
''';
