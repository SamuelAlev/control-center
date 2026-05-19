import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/services/proposal_diff.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The left version-timeline drawer + plan-diff panel (PRD 17 §5).
///
/// Lists every revision (author kind + time), lets the operator pick one to
/// diff against the current proposal (via the pure [ProposalDiffService]) and
/// exposes rewind. When the live revision is ahead of the approved one during
/// execution, the parent surfaces the "unreviewed replan" banner and passes
/// the approved revision here so the diff-vs-approved renders automatically.
class PlanVersionPanel extends StatelessWidget {
  /// Creates a [PlanVersionPanel].
  const PlanVersionPanel({
    super.key,
    required this.revisions,
    required this.current,
    required this.currentRevision,
    required this.selectedRevision,
    required this.onSelectRevision,
    required this.onRewind,
    this.canRewind = false,
  });

  /// Every revision, oldest first.
  final List<OrchestrationRevision> revisions;

  /// The current (draft or live) proposal to diff against.
  final OrchestrationProposal current;

  /// The current proposal's revision number.
  final int currentRevision;

  /// The revision selected for diffing, or null (diff vs the previous one).
  final int? selectedRevision;

  /// Called when a revision is picked.
  final ValueChanged<int> onSelectRevision;

  /// Rewinds to the given revision's proposal (creates a NEW revision).
  final ValueChanged<OrchestrationRevision> onRewind;

  /// Whether rewind is allowed (proposed state only).
  final bool canRewind;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    OrchestrationRevision? selected;
    for (final r in revisions) {
      if (r.revision == selectedRevision) {
        selected = r;
      }
    }
    // Default diff base: the revision just before current.
    selected ??= revisions.length >= 2
        ? revisions[revisions.length - 2]
        : (revisions.isNotEmpty ? revisions.first : null);

    final diff = selected == null
        ? null
        : ProposalDiffService.diff(selected.proposal, current);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        border: Border(right: BorderSide(color: ds.borderPrimary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              l10n.planVersionsTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ds.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (final r in revisions.reversed)
                  _RevisionRow(
                    revision: r,
                    isCurrent: r.revision == currentRevision,
                    isSelected: r.revision == selected?.revision,
                    onTap: () => onSelectRevision(r.revision),
                    onRewind: canRewind && r.revision != currentRevision
                        ? () => onRewind(r)
                        : null,
                  ),
              ],
            ),
          ),
          const CcDivider(),
          Expanded(
            child: diff == null
                ? Center(
                    child: Text(
                      l10n.planNoRevisions,
                      style: TextStyle(
                        color: ds.textTertiary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  )
                : _DiffView(
                    diff: diff,
                    fromRevision: selected!.revision,
                    toRevision: currentRevision,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RevisionRow extends StatelessWidget {
  const _RevisionRow({
    required this.revision,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
    required this.onRewind,
  });

  final OrchestrationRevision revision;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onRewind;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ds.accentSoft : null,
          borderRadius: BorderRadius.circular(8),
          border: isCurrent ? Border.all(color: ds.accent, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              revision.authorKind == 'agent' ? AppIcons.bot : AppIcons.user,
              size: 13,
              color: ds.textTertiary,
            ),
            const SizedBox(width: 8),
            Text(
              'v${revision.revision}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ds.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
            const Spacer(),
            if (onRewind != null)
              CcIconButton(
                icon: AppIcons.undo2,
                semanticLabel: 'Rewind',
                onPressed: onRewind,
              ),
          ],
        ),
      ),
    );
  }
}

class _DiffView extends StatelessWidget {
  const _DiffView({
    required this.diff,
    required this.fromRevision,
    required this.toRevision,
  });

  final PlanDiff diff;
  final int fromRevision;
  final int toRevision;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    if (diff.isEmpty) {
      return Center(
        child: Text(
          l10n.planDiffIdentical,
          style: TextStyle(
            color: ds.textTertiary,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          l10n.planDiffHeader(fromRevision, toRevision),
          style: TextStyle(
            fontSize: 11,
            color: ds.textTertiary,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        if (diff.goalChanged)
          _line(
            ds,
            AppIcons.pencil,
            l10n.planDiffGoalChanged,
            ds.textWarningPrimary,
          ),
        for (final k in diff.addedNodeKeys)
          _line(ds, AppIcons.plus, l10n.planDiffAdded(k), ds.success),
        for (final k in diff.removedNodeKeys)
          _line(ds, AppIcons.minus, l10n.planDiffRemoved(k), ds.danger),
        for (final c in diff.changedNodes)
          _line(
            ds,
            AppIcons.pencil,
            l10n.planDiffChanged(c.key, c.changedFields.join(', ')),
            ds.textWarningPrimary,
          ),
        for (final e in diff.addedEdges)
          _line(
            ds,
            AppIcons.arrowRight,
            l10n.planDiffEdgeAdded('${e.from} → ${e.to}'),
            ds.success,
          ),
        for (final e in diff.removedEdges)
          _line(
            ds,
            AppIcons.arrowRight,
            l10n.planDiffEdgeRemoved('${e.from} → ${e.to}'),
            ds.danger,
          ),
        for (final r in diff.rolesAdded)
          _line(ds, AppIcons.userPlus, l10n.planDiffRoleAdded(r), ds.success),
        for (final r in diff.rolesRemoved)
          _line(ds, AppIcons.userMinus, l10n.planDiffRoleRemoved(r), ds.danger),
        for (final r in diff.rolesReassigned)
          _line(
            ds,
            AppIcons.userCog,
            l10n.planDiffRoleReassigned(r),
            ds.textWarningPrimary,
          ),
        if (diff.budgetChanged)
          _line(
            ds,
            AppIcons.dollarSign,
            l10n.planDiffBudgetChanged,
            ds.textWarningPrimary,
          ),
      ],
    );
  }

  Widget _line(DesignSystemTokens ds, IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: ds.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
