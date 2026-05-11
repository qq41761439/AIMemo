part of '../home_page.dart';

class _SummaryPanel extends ConsumerStatefulWidget {
  const _SummaryPanel();

  @override
  ConsumerState<_SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends ConsumerState<_SummaryPanel> {
  PeriodType _periodType = PeriodType.daily;
  late PeriodRange _selectedRange;
  final _templateController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  bool _isGenerating = false;
  bool _templateLoaded = false;
  bool _templateExpanded = false;
  String _loadedTemplateContent = '';
  String? _latestSummary;
  String? _error;

  bool get _templateDirty =>
      _templateLoaded && _templateController.text != _loadedTemplateContent;

  @override
  void initState() {
    super.initState();
    _templateController.addListener(_handleTemplateChanged);
    _selectedRange = periodRangeFor(_periodType, DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplate();
    });
  }

  @override
  void dispose() {
    _templateController.removeListener(_handleTemplateChanged);
    _templateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagListProvider);
    final modelSettings = ref.watch(modelSettingsProvider);

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
          _ConfigRow(
            label: '模型',
            icon: Icons.settings_outlined,
            child: _ModelSettingsButton(
              settings: modelSettings,
              onPressed: () {
                unawaited(_openModelSettings());
              },
            ),
          ),
          const SizedBox(height: 10),
          _ConfigRow(
            label: '周期',
            icon: Icons.date_range_outlined,
            child: _SummaryRangeSelector(
              periodType: _periodType,
              range: _selectedRange,
              onPeriodChanged: (value) {
                unawaited(_changePeriod(value));
              },
              onPickRange: _pickDateRange,
            ),
          ),
          const SizedBox(height: 10),
          _ConfigRow(
            label: '模板',
            icon: Icons.tune,
            alignTop: _templateExpanded,
            child: _InlineTemplateEditor(
              periodType: _periodType,
              controller: _templateController,
              loaded: _templateLoaded,
              expanded: _templateExpanded,
              dirty: _templateDirty,
              onToggleExpanded: () {
                setState(() => _templateExpanded = !_templateExpanded);
              },
              onSave: () {
                unawaited(_saveTemplate());
              },
              onReset: () {
                unawaited(_resetTemplate());
              },
            ),
          ),
          const SizedBox(height: 10),
          _ConfigRow(
            label: '标签',
            icon: Icons.filter_alt_outlined,
            alignTop: true,
            child: _SummaryTagFilter(
              tags: tags,
              selectedTags: _selectedTags,
              onPrune: _pruneSummaryTags,
              onSelectAll: () => setState(_selectedTags.clear),
              onTagSelected: (tag, selected) {
                setState(() {
                  selected ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                });
              },
            ),
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
                    _showSnackBar('总结已复制。');
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
    if (_templateDirty) {
      final shouldSave = await _confirmSaveTemplateBeforeGenerate();
      if (!shouldSave) {
        return;
      }
      await _saveTemplate(showMessage: false);
      if (!mounted) {
        return;
      }
    }
    setState(() {
      _isGenerating = true;
      _error = null;
      _latestSummary = null;
      _templateExpanded = false;
    });

    try {
      final database = ref.read(appDatabaseProvider);
      final range = _selectedRange;
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
      final llmConfig =
          await ref.read(modelSettingsRepositoryProvider).requestConfig();
      final periodText = '${_periodType.placeholderName}（${range.label}）';
      final periodDays = range.end.difference(range.start).inDays;
      final prompt = renderSummaryPrompt(
        template: template,
        periodType: _periodType,
        tasks: tasks,
        tags: selectedTags,
        periodText: periodText,
        periodDays: periodDays,
      );
      final summary = await ref.read(summaryApiClientProvider).generateSummary(
            periodType: _periodType.value,
            period: periodText,
            periodStart: range.start,
            periodEnd: range.end,
            tags: selectedTags,
            tasks: formatTasksForPrompt(tasks),
            template: template,
            prompt: prompt,
            periodDays: periodDays,
            llmConfig: llmConfig,
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
      _showSnackBar('总结已生成并保存到历史。');
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

  Future<void> _openModelSettings() async {
    final repository = ref.read(modelSettingsRepositoryProvider);
    final settings = await repository.load();
    if (!mounted) {
      return;
    }
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _ModelSettingsDialog(
        initialSettings: settings,
        repository: repository,
      ),
    );
    if (saved == true && mounted) {
      ref.invalidate(modelSettingsProvider);
    }
  }

  Future<void> _changePeriod(PeriodType value) async {
    if (value == _periodType) {
      return;
    }
    if (_templateDirty && !await _confirmDiscardTemplateChanges()) {
      return;
    }
    setState(() {
      _periodType = value;
      _templateLoaded = false;
      if (value == PeriodType.custom) {
        _selectedRange = PeriodRange(
          start: _selectedRange.start,
          end: _selectedRange.end,
          label: dateRangeLabel(_selectedRange.start, _selectedRange.end),
        );
      } else {
        _selectedRange = periodRangeFor(value, DateTime.now());
      }
    });
    _loadTemplate();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final minDate = DateTime(2000);
    final maxDate = DateTime(now.year + 5, 12, 31);

    if (_periodType == PeriodType.custom) {
      final initialEnd = _selectedRange.end.subtract(const Duration(days: 1));
      final picked = await showRangePickerDialog(
        context: context,
        minDate: minDate,
        maxDate: maxDate,
        displayedDate: _selectedRange.start,
        selectedRange: DateTimeRange(
          start: _selectedRange.start,
          end: initialEnd,
        ),
        initialPickerType: PickerType.days,
      );
      if (picked == null || !mounted) {
        return;
      }

      final start = _dateOnly(picked.start);
      final end = _dateOnly(picked.end).add(const Duration(days: 1));
      setState(() {
        _selectedRange = PeriodRange(
          start: start,
          end: end,
          label: dateRangeLabel(start, end),
        );
      });
      return;
    }

    final picked = await showDatePickerDialog(
      context: context,
      minDate: minDate,
      maxDate: maxDate,
      displayedDate: _selectedRange.start,
      selectedDate: _selectedRange.start,
      initialPickerType: switch (_periodType) {
        PeriodType.monthly => PickerType.months,
        PeriodType.yearly => PickerType.years,
        _ => PickerType.days,
      },
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedRange = periodRangeFor(_periodType, picked);
    });
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _loadTemplate() async {
    final periodType = _periodType;
    final content = await ref.read(appDatabaseProvider).getTemplate(periodType);
    if (!mounted || _periodType != periodType) {
      return;
    }
    _replaceTemplateText(content);
    setState(() {
      _loadedTemplateContent = content;
      _templateLoaded = true;
    });
  }

  Future<void> _saveTemplate({bool showMessage = true}) async {
    await ref.read(appDatabaseProvider).saveTemplate(
          _periodType,
          _templateController.text,
        );
    if (!mounted) {
      return;
    }
    setState(() => _loadedTemplateContent = _templateController.text);
    ref.invalidate(templateProvider(_periodType));
    if (showMessage) {
      _showSnackBar('模板已保存。');
    }
  }

  Future<void> _resetTemplate() async {
    await ref.read(appDatabaseProvider).resetTemplate(_periodType);
    await _loadTemplate();
    ref.invalidate(templateProvider(_periodType));
    if (mounted) {
      _showSnackBar('模板已恢复默认。');
    }
  }

  void _handleTemplateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _replaceTemplateText(String content) {
    _templateController.removeListener(_handleTemplateChanged);
    _templateController.text = content;
    _templateController.addListener(_handleTemplateChanged);
  }

  void _pruneSummaryTags(List<String> tags) {
    if (_selectedTags.isEmpty) {
      return;
    }
    final availableTags = tags.toSet();
    final nextSelectedTags =
        _selectedTags.where((tag) => availableTags.contains(tag)).toSet();
    if (nextSelectedTags.length == _selectedTags.length) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedTags
          ..clear()
          ..addAll(nextSelectedTags);
      });
    });
  }

  Future<bool> _confirmDiscardTemplateChanges() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('模板还未保存'),
        content: const Text('切换总结类型会丢失当前模板编辑内容。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  Future<bool> _confirmSaveTemplateBeforeGenerate() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('模板还未保存'),
        content: const Text('生成总结前需要先保存当前模板修改。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存并生成'),
          ),
        ],
      ),
    );
    return shouldSave == true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.icon,
    required this.child,
    this.alignTop = false,
  });

  final String label;
  final IconData icon;
  final Widget child;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 86,
          height: _controlHeight,
          child: Row(
            children: [
              Icon(icon, size: 17, color: _muted),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _configLabelStyle(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _ModelSettingsButton extends StatelessWidget {
  const _ModelSettingsButton({
    required this.settings,
    required this.onPressed,
  });

  final AsyncValue<ModelSettings> settings;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = settings.when(
      data: (settings) => settings.statusLabel,
      loading: () => '读取中',
      error: (_, __) => '读取失败',
    );

    return SizedBox(
      height: _controlHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.storage_outlined, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: _configButtonStyle(context),
      ),
    );
  }
}
