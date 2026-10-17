part of 'space_screen.dart';

extension _SpaceMessageFeed on _SpaceScreenState {
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
                                workspaceId: widget.workspaceId,
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
}
