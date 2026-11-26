part of 'pr_overview_tab.dart';

/// The Overview tab's top row: the (editable) PR title on the left and the
/// PR-level actions on the right. Wraps to two lines on narrow widths.
class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.pr,
    required this.prRef,
    required this.canEdit,
    required this.onOpenReview,
  });

  final PullRequest pr;
  final PrRef prRef;
  final bool canEdit;
  final VoidCallback onOpenReview;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = EditablePrTitle(pr: pr, prRef: prRef, canEdit: canEdit);
        final actions = PrDetailActions(
          pr: pr,
          prRef: prRef,
          onOpenReview: onOpenReview,
        );
        // Below ~560px the title + action cluster can't share a row without
        // squeezing; stack them instead.
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: actions,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}
