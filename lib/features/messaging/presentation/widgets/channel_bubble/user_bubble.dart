import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/network/models/github_user.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/bubble_body.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_preview_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a user message bubble right-aligned with avatar.
class UserBubble extends ConsumerWidget {
  /// Creates a [UserBubble].
  const UserBubble({
    super.key,
    required this.message,
    required this.codeFont,
    this.isThreadReply = false,
    this.threadPreview,
    this.onReplyInThread,
  });

  /// The user message.
  final ChannelMessage message;
  /// Font family for code blocks.
  final String codeFont;

  /// Whether this bubble is rendered inside a thread panel.
  final bool isThreadReply;

  /// Thread reply metadata for preview bar.
  final ThreadPreviewData? threadPreview;

  /// Callback when user clicks reply-in-thread.
  final void Function(String messageId)? onReplyInThread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final githubUser = ref.watch(githubUserProvider).value;
    final maxWidth = MediaQuery.sizeOf(context).width * maxBubbleFraction;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: 'You: ${message.content}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: IntrinsicWidth(
                  child: FocusableBubble(
                    isThreadReply: isThreadReply,
                    messageId: message.id,
                    onReplyInThread: onReplyInThread,
                    alignRight: true,
                    copyText: message.content,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: bubblePadding,
                          decoration: BoxDecoration(
                            color: tokens.bgSecondary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(bubbleRadius),
                              topRight: Radius.circular(bubbleRadius),
                              bottomLeft: Radius.circular(bubbleRadius),
                              bottomRight: Radius.circular(tailRadius),
                            ),
                            border: Border.all(color: tokens.borderSecondary),
                          ),
                          child: BubbleBody(
                            content: message.content,
                            createdAt: message.createdAt,
                            codeFont: codeFont,
                            tokens: tokens,
                            theme: theme,
                          ),
                        ),
                        if (!isThreadReply && threadPreview != null)
                          ThreadPreviewBar(
                            preview: threadPreview!,
                            onTap: () =>
                                onReplyInThread?.call(message.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildUserAvatar(githubUser),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(GitHubUser? githubUser) {
    final login = githubUser?.login ?? '';
    return GitHubUserAvatar(
      login: login.isEmpty ? 'Y' : login,
      avatarUrl: githubUser?.avatarUrl,
      size: avatarSize,
    );
  }
}
