import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/improvements/improvement_campaign_dialog.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The top of an improvement's page: back, what it changes, its status, who
/// proposed it and where it applies, and the decisions. A proposal the
/// server marks `needs_admin` (a skill change, a workspace-wide policy) says
/// why a member cannot decide; a skill change can be accepted only after an
/// evaluation passed, and offers to run one.
class ImprovementPageHeader extends ConsumerWidget {
  /// Creates the header.
  const ImprovementPageHeader({
    super.key,
    required this.view,
    required this.onBack,
  });

  /// The proposal as this viewer sees it.
  final ImprovementProposalView view;

  /// Leaves the page.
  final VoidCallback onBack;

  Future<void> _rollback(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final p = view.proposal;
    final ok = await showCcDialog<bool>(
      context: context,
      builder: (d) => CcDialog(
        title: l10n.improvementRollbackTitle,
        content: Text(l10n.improvementRollbackBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(l10n.improvementRollback),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await runDispatchAction(
        context,
        () => ref
            .read(improvementInboxRepositoryProvider)
            .rollback(p.workspaceId, p.id),
        done: l10n.improvementRolledBackDone,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final p = view.proposal;
    final ws = p.workspaceId;
    final repo = ref.read(improvementInboxRepositoryProvider);
    final admin = ref.watch(myWorkspaceRoleProvider(ws))?.isAdmin ?? false;
    final blocked = view.needsAdmin && !admin;
    final proposed = p.status == ImprovementStatus.proposed;
    final campaignRunning =
        p.campaignState == ImprovementCampaignState.running ||
        p.campaignState == ImprovementCampaignState.staging;
    final agent =
        ref.watch(
          workAgentNameProvider((workspaceId: ws, agentId: p.agentId)),
        ) ??
        l10n.workAgentUnknown;
    final acceptReason = blocked
        ? l10n.improvementNeedsAdmin
        : p.isSkillChange && !p.canAccept && proposed
        ? l10n.improvementNeedsCampaign
        : null;
    final caption = CcTypography.caption.copyWith(color: ds.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.arrowLeft,
          onPressed: onBack,
          child: Text(l10n.improvementsBackToList),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                inertText(p.change, singleLine: true),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CcTypography.body.copyWith(
                  color: ds.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            CcStatusTag(
              label: improvementStatusLabel(l10n, p.status),
              tone: improvementStatusTone(p.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.improvementMeta(
            improvementKindLabel(l10n, p.kind),
            improvementScopeLabel(l10n, p.scope),
            agent,
          ),
          style: caption,
        ),
        if (view.needsAdmin) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            admin ? l10n.improvementAdminDecides : l10n.improvementNeedsAdmin,
            style: caption,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (proposed) ...[
              WorkTip(
                message: acceptReason,
                child: CcButton(
                  size: CcButtonSize.sm,
                  icon: AppIcons.circleCheck,
                  onPressed: acceptReason == null && p.canAccept
                      ? () => runDispatchAction(
                          context,
                          () => repo.accept(ws, p.id),
                          done: l10n.improvementAcceptedDone,
                        )
                      : null,
                  child: Text(l10n.improvementAccept),
                ),
              ),
              WorkTip(
                message: blocked ? l10n.improvementNeedsAdmin : null,
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.x,
                  onPressed: blocked
                      ? null
                      : () => runDispatchAction(
                          context,
                          () => repo.reject(ws, p.id),
                          done: l10n.improvementRejectedDone,
                        ),
                  child: Text(l10n.improvementReject),
                ),
              ),
              if (p.isSkillChange &&
                  p.campaignState != ImprovementCampaignState.passed)
                WorkTip(
                  message: blocked ? l10n.improvementNeedsAdmin : null,
                  child: CcButton(
                    variant: CcButtonVariant.secondary,
                    size: CcButtonSize.sm,
                    icon: AppIcons.listChecks,
                    loading: campaignRunning,
                    onPressed: blocked || campaignRunning
                        ? null
                        : () => showImprovementCampaignDialog(context, p),
                    child: Text(l10n.improvementRunEvaluation),
                  ),
                ),
            ],
            if (p.status == ImprovementStatus.accepted)
              WorkTip(
                message: blocked ? l10n.improvementNeedsAdmin : null,
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.undo2,
                  onPressed: blocked ? null : () => _rollback(context, ref),
                  child: Text(l10n.improvementRollback),
                ),
              ),
          ],
        ),
        if (proposed && acceptReason != null && !blocked) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(acceptReason, style: caption),
        ],
      ],
    );
  }
}
