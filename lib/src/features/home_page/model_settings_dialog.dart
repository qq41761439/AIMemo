part of '../home_page.dart';

class _ModelSettingsDialog extends StatefulWidget {
  const _ModelSettingsDialog({
    required this.initialSettings,
    required this.repository,
  });

  final ModelSettings initialSettings;
  final ModelSettingsRepository repository;

  @override
  State<_ModelSettingsDialog> createState() => _ModelSettingsDialogState();
}

class _ModelSettingsDialogState extends State<_ModelSettingsDialog> {
  late ModelMode _mode;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _hostedBaseUrlController;
  late final TextEditingController _hostedEmailController;
  late final TextEditingController _hostedCodeController;
  bool _saving = false;
  bool _clearingKey = false;
  bool _sendingCode = false;
  bool _loggingIn = false;
  bool _settingsChanged = false;
  late bool _hasHostedSession;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialSettings.mode;
    _apiKeyController = TextEditingController();
    _baseUrlController = TextEditingController(
      text: widget.initialSettings.baseUrl,
    );
    _modelController = TextEditingController(
      text: widget.initialSettings.model,
    );
    _hostedBaseUrlController = TextEditingController(
      text: widget.initialSettings.hostedBaseUrl.trim().isEmpty
          ? ModelSettings.defaults().hostedBaseUrl
          : widget.initialSettings.hostedBaseUrl,
    );
    _hostedEmailController = TextEditingController();
    _hostedCodeController = TextEditingController();
    _hasHostedSession = widget.initialSettings.hasHostedSession;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _hostedBaseUrlController.dispose();
    _hostedEmailController.dispose();
    _hostedCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSavedApiKey = widget.initialSettings.hasApiKey && !_clearingKey;
    final isCustom = _mode == ModelMode.custom;
    final compactButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 42),
      padding: const EdgeInsets.symmetric(horizontal: 18),
    );
    final compactOutlinedButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 42),
      padding: const EdgeInsets.symmetric(horizontal: 18),
    );

    return AlertDialog(
      title: const Text('模型设置'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadioGroup<ModelMode>(
                groupValue: _mode,
                onChanged: _saving ? (_) {} : _changeMode,
                child: Column(
                  children: [
                    RadioListTile<ModelMode>(
                      value: ModelMode.custom,
                      enabled: !_saving,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('使用自己的模型服务'),
                      subtitle: const Text('兼容 OpenAI /chat/completions 的服务。'),
                    ),
                    RadioListTile<ModelMode>(
                      value: ModelMode.hosted,
                      enabled: !_saving,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('使用官方模型'),
                      subtitle: const Text('登录后免费生成总结。'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (isCustom) ...[
                TextField(
                  controller: _apiKeyController,
                  enabled: !_saving,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: hasSavedApiKey ? '已保存，留空则继续使用' : '输入 API Key',
                  ),
                ),
                if (hasSavedApiKey)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _clearApiKey,
                      icon: const Icon(Icons.key_off_outlined, size: 18),
                      label: const Text('清除已保存密钥'),
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _baseUrlController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _modelController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'gpt-4o-mini',
                  ),
                ),
              ] else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasHostedSession) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 22,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '官方托管模型已登录',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _hostedBaseUrl,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: _muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          style: compactOutlinedButtonStyle,
                          onPressed: _saving || _loggingIn || _sendingCode
                              ? null
                              : _clearHostedSession,
                          icon: const Icon(Icons.logout_outlined, size: 18),
                          label: const Text('退出登录'),
                        ),
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hostedEmailController,
                              enabled: !_saving && !_loggingIn && !_sendingCode,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: '邮箱',
                                hintText: 'you@example.com',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: compactOutlinedButtonStyle,
                            onPressed: _saving || _loggingIn || _sendingCode
                                ? null
                                : _sendHostedCode,
                            icon: _sendingCode
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.mail_outline),
                            label: const Text('发送验证码'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _hostedCodeController,
                        enabled: !_saving && !_loggingIn && !_sendingCode,
                        decoration: const InputDecoration(
                          labelText: '验证码',
                          hintText: '6 位验证码',
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        style: compactButtonStyle,
                        onPressed: _saving || _loggingIn || _sendingCode
                            ? null
                            : _loginHosted,
                        icon: _loggingIn
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login_outlined),
                        label: const Text('登录/注册'),
                      ),
                    ],
                  ],
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _ErrorText(_error!),
              ],
            ],
          ),
        ),
      ),
      actions: isCustom
          ? [
              TextButton(
                onPressed: _saving
                    ? null
                    : () => Navigator.of(context).pop(_settingsChanged),
                child: const Text('取消'),
              ),
              FilledButton.icon(
                style: compactButtonStyle,
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('保存'),
              ),
            ]
          : [
              TextButton(
                onPressed: _saving || _loggingIn || _sendingCode
                    ? null
                    : () => Navigator.of(context).pop(_settingsChanged),
                child: Text(_hasHostedSession ? '完成' : '取消'),
              ),
            ],
    );
  }

  void _changeMode(ModelMode? mode) {
    if (mode == null) {
      return;
    }
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _clearApiKey() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.clearApiKey();
      if (!mounted) {
        return;
      }
      setState(() {
        _clearingKey = true;
        _apiKeyController.clear();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _sendHostedCode() async {
    setState(() {
      _sendingCode = true;
      _error = null;
    });
    try {
      await widget.repository.startHostedEmailLogin(
        hostedBaseUrl: _hostedBaseUrl,
        email: _hostedEmailController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送，请查看邮箱或后端控制台。')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sendingCode = false);
      }
    }
  }

  Future<void> _loginHosted() async {
    setState(() {
      _loggingIn = true;
      _error = null;
    });
    try {
      await widget.repository.verifyHostedEmailLogin(
        hostedBaseUrl: _hostedBaseUrl,
        email: _hostedEmailController.text,
        code: _hostedCodeController.text,
      );
      await widget.repository.save(
        mode: ModelMode.hosted,
        baseUrl: _baseUrlController.text,
        model: _modelController.text,
        hostedBaseUrl: _hostedBaseUrl,
        apiKey: _apiKeyController.text,
      );
      if (mounted) {
        setState(() {
          _hasHostedSession = true;
          _settingsChanged = true;
          _hostedCodeController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('官方托管模型已登录。')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loggingIn = false);
      }
    }
  }

  Future<void> _clearHostedSession() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.clearHostedSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _hasHostedSession = false;
        _settingsChanged = true;
        _hostedCodeController.clear();
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        mode: _mode,
        baseUrl: _baseUrlController.text,
        model: _modelController.text,
        hostedBaseUrl: _hostedBaseUrlController.text,
        apiKey: _apiKeyController.text,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('模型设置已保存。')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String get _hostedBaseUrl {
    final value = _hostedBaseUrlController.text.trim();
    return value.isEmpty ? ModelSettings.defaults().hostedBaseUrl : value;
  }
}
