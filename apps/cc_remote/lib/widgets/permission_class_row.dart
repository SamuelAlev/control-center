import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/permission_labels.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Effective class policy, provenance, and the editable plain rule only.
class PermissionClassRow extends StatelessWidget {
  const PermissionClassRow({
    super.key,
    required this.actionClass,
    required this.rules,
    required this.local,
    required this.scopeType,
    required this.scopeId,
    required this.agentContextId,
    required this.mode,
    required this.canEdit,
    required this.draft,
    required this.busy,
    required this.revokeArmed,
    required this.onDraftChanged,
    required this.onSave,
    required this.onRevoke,
  });

  final ActionClass actionClass;
  final List<ActionPolicyRule> rules;
  final List<ActionPolicyRule> local;
  final ActionScopeType scopeType;
  final String scopeId;
  final String? agentContextId;
  final Mode mode;
  final bool canEdit;
  final ActionDecision? draft;
  final bool busy;
  final String? revokeArmed;
  final ValueChanged<ActionDecision> onDraftChanged;
  final ValueChanged<ActionPolicyRule?> onSave;
  final ValueChanged<ActionPolicyRule> onRevoke;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final resolution = const PolicyResolver().resolveClass(
      actionClass,
      rules: rules,
      spaceId: scopeType == ActionScopeType.space ? scopeId : null,
      agentId: scopeType == ActionScopeType.agent ? scopeId : agentContextId,
      mode: mode,
      now: DateTime.now(),
    );
    ActionPolicyRule? plain;
    final specialClass = local.any(
      (r) =>
          r.actionClass == actionClass &&
          (r.provenance != 'user' ||
              r.constraint != null ||
              r.expiresAt != null),
    );
    for (final rule in local) {
      if (rule.actionClass == actionClass &&
          rule.commandPrefix == null &&
          rule.constraint == null &&
          rule.provenance == 'user' &&
          rule.expiresAt == null) {
        plain = rule;
        break;
      }
    }
    final winning = resolution.rule;
    final effective =
        resolution.decision == ActionDecision.prompt &&
            winning?.enforcement == EnforcementLevel.advisory
        ? ActionDecision.allow
        : resolution.decision;
    final source = switch (resolution.source) {
      'workspace' => l.permissionWorkspaceScope,
      'agent' => l.permissionAgentScope,
      'space' => l.permissionSpaceScope,
      'preset' => l.permissionModePreset,
      _ => l.permissionBuiltInDefault,
    };
    final provenance = winning?.provenance == 'remembered'
        ? '${l.permissionRemembered} · $source'
        : source;
    final origin = winning == null
        ? source
        : resolution.source == scopeType.wire
        ? l.permissionSetAtThisScope(provenance)
        : l.permissionInheritedFrom(provenance);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  permissionClassLabel(l, actionClass),
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
              ),
              CcStatusTag(
                label: permissionDecisionLabel(l, effective),
                tone: permissionDecisionTone(effective),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${l.permissionSource}: $origin${winning?.expiresAt == null ? '' : ' · ${l.permissionExpiresAt(shortDate(context, winning!.expiresAt!))}'}',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          if (winning != null && winning.enforcement != EnforcementLevel.hard)
            Text(
              winning.enforcement == EnforcementLevel.advisory
                  ? l.permissionEnforcementAdvisory
                  : l.permissionEnforcementSoft,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          if (canEdit) ...[
            const SizedBox(height: 8),
            if (specialClass)
              Text(
                l.permissionRevokeBeforeEdit,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              )
            else ...[
              SizedBox(
                height: 48,
                child: CcSelect<ActionDecision>(
                  options: [
                    for (final d in ActionDecision.values)
                      CcSelectOption(
                        value: d,
                        label: permissionDecisionLabel(l, d),
                      ),
                  ],
                  value: draft,
                  hintText: l.permissionSetHere,
                  semanticLabel: permissionClassLabel(l, actionClass),
                  enabled: !busy,
                  onChanged: onDraftChanged,
                ),
              ),
              if (draft != null || plain != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (draft != null)
                        CcButton(
                          size: CcButtonSize.lg,
                          onPressed: busy ? null : () => onSave(plain),
                          child: Text(l.save),
                        ),
                      if (plain != null)
                        CcButton(
                          size: CcButtonSize.lg,
                          variant: CcButtonVariant.secondary,
                          onPressed: busy ? null : () => onRevoke(plain!),
                          child: Text(
                            revokeArmed == plain.id
                                ? l.permissionConfirmRevoke
                                : l.permissionRevokeRule,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ],
          CcDivider(color: t.borderSoft),
        ],
      ),
    );
  }
}
