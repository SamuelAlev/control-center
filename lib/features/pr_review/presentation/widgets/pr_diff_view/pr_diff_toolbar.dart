import 'package:control_center/features/pr_review/domain/entities/issue_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/commit_range_selector.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/toolbar_chips.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PrDiffToolbar extends StatelessWidget {
  const PrDiffToolbar({
    super.key,
    required this.fileCount,
    required this.additions,
    required this.deletions,
    required this.commentCount,
    this.commits = const [],
    this.selectedCommitShas = const {},
    this.onCommitSelectionChanged,
    this.inlineCommentsController,
    this.splitView = false,
    this.onSplitViewChanged,
    this.issueComments = const [],
    this.reviewComments = const [],
    this.hasDiffUpdate = false,
    this.onRefreshDiff,
    this.totalCommitsCount = 0,
  });

  final bool splitView;
  final ValueChanged<bool>? onSplitViewChanged;
  final PrInlineCommentsController? inlineCommentsController;
  final int fileCount;
  final int additions;
  final int deletions;
  final int commentCount;
  final List<PrCommit> commits;
  final Set<String> selectedCommitShas;
  final void Function(Set<String> shas)? onCommitSelectionChanged;
  final int totalCommitsCount;
  final List<IssueComment> issueComments;
  final List<PrCodeReviewComment> reviewComments;
  final bool hasDiffUpdate;
  final VoidCallback? onRefreshDiff;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.background,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (commits.isNotEmpty)
            CommitRangeSelector(
              commits: commits,
              selectedShas: selectedCommitShas,
              onSelectionChanged: onCommitSelectionChanged,
              totalCommitsCount: totalCommitsCount,
            ),
          if (commits.isNotEmpty) const SizedBox(width: 16),
          Icon(
            LucideIcons.folderTree,
            size: 14,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(width: 6),
          Text(
            '$fileCount file${fileCount == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+$additions',
            style: const TextStyle(
              color: ReviewStatusColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '−$deletions',
            style: const TextStyle(
              color: ReviewStatusColors.failure,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          if (inlineCommentsController != null)
            CommentInboxChip(
              count: commentCount,
              controller: inlineCommentsController!,
              issueComments: issueComments,
              reviewComments: reviewComments,
            )
          else
            CommentCountChip(count: commentCount),
          if (hasDiffUpdate && onRefreshDiff != null) ...[
            const SizedBox(width: 10),
            DiffUpdateChip(onRefresh: onRefreshDiff!),
          ],
          const Spacer(),
          if (onSplitViewChanged != null) ...[
            ViewModeToggle(
              splitView: splitView,
              onChanged: onSplitViewChanged!,
            ),
          ],
        ],
      ),
    );
  }
}
