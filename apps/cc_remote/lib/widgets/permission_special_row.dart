import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/permission_labels.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Conditional, expiring, and remembered rules stay visible and revocable.
class PermissionSpecialRow extends StatelessWidget {
  const PermissionSpecialRow({
    super.key,
    required this.rule,
    required this.canEdit,
    required this.busy,
    required this.revokeArmed,
    required this.onRevoke,
  });

  final ActionPolicyRule rule;
  final bool canEdit;
  final bool busy;
  final String? revokeArmed;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final expired = rule.isExpiredAt(DateTime.now());
    final title = rule.actionClass == null
        ? l.permissionCommandPrefix(rule.commandPrefix ?? '')
        : permissionClassLabel(l, rule.actionClass!);
    final expiry = rule.expiresAt;
    final when = expiry == null
        ? l.permissionNoExpiry
        : l.permissionExpiresAt(
            DateFormat.yMMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).add_Hm().format(expiry.toLocal()),
          );
    final effective =
        rule.enforcement == EnforcementLevel.advisory &&
            rule.decision == ActionDecision.prompt
        ? ActionDecision.allow
        : rule.decision;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ),
              CcStatusTag(
                label: expired
                    ? l.permissionExpired
                    : permissionDecisionLabel(l, effective),
                tone: expired
                    ? CcStatusTone.neutral
                    : permissionDecisionTone(effective),
              ),
            ],
          ),
          Text(
            '${rule.provenance == 'remembered' ? l.permissionRemembered : l.permissionExplicitRule} · $when',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          Text(switch (rule.enforcement) {
            EnforcementLevel.advisory => l.permissionEnforcementAdvisory,
            EnforcementLevel.soft => l.permissionEnforcementSoft,
            EnforcementLevel.hard => l.permissionEnforcementHard,
          }, style: CcTypography.caption.copyWith(color: t.textTertiary)),
          if (rule.constraint != null)
            Text(
              _constraintDescription(context, rule, l),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          if (canEdit)
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              onPressed: busy ? null : onRevoke,
              child: Text(
                revokeArmed == rule.id
                    ? l.permissionConfirmRevoke
                    : l.permissionRevokeRule,
              ),
            ),
          CcDivider(color: t.borderSoft),
        ],
      ),
    );
  }

  String _constraintDescription(
    BuildContext context,
    ActionPolicyRule rule,
    AppLocalizations l,
  ) {
    final constraint = rule.constraint!;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return [
      if (constraint.paths != null)
        l.permissionPaths(constraint.paths!.join(', ')),
      if (constraint.refs != null)
        l.permissionRefs(constraint.refs!.join(', ')),
      if (constraint.hosts != null)
        l.permissionHosts(constraint.hosts!.join(', ')),
      if (constraint.commands != null)
        l.permissionCommands(constraint.commands!.join(', ')),
      if (constraint.maxCount != null)
        l.permissionMaxCount(number.format(constraint.maxCount)),
      if (constraint.maxCents != null)
        l.permissionMaxCents(number.format(constraint.maxCents)),
    ].join(' · ');
  }
}
