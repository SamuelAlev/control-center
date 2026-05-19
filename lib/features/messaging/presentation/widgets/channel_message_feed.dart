import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/day_separator.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/feed/reverse_follow_physics.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One rendered row in the feed: a message (with optional paired thinking),
/// or a day separator.
sealed class _FeedItem {
  const _FeedItem();
}

class _MessageItem extends _FeedItem {
  const _MessageItem(this.message, {this.collapseHeader = false});
  final ChannelMessage message;
  final bool collapseHeader;
}

class _DayItem extends _FeedItem {
  const _DayItem(this.day);
  final DateTime day;
}

/// Builds feed items from an ascending message list: inserts day separators on
/// local-date changes, and marks consecutive same-sender messages (<5 min
/// apart) to collapse their header. Each agent turn is a single `agent_turn`
/// message (reasoning, tools, and answer interleaved as a transcript), so there
/// is no separate thinking message to pair.
List<_FeedItem> _buildFeedItems(
  List<ChannelMessage> messages, {
  required bool suppressOldestSeparator,
}) {
  final out = <_FeedItem>[];
  DateTime? lastDay;
  ChannelMessage? prevSender;
  for (final display in messages) {
    final day = DateTime(
      display.createdAt.year,
      display.createdAt.month,
      display.createdAt.day,
    );
    final isFirst = out.isEmpty;
    if (lastDay == null || day != lastDay) {
      if (!(isFirst && suppressOldestSeparator)) {
        out.add(_DayItem(day));
      }
      lastDay = day;
      prevSender = null;
    }

    final collapse = prevSender != null &&
        prevSender.senderId == display.senderId &&
        prevSender.senderType == display.senderType &&
        !display.isSystem &&
        !prevSender.isSystem &&
        display.createdAt.difference(prevSender.createdAt).inMinutes.abs() < 5;

    out.add(_MessageItem(display, collapseHeader: collapse));
    prevSender = display;
  }
  return out;
}

const double _bottomThreshold = 50;
const double _loadMoreThreshold = 400;

/// Scrollable feed of channel messages — windowed (newest-N + load-older),
/// rendered bottom-up via a reverse list so follow-bottom and streaming growth
/// stay anchored without scroll jumps.
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
  final _follow = FollowState();
  bool _showFAB = false;
  String? _lastNewestId;
  int _lastItemCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Jumps to the newest message (offset 0 in the reverse list).
  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) {
      return;
    }
    if (animate) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  /// When the user sends a message, snap back to the bottom even if they had
  /// scrolled up — standard chat behavior. Agent/streaming growth never forces
  /// a scroll: the reverse list keeps the viewport anchored on its own.
  void _onWindowChanged(
    ({List<ChannelMessage> messages, bool hasMore})? next,
  ) {
    final newest = next?.messages.isNotEmpty == true ? next!.messages.last : null;
    final prevId = _lastNewestId;
    _lastNewestId = newest?.id;
    if (newest == null || prevId == null || newest.id == prevId) {
      return;
    }
    if (newest.isUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToBottom();
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final pos = _scrollController.position;
    // Reverse list: offset 0 is the bottom (newest). Show the FAB when the
    // user has scrolled up past the threshold.
    final showFab = pos.pixels > _bottomThreshold;
    if (showFab != _showFAB) {
      setState(() => _showFAB = showFab);
    }
    // Load older messages as the user nears the top (the oldest end, which is
    // the high-offset end in a reverse list). Flag the load so the follow
    // physics does NOT compensate for that top-end growth (only bottom-end
    // streaming growth should be compensated).
    if (pos.maxScrollExtent - pos.pixels < _loadMoreThreshold) {
      _follow.loadingOlder = true;
      ref.read(channelFeedWindowProvider(widget.channelId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final windowAsync =
        ref.watch(channelFeedWindowedProvider(widget.channelId));
    ref.listen(channelFeedWindowedProvider(widget.channelId), (_, next) {
      _onWindowChanged(next.value);
    });
    final threadMap = ref.watch(threadReplyMapProvider(widget.channelId));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Read the last value rather than `.when` so a reload (window growth from
    // loadMore, or a streaming DB flush) never replaces the list with a
    // spinner — which would destroy the ScrollController and snap the reverse
    // list back to the bottom.
    final window = windowAsync.value;
    if (window == null) {
      if (windowAsync.hasError) {
        return Center(child: Text(l10n.failedWithError('${windowAsync.error}')));
      }
      return const Center(child: CcSpinner());
    }

    return Builder(
      builder: (context) {
        final messages = window.messages;
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

        final items = _buildFeedItems(
          messages,
          // Suppress the oldest day separator while more history exists, since
          // earlier same-day messages may sit beyond the window.
          suppressOldestSeparator: window.hasMore,
        );

        // Older messages have finished loading once the item count grows;
        // re-enable bottom-growth compensation on the next frame.
        if (items.length != _lastItemCount) {
          if (items.length > _lastItemCount && _follow.loadingOlder) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _follow.loadingOlder = false;
            });
          }
          _lastItemCount = items.length;
        }

        final platformPhysics =
            ScrollConfiguration.of(context).getScrollPhysics(context);

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              reverse: true,
              physics: ReverseFollowPhysics(state: _follow).applyTo(platformPhysics),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              // +1 for the load-more row at the oldest (top) end.
              itemCount: items.length + (window.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Reverse mapping: index 0 = newest (bottom).
                if (window.hasMore && index == items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CcSpinner()),
                  );
                }
                final item = items[items.length - 1 - index];
                if (item is _DayItem) {
                  return DaySeparator(day: item.day);
                }
                final m = item as _MessageItem;
                final preview = threadMap[m.message.id];
                return ChannelMessageBubble(
                  message: m.message,
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
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                    setState(() => _showFAB = false);
                  },
                ),
              ),
          ],
        );
      },
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
