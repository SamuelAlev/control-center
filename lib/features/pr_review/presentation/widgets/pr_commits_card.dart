import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pr commits card.
class PrCommitsCard extends StatelessWidget {
  /// PrCommitsCard({super.key,.
  const PrCommitsCard({super.key, required this.commits});

  /// Commits to display.
  final List<PrCommit> commits;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return CcCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(AppIcons.gitCommit, size: 16, color: ds.textTertiary),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).prCommits,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ds.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${commits.length}',
                  style: CcTypography.caption.copyWith(color: ds.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (commits.isEmpty)
              Text(
                'No commits in this PR yet.',
                style: CcTypography.caption.copyWith(color: ds.textTertiary),
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
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final codeFont = ref.watch(codeFontFamilyProvider);
    final author = commit.author?.login.isNotEmpty == true
        ? commit.author!.login
        : '';
    final whenLabel = commit.date != null
        ? AppLocalizations.of(
            context,
          ).committedRelative(formatRelativeTime(context, commit.date))
        : '';
    final byLine = [
      if (author.isNotEmpty) author,
      if (whenLabel.isNotEmpty) whenLabel,
    ].join(' · ');

    Widget? byLineWidget;
    if (byLine.isNotEmpty) {
      byLineWidget = Text(
        byLine,
        style: CcTypography.caption.copyWith(color: ds.textTertiary),
      );
      // The by-line only names a concrete instant when the commit has a date.
      if (commit.date != null) {
        byLineWidget = AppTimestamp(
          dateTime: commit.date!,
          child: byLineWidget,
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ds.borderSecondary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(AppIcons.gitCommit, size: 16, color: ds.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.title.isEmpty ? '(no commit message)' : commit.title,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ds.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                ?byLineWidget,
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ds.bgPrimary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ds.borderSecondary),
            ),
            child: Text(
              commit.shortSha,
              style: AppFonts.codeDynamic(
                codeFont,
                textStyle: CcTypography.caption.copyWith(
                  color: ds.textTertiary,
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
