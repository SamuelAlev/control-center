part of 'personal_connection_card.dart';

/// One browser sign-in attempt: `oauth.begin`, then `oauth.status` until it
/// settles. The browser's last page (Connect's, or this server's own-app
/// callback) shows a confirmation code the person types here
/// (`oauth.complete`); nothing is stored before that. In own mode the
/// provider redirects to the server, which must be reachable over public
/// HTTPS from the phone.
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
    _email.dispose();
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
      final uri = attempt.browserUrl;
      if (uri == null) {
        throw StateError('Invalid sign-in URL');
      }
      _code.clear();
      setState(() => _attempt = attempt);
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => unawaited(_poll()),
      );
      openExternal(uri.toString());
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

  /// Hands the code the sign-in's last page showed (this server's own-app
  /// callback, or Connect's) back to the server.
  Future<void> _confirmCode() async {
    final attempt = _attempt;
    if (attempt == null || _busy || !_authorized) {
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
        final refused = result.status.isTerminal ? null : result.codeError;
        if (refused != null) {
          // A wrong code; the attempt stays open for another.
          setState(() => _error = _failureMessage(l, refused, ''));
        } else {
          _settle(result);
        }
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _error = _failureMessage(l, signInFailureOfRpcError(e), ''),
        );
      }
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
      final status = await RemoteProviderSignIn(client).status(
        attempt.loginId,
        workspaceId: widget.workspaceId,
        lane: attempt.lane,
      );
      if (mounted && _authorized && _attempt?.loginId == attempt.loginId) {
        _settle(status);
      }
    } on Object catch (e) {
      // A server that no longer knows the attempt (cancelled on Connect's
      // page, used, replaced) has answered: end it rather than spin. A lost
      // phone connection is not a failed sign-in; wait for expiry.
      final failure = signInFailureOfRpcError(e);
      if (mounted &&
          _attempt?.loginId == attempt.loginId &&
          (failure == SignInFailure.staleRequest ||
              failure == SignInFailure.attemptUnknown)) {
        _stop(
          error: _failureMessage(AppLocalizations.of(context), failure, ''),
        );
      }
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
        _stop(
          error: _failureMessage(
            AppLocalizations.of(context),
            attempt.error,
            attempt.message,
          ),
        );
    }
  }

  /// What a sign-in failure means, in words a person can act on.
  ///
  /// A provider's own reason for refusing an own app's exchange
  /// ([serverMessage]) is added when the server passed one on.
  String _failureMessage(
    AppLocalizations l,
    SignInFailure? failure,
    String serverMessage,
  ) {
    final message = _failureCopy(l, failure);
    // An account held by another person is said in full by its own sentence.
    final detail = failure == SignInFailure.accountAlreadyBound
        ? ''
        : serverMessage.trim();
    return detail.isEmpty ? message : '$message\n$detail';
  }

  String _failureCopy(AppLocalizations l, SignInFailure? failure) =>
      switch (failure) {
        SignInFailure.attemptUnknown => l.credentialsSignInServerRestarted,
        SignInFailure.expired ||
        SignInFailure.invalidRequest => l.credentialsLoginTimedOut,
        SignInFailure.staleRequest => l.credentialsSignInNoLongerOpen,
        SignInFailure.codeMismatch => l.credentialsSignInInvalidCode,
        SignInFailure.invalidCode => l.credentialsSignInTooManyCodes,
        SignInFailure.providerUnavailable => l.credentialsSignInRetryLater,
        SignInFailure.rateLimited => l.credentialsSignInRateLimited,
        SignInFailure.accessDenied => l.credentialsSignInCancelled,
        SignInFailure.accountAlreadyBound =>
          l.credentialsSignInAccountAlreadyBound,
        SignInFailure.scopeMismatch ||
        SignInFailure.exchangeFailed ||
        SignInFailure.needsSignIn => l.credentialsSignInRefused,
        SignInFailure.storeFailed => l.credentialsSignInNotSaved,
        SignInFailure.misconfigured ||
        SignInFailure.notInstalled ||
        SignInFailure.teamBoundElsewhere ||
        SignInFailure.notAdmin ||
        SignInFailure.suspended ||
        SignInFailure.installBlocked ||
        SignInFailure.unknown ||
        null => l.credentialsOperationFailed,
      };

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
