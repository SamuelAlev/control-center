part of 'personal_connection_card.dart';

/// One browser sign-in attempt: `oauth.begin`, then `oauth.status` until it
/// settles. In Connect mode the browser shows a confirmation code the person
/// types here (`oauth.complete`); in own mode the provider redirects to the
/// server, which must be reachable over public HTTPS from the phone.
mixin _PersonalConnectionFlow
    on ConsumerState<PersonalConnectionCard>, _PersonalCredentialActions {
  Timer? _timer;
  SignInAttempt? _attempt;
  final _code = TextEditingController();
  bool _polling = false;

  /// Whether this server's sign-in for the lane can finish from a phone.
  bool get _canSignIn {
    final info = widget.laneInfo;
    if (widget.lane == null || info == null) return false;
    return switch (info.mode) {
      SignInLaneMode.connect => true,
      SignInLaneMode.own => phoneCanUseRedirect(info.redirectUri),
      SignInLaneMode.unavailable => false,
    };
  }

  /// Own mode whose callback a phone cannot reach.
  bool get _ownUnreachable {
    final info = widget.laneInfo;
    return widget.lane != null &&
        info != null &&
        info.mode == SignInLaneMode.own &&
        !phoneCanUseRedirect(info.redirectUri);
  }

  @override
  void didUpdateWidget(PersonalConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.providerId != widget.providerId ||
        oldWidget.isForge != widget.isForge ||
        oldWidget.lane != widget.lane) {
      _stop();
      _token.clear();
      _editing = false;
      _confirmRemove = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _token.clear();
    _token.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    final lane = widget.lane;
    if (lane == null ||
        !_authorized ||
        _busy ||
        _attempt != null ||
        !_canSignIn) {
      return;
    }
    final workspaceId = widget.workspaceId;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      final attempt = await RemoteProviderSignIn(
        client,
      ).begin(lane, workspaceId: workspaceId);
      if (!mounted ||
          !_authorized ||
          widget.lane != lane ||
          widget.workspaceId != workspaceId) {
        return;
      }
      final uri = Uri.tryParse(attempt.url);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw StateError('Invalid sign-in URL');
      }
      _code.clear();
      setState(() => _attempt = attempt);
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_poll()),
      );
      openExternal(attempt.url);
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

  /// Hands the code Connect's page showed back to the server.
  Future<void> _confirmCode() async {
    final attempt = _attempt;
    if (attempt == null ||
        attempt.mode != SignInLaneMode.connect ||
        _busy ||
        !_authorized) {
      return;
    }
    final l = AppLocalizations.of(context);
    final code = normaliseConfirmCode(_code.text);
    if (code == null) {
      setState(() => _error = l.credentialsConnectCodeMalformed);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      final result = await RemoteProviderSignIn(client).complete(
        loginId: attempt.loginId,
        code: code,
        workspaceId: widget.workspaceId,
      );
      if (mounted && _attempt?.loginId == attempt.loginId) {
        _settle(result);
      }
    } on RemoteRpcException {
      // The server refused this code; the attempt stays open for another.
      if (mounted) setState(() => _error = l.credentialsSignInInvalidCode);
    } on Object {
      if (mounted) setState(() => _error = l.credentialsOperationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _poll() async {
    final attempt = _attempt;
    if (!mounted || _polling || attempt == null) return;
    if (!_authorized) {
      _stop();
      return;
    }
    if (DateTime.now().toUtc().isAfter(attempt.expiresAt)) {
      _stop(error: AppLocalizations.of(context).credentialsLoginTimedOut);
      return;
    }
    _polling = true;
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      final status = await RemoteProviderSignIn(
        client,
      ).status(attempt.loginId, workspaceId: widget.workspaceId);
      if (mounted && _authorized && _attempt?.loginId == attempt.loginId) {
        _settle(status);
      }
    } on Object {
      // A lost phone connection is not a failed sign-in; wait for expiry.
    } finally {
      _polling = false;
    }
  }

  void _settle(SignInAttempt attempt) {
    switch (attempt.status) {
      case SignInAttemptStatus.pending:
        return;
      case SignInAttemptStatus.succeeded:
        _stop();
        _refresh();
      case SignInAttemptStatus.failed:
        final l = AppLocalizations.of(context);
        _stop(
          error: switch (attempt.error) {
            SignInFailure.expired => l.credentialsLoginTimedOut,
            SignInFailure.invalidCode => l.credentialsSignInInvalidCode,
            _ => l.credentialsOperationFailed,
          },
        );
    }
  }

  void _stop({String? error}) {
    _timer?.cancel();
    _timer = null;
    _code.clear();
    if (!mounted) return;
    setState(() {
      _attempt = null;
      _error = error;
    });
  }
}
