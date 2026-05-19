import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/settings/providers/governance_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The authorization audit trail: every allow and every refusal the server
/// decided, newest first, plus the chain check.
///
/// The verify button is the point of the whole feature. An audit log you
/// cannot check is a log; a hash-chained one you can re-derive is evidence —
/// the server recomputes every entry's hash from its own content and reports
/// the first link that does not hold.
class AuditTrailSection extends ConsumerStatefulWidget {
  /// Creates an [AuditTrailSection].
  const AuditTrailSection({super.key});

  @override
  ConsumerState<AuditTrailSection> createState() => _AuditTrailSectionState();
}

class _AuditTrailSectionState extends ConsumerState<AuditTrailSection> {
  ChainVerificationView? _verification;
  bool _verifying = false;

  Future<void> _verify() async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null || _verifying) {
      return;
    }
    setState(() => _verifying = true);
    try {
      final result = await verifyAuditChain(
        ref.read(rpcClientProvider),
        workspaceId: workspaceId,
      );
      if (mounted) {
        setState(() => _verification = result);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).failedWithError('$e'),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final decisions = ref.watch(auditDecisionsProvider).value ?? const [];
    final verification = _verification;

    return SectionCard(
      label: l10n.auditTrailLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.auditTrailDescription,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: _verifying ? null : _verify,
                child: Text(l10n.auditVerifyChain),
              ),
              if (verification != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    verification.intact
                        ? l10n.auditChainIntact(verification.rowsChecked)
                        : l10n.auditChainBroken(
                            verification.brokenAtSeq ?? 0,
                            verification.reason ?? '',
                          ),
                    style: CcTypography.bodySm.copyWith(
                      color: verification.intact
                          ? t.textSuccessPrimary
                          : t.textErrorPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (decisions.isEmpty)
            Text(
              l10n.auditEmpty,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          else
            for (final d in decisions.take(50)) _AuditRow(decision: d),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.decision});

  final AuditDecisionView decision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Never status-by-colour alone: the verdict is also spelled out.
    final label = decision.isDeny ? l10n.auditDenied : l10n.auditAllowed;
    final color = decision.isDeny ? t.textErrorPrimary : t.textTertiary;
    final attribution = decision.onBehalfOfUserId == null
        ? decision.actorId
        : '${decision.actorId} ${l10n.auditOnBehalfOf(decision.onBehalfOfUserId!)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: CcTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  decision.actionName,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
                Text(
                  [
                    attribution,
                    decision.surface,
                    if (decision.sourceScope != null) decision.sourceScope!,
                    if (decision.permission != null) decision.permission!,
                    ...decision.actionClasses,
                  ].join(' · '),
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppTimestamp.relative(
            decision.occurredAt,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    );
  }
}
