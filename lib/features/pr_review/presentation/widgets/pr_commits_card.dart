import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pr commits card.
class PrCommitsCard extends StatelessWidget {
  /// PrCommitsCard({super.key,.
  const PrCommitsCard({super.key, required this.commits});

  /// Commits to display.
  final List<PrCommit> commits;

  @override
  Widget build(BuildContext context) {
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.gitCommit,
                  size: 16,
                  color: context.theme.colors.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).prCommits,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.theme.colors.foreground,
                  ),
                ),
                const Spacer(),
                Text(
                  '${commits.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (commits.isEmpty)
              Text(
                'No commits in this PR yet.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              )
            else
              ...List.generate(commits.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i == commits.length - 1 ? 0 : 8,
                  ),
                  child: _CommitTile(commit: commits[i]),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _CommitTile extends ConsumerWidget {
  const _CommitTile({required this.commit});

  final PrCommit commit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    final author = commit.author?.login.isNotEmpty == true
        ? commit.author!.login
        : '';
    final whenLabel = commit.date != null
        ? 'committed ${formatRelative(commit.date)}'
        : '';
    final byLine = [
      if (author.isNotEmpty) author,
      if (whenLabel.isNotEmpty) whenLabel,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.theme.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.gitCommit,
            size: 16,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.title.isEmpty ? '(no commit message)' : commit.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.theme.colors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (byLine.isNotEmpty)
                  Text(
                    byLine,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.theme.colors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.theme.colors.border),
            ),
            child: Text(
              commit.shortSha,
              style: AppFonts.codeDynamic(
                codeFont,
                textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.theme.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

