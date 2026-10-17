part of 'harness_connection_card.dart';

mixin _HarnessConnectionFlow on ConsumerState<HarnessConnectionCard> {
  final _secret = TextEditingController();
  final _code = TextEditingController();
  Timer? _timer;
  HarnessOAuthStart? _flow;
  RpcHarnessProviderRepository? _flowRepo;
  String? _error;
  bool _busy = false;
  bool _polling = false;
  DateTime? _deadline;
  String? _confirmRemovalId;

  @override
  void didUpdateWidget(HarnessConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.info.id != widget.info.id) {
      unawaited(_cancel());
      _secret.clear();
      _confirmRemovalId = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    final id = _flow?.flowId;
    final repo = _flowRepo;
    if (id != null && repo != null) {
      unawaited(repo.cancelOAuth(id).catchError((Object _) {}));
    }
    _secret.clear();
    _code.clear();
    _secret.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _sameWorkspace =>
      ref.read(activeWorkspaceIdProvider).value == widget.workspaceId;
  bool get _authorized =>
      widget.canManage &&
      ref.read(remoteIdentityProvider).value?.isServerOwner == true &&
      _sameWorkspace;
  RpcHarnessProviderRepository get _repo =>
      RpcHarnessProviderRepository(ref.read(rpcClientProvider).requireValue);

  Future<void> _save() async {
    final value = _secret.text.trim();
    if (!_authorized || value.isEmpty || _busy) return;
    final providerId = widget.info.id;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.saveApiKey(providerId: providerId, apiKey: value);
      if (!mounted || widget.info.id != providerId) return;
      _secret.clear();
      if (!_authorized) return;
      ref.invalidate(remoteHarnessProvidersProvider);
    } on Object {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context).credentialsOperationFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(HarnessCredentialSummary? credential) async {
    final credentialId = credential?.credentialId;
    if (!_authorized ||
        _busy ||
        (credential == null
            ? !widget.info.isCustom || !widget.info.hasCredential
            : !credential.removable) ||
        _confirmRemovalId != (credentialId ?? '')) {
      return;
    }
    final providerId = widget.info.id;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.removeCredential(
        providerId: providerId,
        credentialId: credentialId,
      );
      if (!mounted || !_authorized || widget.info.id != providerId) return;
      setState(() => _confirmRemovalId = null);
      ref.invalidate(remoteHarnessProvidersProvider);
    } on Object {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context).credentialsOperationFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() async {
    if (!_authorized || _busy || _flow != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = _repo;
      final providerId = widget.info.id;
      final flow = await repo.startOAuth(providerId);
      if (!mounted || !_authorized || widget.info.id != providerId) {
        await repo.cancelOAuth(flow.flowId);
        return;
      }
      final uri = Uri.tryParse(flow.authUrl);
      if (flow.flowId.isEmpty ||
          uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        if (flow.flowId.isNotEmpty) await repo.cancelOAuth(flow.flowId);
        throw StateError('Invalid provider authorization URL');
      }
      _flowRepo = repo;
      setState(() {
        _flow = flow;
        _deadline = DateTime.now().add(const Duration(minutes: 15));
      });
      // If the browser blocks the new tab, the Open button remains available.
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_poll()),
      );
      openExternal(flow.authUrl);
    } on Object {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context).credentialsOperationFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _poll() async {
    final flow = _flow;
    if (!mounted || _polling || flow == null) return;
    if (!_authorized) {
      await _cancel();
      return;
    }
    if (DateTime.now().isAfter(_deadline!)) {
      await _cancel(timedOut: true);
      return;
    }
    _polling = true;
    try {
      final result = await (_flowRepo ?? _repo).oauthStatus(flow.flowId);
      if (!mounted || !_authorized || _flow?.flowId != flow.flowId) return;
      if (result.state == HarnessOAuthState.completed) {
        _timer?.cancel();
        _code.clear();
        setState(() {
          _flow = null;
          _flowRepo = null;
          _deadline = null;
        });
        ref.invalidate(remoteHarnessProvidersProvider);
      } else if (result.state == HarnessOAuthState.error) {
        _timer?.cancel();
        _code.clear();
        setState(() {
          _flow = null;
          _flowRepo = null;
          _deadline = null;
          _error = result.error?.isNotEmpty == true
              ? result.error
              : AppLocalizations.of(context).credentialsOperationFailed;
        });
      }
    } on Object {
      // An interrupted connection is not a failed OAuth authorization.
      // Keep polling while the flow is live; expiry produces a visible error.
    } finally {
      _polling = false;
    }
  }

  Future<void> _complete() async {
    final flow = _flow;
    final code = _code.text.trim();
    if (flow == null ||
        !flow.supportsManualPaste ||
        flow.isDeviceCode ||
        code.isEmpty ||
        !_authorized ||
        _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (_flowRepo ?? _repo).completeOAuth(flowId: flow.flowId, code: code);
      if (!mounted || _flow?.flowId != flow.flowId) return;
      _timer?.cancel();
      _code.clear();
      if (!_authorized) {
        await _cancel();
        return;
      }
      setState(() {
        _flow = null;
        _flowRepo = null;
        _deadline = null;
      });
      ref.invalidate(remoteHarnessProvidersProvider);
    } on Object {
      if (mounted) {
        setState(
          () =>
              _error = AppLocalizations.of(context).credentialsOperationFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel({bool timedOut = false}) async {
    _timer?.cancel();
    final flow = _flow;
    if (flow == null) return;
    final repo = _flowRepo;
    _code.clear();
    setState(() {
      _flow = null;
      _flowRepo = null;
      _deadline = null;
      _error = timedOut
          ? AppLocalizations.of(context).credentialsLoginTimedOut
          : null;
    });
    try {
      await (repo ?? _repo).cancelOAuth(flow.flowId);
    } on Object {
      if (mounted && !timedOut) {
        setState(
          () =>
              _error = AppLocalizations.of(context).credentialsOperationFailed,
        );
      }
    }
  }
}
