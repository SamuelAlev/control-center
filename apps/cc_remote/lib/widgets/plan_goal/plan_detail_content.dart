import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/plan_goal/plan_execution_summary.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/plan_goal/plan_widen_action.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Include prerequisite nodes for a partial approval without changing selection.
Set<String> planDependencyClosure(PlanDocument plan, Set<String> selected) {
  final approvedKeys = <String>{};

  void addDependencies(String key) {
    if (!approvedKeys.add(key)) return;
    final node = plan.graph.node(key);
    for (final dep in node?.dependsOn ?? const <String>[]) {
      addDependencies(dep);
    }
  }

  for (final key in selected) {
    addDependencies(key);
  }
  return approvedKeys;
}

/// Review, selection, execution progress and explicit plan actions.
class PhonePlanDetailContent extends StatelessWidget {
  const PhonePlanDetailContent({
    super.key,
    required this.workspace,
    required this.workspaceId,
    required this.planAsync,
    required this.executionAsync,
    required this.selected,
    required this.canWrite,
    required this.estimate,
    required this.error,
    required this.approvedExecutionId,
    required this.busy,
    required this.onToggle,
    required this.onClearSelection,
    required this.onEstimate,
    required this.onApprove,
    required this.onReject,
    required this.onStop,
  });

  final AsyncValue<String?> workspace;
  final String? workspaceId;
  final AsyncValue<PlanDocument?>? planAsync;
  final AsyncValue<OrchestrationDto?>? executionAsync;
  final Set<String> selected;
  final bool canWrite;
  final Map<String, dynamic>? estimate;
  final String? error;
  final String? approvedExecutionId;
  final bool busy;
  final ValueChanged<String> onToggle;
  final VoidCallback onClearSelection;
  final VoidCallback onEstimate;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<String> onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final id = workspaceId;
    final plan = planAsync?.value;
    final execution = executionAsync?.value;
    if (workspace.hasError) {
      return CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: l10n.mobilePlansLoadFailed,
        description: workspace.error.toString(),
      );
    }
    if (id == null || planAsync == null || planAsync!.isLoading) {
      return const Center(child: CcSpinner(size: 24));
    }
    if (planAsync!.hasError) {
      return CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: l10n.mobilePlansLoadFailed,
        description: planAsync!.error.toString(),
      );
    }
    if (plan == null) {
      return CcEmptyState(
        icon: AppIcons.fileText,
        message: l10n.mobilePlanMissing,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PhonePlanDocumentBody(
          plan: plan,
          selected: selected,
          approvedNodeKeys: execution?.approvedNodeKeys?.toSet(),
          canSelect:
              canWrite &&
              (plan.status == PlanDocumentStatus.proposed ||
                  (execution?.approvedNodeKeys != null &&
                      const {
                        'executing',
                        'synthesizing',
                      }.contains(execution?.status))),
          onToggle: onToggle,
        ),
        if (executionAsync?.hasError == true)
          Text(
            executionAsync!.error.toString(),
            style: TextStyle(color: t.danger),
          ),
        if (executionAsync?.isLoading == true)
          const Center(child: CcSpinner(size: 20)),
        if (execution != null)
          PhonePlanExecutionSummary(
            execution: execution,
            workspaceId: id,
            conversationId: plan.conversationId,
          )
        else if (plan.status == PlanDocumentStatus.approved &&
            executionAsync?.hasError != true &&
            executionAsync?.isLoading != true)
          Text(
            approvedExecutionId == null
                ? l10n.mobilePlanExecutionPending
                : l10n.mobilePlanRunId(approvedExecutionId!),
            style: TextStyle(color: t.textSecondary),
          ),
        if (execution != null && execution.approvedNodeKeys != null)
          PhonePlanWidenAction(
            plan: plan,
            execution: execution,
            workspaceId: id,
            selected: selected,
            onCleared: onClearSelection,
          ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: TextStyle(color: t.danger)),
        ],
        if (plan.status == PlanDocumentStatus.proposed && canWrite) ...[
          const SizedBox(height: 20),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            loading: busy,
            variant: CcButtonVariant.secondary,
            onPressed: busy ? null : onEstimate,
            child: Text(l10n.mobilePlanEstimate),
          ),
          if (estimate != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.mobilePlanEstimatedCost(
                (estimate!['total_cost_cents_low'] as num?) == null
                    ? l10n.mobilePlanCostUnknown
                    : planMoney(
                        context,
                        (estimate!['total_cost_cents_low'] as num).toInt(),
                      ),
                (estimate!['total_cost_cents_high'] as num?) == null
                    ? l10n.mobilePlanCostUnknown
                    : planMoney(
                        context,
                        (estimate!['total_cost_cents_high'] as num).toInt(),
                      ),
              ),
              style: TextStyle(color: t.textSecondary),
            ),
            if (estimate!['exceeds_budget'] == true)
              Text(
                l10n.mobilePlanExceedsBudget,
                style: TextStyle(color: t.danger),
              ),
          ],
          const SizedBox(height: 12),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            loading: busy,
            onPressed: busy || estimate == null || plan.graph.workNodes.isEmpty
                ? null
                : onApprove,
            child: Text(
              selected.isEmpty || selected.length == plan.graph.workNodes.length
                  ? l10n.mobilePlanApproveAll
                  : l10n.mobilePlanApproveSelected,
            ),
          ),
          const SizedBox(height: 8),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            variant: CcButtonVariant.destructive,
            onPressed: busy ? null : onReject,
            child: Text(l10n.mobilePlanReject),
          ),
        ],
        if (execution != null &&
            canWrite &&
            (execution.status == 'executing' ||
                execution.status == 'synthesizing')) ...[
          const SizedBox(height: 16),
          CcButton(
            fullWidth: true,
            size: CcButtonSize.lg,
            variant: CcButtonVariant.destructive,
            onPressed: busy ? null : () => onStop(execution.id),
            child: Text(l10n.mobilePlanStop),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
