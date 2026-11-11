import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_rule_kinds.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_standing_list.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_vocabulary.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One action class at the scope being edited: its setting, where that came
/// from, a picker that writes the plain rule, and under it the standing
/// approvals and conditional rules set here for this class.
///
/// The row shows the class's setting ([PolicyResolver.resolveClassSetting]);
/// the entries under it are its exceptions. They are separate rules on the
/// server, so the picker and an entry's revoke never touch each other.
class GuardrailClassRow extends ConsumerWidget {
  /// Creates a [GuardrailClassRow].
  const GuardrailClassRow({
    super.key,
    required this.actionClass,
    required this.rules,
    required this.scopeType,
    required this.scopeId,
  });

  /// The class this row is about.
  final ActionClass actionClass;

  /// The workspace's live (unexpired) rules.
  final List<ActionPolicyRule> rules;

  /// The scope being edited.
  final ActionScopeType scopeType;

  /// The scope id being edited (empty for the workspace).
  final String scopeId;

  static const PolicyResolver _resolver = PolicyResolver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cls = actionClass;
    final setting = _resolver.resolveClassSetting(
      cls,
      rules: rules,
      spaceId: scopeType == ActionScopeType.space ? scopeId : null,
      agentId: scopeType == ActionScopeType.agent ? scopeId : null,
    );
    final here = [
      for (final r in rules)
        if (r.isAt(scopeType, scopeId) && r.actionClass == cls) r,
    ];
    final plain = here.firstWhereOrNull((r) => r.isPlainClassRule);
    final exceptions = [
      for (final r in here)
        if (!r.isPlainClassRule) r,
    ];
    final decidedHere = setting.source == scopeType.wire;
    // An approval answers an ask and never a deny, so under a denied class it
    // is listed as not in effect. A person's own conditional allow is more
    // specific than the setting and applies either way.
    final denied = setting.decision == ActionDecision.deny;
    final allowedBelow = setting.decision == ActionDecision.allow
        ? 0
        : exceptions
              .where(
                (r) =>
                    r.decision == ActionDecision.allow &&
                    !(denied && r.isStandingApproval),
              )
              .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcConfigRow(
          title: Text(guardrailClassLabel(l10n, cls)),
          subtitle: allowedBelow == 0
              ? null
              : Text(l10n.guardrailClassPartlyAllowed(allowedBelow)),
          source: decidedHere
              ? CcConfigSource.localOverride
              : _inheritedSource(setting.source),
          sourceLabel: _sourceLabel(l10n, setting, decidedHere),
          status: CcStatusTag(
            label: guardrailDecisionLabel(l10n, setting.decision),
            tone: guardrailDecisionTone(setting.decision),
          ),
          actions: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 132,
                child: CcSelect<ActionDecision>(
                  options: guardrailDecisionOptions(l10n),
                  value: setting.decision,
                  semanticLabel: guardrailClassLabel(l10n, cls),
                  onChanged: (d) => _setPlainRule(ref, plain, d),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Opacity(
                opacity: plain != null ? 1 : 0,
                child: CcIconButton(
                  icon: AppIcons.rotateCcw,
                  size: CcButtonSize.sm,
                  onPressed: plain != null
                      ? () => deleteActionPolicyRule(ref, plain.id)
                      : null,
                  tooltip: l10n.guardrailClearToInherited,
                  semanticLabel: l10n.guardrailClearToInherited,
                ),
              ),
            ],
          ),
        ),
        if (exceptions.isNotEmpty)
          GuardrailStandingList(rules: exceptions, classDenied: denied),
      ],
    );
  }

  /// Writes the plain rule under its stable id. The entries listed under the
  /// row are other rules and stay as they are.
  void _setPlainRule(
    WidgetRef ref,
    ActionPolicyRule? plain,
    ActionDecision decision,
  ) {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final now = DateTime.now();
    upsertActionPolicyRule(
      ref,
      ActionPolicyRule(
        id: stableActionPolicyRuleId(
          workspaceId: workspaceId,
          scopeType: scopeType,
          scopeId: scopeId,
          actionClass: actionClass,
        ),
        workspaceId: workspaceId,
        scopeType: scopeType,
        scopeId: scopeId,
        actionClass: actionClass,
        decision: decision,
        createdBy: plain?.createdBy,
        createdAt: plain?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  CcConfigSource _inheritedSource(String source) => switch (source) {
    'default' => CcConfigSource.defaultValue,
    'preset' => CcConfigSource.system,
    _ => CcConfigSource.inherited,
  };

  String _sourceLabel(
    AppLocalizations l10n,
    PolicyResolution setting,
    bool decidedHere,
  ) {
    if (decidedHere) {
      return setting.rule?.isStandingApproval ?? false
          ? l10n.guardrailStandingApproval
          : l10n.guardrailSourceThisScope;
    }
    return switch (setting.source) {
      'default' => l10n.guardrailSourceDefault,
      'preset' => l10n.guardrailSourcePreset,
      _ => l10n.guardrailSourceInherited,
    };
  }
}
