part of 'personal_connection_card.dart';

mixin _PersonalConnectionFlow
    on ConsumerState<PersonalConnectionCard>, _PersonalCredentialActions {
  Timer? _timer;
  String? _loginId;
  String? _verificationUrl;
  String? _userCode;
  DateTime? _expires;
  bool _polling = false;

  @override
  void didUpdateWidget(PersonalConnectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.providerId != widget.providerId ||
        oldWidget.isForge != widget.isForge) {
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
    super.dispose();
  }

  Future<void> _begin() async {
    if (!_authorized || _busy || _verificationUrl != null) return;
    final providerId = widget.providerId;
    final workspaceId = widget.workspaceId;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      final data = await client.call('oauth.begin', {
        'provider': providerId,
        'workspace_id': workspaceId,
      });
      if (!mounted ||
          !_authorized ||
          widget.providerId != providerId ||
          widget.workspaceId != workspaceId) {
        return;
      }
      final mode = data['mode'];
      if (mode == 'device') {
        final code = data['user_code'] as String? ?? '';
        final url = data['verification_uri'] as String? ?? '';
        final id = data['login_id'] as String? ?? '';
        final uri = Uri.tryParse(url);
        if (id.isEmpty ||
            code.isEmpty ||
            uri == null ||
            (uri.scheme != 'http' && uri.scheme != 'https')) {
          throw StateError('Invalid device sign-in response');
        }
        setState(() {
          _loginId = id;
          _userCode = code;
          _verificationUrl = url;
          _expires = DateTime.now().add(
            Duration(seconds: (data['expires_in'] as num?)?.toInt() ?? 900),
          );
        });
        _timer = Timer.periodic(
          const Duration(seconds: 2),
          (_) => unawaited(_poll()),
        );
      } else if (mode == 'redirect') {
        final url = data['url'] as String? ?? '';
        final uri = Uri.tryParse(url);
        if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
          throw StateError('Invalid redirect sign-in response');
        }
        setState(() {
          _verificationUrl = url;
          _expires = DateTime.now().add(const Duration(minutes: 10));
        });
        _timer = Timer.periodic(
          const Duration(seconds: 2),
          (_) => unawaited(_poll()),
        );
        openExternal(url);
      } else {
        throw StateError('Unsupported sign-in response');
      }
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
    if (!mounted || _polling || _verificationUrl == null) return;
    if (!_authorized) {
      _stop();
      return;
    }
    if (DateTime.now().isAfter(_expires!)) {
      _stop(error: AppLocalizations.of(context).credentialsLoginTimedOut);
      return;
    }
    _polling = true;
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      final url = _verificationUrl;
      final loginId = _loginId;
      if (loginId != null) {
        final data = await client.call('oauth.status', {
          'login_id': loginId,
          'workspace_id': widget.workspaceId,
        });
        if (!mounted ||
            !_authorized ||
            _loginId != loginId ||
            _verificationUrl != url) {
          return;
        }
        if (data['status'] == 'succeeded') {
          _stop();
          _refresh();
          return;
        }
        if (data['status'] != 'pending') {
          _stop(error: AppLocalizations.of(context).credentialsOperationFailed);
          return;
        }
      } else {
        _refresh();
        final connected = widget.isForge
            ? (await ref.read(remoteForgeConnectionsProvider.future)).any(
                (c) => c.forge.wire == widget.providerId && c.authenticated,
              )
            : (await ref.read(
                    remoteTicketConnectionsProvider.future,
                  ))[widget.providerId]?.connected ==
                  true;
        if (mounted && _authorized && _verificationUrl == url && connected) {
          _stop();
        }
      }
    } on Object {
      // A lost phone connection is not a failed server login; wait for expiry.
    } finally {
      _polling = false;
    }
  }

  void _stop({String? error}) {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _loginId = null;
      _verificationUrl = null;
      _userCode = null;
      _expires = null;
      _error = error;
    });
  }
}
