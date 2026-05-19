import 'dart:async';

import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/core/domain/value_objects/transcript_update.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/bubble_body.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_view.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_preview_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an agent turn: a single `agent_turn` message carrying an ordered
/// transcript (reasoning, tool calls, answer text). Shows a collapsible process
/// timeline above the visible answer, streaming live while the run is active.
class AgentBubble extends ConsumerStatefulWidget {
  /// Creates an [AgentBubble].
  const AgentBubble({
    super.key,
    required this.message,
    required this.codeFont,
    this.isThreadReply = false,
    this.threadPreview,
    this.onReplyInThread,
  });

  /// The agent turn message to display.
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
  ConsumerState<AgentBubble> createState() => _AgentBubbleState();
}

class _AgentBubbleState extends ConsumerState<AgentBubble> {
  StreamSubscription<TranscriptUpdate>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant AgentBubble old) {
    super.didUpdateWidget(old);
    if (old.message.id != widget.message.id) {
      _sub?.cancel();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// While the turn streams, the registry holds the authoritative live segment
  /// list and broadcasts an update per change. We just rebuild on each update
  /// and re-read the snapshot — no local fold needed.
  void _subscribe() {
    final registry = ref.read(activeStreamRegistryProvider);
    final stream = registry.updatesFor(widget.message.id);
    _sub = stream?.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Map<String, dynamic>? get _erroredMeta =>
      widget.message.metadata?['error'] == true ? widget.message.metadata : null;
  bool get _failed => _erroredMeta != null && !_retried;
  bool get _retried => widget.message.metadata?['retried'] == true;
  String? get _errorFamily => _erroredMeta?['errorFamily'] as String?;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final agentAsync = ref.watch(agentDetailProvider(message.senderId));
    final agentName =
        agentAsync.value?.name ?? message.senderId.substring(0, 4);
    final maxWidth = MediaQuery.sizeOf(context).width * maxBubbleFraction;
    final registry = ref.watch(activeStreamRegistryProvider);

    final isLive = registry.isActive(message.id);
    final segments = (isLive ? registry.snapshot(message.id) : null) ??
        message.transcript;
    final process = segments
        .where((s) => s is! TextSegment)
        .toList(growable: false);
    final answer = isLive ? _answerFrom(segments) : message.content;

    // The in-reply-to caption attributes a wake/consult/delegation turn to the
    // agent that triggered it, so multi-agent rooms read as a conversation.
    final inReplyTo = message.metadata?['inReplyToAgentName'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '$agentName: ${message.content}',
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GitHubUserAvatar(
              login: agentName,
              size: avatarSize,
              showHoverCard: false,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: IntrinsicWidth(
                  child: FocusableBubble(
                    isThreadReply: widget.isThreadReply,
                    messageId: message.id,
                    onReplyInThread: widget.onReplyInThread,
                    copyText: message.content,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: bubblePadding,
                          decoration: BoxDecoration(
                            color: tokens.bgPrimary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(bubbleRadius),
                              topRight: Radius.circular(bubbleRadius),
                              bottomLeft: Radius.circular(tailRadius),
                              bottomRight: Radius.circular(bubbleRadius),
                            ),
                            border: Border.all(color: tokens.borderSecondary),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                agentName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                ),
                              ),
                              if (inReplyTo != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    '↳ ${AppLocalizations.of(context).replyingTo(inReplyTo)}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: tokens.textQuaternary,
                                    ),
                                  ),
                                ),
                              if (process.isNotEmpty || isLive) ...[
                                const SizedBox(height: 8),
                                TranscriptView(
                                  segments: process,
                                  isLive: isLive,
                                  codeFont: widget.codeFont,
                                ),
                              ],
                              if (answer.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                BubbleBody(
                                  content: answer,
                                  createdAt: message.createdAt,
                                  codeFont: widget.codeFont,
                                  tokens: tokens,
                                  theme: theme,
                                ),
                              ],
                              if (_failed) ...[
                                const SizedBox(height: 8),
                                _FailedBadge(
                                  errorFamily: _errorFamily,
                                  onRetry: () => ref
                                      .read(messagingServiceProvider)
                                      .retryAgentTurn(
                                        channelId: message.channelId,
                                        failedMessageId: message.id,
                                      ),
                                ),
                              ] else if (_retried) ...[
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).retried,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: tokens.textQuaternary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!widget.isThreadReply && widget.threadPreview != null)
                          ThreadPreviewBar(
                            preview: widget.threadPreview!,
                            onTap: () =>
                                widget.onReplyInThread?.call(message.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _answerFrom(List<TranscriptSegment> segments) => segments
      .whereType<TextSegment>()
      .map((s) => s.text.trim())
      .where((t) => t.isNotEmpty)
      .join('\n\n')
      .trim();
}

/// A quiet failed-run badge with a scoped Retry action.
class _FailedBadge extends StatelessWidget {
  const _FailedBadge({required this.errorFamily, required this.onRetry});

  final String? errorFamily;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final label = errorFamily == null
        ? l10n.messageFailed
        : '${l10n.messageFailed} · $errorFamily';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 14, color: tokens.textErrorPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: tokens.textErrorPrimary),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            foregroundColor: tokens.accent,
          ),
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
