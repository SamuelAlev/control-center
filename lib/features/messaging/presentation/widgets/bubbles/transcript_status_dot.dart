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
