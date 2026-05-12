part of '../home_page.dart';

class _StartupLoadingPage extends StatelessWidget {
  const _StartupLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ErrorText(error.toString()),
        ),
      ),
    );
  }
}

class _StartupChoicePage extends ConsumerStatefulWidget {
  const _StartupChoicePage();

  @override
  ConsumerState<_StartupChoicePage> createState() => _StartupChoicePageState();
}

class _StartupChoicePageState extends ConsumerState<_StartupChoicePage> {
  bool _showLogin = false;
  bool _savingLocal = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(modelSettingsRepositoryProvider);
    final settings = ref.watch(modelSettingsProvider);

    return Scaffold(
      backgroundColor: _faint,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _panel,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_outlined,
                              color: _accent,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AIMemo',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '选择这台设备的使用方式',
                                  style: _captionStyle(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _savingLocal ? null : _continueLocal,
                              icon: _savingLocal
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.computer_outlined),
                              label: const Text('本地运行'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _savingLocal
                                  ? null
                                  : () => setState(() {
                                        _showLogin = true;
                                        _error = null;
                                      }),
                              icon: const Icon(Icons.sync_outlined),
                              label: const Text('登录同步'),
                            ),
                          ),
                        ],
                      ),
                      if (_showLogin) ...[
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 18),
                        settings.when(
                          data: (initialSettings) => _HostedAccountLoginForm(
                            initialSettings: initialSettings,
                            repository: repository,
                            signedInTitle: 'AIMemo 账号已登录',
                            loginButtonLabel: '登录并同步',
                            allowLogout: false,
                            onVerified: (hostedBaseUrl) async {
                              await repository.saveAppRunMode(AppRunMode.sync);
                            },
                            onSessionChanged: (_) {
                              ref.invalidate(modelSettingsProvider);
                              ref.invalidate(appRunModeProvider);
                              ref.invalidate(hostedQuotaProvider);
                              ref.invalidate(hostedSummaryHistoryProvider);
                            },
                          ),
                          loading: () => const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (error, _) => _ErrorText(error.toString()),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _ErrorText(_error!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueLocal() async {
    setState(() {
      _savingLocal = true;
      _error = null;
    });
    try {
      await ref
          .read(modelSettingsRepositoryProvider)
          .saveAppRunMode(AppRunMode.local);
      ref.invalidate(appRunModeProvider);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _savingLocal = false);
      }
    }
  }
}
