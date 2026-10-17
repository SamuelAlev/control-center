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
  final status = statusLineFor(segments);
  if (status == null) {
    return l10n.transcriptThinking;
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
