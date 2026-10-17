part of 'space_screen.dart';

extension _SpaceMessages on _SpaceScreenState {
  void _updateWindow(List<MessageDto> messages) {
    final liveIds = {for (final m in messages) m.id};
    _keptTiles.removeWhere((id, _) => !liveIds.contains(id));
    _rowKeys.removeWhere((id, _) => !liveIds.contains(id));
    if (messages.length == _lastMessageCount) return;
    final grew = messages.length > _lastMessageCount;
    _lastMessageCount = messages.length;
    if (grew && _follow.loadingOlder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _follow.loadingOlder = false;
        _maybeLoadOlder();
      });
    }
  }

  void _scheduleRead(List<MessageDto> messages) {
    final id = messages.isEmpty ? 'empty' : messages.last.id;
    if (_markingRead ||
        _readError != null ||
        _lastReadId == id ||
        ModalRoute.of(context)?.isCurrent != true ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    _markingRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          ref.read(activeWorkspaceIdProvider).value != widget.workspaceId) {
        _markingRead = false;
        return;
      }
      try {
        final client = ref.read(rpcClientProvider).value;
        if (client == null) throw StateError('Connection unavailable');
        await RemoteSpaceReadRepository(client).markSpaceRead(
          widget.workspaceId,
          widget.spaceId,
          conversationId: widget.conversationId,
        );
        _lastReadId = id;
      } catch (error) {
        _set(() => _readError = error);
      } finally {
        _markingRead = false;
      }
    });
  }

  Widget _messageFeed(
    DesignSystemTokens t,
    AsyncValue<({List<MessageDto> messages, bool hasMore})> feed,
    List<MessageDto> messages,
    PhoneTurnRelay turns,
    bool active,
  ) {
    final l10n = AppLocalizations.of(context);
    final linkedId = widget.messageId;
    return Column(
      children: [
        if (linkedId != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: ref
                  .watch(
                    linkedMessageProvider((scope: _scope, messageId: linkedId)),
                  )
                  .when(
                    loading: () => const CcSpinner(),
                    error: (e, _) => CcAlert(
                      title: l10n.messagesLoadFailed,
                      description: Text('$e'),
                    ),
                    data: (message) => message == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l10n.mobileLinkedMessage),
                              SpaceMessageTile(
                                message: message,
                                myUserId: _myUserId,
                                userNames: _userNames,
                                turns: turns,
                              ),
                              CcButton(
                                size: CcButtonSize.lg,
                                variant: CcButtonVariant.secondary,
                                onPressed: () => context.go(
                                  remoteSpaceLocation(
                                    workspaceId: widget.workspaceId,
                                    spaceId: widget.spaceId,
                                    conversationId: widget.conversationId,
                                  ),
                                ),
                                child: Text(l10n.jumpToLatest),
                              ),
                            ],
                          ),
                  ),
            ),
          ),
        Expanded(
          child: feed.when(
            loading: () => const Center(child: CcSpinner(size: 24)),
            error: (e, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CcEmptyState(
                  icon: AppIcons.triangleAlert,
                  message: l10n.messagesLoadFailed,
                  description: '$e',
                ),
                CcButton(
                  onPressed: () =>
                      ref.invalidate(conversationFeedProvider(_scope)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
            data: (_) {
              final visible = messages.where((m) => m.id != linkedId).toList();
              if (visible.isEmpty) {
                return CcEmptyState(
                  icon: AppIcons.messageCircle,
                  message: l10n.noMessagesYet,
                  description: l10n.noMessagesDescription,
                );
              }
              final physics = ScrollConfiguration.of(
                context,
              ).getScrollPhysics(context);
              final capped =
                  ref.watch(remoteFeedWindowProvider(_feedKey)) >=
                  kRemoteFeedMaxWindow;
              return NotificationListener<UserScrollNotification>(
                onNotification: (n) {
                  if (_follow.mode == FollowMode.following &&
                      n.direction != ScrollDirection.idle) {
                    _releaseFollowing();
                  }
                  return false;
                },
                child: Listener(
                  onPointerDown: (_) => _releaseFollowing(),
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        physics: ReverseFollowPhysics(
                          state: _follow,
                        ).applyTo(physics),
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            visible.length + (_hasMore || capped ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == visible.length) {
                            return capped
                                ? CcButton(
                                    size: CcButtonSize.lg,
                                    variant: CcButtonVariant.secondary,
                                    onPressed: () => context.push(
                                      remoteWorkspaceLocation(
                                        '/spaces/${Uri.encodeComponent(widget.spaceId)}/history?conversation_id=${Uri.encodeQueryComponent(widget.conversationId)}',
                                        widget.workspaceId,
                                      ),
                                    ),
                                    child: Text(l10n.mobileOlderMessages),
                                  )
                                : const Center(child: CcSpinner(size: 16));
                          }
                          final message = visible[visible.length - 1 - index];
                          return RepaintBoundary(
                            child: KeyedSubtree(
                              key: _rowKeys.putIfAbsent(
                                message.id,
                                GlobalKey.new,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _messageTile(message, turns)),
                                  PhoneIconButton(
                                    icon: AppIcons.moreHorizontal,
                                    semanticLabel: l10n.mobileMessageActions,
                                    onPressed: () => _messageActions(message),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_showJump)
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 12,
                          child: Center(
                            child: JumpToLatest(
                              onTap: _jumpToLatest,
                              isStreaming:
                                  active &&
                                  _scroll.hasClients &&
                                  _scroll.position.pixels > kFollowPinThreshold,
                              newCount: _newWhileAway,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _messageTile(MessageDto message, PhoneTurnRelay turns) {
    final kept = _keptTiles[message.id];
    if (kept != null &&
        _sameMessage(kept.message, message) &&
        kept.myUserId == _myUserId &&
        identical(kept.userNames, _userNames) &&
        identical(kept.turns, turns)) {
      return kept.child;
    }
    final tile = SpaceMessageTile(
      message: message,
      myUserId: _myUserId,
      userNames: _userNames,
      turns: turns,
    );
    _keptTiles[message.id] = _KeptTile(
      message,
      _myUserId,
      _userNames,
      turns,
      tile,
    );
    return tile;
  }

  Future<void> _messageActions(MessageDto message) async {
    final l10n = AppLocalizations.of(context);
    final writable = ref.read(workspaceRoleProvider).value?.canWrite == true;
    final failed =
        message.metadata is Map &&
        (message.metadata as Map)['error'] == true &&
        (message.metadata as Map)['retried'] != true;
    final action = await showCcDialog<String>(
      context: context,
      builder: (dialog) => CcDialog(
        title: l10n.mobileMessageActions,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (writable && !widget.conversation.isThread)
              CcButton(
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () => Navigator.pop(dialog, 'thread'),
                child: Text(l10n.mobileOpenThread),
              ),
            if (writable && failed)
              CcButton(
                size: CcButtonSize.lg,
                fullWidth: true,
                onPressed: () => Navigator.pop(dialog, 'retry'),
                child: Text(l10n.retry),
              ),
            CcButton(
              size: CcButtonSize.lg,
              fullWidth: true,
              onPressed: () => Navigator.pop(dialog, 'link'),
              child: Text(l10n.mobileCopyLink),
            ),
          ],
        ),
        actions: [
          CcButton(
            size: CcButtonSize.lg,
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(dialog),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
    if (!mounted ||
        action == null ||
        ref.read(activeWorkspaceIdProvider).value != widget.workspaceId) {
      return;
    }
    try {
      switch (action) {
        case 'thread':
          await openRemoteThread(context, ref, message);
        case 'retry':
          final client = ref.read(rpcClientProvider).value;
          if (client == null) throw StateError('Connection unavailable');
          await RemoteMessagingDispatch(client).retryAgentTurn(
            workspaceId: widget.workspaceId,
            spaceId: widget.spaceId,
            failedMessageId: message.id,
          );
        case 'link':
          await Clipboard.setData(
            ClipboardData(
              text: Uri.base
                  .resolve(
                    remoteSpaceLocation(
                      workspaceId: widget.workspaceId,
                      spaceId: widget.spaceId,
                      conversationId: widget.conversationId,
                      messageId: message.id,
                    ),
                  )
                  .toString(),
            ),
          );
      }
    } catch (error) {
      _draft.error = error;
      _draft.changed();
    }
  }
}

class _KeptTile {
  const _KeptTile(
    this.message,
    this.myUserId,
    this.userNames,
    this.turns,
    this.child,
  );
  final MessageDto message;
  final String? myUserId;
  final Map<String, String> userNames;
  final PhoneTurnRelay turns;
  final Widget child;
}

bool _sameMessage(MessageDto a, MessageDto b) =>
    a.content == b.content &&
    a.senderId == b.senderId &&
    a.senderType == b.senderType &&
    a.messageType == b.messageType &&
    a.compacted == b.compacted &&
    a.createdAt == b.createdAt &&
    a.spaceId == b.spaceId &&
    a.conversationId == b.conversationId &&
    _sameValue(a.metadata, b.metadata);
bool _sameValue(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && _sameValue(a[key], b[key]));
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameValue(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
