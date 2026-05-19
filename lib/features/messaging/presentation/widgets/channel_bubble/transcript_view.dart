import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/services/transcript_status.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_segment_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:control_center/shared/widgets/transcript/widgets/shimmer_text.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A collapsible timeline of an agent turn's *process* — the reasoning spans,
/// tool calls, errors, and sandbox violations that lead up to the answer.
///
/// Pure render over the supplied [segments] (the non-text portion of a
/// channel message's transcript); the parent rebuilds it on each live update by
/// re-reading the active-stream snapshot, so this widget needs no stream
/// subscription of its own. Visible answer text is rendered by the bubble, not
/// here, so the two compose cleanly.
class TranscriptView extends StatefulWidget {
  /// Creates a [TranscriptView].
  const TranscriptView({
    super.key,
    required this.segments,
    required this.codeFont,
    this.isLive = false,
  });

  /// Process segments in chronological order ([TextSegment]s excluded).
  final List<TranscriptSegment> segments;

  /// Mono font for rich code/diff/terminal bodies.
  final String codeFont;

  /// Whether the agent is still emitting segments.
  final bool isLive;

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final segments = widget.segments;

    if (segments.isEmpty && !widget.isLive) {
      return const SizedBox.shrink();
    }

    // While live, keep the timeline open so the user watches work happen.
    final showBody = _expanded || (widget.isLive && segments.isNotEmpty);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            isLive: widget.isLive,
            segments: segments,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
            tokens: tokens,
            theme: theme,
          ),
          if (showBody)
            _Body(
              segments: segments,
              isLive: widget.isLive,
              codeFont: widget.codeFont,
              tokens: tokens,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isLive,
    required this.segments,
    required this.expanded,
    required this.onToggle,
    required this.tokens,
    required this.theme,
  });

  final bool isLive;
  final List<TranscriptSegment> segments;
  final bool expanded;
  final VoidCallback onToggle;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: tokens.textTertiary,
      fontWeight: FontWeight.w500,
    );

    final Widget summary;
    if (isLive) {
      summary = ShimmerText(_liveStatus(segments, l10n), style: labelStyle);
    } else {
      summary = Text(
        _doneSummary(segments, l10n),
        style: labelStyle,
        overflow: TextOverflow.ellipsis,
      );
    }

    return CcTappable(
      onPressed: onToggle,
      builder: (context, states) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                size: 14,
                color: tokens.fgTertiary,
              ),
            ),
            Expanded(child: summary),
          ],
        ),
      ),
    );
  }

  String _liveStatus(List<TranscriptSegment> segments, AppLocalizations l10n) {
    final status = statusLineFor(segments);
    if (status == null) {
      return l10n.transcriptThinking;
    }
    return switch (status.kind) {
      TranscriptStatusKind.thinking => l10n.transcriptThinking,
      TranscriptStatusKind.readingFiles => l10n.transcriptStatusReadingFiles,
      TranscriptStatusKind.makingEdits => l10n.transcriptStatusMakingEdits,
      TranscriptStatusKind.runningCommands => l10n.transcriptStatusRunningCommands,
      TranscriptStatusKind.searching => l10n.transcriptStatusSearching,
      TranscriptStatusKind.responding => l10n.transcriptStatusResponding,
      TranscriptStatusKind.runningTool =>
        l10n.transcriptStatusRunningTool(humanizeToolName(status.toolName ?? '')),
    };
  }

  String _doneSummary(List<TranscriptSegment> segments, AppLocalizations l10n) {
    final totalMs = segments.fold<int>(0, (acc, s) => acc + (s.durationMs ?? 0));
    final base = l10n.transcriptThoughtFor(_formatDuration(totalMs));
    final toolCalls = segments.whereType<ToolSegment>().length;
    if (toolCalls > 0) {
      return '$base · ${l10n.transcriptToolCalls(toolCalls)}';
    }
    return base;
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
}

class _Body extends StatelessWidget {
  const _Body({
    required this.segments,
    required this.isLive,
    required this.codeFont,
    required this.tokens,
  });

  final List<TranscriptSegment> segments;
  final bool isLive;
  final String codeFont;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: tokens.borderSecondary),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < segments.length; i++)
              TranscriptSegmentRow(
                segment: segments[i],
                codeFont: codeFont,
                pending: isLive &&
                    i == segments.length - 1 &&
                    segments[i] is ToolSegment &&
                    (segments[i] as ToolSegment).status ==
                        ToolSegmentStatus.running,
              ),
          ],
        ),
      ),
    );
  }
}
