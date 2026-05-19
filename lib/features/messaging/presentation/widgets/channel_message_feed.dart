import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_bubble.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FeedItem {
  const _FeedItem({required this.message, this.thinking});
  final ChannelMessage message;
  final ChannelMessage? thinking;
}

List<_FeedItem> _groupTurns(List<ChannelMessage> messages) {
  final result = <_FeedItem>[];
  for (var i = 0; i < messages.length; i++) {
    final msg = messages[i];
    if (msg.isThinking && i + 1 < messages.length) {
      final next = messages[i + 1];
      final isSameAgentReply = !next.isUser &&
          next.messageType == ChannelMessageType.text &&
          next.senderId == msg.senderId;
      if (isSameAgentReply) {
        result.add(_FeedItem(message: next, thinking: msg));
        i++;
        continue;
      }
    }
    result.add(_FeedItem(message: msg));
  }
  return result;
}

const double _bottomThreshold = 50;

/// Scrollable feed of channel messages with auto-scroll and grouping.
class ChannelMessageFeed extends ConsumerStatefulWidget {
  /// Creates a new [ChannelMessageFeed].
  const ChannelMessageFeed({
    super.key,
    required this.channelId,
    this.onReplyInThread,
  });

  /// Channel to display messages for.
  final String channelId;

  /// Callback when user clicks reply-in-thread on a message.
  final void Function(String messageId)? onReplyInThread;

  @override
  ConsumerState<ChannelMessageFeed> createState() => _ChannelMessageFeedState();
}

class _ChannelMessageFeedState extends ConsumerState<ChannelMessageFeed> {
  final _scrollController = ScrollController();
  int _lastCount = 0;
  bool _followBottom = true;
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onPositionChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPositionChanged() {
    if (!_scrollController.hasClients) {
      return;
    }
    final atBottom =
        _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <
        _bottomThreshold;
    if (atBottom && !_followBottom) {
      setState(() {
        _followBottom = true;
        _showFAB = false;
      });
    }
  }

  bool _onUserScroll(UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.forward) {
      if (_followBottom) {
        setState(() {
          _followBottom = false;
          _showFAB = true;
        });
      }
    } else if (notification.direction == ScrollDirection.reverse) {
      if (!_followBottom && _scrollController.hasClients) {
        final atBottom =
            _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            _bottomThreshold;
        if (atBottom) {
          setState(() {
            _followBottom = true;
            _showFAB = false;
          });
        }
      }
    }
    return false;
  }

  void _animateToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final pos = _scrollController.position;
      final gap = pos.maxScrollExtent - pos.pixels;
      if (gap > 5) {
        _scrollController.animateTo(
          pos.maxScrollExtent,
          duration: const Duration(milliseconds: 80),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(channelTopLevelMessagesProvider(widget.channelId));
    final threadMap = ref.watch(threadReplyMapProvider(widget.channelId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.messageSquare,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(l10n.noMessagesYet, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  l10n.sendFirstMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final newMessages = messages.length > _lastCount;
        _lastCount = messages.length;

        if (_followBottom) {
          _animateToBottom();
        } else if (newMessages) {
          setState(() => _showFAB = true);
        }

        final items = _groupTurns(messages);

        return NotificationListener<UserScrollNotification>(
          onNotification: _onUserScroll,
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final preview = threadMap[item.message.id];
                  return ChannelMessageBubble(
                    message: item.message,
                    thinkingMessage: item.thinking,
                    isThreadReply: false,
                    threadPreview: preview,
                    onReplyInThread: widget.onReplyInThread,
                  );
                },
              ),
              if (_showFAB)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: _FABScrollToBottom(
                    onTap: () {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      setState(() {
                        _followBottom = true;
                        _showFAB = false;
                      });
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text(l10n.failedWithError('$e'))),
    );
  }
}

class _FABScrollToBottom extends StatelessWidget {
  const _FABScrollToBottom({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: theme.colorScheme.primary,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            LucideIcons.arrowDown,
            size: 18,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
