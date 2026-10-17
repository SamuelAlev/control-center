part of 'space_screen.dart';

extension _SpaceComposer on _SpaceScreenState {
  Future<void> _attach() async {
    final picked = await pickAttachments();
    if (!mounted || picked.isEmpty) return;
    final rejected = picked
        .where((file) => !attachmentFitsLane(file.bytes.length))
        .toList();
    final accepted = [
      for (final file in picked)
        if (!rejected.contains(file)) DraftAttachment(file),
    ];
    _set(
      () => _attachError = rejected.isEmpty
          ? null
          : AppLocalizations.of(context).attachmentsTooLarge(
              rejected.length,
              rejected.map((file) => file.name).join(', '),
            ),
    );
    _pending.addAll(accepted);
    _draft.changed();
    for (final file in accepted) {
      await _uploadDraftAttachment(file);
    }
  }

  Future<void> _uploadDraftAttachment(DraftAttachment file) async {
    if (file.uploading || file.stored != null || !_pending.contains(file)) {
      return;
    }
    file.uploading = true;
    file.error = null;
    _draft.changed();
    try {
      final endpoint = ref.read(mediaEndpointProvider).value;
      if (endpoint == null) {
        throw StateError('Secure upload connection unavailable');
      }
      file.stored = await uploadAttachment(
        picked: file.picked,
        workspaceId: widget.workspaceId,
        endpoint: endpoint,
        order: _pending.indexOf(file),
      );
    } catch (error) {
      file.error = error;
      _draft.error = error;
    } finally {
      file.uploading = false;
      if (_pending.every((item) => item.error == null)) _draft.error = null;
      _draft.changed();
    }
  }

  Future<void> _removeAttachment(DraftAttachment file) async {
    if (_sending || file.uploading) return;
    try {
      if (file.stored case final stored?) {
        final client = ref.read(rpcClientProvider).value;
        if (client == null) throw StateError('Connection unavailable');
        await client.call('files.discard', {
          'workspace_id': widget.workspaceId,
          'file_id': stored.fileId,
        });
      }
      _pending.remove(file);
      if (_pending.every((item) => item.error == null)) _draft.error = null;
    } catch (error) {
      _draft.error = error;
    }
    _draft.changed();
  }

  Future<void> _send() async {
    if (!_draft.ready) return;
    final text = _composer.text.trim();
    if (text.isEmpty && _pending.isEmpty) return;
    final draft = _draft;
    final scope = _scope;
    final client = ref.read(rpcClientProvider).value;
    if (client == null ||
        ref.read(activeWorkspaceIdProvider).value != scope.workspaceId ||
        ref.read(workspaceRoleProvider).value?.canWrite != true) {
      draft.error = StateError(
        'Authenticated workspace connection unavailable',
      );
      draft.changed();
      return;
    }
    draft.sending = true;
    draft.error = null;
    _attachError = null;
    draft.changed();
    try {
      final stored = [for (final file in draft.attachments) file.stored!];
      final refs = stored.map((file) => '@[file:${file.name}]').join(' ');
      final content = refs.isEmpty
          ? text
          : text.isEmpty
          ? refs
          : '$text\n\n$refs';
      final intent = draft.intentKey(
        '$content\u0000${stored.map((file) => file.fileId).join(',')}',
      );
      final dispatch = RemoteMessagingDispatch(client);
      final running =
          ref.read(activeRunLogsProvider(scope.conversationId)).value ??
          const [];
      final active = running.any(
        (run) => const ['pending', 'running', 'paused'].contains(run.status),
      );
      final queued = draft.queueForIntent(active)
          ? await dispatch.enqueueSteering(
              workspaceId: scope.workspaceId,
              spaceId: scope.spaceId,
              conversationId: scope.conversationId,
              content: content,
              attachments: [for (final file in stored) file.toJson()],
              idempotencyKey: '$intent:queue',
            )
          : null;
      if (queued == null) {
        await dispatch.sendAndDispatch(
          scope.workspaceId,
          scope.spaceId,
          content,
          conversationId: scope.conversationId,
          metadata: stored.isEmpty
              ? null
              : {
                  'attachments': [for (final file in stored) file.toJson()],
                },
          idempotencyKey: '$intent:send',
        );
      }
      draft.sent();
    } catch (error) {
      // Text, successful uploads and the logical action key survive a failure.
      // A user retry reuses the server's write ledger rather than duplicating.
      draft.error = error;
    } finally {
      draft.sending = false;
      draft.changed();
    }
  }
}
