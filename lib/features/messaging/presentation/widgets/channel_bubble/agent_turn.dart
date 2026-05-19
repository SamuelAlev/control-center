import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_feedback_bar.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_name_color.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/live_transcript_controller.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_flow.dart';
import 'package:control_center/features/messaging/providers/live_turn_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/format_utils.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
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
    this.collapseHeader = false,
  });

  /// The agent turn message to display.
  final ChannelMessage message;

  /// Font family for code blocks.
  final String codeFont;

  /// When true, the name header is omitted and top padding tightens — used for
  /// consecutive same-sender turns so the name is not repeated (openchamber).
  final bool collapseHeader;

  @override
  ConsumerState<AgentTurn> createState() => _AgentTurnState();
}

class _AgentTurnState extends ConsumerState<AgentTurn> {
  /// Fans the live update stream into structure/tail pulses so only the turn
  /// body (and, per delta, only the open row) rebuilds — never the whole turn
  /// per token like the old subscription+`setState` did.
  late LiveTranscriptController _live;

  @override
  void initState() {
    super.initState();
    _live = LiveTranscriptController(
      ref.read(activeStreamRegistryProvider),
      widget.message.id,
    );
  }

  @override
  void didUpdateWidget(covariant AgentTurn old) {
    super.didUpdateWidget(old);
    if (old.message.id != widget.message.id) {
      _live.dispose();
      _live = LiveTranscriptController(
        ref.read(activeStreamRegistryProvider),
        widget.message.id,
      );
    }
  }

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _erroredMeta =>
      widget.message.metadata?['error'] == true
      ? widget.message.metadata
      : null;
  bool get _failed => _erroredMeta != null && !_retried;
  bool get _retried => widget.message.metadata?['retried'] == true;
  String? get _errorFamily => _erroredMeta?['errorFamily'] as String?;

  /// The turn ended cleanly but unfinished: the loop hit its turn ceiling.
  /// Not an error (no retry affordance), but not a completion either — the
  /// feedback bar makes no sense on a cut-short turn, so it is hidden too.
  bool get _turnLimited => widget.message.turnOutcome == TurnOutcome.maxTurns;

