import 'package:cc_domain/features/pr_review/domain/value_objects/api_contract_diff.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Center pane: the swagger-style API-contract diff (PRD 18 §5). Each change is
/// severity-classified with a breaking badge; per-change approve/reject feeds
/// the merge gate and is recorded.
class ContractDiffPanel extends StatelessWidget {
  /// Creates a [ContractDiffPanel].
  const ContractDiffPanel({
    super.key,
    required this.diffs,
    required this.onDecision,
  });

  /// The contract diffs.
  final List<ApiContractDiff> diffs;

  /// Called when the operator approves/rejects a change.
  final void Function(
    String diffId,
    String changeId,
    ApiChangeDecision decision,
  )
  onDecision;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    if (diffs.isEmpty) {
      return Center(
        child: Text(
          l10n.reviewStudioNoContractChanges,
          style: TextStyle(color: ds.textTertiary, fontSize: 13),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final diff in diffs) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  diff.specPath,
                  style: TextStyle(
                    color: ds.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (diff.derived)
                _tag(
                  ds,
                  l10n.reviewStudioDerivedContract,
                  ds.textWarningPrimary,
                ),
              if (diff.breakingCount > 0)
                _tag(
                  ds,
                  l10n.reviewStudioBreakingCount(diff.breakingCount),
                  ds.danger,
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final c in diff.changes)
            _ChangeRow(
              diffId: diff.id,
              change: c,
              gated: !diff.derived,
              onDecision: onDecision,
            ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _tag(DesignSystemTokens ds, String text, Color color) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.diffId,
    required this.change,
    required this.gated,
    required this.onDecision,
  });

  final String diffId;
  final ApiContractChange change;
  final bool gated;
  final void Function(String, String, ApiChangeDecision) onDecision;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final severityColor = switch (change.severity) {
      ApiChangeSeverity.breaking => ds.danger,
      ApiChangeSeverity.nonBreaking => ds.success,
      ApiChangeSeverity.info => ds.textTertiary,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ds.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: change.blocksGate && gated
              ? ds.danger.withValues(alpha: 0.5)
              : ds.borderPrimary,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (change.method != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: ds.bgSecondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          change.method!,
                          style: TextStyle(
                            color: ds.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        change.path,
                        style: TextStyle(
                          color: ds.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (change.isBreaking) ...[
                      const SizedBox(width: 6),
                      Text(
                        l10n.reviewStudioBreaking,
                        style: TextStyle(
                          color: ds.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                if (change.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      change.detail,
                      style: TextStyle(color: ds.textSecondary, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          if (gated) ...[
            const SizedBox(width: 8),
            _decisionControls(context, ds, l10n),
          ],
        ],
      ),
    );
  }

  Widget _decisionControls(
    BuildContext context,
    DesignSystemTokens ds,
    AppLocalizations l10n,
  ) {
    switch (change.decision) {
      case ApiChangeDecision.approved:
        return _statusChip(ds, l10n.reviewStudioApproved, ds.success);
      case ApiChangeDecision.rejected:
        return _statusChip(ds, l10n.reviewStudioRejected, ds.danger);
      case ApiChangeDecision.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcIconButton(
              tooltip: l10n.reviewStudioApprove,
              icon: AppIcons.check,
              color: ds.success,
              onPressed: () =>
                  onDecision(diffId, change.id, ApiChangeDecision.approved),
            ),
            CcIconButton(
              tooltip: l10n.reviewStudioReject,
              icon: AppIcons.x,
              color: ds.danger,
              onPressed: () =>
                  onDecision(diffId, change.id, ApiChangeDecision.rejected),
            ),
          ],
        );
    }
  }

  Widget _statusChip(DesignSystemTokens ds, String text, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
