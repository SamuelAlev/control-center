import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_reply_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Right-side thread panel showing parent message + replies + reply input.
class ThreadPanel extends ConsumerStatefulWidget {
  /// Creates a [ThreadPanel].
  const ThreadPanel({
    super.key,
    required this.channelId,
    required this.parentMessageId,
    required this.onClose,
  });

  /// The parent channel ID.
  final String channelId;
  /// The parent message ID.
  final String parentMessageId;
  /// Called when the panel should close.
  final VoidCallback onClose;

  @override
  ConsumerState<ThreadPanel> createState() => _ThreadPanelState();
}

class _ThreadPanelState extends ConsumerState<ThreadPanel> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after first build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 80),
        curve: Curves.linear,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final parentAsync = ref.watch(
      channelTopLevelMessagesProvider(widget.channelId),
    );

    // Find parent message from the channel's top-level messages
    final ChannelMessage? parentMessage;
    if (parentAsync.hasValue) {
      parentMessage = parentAsync.value
          ?.where((m) => m.id == widget.parentMessageId)
          .firstOrNull;
    } else {
      parentMessage = null;
    }

    final repliesAsync = ref.watch(
      threadMessagesProvider(widget.parentMessageId),
    );

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border(
          left: BorderSide(color: tokens.borderSecondary, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tokens.borderSecondary, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  l10n.threadLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  icon: Icon(
                    AppIcons.x,
                    size: 18,
                    color: tokens.textTertiary,
                  ),
                  tooltip: l10n.closeThread,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: repliesAsync.when(
              data: (replies) {
                // Auto-scroll when new replies arrive
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToEnd(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: (parentMessage != null ? 1 : 0) + replies.length,
                  itemBuilder: (context, index) {
                    if (parentMessage != null && index == 0) {
                      // Parent message at top
                      return ChannelMessageBubble(
                        message: parentMessage,
                        isThreadReply: true,
                      );
                    }
                    final replyIndex =
                        parentMessage != null ? index - 1 : index;
                    final reply = replies[replyIndex];
                    return ChannelMessageBubble(
                      message: reply,
                      isThreadReply: true,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (e, _) => Center(
                child: Text(l10n.failedWithError('$e'), style: theme.textTheme.bodySmall),
              ),
            ),
          ),

          // Divider + Reply input
          Divider(height: 1, color: tokens.borderSecondary),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ThreadReplyBar(
              channelId: widget.channelId,
              parentMessageId: widget.parentMessageId,
            ),
          ),
        ],
      ),
    );
  }
}
