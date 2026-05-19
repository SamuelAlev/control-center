import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_review_run_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A button that starts the canonical AI review (the Review Hub flow):
/// deterministic area computation → reviewer fan-out into the PR space →
/// structured walkthrough → verdict. Stays on the review tab — progress
/// streams through the space and the association status.
class AskAiReviewButton extends ConsumerStatefulWidget {
  /// Creates an [AskAiReviewButton].
  const AskAiReviewButton({super.key, required this.pr});

  /// The pull request to review.
  final PullRequest pr;

  @override
  ConsumerState<AskAiReviewButton> createState() => _AskAiReviewButtonState();
}

class _AskAiReviewButtonState extends ConsumerState<AskAiReviewButton> {
  bool _loading = false;

  /// Starts a review. [level] null means "the workspace default", which is
  /// what the primary button does — the picker exists for the one PR that
  /// warrants a different depth, not to make every review a decision.
  Future<void> _startReview({ReviewLevel? level}) async {
    if (_loading) {
      return;
    }
    // Captured up front, and the toasts below are NOT gated on `mounted`:
    // starting a review swaps this button's surface for the tab's "starting"
    // state, so by the time the call answers the button is usually gone. The
    // toast handle lives at the app shell, well above it — gating on `mounted`
    // would silently drop the outcome, including the failure.
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);

    setState(() => _loading = true);
    try {
      final result = await ref
          .read(prReviewStarterProvider.notifier)
          .start(pr: widget.pr, level: level);
      if (result['status'] == 'already_running') {
        toast?.show(
          l10n.reviewHubAlreadyRunning,
          variant: CcToastVariant.warning,
        );
      } else {
        toast?.show(l10n.reviewHubStarted, variant: CcToastVariant.success);
      }
    } catch (e) {
      toast?.show(
        l10n.failedToStartAiReview('$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _levelLabel(AppLocalizations l10n, ReviewLevel level) =>
      switch (level) {
        ReviewLevel.light => l10n.reviewLevelLight,
        ReviewLevel.balanced => l10n.reviewLevelBalanced,
        ReviewLevel.thorough => l10n.reviewLevelThorough,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceLevel = ref.watch(workspaceReviewLevelProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTooltip(
          message: l10n.askAiReviewDescription,
          child: CcButton(
            onPressed: _loading ? null : _startReview,
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            loading: _loading,
            icon: AppIcons.sparkles,
            child: Text(l10n.askAi),
          ),
        ),
        const SizedBox(width: 2),
        CcMenu(
          semanticLabel: l10n.askAiReviewAtLevel,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          minWidth: 200,
          items: [
            for (final level in ReviewLevel.values)
              CcMenuItem(
                label: _levelLabel(l10n, level),
                // The workspace default is marked rather than pre-selected:
                // every row starts a review, and the mark says which one the
                // plain button would have run.
                selected: level == workspaceLevel,
                enabled: !_loading,
                onSelected: () => _startReview(level: level),
              ),
          ],
          // Inert by construction — the enclosing menu owns the tap. A
          // CcButton here would swallow it and the menu would never open.
          target: _LevelChevron(enabled: !_loading, t: t),
        ),
      ],
    );
  }
}

/// The chevron half of the split control: a visual matched to the secondary
/// button beside it, with no gesture of its own.
class _LevelChevron extends StatelessWidget {
  const _LevelChevron({required this.enabled, required this.t});

  final bool enabled;
  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      // Matches the 32px CcButtonSize.sm height beside it.
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? t.bgSecondary : t.bgDisabled,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: enabled ? t.borderPrimary : t.borderDisabled),
      ),
      child: Icon(
        AppIcons.chevronDown,
        size: 14,
        color: enabled ? t.textSecondary : t.textDisabled,
      ),
    );
  }
}
