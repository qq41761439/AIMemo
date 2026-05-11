part of '../home_page.dart';

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
    ref.listen<int>(taskPaneFocusRequestProvider, (_, __) {
      _tabController.animateTo(0);
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
