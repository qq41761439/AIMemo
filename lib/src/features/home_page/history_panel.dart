part of '../home_page.dart';

class _HistoryPanel extends ConsumerWidget {
  const _HistoryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(modelSettingsProvider).valueOrNull;
    final showHostedHistory = settings?.mode == ModelMode.hosted &&
        settings?.hasHostedSession == true;
    final subtitle =
        showHostedHistory ? '官方托管生成的云端总结会显示在这里。' : '生成后的总结会自动保存在这里。';

    return _PanelPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            icon: Icons.history,
            title: '总结历史',
            subtitle: subtitle,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: showHostedHistory
                ? _HostedSummaryHistoryList(
                    summaries: ref.watch(hostedSummaryHistoryProvider),
                  )
                : _LocalSummaryHistoryList(
                    summaries: ref.watch(summaryHistoryProvider),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocalSummaryHistoryList extends StatelessWidget {
  const _LocalSummaryHistoryList({required this.summaries});

  final AsyncValue<List<SummaryRecord>> summaries;

  @override
  Widget build(BuildContext context) {
    return summaries.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyHint(text: '生成的总结会保存在这里。');
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final tags =
                item.tagFilter.isEmpty ? '全部标签' : item.tagFilter.join('、');
            return _SummaryHistoryTile(
              title: '${item.periodType.title} · ${item.periodLabel}',
              subtitle: '$tags · ${compactDateTime(item.createdAt)}',
              output: item.output,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorText(error.toString()),
    );
  }
}

class _HostedSummaryHistoryList extends StatelessWidget {
  const _HostedSummaryHistoryList({required this.summaries});

  final AsyncValue<List<HostedSummaryRecord>> summaries;

  @override
  Widget build(BuildContext context) {
    return summaries.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyHint(text: '云端总结会保存在这里。');
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final tags = item.tags.isEmpty ? '全部标签' : item.tags.join('、');
            return _SummaryHistoryTile(
              title: '${item.periodType.title} · ${item.periodLabel}',
              subtitle:
                  '$tags · ${compactDateTime(item.createdAt)} · ${item.model}',
              output: item.output,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorText(error.toString()),
    );
  }
}

class _SummaryHistoryTile extends StatelessWidget {
  const _SummaryHistoryTile({
    required this.title,
    required this.subtitle,
    required this.output,
  });

  final String title;
  final String subtitle;
  final String output;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: '复制总结',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: output));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('总结已复制。')),
              );
            },
            icon: const Icon(Icons.copy_all_outlined),
          ),
        ),
        SelectableText(output),
        const SizedBox(height: 16),
      ],
    );
  }
}
