import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The plan total, as computed by the estimator (PRD 17 §3).
class PlanTotalEstimate {
  /// Parses the `plan.estimate` wire payload.
  factory PlanTotalEstimate.fromWire(Map<String, dynamic> w) =>
      PlanTotalEstimate(
        costCentsLow: (w['total_cost_cents_low'] as num?)?.toInt(),
        costCentsHigh: (w['total_cost_cents_high'] as num?)?.toInt(),
        durationMsLow: (w['total_duration_ms_low'] as num?)?.toInt(),
        durationMsHigh: (w['total_duration_ms_high'] as num?)?.toInt(),
        budgetCeilingCents: (w['budget_ceiling_cents'] as num?)?.toInt(),
        isPartial: w['is_partial'] == true,
        exceedsBudget: w['exceeds_budget'] == true,
      );

  /// Creates a plan total.
  const PlanTotalEstimate({
    this.costCentsLow,
    this.costCentsHigh,
    this.durationMsLow,
    this.durationMsHigh,
    this.budgetCeilingCents,
    this.isPartial = false,
    this.exceedsBudget = false,
  });

  /// Lower bound of the plan-total cost (US cents).
  final int? costCentsLow;

  /// Upper bound of the plan-total cost.
  final int? costCentsHigh;

  /// Lower bound of the critical-path duration (ms).
  final int? durationMsLow;

  /// Upper bound of the critical-path duration.
  final int? durationMsHigh;

  /// The budget ceiling, when set.
  final int? budgetCeilingCents;

  /// Whether totals cover only the estimable subset of nodes.
  final bool isPartial;

  /// Whether the estimated total may exceed the budget ceiling.
  final bool exceedsBudget;
}

/// The bottom approval bar (PRD 17 §3/§4): plan total, budget check and the
/// approve / reject / cancel / estimate actions.
///
/// Reviewing a proposed plan is one decision — approve it or reject it. The
/// former "approve subtree" action (approve the selected node plus its
/// dependency closure) was cut: it read as a variant of approve while silently
/// meaning something else and widening an already-running plan is what
/// [onApproveSelectedNodes] is for.
class PlanApprovalBar extends StatelessWidget {
  /// Creates a [PlanApprovalBar].
  const PlanApprovalBar({
    super.key,
    required this.total,
    required this.canApprove,
    required this.isExecuting,
    required this.hasSelection,
    required this.busy,
    this.validationError,
    required this.onEstimate,
    required this.onApprovePlan,
    required this.onApproveSelectedNodes,
    required this.onCancelOrReject,
    this.onContinueNode,
    this.showContinueNode = false,
  });

  /// The current plan total, or null when not yet estimated.
  final PlanTotalEstimate? total;

  /// Whether the plan is in an approvable (proposed) state.
  final bool canApprove;

  /// Whether the plan is already executing (partial-approval widening).
  final bool isExecuting;

  /// Whether a node is selected (enables approving selected nodes on an
  /// executing plan).
  final bool hasSelection;

  /// Whether an action is in flight.
  final bool busy;

  /// A blocking validation error (approve disabled while non-null).
  final String? validationError;

  /// Runs the estimator.
  final VoidCallback onEstimate;

  /// Approves the whole plan.
  final VoidCallback onApprovePlan;

  /// Approves the selected node(s) on an executing partial plan, or null when
  /// there is no partial approval to widen (a plan document is approved whole),
  /// which drops the action from the executing bar.
  final VoidCallback? onApproveSelectedNodes;

  /// Rejects (plan doc) or cancels (orchestration).
  final VoidCallback onCancelOrReject;

  /// Resumes a stop-and-ask held node.
  final VoidCallback? onContinueNode;

  /// Whether the "continue node" action applies to the selection.
  final bool showContinueNode;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        border: Border(top: BorderSide(color: ds.borderPrimary)),
      ),
      child: Row(
        children: [
          Expanded(child: _totals(context, ds, l10n)),
          const SizedBox(width: 12),
          if (validationError != null)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.circleAlert, size: 14, color: ds.danger),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      validationError!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: ds.danger,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: busy ? null : onEstimate,
            icon: AppIcons.calculator,
            child: Text(l10n.planEstimateAction),
          ),
          const SizedBox(width: 8),
          if (showContinueNode && onContinueNode != null) ...[
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: busy ? null : onContinueNode,
              icon: AppIcons.play,
              child: Text(l10n.planContinueNode),
            ),
            const SizedBox(width: 8),
          ],
          if (isExecuting) ...[
            if (onApproveSelectedNodes != null) ...[
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                onPressed: (busy || !hasSelection)
                    ? null
                    : onApproveSelectedNodes,
                child: Text(l10n.planApproveSelectedNodes),
              ),
              const SizedBox(width: 8),
            ],
            CcButton(
              variant: CcButtonVariant.destructive,
              size: CcButtonSize.sm,
              onPressed: busy ? null : onCancelOrReject,
              child: Text(l10n.planCancel),
            ),
          ] else if (canApprove) ...[
            CcButton(
              variant: CcButtonVariant.destructive,
              size: CcButtonSize.sm,
              onPressed: busy ? null : onCancelOrReject,
              child: Text(l10n.planReject),
            ),
            const SizedBox(width: 8),
            CcButton(
              size: CcButtonSize.sm,
              loading: busy,
              onPressed: (busy || validationError != null)
                  ? null
                  : onApprovePlan,
              icon: AppIcons.check,
              child: Text(l10n.planApprove),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totals(
    BuildContext context,
    DesignSystemTokens ds,
    AppLocalizations l10n,
  ) {
    final t = total;
    if (t == null) {
      return Text(
        l10n.planTotalNotEstimated,
        style: TextStyle(
          fontSize: 12,
          color: ds.textTertiary,
          decoration: TextDecoration.none,
        ),
      );
    }
    final parts = <String>[];
    if (t.costCentsLow != null) {
      final lo = (t.costCentsLow! / 100).toStringAsFixed(2);
      final hi = (t.costCentsHigh! / 100).toStringAsFixed(2);
      parts.add('\$$lo–$hi');
    } else {
      parts.add(l10n.planEstimateNoHistory);
    }
    if (t.durationMsLow != null) {
      final lo = (t.durationMsLow! / 60000).toStringAsFixed(0);
      final hi = (t.durationMsHigh! / 60000).toStringAsFixed(0);
      parts.add('$lo–${hi}m');
    }
    if (t.budgetCeilingCents != null) {
      parts.add(
        l10n.planBudgetCeiling(
          (t.budgetCeilingCents! / 100).toStringAsFixed(2),
        ),
      );
    }
    return Row(
      children: [
        Text(
          parts.join('  ·  '),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.exceedsBudget ? ds.danger : ds.textPrimary,
            decoration: TextDecoration.none,
          ),
        ),
        if (t.isPartial) ...[
          const SizedBox(width: 8),
          Text(
            l10n.planEstimatePartial,
            style: TextStyle(
              fontSize: 11,
              color: ds.textTertiary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
        if (t.exceedsBudget) ...[
          const SizedBox(width: 8),
          Icon(AppIcons.triangleAlert, size: 14, color: ds.danger),
          const SizedBox(width: 4),
          Text(
            l10n.planBudgetExceeded,
            style: TextStyle(
              fontSize: 11,
              color: ds.danger,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ],
    );
  }
}
