import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_studio/review_studio_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_ai_review_tab.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The unified review surface — one tab (`pr.review`) that replaced the former
/// separate "AI review" and "Review Studio" tabs.
///
/// Both read the same PR and share one review model: **Findings** is the
/// consensus finding flow (reviewer agents → `review_node` messages → verdict);
/// **Studio** is the deterministic code-graph view (cohorts, multi-axis
/// dashboard, contract/visual diffs). A slim mode switcher toggles between them
/// so the reviewer sees one review, not two competing tabs.
class PrReviewTab extends ConsumerStatefulWidget {
  /// Creates a [PrReviewTab].
  const PrReviewTab({super.key, required this.pr});

  /// The pull request under review.
  final PullRequest pr;

  @override
  ConsumerState<PrReviewTab> createState() => _PrReviewTabState();
}

enum _ReviewMode { findings, studio }

class _PrReviewTabState extends ConsumerState<PrReviewTab> {
  _ReviewMode _mode = _ReviewMode.findings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final parts = widget.pr.repoFullName.split('/');
    final owner = parts.isNotEmpty ? parts.first : '';
    final repo = parts.length > 1 ? parts.sublist(1).join('/') : '';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: t.bgSecondary,
            border: Border(bottom: BorderSide(color: t.lineStrong)),
          ),
          child: Row(
            children: [
              _ModeChip(
                label: l10n.reviewFindings,
                icon: AppIcons.sparkles,
                selected: _mode == _ReviewMode.findings,
                onTap: () => setState(() => _mode = _ReviewMode.findings),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ModeChip(
                label: l10n.reviewStudioTitle,
                icon: AppIcons.boxes,
                selected: _mode == _ReviewMode.studio,
                onTap: () => setState(() => _mode = _ReviewMode.studio),
              ),
            ],
          ),
        ),
        Expanded(
          // Keep both mounted (IndexedStack) so switching modes never re-runs
          // the AI-review resolve or the Studio compute.
          child: IndexedStack(
            index: _mode == _ReviewMode.findings ? 0 : 1,
            children: [
              SingleChildScrollView(child: PrAiReviewTab(pr: widget.pr)),
              ReviewStudioView(
                owner: owner,
                repo: repo,
                prNumber: widget.pr.number,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: selected ? t.bgPrimary : Colors.transparent,
          borderRadius: AppRadii.brSm,
          border: Border.all(
            color: selected ? t.lineStrong : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? t.fg : t.fgTertiary),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? t.fg : t.fgSecondary,
                fontWeight: selected
                    ? FontWeight.w600
                    : CcTypography.regularWeight,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
