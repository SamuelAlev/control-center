part of 'personal_connection_card.dart';

mixin _PersonalCredentialActions on ConsumerState<PersonalConnectionCard> {
  final _token = TextEditingController();
  final _email = TextEditingController();

  /// Bitbucket API tokens authenticate with the Atlassian account's email,
  /// stored together as `email:token`.
  bool get _needsEmail => widget.providerId == 'bitbucket';
  String? _error;
  bool _busy = false;
  bool _confirmRemove = false;
  bool _editing = false;
  bool get _sameWorkspace =>
      ref.read(activeWorkspaceIdProvider).value == widget.workspaceId;
  bool get _authorized => widget.canManage && _sameWorkspace;

  void _refresh() {
    if (widget.isForge) {
      ref.invalidate(remoteForgeConnectionsProvider);
    } else {
      ref.invalidate(remoteTicketConnectionsProvider);
    }
  }

  /// Stores a pasted GitLab or Bitbucket token. Sign-in lanes never take one.
  Future<void> _save() async {
    var token = _token.text.trim();
    if (!_authorized ||
        _busy ||
        token.isEmpty ||
        widget.lane != null ||
        !widget.isForge) {
      return;
    }
    if (_needsEmail) {
      final email = _email.text.trim();
      if (!RegExp(r'^[^\s@:]+@[^\s@:]+\.[^\s@:]+$').hasMatch(email)) {
        setState(
          () => _error = AppLocalizations.of(
            context,
          ).credentialsAtlassianEmailInvalid,
        );
        return;
      }
      token = '$email:$token';
    }
    final providerId = widget.providerId;
    final workspaceId = widget.workspaceId;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      // The person's own token for the forge, used in every workspace.
      await client.call('credentials.setForgeToken', {
        'forge': providerId,
        'token': token,
      });
      if (!mounted ||
          widget.providerId != providerId ||
          widget.workspaceId != workspaceId) {
        return;
      }
      _token.clear();
      _email.clear();
      if (!_authorized) return;
      setState(() => _editing = false);
      _refresh();
    } on Object catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        setState(
          () => _error =
              _tokenRefusalMessage(l, e) ?? l.credentialsOperationFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Why the server refused the pasted token, in words the person can act
  /// on; null when [error] is not such a refusal.
  String? _tokenRefusalMessage(AppLocalizations l, Object error) {
    final refusal = error is RemoteRpcException
        ? PersonTokenRefusal.ofErrorData(error.data)
        : null;
    return switch (refusal) {
      PersonTokenRefusal.unreachable => l.credentialsTokenUnreachable(
        widget.name,
      ),
      PersonTokenRefusal.rejected => l.credentialsTokenRejected(widget.name),
      PersonTokenRefusal.wrongKind => l.credentialsTokenWrongKind(widget.name),
      PersonTokenRefusal.narrowScope => l.credentialsTokenNarrowScope(
        // The forges' own scope names, never translated.
        _needsEmail ? 'write:pullrequest:bitbucket' : 'api',
      ),
      PersonTokenRefusal.expired => l.credentialsTokenExpired,
      null => null,
    };
  }

  Future<void> _remove() async {
    if (!_authorized || _busy || !_confirmRemove) return;
    final providerId = widget.providerId;
    final workspaceId = widget.workspaceId;
    final lane = widget.lane;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      if (lane != null) {
        // Revokes the grant upstream where the provider allows it.
        await RemoteProviderSignIn(
          client,
        ).disconnect(lane, workspaceId: workspaceId);
      } else {
        await client.call('credentials.clearForgeToken', {'forge': providerId});
      }
      if (!mounted ||
          !_authorized ||
          widget.providerId != providerId ||
          widget.workspaceId != workspaceId ||
          widget.lane != lane) {
        return;
      }
      setState(() => _confirmRemove = false);
      _refresh();
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
}
