part of 'transcript_flow.dart';

/// The quiet, shimmering "still working" line shown at the tail of a live turn
/// between steps. Mirrors the status the old accordion header used to show, now
/// as a footer in the continuous flow.
///
/// Quiet, not faint: while a turn is in flight this line is the only thing on
/// screen reporting what the agent is doing, so it takes a body-grade text token
/// (`textSecondary`) rather than the annotation-grade tertiary. That is the
/// colour under reduced motion; while it sweeps, [CcShimmerText] rests on its
/// own AA-clearing floor so the band has room to show.
class _LiveStatusLine extends StatelessWidget {
  const _LiveStatusLine({required this.segments});

  final List<TranscriptSegment> segments;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(
      color: tokens.textSecondary,
      fontWeight: FontWeight.w500,
    );
    return Row(
      children: [
        Flexible(
          child: CcShimmerText(liveStatusLabel(segments, l10n), style: style),
        ),
      ],
    );
  }
}

/// Maps the derived in-flight [TranscriptStatus] to a localized status line.
/// Shared between the live tail indicator and any other "what is the agent
/// doing" surface.
String liveStatusLabel(
  List<TranscriptSegment> segments,
  AppLocalizations l10n,
) {
  final status = _liveStatusOf(segments);
  if (status == null) {
    return l10n.transcriptThinking;
  }
  if (status.kind == TranscriptStatusKind.runningTool &&
      isReplTool(status.toolName ?? '')) {
    return l10n.transcriptStatusRunningScript;
  }
  return switch (status.kind) {
    TranscriptStatusKind.thinking => l10n.transcriptThinking,
    TranscriptStatusKind.readingFiles => l10n.transcriptStatusReadingFiles,
    TranscriptStatusKind.makingEdits => l10n.transcriptStatusMakingEdits,
    TranscriptStatusKind.runningCommands =>
      l10n.transcriptStatusRunningCommands,
    TranscriptStatusKind.searching => l10n.transcriptStatusSearching,
    TranscriptStatusKind.responding => l10n.transcriptStatusResponding,
    TranscriptStatusKind.runningTool => l10n.transcriptStatusRunningTool(
      resolveToolDisplayName(status.toolName ?? ''),
    ),
  };
}

/// The status of a live turn, reading through a running script.
///
/// A script's calls follow its own segment, so while it runs the newest
/// segment is often one of its calls that has already finished. That is not
/// the turn going idle: the newest call still running reports what the agent
/// is doing, and between calls the script itself does.
TranscriptStatus? _liveStatusOf(List<TranscriptSegment> segments) {
  if (segments.isEmpty) {
    return null;
  }
  final last = segments.last;
  if (last is ToolSegment &&
      last.isNested &&
      last.status != ToolSegmentStatus.running) {
    for (var i = segments.length - 1; i >= 0; i--) {
      final seg = segments[i];
      if (seg is ToolSegment && seg.status == ToolSegmentStatus.running) {
        return statusLineFor([seg]);
      }
    }
  }
  return statusLineFor(segments);
}
