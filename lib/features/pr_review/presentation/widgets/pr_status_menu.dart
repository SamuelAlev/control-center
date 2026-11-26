import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_draft_actions.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The PR state tag, doubling as the control that changes it.
///
/// On an open pull request the viewer may change, the tag opens a menu of the
/// states it can move to: draft, open (ready for review) and closed. Each move
/// runs the same confirmed action as its button elsewhere on the page. A
/// merged or closed pull request, or one the viewer cannot change, shows the
/// plain [PrStatusBadge].
class PrStatusMenu extends ConsumerWidget {
  /// Creates a [PrStatusMenu] for [pr].
  const PrStatusMenu({super.key, required this.pr, required this.prRef});

  /// The pull request whose state is shown.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number).
  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = PrStatusBadge(pr: pr);
    final canDraft = canToggleDraft(ref, pr, prRef);
    final canClose = canClosePullRequest(ref, pr, prRef);
    if (!canDraft && !canClose) {
      return badge;
    }
    final l10n = AppLocalizations.of(context);
    final t = context.ds;
    return CcMenu(
      semanticLabel: l10n.status,
      minWidth: 160,
      // The badge is inert chrome: the menu's own tappable takes the press.
      target: badge,
      washTarget: true,
      items: [
        // A forge with no draft toggle still names the state a draft is in.
        if (canDraft || pr.isDraft)
          CcMenuItem(
            label: l10n.draft,
            leading: (_) => Icon(
              AppIcons.gitPullRequestDraft,
              size: 16,
              color: t.textTertiary,
            ),
            selected: pr.isDraft,
            enabled: pr.isDraft || canDraft,
            onSelected: () {
              if (!pr.isDraft) {
                confirmAndConvertToDraft(context, ref, pr, prRef);
              }
            },
          ),
        CcMenuItem(
          label: l10n.openStatus,
          leading: (_) => Icon(
            AppIcons.gitPullRequest,
            size: 16,
            color: t.fgSuccessPrimary,
          ),
          selected: !pr.isDraft,
          enabled: !pr.isDraft || canDraft,
          onSelected: () {
            if (pr.isDraft) {
              confirmAndMarkReadyForReview(context, ref, prRef);
            }
          },
        ),
        if (canClose) ...[
          const CcMenuItem.divider(),
          CcMenuItem(
            label: l10n.closed,
            leading: (_) => Icon(
              AppIcons.gitPullRequestClosed,
              size: 16,
              color: t.fgErrorPrimary,
            ),
            onSelected: () => confirmAndClosePullRequest(context, ref, pr),
          ),
        ],
      ],
    );
  }
}
