part of '../home_page.dart';

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
                      '模板 · ${periodType.title}',
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
                labelText: '模板',
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
