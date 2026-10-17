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

  Future<void> _save() async {
    final token = _token.text.trim();
    if (!_authorized || _busy || token.isEmpty) return;
    final providerId = widget.providerId;
    final workspaceId = widget.workspaceId;
    final isForge = widget.isForge;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      await client.call(
        isForge ? 'credentials.setForgeToken' : 'credentials.setTicketingToken',
        {
          if (isForge) 'forge': providerId else 'provider': providerId,
          'token': token,
          'workspace_id': workspaceId,
        },
      );
      if (!mounted ||
          widget.providerId != providerId ||
          widget.workspaceId != workspaceId ||
          widget.isForge != isForge) {
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
    final isForge = widget.isForge;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = ref.read(rpcClientProvider).requireValue;
      await client.call(
        isForge
            ? 'credentials.clearForgeToken'
            : 'credentials.clearTicketingToken',
        {
          if (isForge) 'forge': providerId else 'provider': providerId,
          'workspace_id': workspaceId,
        },
      );
      if (!mounted ||
          !_authorized ||
          widget.providerId != providerId ||
          widget.workspaceId != workspaceId ||
          widget.isForge != isForge) {
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
