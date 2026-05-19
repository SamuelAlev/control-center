import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/playbook_run_dialog.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Plan Studio hub (PRD 17): active orchestration plans, plan-mode
/// documents, and playbooks.
class PlansScreen extends ConsumerWidget {
  /// Creates a [PlansScreen].
  const PlansScreen({super.key, required this.workspaceId});

  /// The active workspace.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final orchestrations =
        ref.watch(workspaceOrchestrationsProvider(workspaceId)).value ??
        const [];
    final plans = ref.watch(planDocumentsProvider).value ?? const [];
    final playbooks = ref.watch(playbooksProvider).value ?? const [];

    // Proposed first, then executing, then the rest.
    final sortedOrchestrations = [...orchestrations]
      ..sort((a, b) {
        int rank(OrchestrationStatus s) => switch (s) {
          OrchestrationStatus.proposed => 0,
          OrchestrationStatus.executing => 1,
          OrchestrationStatus.synthesizing => 1,
          _ => 2,
        };
        return rank(a.status).compareTo(rank(b.status));
      });
    final visiblePlans = plans
        .where(
          (p) =>
              p.status == PlanDocumentStatus.proposed ||
              p.status == PlanDocumentStatus.approved,
        )
        .toList();

    return PageWrapper(
      title: l10n.plansTitle,
      subtitle: l10n.plansSubtitle,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Section(title: l10n.plansActiveSection),
          if (sortedOrchestrations.isEmpty)
            _Empty(l10n.plansNoActive)
          else
            for (final o in sortedOrchestrations)
              _OrchestrationCard(o: o, workspaceId: workspaceId),
          const SizedBox(height: 24),
          _Section(title: l10n.plansDocumentsSection),
          if (visiblePlans.isEmpty)
            _Empty(l10n.plansNoDocuments)
          else
            for (final p in visiblePlans)
              _PlanDocumentCard(plan: p, workspaceId: workspaceId),
          const SizedBox(height: 24),
          _Section(title: l10n.plansPlaybooksSection),
          if (playbooks.isEmpty)
            _Empty(l10n.plansNoPlaybooks)
          else
            for (final p in playbooks)
              _PlaybookCard(playbook: p, workspaceId: workspaceId),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: ds.textPrimary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: ds.textTertiary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

class _OrchestrationCard extends StatelessWidget {
  const _OrchestrationCard({required this.o, required this.workspaceId});
  final Orchestration o;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcCard(
        interactive: true,
        onPressed: () =>
            context.go(planStudioRoute(workspaceId, 'orchestration', o.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(AppIcons.network, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  o.proposal.goal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ds.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              CcBadge(
                label: o.status.name,
                variant: o.status == OrchestrationStatus.proposed
                    ? CcBadgeVariant.warning
                    : CcBadgeVariant.neutral,
              ),
              const SizedBox(width: 8),
              Text(
                '${o.proposal.subTickets.length} steps · v${o.revision}',
                style: TextStyle(
                  fontSize: 12,
                  color: ds.textTertiary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanDocumentCard extends StatelessWidget {
  const _PlanDocumentCard({required this.plan, required this.workspaceId});
  final PlanDocument plan;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcCard(
        interactive: true,
        onPressed: () =>
            context.go(planStudioRoute(workspaceId, 'document', plan.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(AppIcons.listChecks, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  plan.goal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ds.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              CcBadge(
                label: plan.status.name,
                variant: plan.status == PlanDocumentStatus.proposed
                    ? CcBadgeVariant.warning
                    : CcBadgeVariant.neutral,
              ),
              const SizedBox(width: 8),
              Text(
                '${plan.graph.workNodes.length} steps',
                style: TextStyle(
                  fontSize: 12,
                  color: ds.textTertiary,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybookCard extends ConsumerWidget {
  const _PlaybookCard({required this.playbook, required this.workspaceId});
  final Playbook playbook;
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(AppIcons.bookMarked, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playbook.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ds.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (playbook.description.isNotEmpty)
                      Text(
                        playbook.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: ds.textTertiary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                l10n.planPlaybookParamCount(playbook.params.length),
                style: TextStyle(
                  fontSize: 12,
                  color: ds.textTertiary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 8),
              CcIconButton(
                icon: AppIcons.trash2,
                semanticLabel: l10n.planPlaybookDelete,
                onPressed: () => ref
                    .read(planStudioRepositoryProvider)
                    .deletePlaybook(playbook.id),
              ),
              const SizedBox(width: 4),
              CcButton(
                size: CcButtonSize.sm,
                icon: AppIcons.play,
                onPressed: () => _run(context, ref),
                child: Text(l10n.planPlaybookRun),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    final result = await showCcDialog<PlaybookRunResult>(
      context: context,
      builder: (_) =>
          PlaybookRunDialog(playbook: playbook, workspaceId: workspaceId),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final toast = CcToastScope.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(planStudioRepositoryProvider)
          .runPlaybook(
            playbookId: playbook.id,
            ticketId: result.ticketId,
            args: result.args,
          );
      toast?.show(l10n.planPlaybookProposed, variant: CcToastVariant.success);
    } on RemoteRpcException catch (e) {
      toast?.show(e.message, variant: CcToastVariant.danger);
    }
  }
}
