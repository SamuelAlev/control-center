import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/review_artifact_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Says so when the pull request has moved on since the review ran.
///
/// A review is about one commit. Once the author pushes again, every finding
/// in it is a claim about code that may no longer exist — and a reader with no
/// way to tell has to treat the whole review as suspect, which is the same as
/// having no review. The reviewed commit was already being recorded and simply
/// never compared against the live head.
///
/// Renders nothing in the ordinary case: a banner that appears on every review
/// is one nobody reads on the review that needed it.
class ReviewStaleBanner extends ConsumerWidget {
  /// Creates a [ReviewStaleBanner].
  const ReviewStaleBanner({
    super.key,
    required this.pr,
    required this.spaceId,
    required this.onRerun,
    this.rerunning = false,
  });

  /// The pull request as it stands now.
  final PullRequest pr;

  /// The review space whose finalized summary carries the reviewed commit.
  final String spaceId;

  /// Starts a fresh review.
  final VoidCallback onRerun;

  /// Whether a review is already being started.
  final bool rerunning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // From the artifact, NOT its walkthrough: a clean review authors no
    // narrative, so reading the commit off one would leave exactly the reviews
    // that passed unable to report that they had gone stale.
    final reviewedSha = ref.watch(reviewArtifactProvider(spaceId))?.headSha;

    // Both sides must be known before this can claim anything. A review
    // finalized before the commit was recorded, or a PR whose head has not
    // loaded, is not evidence of staleness — and crying stale on a current
    // review is worse than staying quiet on an old one.
    if (reviewedSha == null ||
        reviewedSha.isEmpty ||
        pr.headSha.isEmpty ||
        reviewedSha == pr.headSha) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: t.bgWarningPrimary,
        border: Border(bottom: BorderSide(color: t.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.triangleAlert, size: 15, color: t.fgWarningPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reviewStaleTitle,
                  style: CcTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${l10n.reviewStaleBody} '
                  '${l10n.reviewStaleReviewedAt(_short(reviewedSha))}',
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            loading: rerunning,
            onPressed: rerunning ? null : onRerun,
            icon: AppIcons.sparkles,
            child: Text(l10n.reviewStaleRerun),
          ),
        ],
      ),
    );
  }

  /// Seven characters, the length every git surface shows.
  static String _short(String sha) =>
      sha.length <= 7 ? sha : sha.substring(0, 7);
}