  /// Accessibility label for the whole turn, capped so a long answer doesn't
  /// force the semantics tree to re-diff a multi-KB string per update. While
  /// live, just the name — the feed already paces live announcements.
  String _semanticsLabel(String agentName) {
    if (_live.isLive) {
      return agentName;
    }
    final content = widget.message.content;
    final capped = content.length > 200
        ? '${content.substring(0, 200)}…'
        : content;
    return '$agentName: $capped';
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final tokens = resolveTokens(context);
    final agentAsync = ref.watch(agentDetailProvider(message.senderId));
    final agentName =
        agentAsync.value?.name ?? message.senderId.substring(0, 4);

    // The in-reply-to caption attributes a wake/consult/delegation turn to the
    // agent that triggered it, so multi-agent rooms read as a conversation.
    final inReplyTo = message.metadata?['inReplyToAgentName'] as String?;

    // Flat turns breathe between turn boundaries; grouped (collapseHeader) and
    // thread replies stay tight. The bubble owns its spacing so the feed does
    // not need to.
    final topPad = widget.collapseHeader ? AppSpacing.xxs : AppSpacing.xl;

    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Semantics(
        label: _semanticsLabel(agentName),
        child: FocusableBubble(
          messageId: message.id,
          channelId: message.channelId,
          copyText: message.content,
          canRevert: true,
          // Fill the conversation column so CrossAxisAlignment.start anchors
          // the turn to the left edge even when it has no body yet (just the
          // name header + trailer). Without this the Column shrink-wraps to its
          // widest child and the feed's topCenter wrapper centres the whole
          // block — which reads as a stray centred name.
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.collapseHeader) ...[
                  Text(
                    agentName,
                    style: AppFonts.codeDynamic(
                      widget.codeFont,
                      textStyle: CcTypography.caption.copyWith(
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
                        style: CcTypography.caption.copyWith(
                          color: tokens.textQuaternary,
                        ),
                      ),
                    ),
                ] else if (inReplyTo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      '↳ ${AppLocalizations.of(context).replyingTo(inReplyTo)}',
                      style: CcTypography.caption.copyWith(
                        color: tokens.textQuaternary,
                      ),
                    ),
                  ),
                // Only the body area rebuilds on structural stream changes
                // (and, per delta, only the open row inside TranscriptFlow) —
                // the header, trailer, and Semantics stay out of the live
                // update path entirely.
                ValueListenableBuilder<int>(
                  valueListenable: _live.structure,
                  builder: (context, _, _) => _TurnBody(
                    message: message,
                    live: _live,
                    codeFont: widget.codeFont,
                  ),
                ),
                _AgentTrailer(
                  message: message,
                  codeFont: widget.codeFont,
                  tokens: tokens,
                ),
                if (!_failed && !_turnLimited && message.turnOutcome != null)
                  AgentFeedbackBar(message: message),
                if (_turnLimited) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const _TurnLimitBadge(),
                ],
                if (_failed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _FailedBadge(
                    errorFamily: _errorFamily,
                    onRetry: () => ref
                        .read(messagingServiceProvider)
                        .retryAgentTurn(
                          workspaceId: ref.requireWorkspaceId(),
                          channelId: message.channelId,
                          failedMessageId: message.id,
                        ),
                  ),
                ] else if (_retried) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppLocalizations.of(context).retried,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textQuaternary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The turn body: the transcript flow (live or persisted) or, transcript-less,
/// the answer prose. Split out of [AgentTurn] so live structural updates
/// rebuild only this subtree (under the `ValueListenableBuilder` on
/// [LiveTranscriptController.structure]).
class _TurnBody extends ConsumerWidget {
  const _TurnBody({
    required this.message,
    required this.live,
    required this.codeFont,
  });

  final ChannelMessage message;
  final LiveTranscriptController live;
  final String codeFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = live.isLive;
    // Segment source order: live registry → persisted metadata (one-shot /
    // pre-lite rows) → transcript cache (seeded on turn finish) → one-time
    // fetch for lite list rows (`segments_elided`). While the fetch is in
    // flight the bubble renders `message.content` — the answer text — so a
    // history row is never blank, just process-detail-light for a beat.
    List<TranscriptSegment> segments;
    if (isLive) {
      segments = live.snapshot ?? const [];
    } else {
      segments = message.transcript;
      if (segments.isEmpty) {
        final cached = ref.watch(transcriptCacheProvider).get(message.id);
        // An EMPTY cache entry is not an answer — treat it as a miss so it can
        // never shadow the `segments_elided` refetch below (which is the only
        // path that can still load a transcript the relay never carried).
        if (cached != null && cached.isNotEmpty) {
          segments = cached;
        } else if (message.metadata?['segments_elided'] == true) {
          segments =
              ref.watch(messageTranscriptProvider(message.id)).value ??
              const [];
        }
      }
    }

    if (segments.isNotEmpty || isLive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          TranscriptFlow(
            segments: segments,
            isLive: isLive,
            live: isLive ? live : null,
            codeFont: codeFont,
          ),
        ],
      );
    }
    if (message.content.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          TurnProse(content: message.content, codeFont: codeFont),
        ],
      );
    }
    if (_isPending(ref)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // TranscriptFlow already owns the right affordance for "working, no
          // output yet": with an empty segment list its live tail is the
          // shimmered status line, which resolves to "Thinking…" and stops
          // animating under reduced motion.
          TranscriptFlow(segments: const [], isLive: true, codeFont: codeFont),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// Whether this turn has been dispatched but has produced nothing yet.
  ///
  /// The row is inserted (with `streamComplete: false`) the moment the run
  /// starts, while the *client's* stream registry only learns of the turn on
  /// its first relay frame — the server registers the turn in its own registry.
  /// Everything in between (worktree setup, prompt build, waiting on the first
  /// upstream byte) used to render as a bare name + timestamp, which reads
  /// exactly like "answered with nothing".
  ///
  /// Gated on the run still being active, so a turn stranded by a server
  /// restart degrades to the old blank body instead of shimmering "Thinking…"
  /// forever: its row keeps `streamComplete: false` for good, because the
  /// orphan-run reaper closes the run log without finalizing the message.
  bool _isPending(WidgetRef ref) {
    if (message.isStreamingComplete || message.turnOutcome != null) {
      return false;
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return false;
    }
    final runs = ref
        .watch(
          conversationActiveRunsProvider((
            workspaceId: workspaceId,
            conversationId: message.conversationId,
          )),
        )
        .asData
        ?.value;
    return runs != null && runs.any((r) => r.id == message.id);
  }
}

