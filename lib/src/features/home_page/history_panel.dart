part of '../home_page.dart';

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
