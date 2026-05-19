import 'dart:async';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_name_color.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_flow.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_preview_bar.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders an agent turn as a flat, full-column block: a small name-only
/// header (no avatar, no bubble chrome), then a continuous body — the
/// collapsible process transcript (reasoning / tools / errors) flowing into
/// the visible answer — followed by a quiet metadata line.
///
/// agent turns read like a document, not a bubble. User messages stay right-aligned bubbles; this is the calm agent
/// side. Streaming live while the run is active.
class AgentTurn extends ConsumerStatefulWidget {
  /// Creates an [AgentTurn].
  const AgentTurn({
    super.key,
    required this.message,
    required this.codeFont,
    this.isThreadReply = false,
    this.threadPreview,
    this.onReplyInThread,
    this.collapseHeader = false,
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

  /// When true, the name header is omitted and top padding tightens — used for
  /// consecutive same-sender turns so the name is not repeated (openchamber).
  final bool collapseHeader;

  @override
  ConsumerState<AgentTurn> createState() => _AgentTurnState();
}

class _AgentTurnState extends ConsumerState<AgentTurn> {
  StreamSubscription<TranscriptUpdate>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant AgentTurn old) {
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
      widget.message.metadata?['error'] == true
          ? widget.message.metadata
          : null;
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
    final registry = ref.watch(activeStreamRegistryProvider);

    final isLive = registry.isActive(message.id);
    final segments =
        (isLive ? registry.snapshot(message.id) : null) ?? message.transcript;

    // The in-reply-to caption attributes a wake/consult/delegation turn to the
    // agent that triggered it, so multi-agent rooms read as a conversation.
    final inReplyTo = message.metadata?['inReplyToAgentName'] as String?;

    // Flat turns breathe between turn boundaries; grouped (collapseHeader) and
    // thread replies stay tight. The bubble owns its spacing so the feed does
    // not need to.
    final topPad = widget.isThreadReply || widget.collapseHeader
        ? AppSpacing.xxs
        : AppSpacing.xl;

    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Semantics(
        label: '$agentName: ${message.content}',
        child: FocusableBubble(
          isThreadReply: widget.isThreadReply,
          messageId: message.id,
          onReplyInThread: widget.onReplyInThread,
          copyText: message.content,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.collapseHeader) ...[
                Text(
                  agentName,
                  style: AppFonts.codeDynamic(
                    widget.codeFont,
                    textStyle: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: agentNameColor(message.senderId, tokens),
                    ),
                  ),
                ),
                if (inReplyTo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      '↳ ${AppLocalizations.of(context).replyingTo(inReplyTo)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: tokens.textQuaternary),
                    ),
                  ),
              ] else if (inReplyTo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    '↳ ${AppLocalizations.of(context).replyingTo(inReplyTo)}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: tokens.textQuaternary),
                  ),
                ),
              if (segments.isNotEmpty || isLive) ...[
                const SizedBox(height: AppSpacing.sm),
                TranscriptFlow(
                  segments: segments,
                  isLive: isLive,
                  codeFont: widget.codeFont,
                ),
              ] else if (message.content.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                TurnProse(
                  content: message.content,
                  codeFont: widget.codeFont,
                ),
              ],
              _AgentTrailer(
                message: message,
                codeFont: widget.codeFont,
                tokens: tokens,
                theme: theme,
              ),
              if (_failed) ...[
                const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context).retried,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: tokens.textQuaternary, fontStyle: FontStyle.italic),
                ),
              ],
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
    );
  }

}

/// The quiet trailing line under an agent turn: the timestamp, then —
/// once the turn has resolved (`turnOutcome != null`) — duration · cost ·
/// tokens, in a mono, tabular-figures style (DESIGN.md `mono-num`). The
/// timestamp is always shown (so a turn is dateable even mid-stream); the
/// metadata is appended only when known. Replaces the per-prose-block timestamp
/// the old bubble body printed, so the continuous flow has exactly one.
class _AgentTrailer extends StatelessWidget {
  const _AgentTrailer({
    required this.message,
    required this.codeFont,
    required this.tokens,
    required this.theme,
  });

  final ChannelMessage message;
  final String codeFont;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final line = _compose(message);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        line,
        style: AppFonts.codeDynamic(
          codeFont,
          textStyle: theme.textTheme.labelSmall?.copyWith(
            color: tokens.textQuaternary,
            fontSize: 11,
          ),
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }

  String _compose(ChannelMessage message) {
    final parts = <String>[formatTime(message.createdAt)];
    if (message.turnOutcome == null) {
      return parts.join(' · ');
    }
    final ms = message.turnDurationMs;
    if (ms != null) {
      parts.add(_formatDuration(ms));
    }
    final cents = message.turnCostCents;
    if (cents != null && cents > 0) {
      parts.add('\$${(cents / 100).toStringAsFixed(2)}');
    }
    final tokens = message.turnTotalTokens;
    if (tokens != null && tokens > 0) {
      parts.add(_formatTokens(tokens));
    }
    return parts.join(' · ');
  }

  static String _formatDuration(int ms) {
    if (ms < 1000) {
      return '<1s';
    }
    final s = ms ~/ 1000;
    if (s < 60) {
      return '${s}s';
    }
    final m = s ~/ 60;
    final rem = s % 60;
    return rem == 0 ? '${m}m' : '${m}m ${rem}s';
  }

  static String _formatTokens(int tokens) {
    if (tokens < 1000) {
      return '$tokens tok';
    }
    final k = tokens / 1000;
    return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k tok';
  }
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
