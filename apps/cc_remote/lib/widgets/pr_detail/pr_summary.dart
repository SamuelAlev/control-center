import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/pr_row.dart';
import 'package:cc_remote/widgets/workspace_avatar.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Title, lifecycle, refs, churn badges, and reviewer chips.
class PrSummary extends StatelessWidget {
  /// Creates a [PrSummary].
  const PrSummary({super.key, required this.pr, required this.reviewers});

  /// The pull request.
  final PullRequest pr;

  /// Requested and completed reviewers.
  final List<PrReviewer> reviewers;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pr.title,
          style: TextStyle(
            fontSize: 19,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(prLifecycleIcon(pr), size: 16, color: prLifecycleColor(t, pr)),
            const SizedBox(width: 6),
            Text(
              prLifecycleLabel(l10n, pr),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: prLifecycleColor(t, pr),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${pr.headRef} → ${pr.baseRef}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // RTL carve-out: branch names read LTR in every locale.
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CcBadge(
              label: l10n.filesCount(pr.changedFiles),
              variant: CcBadgeVariant.neutral,
            ),
            if (churn(pr.additions, pr.deletions).isNotEmpty)
              CcBadge(
                label: churn(pr.additions, pr.deletions),
                variant: CcBadgeVariant.neutral,
              ),
            CcBadge(
              label: l10n.commitsCount(pr.commitsCount),
              variant: CcBadgeVariant.neutral,
            ),
            if (pr.mergeableState == PrMergeableState.dirty)
              CcBadge(label: l10n.conflicts, variant: CcBadgeVariant.danger),
          ],
        ),
        if (pr.labels.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in pr.labels)
                CcColorTag(
                  label: label.name,
                  color: label.color,
                  tooltip: label.description.isEmpty ? null : label.description,
                  compact: true,
                ),
            ],
          ),
        ],
        if (reviewers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Reviewers(reviewers: reviewers),
        ],
      ],
    );
  }
}

String _nameOf(PrReviewer r) => switch (r) {
  PrUserReviewer(:final user) => user.login,
  PrTeamReviewer(:final name, :final slug) => name.isEmpty ? slug : name,
};

String? _avatarOf(PrReviewer r) => switch (r) {
  PrUserReviewer(:final user) => user.avatarUrl,
  PrTeamReviewer(:final avatarUrl) => avatarUrl,
};

class _Reviewers extends StatelessWidget {
  const _Reviewers({required this.reviewers});

  final List<PrReviewer> reviewers;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          AppLocalizations.of(context).reviewers,
          style: TextStyle(fontSize: 12, color: t.textTertiary),
        ),
        for (final r in reviewers)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RemoteAvatar(
                url: _avatarOf(r),
                fallbackLabel: _nameOf(r),
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                _nameOf(r),
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
              const SizedBox(width: 3),
              Icon(
                switch (r.state) {
                  PrReviewSubmissionState.approved => AppIcons.circleCheck,
                  PrReviewSubmissionState.changesRequested => AppIcons.circleX,
                  PrReviewSubmissionState.commented => AppIcons.messageSquare,
                  PrReviewSubmissionState.pending => AppIcons.clock,
                },
                size: 12,
                color: switch (r.state) {
                  PrReviewSubmissionState.approved => t.textSuccessPrimary,
                  PrReviewSubmissionState.changesRequested =>
                    t.textErrorPrimary,
                  _ => t.fgTertiary,
                },
              ),
            ],
          ),
      ],
    );
  }
}
