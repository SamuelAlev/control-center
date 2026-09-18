part of 'space_screen.dart';

extension _SpaceComposer on _SpaceScreenState {
  Future<void> _attach() async {
    final picked = await pickAttachments();
    if (picked.isEmpty || !mounted) return;
    final hasHttp = ref.read(mediaEndpointProvider).value != null;
    final tooBig = picked
        .where(
          (a) => !attachmentFitsLane(a.bytes.length, hasHttpOrigin: hasHttp),
        )
        .toList();
    final l10n = AppLocalizations.of(context);
    final names = tooBig.map((a) => a.name).join(', ');
    _set(() {
      _pending.addAll(picked.where((a) => !tooBig.contains(a)));
      _attachError = tooBig.isEmpty
          ? null
          : (hasHttp
                ? l10n.attachmentsTooLarge(tooBig.length, names)
                : l10n.attachmentsTooLargeRelay(tooBig.length, names));
    });
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty && _pending.isEmpty) return;
    final client = ref.read(rpcClientProvider).value;
    if (client == null) return;
    _set(() {
      _sending = true;
      _attachError = null;
    });
    try {
      final outgoing = List<PickedAttachment>.of(_pending);
      _composer.clear();
      _set(_pending.clear);
      final workspaceId = ref.read(activeWorkspaceIdProvider).value;
      if (workspaceId == null) return;
      final stored = await uploadAttachments(
        picked: outgoing,
        workspaceId: workspaceId,
        client: client,
        endpoint: ref.read(mediaEndpointProvider).value,
      );
      if (outgoing.isNotEmpty && stored.isEmpty && text.isEmpty) {
        if (mounted) {
          _set(
            () => _attachError = AppLocalizations.of(
              context,
            ).attachmentUploadFailed,
          );
        }
        return;
      }
      await RemoteMessagingDispatch(client).sendAndDispatch(
        workspaceId,
        widget.spaceId,
        _composeWithReferences(text, stored),
        metadata: stored.isEmpty
            ? null
            : {'attachments': [for (final a in stored) a.toJson()]},
      );
      if (mounted && stored.length != outgoing.length) {
        _set(
          () => _attachError = AppLocalizations.of(
            context,
          ).attachmentsLeftOut(outgoing.length - stored.length),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) _set(() => _sending = false);
    }
  }

  String _composeWithReferences(String text, List<MessageAttachment> stored) {
    if (stored.isEmpty) return text;
    final refs = stored.map((a) => '@[file:${a.name}]').join(' ');
    return text.isEmpty ? refs : '$text\n\n$refs';
  }
}
