part of '../home_page.dart';

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

class _OutlinedFilterChip extends StatelessWidget {
  const _OutlinedFilterChip({
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
        onSelected: onSelected,
        backgroundColor: _panel,
        selectedColor: _accentSoft,
        side: BorderSide(
          color: selected ? _accent : _border,
          width: selected ? 1.2 : 1,
        ),
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
