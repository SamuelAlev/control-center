import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_files_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_commits_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Commits tab.
class CommitsTab extends StatelessWidget {
  /// CommitsTab({.
  const CommitsTab({
    super.key,
    required this.commits,
    required this.isLoading,
    required this.error,
    this.totalCommitsCount = 0,
  });
  /// List of commits to display.
  final List<PrCommit> commits;
  /// Whether data is still loading.
  final bool isLoading;
  /// Object?.
  final Object? error;
  /// Total number of commits in the PR (from the PR detail endpoint).
  /// Used to show a "showing latest X of N" notice when truncated.
  final int totalCommitsCount;

  @override
  Widget build(BuildContext context) {
    if (isLoading && commits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: FCircularProgress()),
      );
    }
    if (error != null && commits.isEmpty) {
      return SectionError(error: error!);
    }
    final showTruncationNotice =
        totalCommitsCount > 0 && commits.length < totalCommitsCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTruncationNotice)
            _TruncationNotice(
              loaded: commits.length,
              total: totalCommitsCount,
            ),
          PrCommitsCard(commits: commits),
        ],
      ),
    );
  }
}

class _TruncationNotice extends StatelessWidget {
  const _TruncationNotice({required this.loaded, required this.total});

  final int loaded;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Icon(
            LucideIcons.info,
            size: 13,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.commitsShowingLatest(loaded, total),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