/// The quiet trailing line under an agent turn: the timestamp, then —
/// once the turn has resolved (`turnOutcome != null`) — duration · cost ·
/// tokens, in a mono, tabular-figures style (DESIGN.md `mono-num`). The
/// timestamp is always shown (so a turn is dateable even mid-stream); the
/// metadata is appended only when known. Replaces the per-prose-block timestamp
/// the old bubble body printed, so the continuous flow has exactly one.
///
/// Only the **time run** is an [AppTimestamp] target. The line is one visual
/// unit, but wrapping the whole composed string would make the duration, cost,
/// and token counts show a click cursor, pop the timestamp hover card, and copy
/// an ISO instant on tap — none of which they describe. The metadata run is
/// inert text carrying its own leading separator, so the line still reads
/// unbroken with identical metrics (same mono style, so the default
/// [CrossAxisAlignment.center] lands both runs on the same baseline).
class _AgentTrailer extends StatelessWidget {
  const _AgentTrailer({
    required this.message,
    required this.codeFont,
    required this.tokens,
  });

  final ChannelMessage message;
  final String codeFont;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.codeDynamic(
      codeFont,
      textStyle: CcTypography.caption.copyWith(
        color: tokens.textQuaternary,
        fontSize: 11,
      ),
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final meta = _composeMeta(message);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          AppTimestamp(
            dateTime: message.createdAt,
            child: Text(formatTime(message.createdAt), style: style),
          ),
          if (meta.isNotEmpty)
            Flexible(
              child: Text(
                meta,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  /// The run appended after the time — duration · cost · tokens — carrying its
  /// own leading separator so the line reads as one. Empty while the turn is
  /// still in flight (no resolved outcome, so no totals to report).
  String _composeMeta(ChannelMessage message) {
    if (message.turnOutcome == null) {
      return '';
    }
    final parts = <String>[];
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
    return parts.isEmpty ? '' : ' · ${parts.join(' · ')}';
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

/// A quiet badge for a turn that stopped at the loop's turn ceiling: warns
/// that the run is unfinished and that a plain reply keeps it going. Distinct
/// from [_FailedBadge] — nothing errored, so no retry affordance, and the
/// warning (not error) color keeps it informational rather than alarming.
class _TurnLimitBadge extends StatelessWidget {
  const _TurnLimitBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.octagonAlert, size: 14, color: tokens.fgWarningPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            AppLocalizations.of(context).turnLimitReached,
            style: CcTypography.caption.copyWith(
              color: tokens.textWarningPrimary,
            ),
          ),
        ),
      ],
    );
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
    final l10n = AppLocalizations.of(context);
    final label = errorFamily == null
        ? l10n.messageFailed
        : '${l10n.messageFailed} · $errorFamily';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.circleAlert, size: 14, color: tokens.textErrorPrimary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: CcTypography.caption.copyWith(
              color: tokens.textErrorPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CcButton(
          onPressed: onRetry,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
