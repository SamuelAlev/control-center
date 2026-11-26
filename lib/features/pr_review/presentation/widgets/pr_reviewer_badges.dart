import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_team_avatar.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/widgets.dart';

/// Avatar for a [PrReviewer] row: a user avatar, a team logo, or — for a
/// merged team — the team logo with the reviewing member's avatar badged on it.
class PrReviewerAvatar extends StatelessWidget {
  /// Creates a [PrReviewerAvatar].
  const PrReviewerAvatar({super.key, required this.reviewer});

  /// The reviewer whose avatar is rendered.
  final PrReviewer reviewer;

  @override
  Widget build(BuildContext context) {
    final r = reviewer;
    if (r is PrUserReviewer) {
      return GitHubUserAvatar(
        login: r.user.login,
        avatarUrl: r.user.avatarUrl,
        size: 24,
      );
    }
    final team = r as PrTeamReviewer;
    final teamGlyph = GitHubTeamAvatar(
      name: team.name,
      avatarUrl: team.avatarUrl,
      size: 24,
    );
    if (team.reviewedBy == null) {
      return teamGlyph;
    }
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          teamGlyph,
          PositionedDirectional(
            end: -2,
            bottom: -2,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      context.designSystem?.bgPrimary ??
                      DesignSystemTokens.light().bgPrimary,
                  width: 1.5,
                ),
              ),
              child: GitHubUserAvatar(
                login: team.reviewedBy!.login,
                avatarUrl: team.reviewedBy!.avatarUrl,
                size: 16,
                showHoverCard: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Resting review-verdict glyph for a reviewer row.
class PrReviewerStateDot extends StatelessWidget {
  /// Creates a [PrReviewerStateDot].
  const PrReviewerStateDot({super.key, required this.state});

  /// The reviewer's current submission state.
  final PrReviewSubmissionState state;

  /// The words for [state], used by the glyph's tooltip and the row's
  /// screen-reader label alike.
  static String labelFor(
    PrReviewSubmissionState state,
    AppLocalizations l10n,
  ) => switch (state) {
    PrReviewSubmissionState.approved => l10n.approved,
    PrReviewSubmissionState.changesRequested => l10n.changesRequested,
    PrReviewSubmissionState.commented => l10n.commented,
    PrReviewSubmissionState.pending => l10n.reviewRequested,
  };

  @override
  Widget build(BuildContext context) {
    final muted =
        context.designSystem?.textTertiary ??
        DesignSystemTokens.light().textTertiary;
    final (color, icon) = switch (state) {
      PrReviewSubmissionState.approved => (
        ReviewStatusColors.success,
        AppIcons.checkCircle2,
      ),
      PrReviewSubmissionState.changesRequested => (
        ReviewStatusColors.failure,
        AppIcons.xCircle,
      ),
      PrReviewSubmissionState.commented => (muted, AppIcons.messageCircle),
      PrReviewSubmissionState.pending => (muted, AppIcons.clock),
    };
    return CcTooltip(
      message: labelFor(state, AppLocalizations.of(context)),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
