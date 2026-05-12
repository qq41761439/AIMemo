import 'dart:async';

import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_run_mode.dart';
import '../models/model_settings.dart';
import '../models/period_type.dart';
import '../models/summary_record.dart';
import '../models/task_record.dart';
import '../providers.dart';
import '../services/memo_store.dart';
import '../services/model_settings_repository.dart';
import '../services/period_utils.dart';
import '../services/task_body.dart';
import '../services/template_renderer.dart';

part 'home_page/task_list_pane.dart';
part 'home_page/action_pane.dart';
part 'home_page/task_detail_panel.dart';
part 'home_page/summary_panel.dart';
part 'home_page/model_settings_dialog.dart';
part 'home_page/startup_gate.dart';
part 'home_page/summary_widgets.dart';
part 'home_page/history_panel.dart';
part 'home_page/shared_widgets.dart';

const _ink = Color(0xFF202622);
const _muted = Color(0xFF68716A);
const _faint = Color(0xFFF4F5F2);
const _panel = Color(0xFFFFFFFF);
const _border = Color(0xFFDDE2DC);
const _accent = Color(0xFF2F6F5E);
const _accentSoft = Color(0xFFE4ECE7);
const _controlHeight = 40.0;
const _controlRadius = 6.0;
const _mobileWorkspaceBreakpoint = 720.0;
const _defaultActionPaneWidth = 520.0;
const _minActionPaneWidth = 380.0;
const _maxActionPaneWidth = 720.0;
const _minTaskPaneWidth = 420.0;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRunMode = ref.watch(appRunModeProvider);
    return appRunMode.when(
      data: (mode) =>
          mode == null ? const _StartupChoicePage() : const _HomeWorkspace(),
      loading: () => const _StartupLoadingPage(),
      error: (error, _) => _StartupErrorPage(error: error),
    );
  }
}

class _HomeWorkspace extends ConsumerStatefulWidget {
  const _HomeWorkspace();

  @override
  ConsumerState<_HomeWorkspace> createState() => _HomeWorkspaceState();
}

class _HomeWorkspaceState extends ConsumerState<_HomeWorkspace> {
  double _actionPaneWidth = _defaultActionPaneWidth;
  int _mobilePageIndex = 0;
  bool _compactWorkspace = false;
  late final MemoStore _database;
  Timer? _saveActionPaneWidthTimer;
  Timer? _syncTimer;
  bool _actionPaneWidthChanged = false;

  @override
  void initState() {
    super.initState();
    _database = ref.read(appDatabaseProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActionPaneWidth();
      _startAutoSync();
    });
  }

  @override
  void dispose() {
    _saveActionPaneWidthTimer?.cancel();
    _syncTimer?.cancel();
    if (_actionPaneWidthChanged) {
      unawaited(_database.saveActionPaneWidth(_actionPaneWidth));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(taskPaneFocusRequestProvider, (_, __) {
      if (_compactWorkspace && mounted && _mobilePageIndex != 1) {
        setState(() => _mobilePageIndex = 1);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _compactWorkspace =
                constraints.maxWidth < _mobileWorkspaceBreakpoint;
            if (_compactWorkspace) {
              return _MobileWorkspace(
                selectedIndex: _mobilePageIndex,
                onDestinationSelected: (index) {
                  setState(() => _mobilePageIndex = index);
                },
              );
            }

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

  void _startAutoSync() {
    if (ref.read(appRunModeProvider).valueOrNull != AppRunMode.sync) {
      return;
    }
    unawaited(_performSync(showSuccessMessage: false));
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_performSync(showSuccessMessage: true));
    });
  }

  Future<void> _performSync({required bool showSuccessMessage}) async {
    try {
      final coordinator = await ref.read(syncCoordinatorProvider.future);
      if (coordinator == null) {
        return;
      }
      final result = await coordinator.sync();
      if (!mounted) {
        return;
      }
      if (result.hasChanges) {
        ref.invalidate(taskListProvider);
        ref.invalidate(tagListProvider);
        if (showSuccessMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('同步完成：$result'),
              duration: const Duration(seconds: 2),
              backgroundColor: _accent,
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步失败：$error'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _scheduleActionPaneWidthSave(double width) {
    _actionPaneWidthChanged = true;
    _saveActionPaneWidthTimer?.cancel();
    _saveActionPaneWidthTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_database.saveActionPaneWidth(width));
    });
  }
}

class _MobileWorkspace extends ConsumerWidget {
  const _MobileWorkspace({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageIndex = selectedIndex.clamp(0, 3);
    return Scaffold(
      backgroundColor: _faint,
      body: IndexedStack(
        index: pageIndex,
        children: const [
          _TaskListPane(),
          _KeepAlivePane(child: _AddTaskPanel()),
          _KeepAlivePane(child: _SummaryPanel()),
          _KeepAlivePane(child: _HistoryPanel()),
        ],
      ),
      floatingActionButton: pageIndex == 0
          ? FloatingActionButton(
              tooltip: '添加任务',
              onPressed: () {
                ref.read(selectedTaskProvider.notifier).state = null;
                ref.read(editingTaskProvider.notifier).state = null;
                onDestinationSelected(1);
              },
              child: const Icon(Icons.add_task),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: pageIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rtl_outlined),
            selectedIcon: Icon(Icons.checklist_rtl),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_task_outlined),
            selectedIcon: Icon(Icons.add_task),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '总结',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
        ],
      ),
    );
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
