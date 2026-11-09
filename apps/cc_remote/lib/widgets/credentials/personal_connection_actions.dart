part of 'personal_connection_card.dart';

mixin _PersonalCredentialActions on ConsumerState<PersonalConnectionCard> {
  final _token = TextEditingController();
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
    final token = _token.text.trim();
    if (!_authorized ||
        _busy ||
        token.isEmpty ||
        widget.lane != null ||
        !widget.isForge) {
      return;
    }
    final providerId = widget.providerId;
    final workspaceId = widget.workspaceId;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      await client.call('credentials.setForgeToken', {
        'forge': providerId,
        'token': token,
        'workspace_id': workspaceId,
      });
      if (!mounted ||
          widget.providerId != providerId ||
          widget.workspaceId != workspaceId) {
        return;
      }
      _token.clear();
      if (!_authorized) return;
      setState(() => _editing = false);
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

  Future<void> _remove() async {
    if (!_authorized || _busy || !_confirmRemove || widget.hostManaged) return;
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
        await client.call('credentials.clearForgeToken', {
          'forge': providerId,
          'workspace_id': workspaceId,
        });
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
