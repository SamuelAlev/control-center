part of 'transcript_segment_row.dart';

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.segment,
    required this.pending,
    required this.tokens,
  });

  final TranscriptSegment segment;
  final bool pending;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final seg = segment;
    if (pending) {
      if (reduceMotion) {
        return Icon(
          AppIcons.loaderCircle,
          size: 12,
          color: tokens.fgBrandPrimary,
        );
      }
      return const SizedBox(width: 12, height: 12, child: CcSpinner(size: 12));
    }
    if (seg is ToolSegment) {
      return switch (seg.status) {
        ToolSegmentStatus.running => Icon(
          AppIcons.minus,
          size: 12,
          color: tokens.textQuaternary,
        ),
        ToolSegmentStatus.ok => Icon(
          AppIcons.check,
          size: 12,
          color: tokens.fgSuccessPrimary,
        ),
        // Refused before it ran (by a person, a policy or a hook) is not a
        // tool that failed: a shield says who stopped it.
        ToolSegmentStatus.error
            when nestedCallStateOf(seg) == NestedCallState.denied =>
          Semantics(
            label: AppLocalizations.of(context).transcriptToolDenied,
            child: Icon(
              AppIcons.shieldOff,
              size: 12,
              color: tokens.fgWarningPrimary,
            ),
          ),
        ToolSegmentStatus.error => Icon(
          AppIcons.circleX,
          size: 12,
          color: tokens.fgErrorPrimary,
        ),
        ToolSegmentStatus.interrupted => Icon(
          AppIcons.circleSlash,
          size: 12,
          color: tokens.fgWarningPrimary,
        ),
      };
    }
    if (seg is ErrorSegment) {
      return Icon(AppIcons.circleX, size: 12, color: tokens.fgErrorPrimary);
    }
    if (seg is ViolationSegment) {
      return Icon(AppIcons.shield, size: 12, color: tokens.fgWarningPrimary);
    }
    return const SizedBox(width: 12, height: 12);
  }
}

/// [header], and under it what a long call says it is doing now ("Pushing
/// feature (2 of 8)") while it runs. The line is server text, in English.
class _ToolProgressLine extends StatelessWidget {
  const _ToolProgressLine({
    required this.segment,
    required this.tokens,
    required this.header,
  });

  final TranscriptSegment segment;
  final DesignSystemTokens tokens;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final seg = segment;
    if (seg is! ToolSegment ||
        seg.status != ToolSegmentStatus.running ||
        seg.progress.isEmpty) {
      return header;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 20, bottom: 6),
            child: Text(
              seg.progress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ),
        ),
      ],
    );
  }
}
