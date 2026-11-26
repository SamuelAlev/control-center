import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/hover_focus_reveal.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_reviewer_badges.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_team_hover_target.dart';
import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A reviewer rail row. Renders an individual user, a pending team, or a team
/// merged with the member who reviewed on its behalf.
///
/// On hover or keyboard focus, trailing actions replace the resting status
/// glyph: [onReRequest] (for reviewers who have already submitted a review) and
/// [onRemove] (for removable reviewers).
class PrReviewerRow extends StatelessWidget {
  /// Creates a [PrReviewerRow].
  const PrReviewerRow({
    super.key,
    required this.reviewer,
    required this.pending,
    required this.organization,
    this.onReRequest,
    this.onRemove,
  });

  /// The reviewer rendered by this row.
  final PrReviewer reviewer;

  /// Whether a mutation (re-request or remove) is currently in flight.
  final bool pending;

  /// Repository owner/organization, used for team profile navigation and hover.
  final String organization;

  /// Called when the user clicks "Re-request review", or null when unavailable.
  final VoidCallback? onReRequest;

  /// Called when the user removes this reviewer, or null when unavailable.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final r = reviewer;
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final reviewedBy = r is PrTeamReviewer ? r.reviewedBy : null;
    final name = switch (r) {
      PrUserReviewer() => r.user.login,
      PrTeamReviewer() => r.name,
    };
    final semanticLabel = [
      name,
      PrReviewerStateDot.labelFor(r.state, l10n),
      if (reviewedBy != null) l10n.reviewedOnBehalfOf(reviewedBy.login),
      if (r.isCodeOwner) l10n.requiredByCodeOwners,
    ].join(', ');

    final info = ExcludeSemantics(
      child: Row(
        children: [
          if (r.isCodeOwner) ...[
            CcTooltip(
              message: l10n.requiredByCodeOwners,
              child: Icon(AppIcons.shield, size: 14, color: t.fgBrandPrimary),
            ),
            const SizedBox(width: 6),
          ],
          PrReviewerAvatar(reviewer: r),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.caption.copyWith(color: t.textPrimary),
                ),
                if (reviewedBy != null)
                  Text(
                    l10n.reviewedOnBehalfOf(reviewedBy.login),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(color: t.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    // Keep the user/team hover target scoped to the identity portion so its
    // hover card does not obscure the trailing "Re-request review" tooltip,
    // and so team rows do not nest CcTappable inside CcTappable.
    final Widget leading = switch (r) {
      PrUserReviewer() => GitHubUserHoverTarget(
        login: r.user.login,
        child: Semantics(container: true, label: semanticLabel, child: info),
      ),
      PrTeamReviewer() => GitHubTeamHoverTarget(
        organization: organization,
        slug: r.slug,
        child: CcTappable(
          onPressed: () => context.go(
            teamProfileRoute(
              context.currentWorkspaceId!,
              organization,
              r.slug,
            ),
          ),
          semanticLabel: semanticLabel,
          borderRadius: AppRadii.brSm,
          builder: (_, _) => info,
        ),
      ),
    };

    return HoverFocusReveal(
      builder: (context, revealed) => Row(
        children: [
          Expanded(child: leading),
          if (pending)
            const SizedBox(
              width: 22,
              height: 22,
              child: Center(child: CcSpinner(size: 14)),
            )
          else
            _ReviewerTrailingSlot(
              revealed: revealed,
              name: name,
              resting: ExcludeSemantics(
                child: PrReviewerStateDot(state: r.state),
              ),
              onReRequest: onReRequest,
              onRemove: onRemove,
            ),
        ],
      ),
    );
  }
}

/// Trailing slot of a reviewer row: [resting] status glyph at rest, replaced on
/// hover or keyboard focus by the re-request and/or remove action buttons.
class _ReviewerTrailingSlot extends StatelessWidget {
  const _ReviewerTrailingSlot({
    required this.revealed,
    required this.name,
    required this.resting,
    this.onReRequest,
    this.onRemove,
  });

  final bool revealed;
  final String name;
  final Widget resting;
  final VoidCallback? onReRequest;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final restingBox = SizedBox(
      width: 22,
      height: 22,
      child: Center(child: resting),
    );
    if (onReRequest == null && onRemove == null) {
      return restingBox;
    }
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        HoverFocusReveal.fade(revealed: !revealed, child: restingBox),
        HoverFocusReveal.fade(
          revealed: revealed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onReRequest != null)
                CcTooltip(
                  message: l10n.reRequestReview,
                  child: _RowActionButton(
                    icon: AppIcons.repeat,
                    semanticLabel: l10n.reRequestReviewFor(name),
                    restingColor: t.fgTertiary,
                    activeColor: t.fgPrimary,
                    activeBackground: t.hoverStrong,
                    onPressed: onReRequest!,
                  ),
                ),
              if (onReRequest != null && onRemove != null)
                const SizedBox(width: 4),
              if (onRemove != null)
                _RowActionButton(
                  icon: AppIcons.x,
                  semanticLabel: l10n.removeLabel(name),
                  restingColor: t.fgQuaternary,
                  activeColor: t.fgErrorPrimary,
                  activeBackground: t.dangerSoft,
                  onPressed: onRemove!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RowActionButton extends StatelessWidget {
  const _RowActionButton({
    required this.icon,
    required this.semanticLabel,
    required this.restingColor,
    required this.activeColor,
    required this.activeBackground,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final Color restingColor;
  final Color activeColor;
  final Color activeBackground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      borderRadius: AppRadii.brSm,
      builder: (context, states) {
        final active =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        return Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeBackground : const Color(0x00000000),
            borderRadius: AppRadii.brSm,
          ),
          child: Icon(
            icon,
            size: 14,
            color: active ? activeColor : restingColor,
          ),
        );
      },
    );
  }
}
