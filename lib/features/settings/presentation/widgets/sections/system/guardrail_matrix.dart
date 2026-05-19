import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_vocabulary.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The thirteen action classes at one scope: a tally, then four families of
/// rows, each with its effective decision, where that decision came from, and
/// an inline picker that upserts a rule at the scope being edited.
class GuardrailMatrix extends ConsumerWidget {
  /// Creates a [GuardrailMatrix].
  const GuardrailMatrix({
    super.key,
    required this.rules,
    required this.currentScope,
    required this.scopeKind,
  });

  /// The workspace's live rule set.
  final List<ActionPolicyRule> rules;

  /// The (type, id) being edited, or null when the chosen scope has no target
  /// (agent scope in a workspace with no agents).
  final (ActionScopeType, String)? currentScope;

  /// The scope kind the picker is on, used only for the empty-state copy.
  final ActionScopeType scopeKind;

  static const PolicyResolver _resolver = PolicyResolver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final scope = currentScope;
    if (scope == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          scopeKind == ActionScopeType.agent
              ? l10n.guardrailNoAgents
              : l10n.guardrailNoSpaces,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
      );
    }
    final (scopeType, scopeId) = scope;
    final spaceId = scopeType == ActionScopeType.space ? scopeId : null;
    final agentId = scopeType == ActionScopeType.agent ? scopeId : null;

    // The tally, computed over the same resolution the rows below render, so
    // the summary can never disagree with the matrix it summarizes.
    final counts = <ActionDecision, int>{
      for (final d in ActionDecision.values) d: 0,
    };
    final localRules = <ActionPolicyRule>[];
    for (final cls in ActionClass.values) {
      final decision = _resolver
          .resolveClass(cls, rules: rules, spaceId: spaceId, agentId: agentId)
          .decision;
      counts[decision] = counts[decision]! + 1;
      final local = _localRuleFor(rules, scopeType, scopeId, cls);
      if (local != null) {
        localRules.add(local);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSummary(
          facts: [
            SettingsFact(
              label: guardrailDecisionLabel(l10n, ActionDecision.allow),
              value: '${counts[ActionDecision.allow]}',
              tone: CcStatusTone.positive,
            ),
            SettingsFact(
              label: guardrailDecisionLabel(l10n, ActionDecision.prompt),
              value: '${counts[ActionDecision.prompt]}',
              tone: CcStatusTone.caution,
            ),
            SettingsFact(
              label: guardrailDecisionLabel(l10n, ActionDecision.deny),
              value: '${counts[ActionDecision.deny]}',
              tone: CcStatusTone.negative,
            ),
            SettingsFact(
              label: l10n.guardrailSetHere,
              value: '${localRules.length}',
              tone: localRules.isEmpty ? null : CcStatusTone.info,
            ),
          ],
          trailing: localRules.isEmpty
              ? null
              : CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  icon: AppIcons.rotateCcw,
                  onPressed: () {
                    for (final rule in localRules) {
                      deleteActionPolicyRule(ref, rule.id);
                    }
                  },
                  child: Text(l10n.guardrailClearAllHere),
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final family in kGuardrailFamilies)
          SettingsGroup(
            title: family.label(l10n),
            showRule: true,
            separator: SettingsGroupSeparator.none,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [
              for (final cls in family.classes)
                _row(
                  ref,
                  l10n,
                  t,
                  rules,
                  cls,
                  scopeType,
                  scopeId,
                  spaceId,
                  agentId,
                ),
            ],
          ),
      ],
    );
  }

  Widget _row(
    WidgetRef ref,
    AppLocalizations l10n,
    DesignSystemTokens t,
    List<ActionPolicyRule> rules,
    ActionClass cls,
    ActionScopeType scopeType,
    String scopeId,
    String? spaceId,
    String? agentId,
  ) {
    final resolution = _resolver.resolveClass(
      cls,
      rules: rules,
      spaceId: spaceId,
      agentId: agentId,
    );
    final localRule = _localRuleFor(rules, scopeType, scopeId, cls);
    final isLocal = localRule != null;

    return CcConfigRow(
      title: Text(guardrailClassLabel(l10n, cls)),
      source: _sourceFor(resolution.source, isLocal),
      sourceLabel: _sourceLabel(l10n, resolution.source, isLocal),
      status: CcStatusTag(
        label: guardrailDecisionLabel(l10n, resolution.decision),
        tone: guardrailDecisionTone(resolution.decision),
      ),
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 132,
            child: CcSelect<ActionDecision>(
              options: guardrailDecisionOptions(l10n),
              value: resolution.decision,
              semanticLabel: guardrailClassLabel(l10n, cls),
              onChanged: (d) =>
                  _setDecision(ref, cls, scopeType, scopeId, localRule, d),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Opacity(
            opacity: isLocal ? 1 : 0,
            child: CcIconButton(
              icon: AppIcons.rotateCcw,
              size: CcButtonSize.sm,
              onPressed: isLocal
                  ? () => deleteActionPolicyRule(ref, localRule.id)
                  : null,
              tooltip: l10n.guardrailClearToInherited,
              semanticLabel: l10n.guardrailClearToInherited,
            ),
          ),
        ],
      ),
    );
  }

  void _setDecision(
    WidgetRef ref,
    ActionClass cls,
    ActionScopeType scopeType,
    String scopeId,
    ActionPolicyRule? existing,
    ActionDecision decision,
  ) {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final now = DateTime.now();
    final rule = ActionPolicyRule(
      id:
          existing?.id ??
          stableActionPolicyRuleId(
            workspaceId: workspaceId,
            scopeType: scopeType,
            scopeId: scopeId,
            actionClass: cls,
          ),
      workspaceId: workspaceId,
      scopeType: scopeType,
      scopeId: scopeId,
      actionClass: cls,
      decision: decision,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    upsertActionPolicyRule(ref, rule);
  }

  ActionPolicyRule? _localRuleFor(
    List<ActionPolicyRule> rules,
    ActionScopeType scopeType,
    String scopeId,
    ActionClass cls,
  ) {
    for (final r in rules) {
      if (r.scopeType == scopeType &&
          r.scopeId == scopeId &&
          r.actionClass == cls &&
          r.commandPrefix == null) {
        return r;
      }
    }
    return null;
  }

  CcConfigSource _sourceFor(String source, bool isLocal) {
    if (isLocal) {
      return CcConfigSource.localOverride;
    }
    return switch (source) {
      'default' => CcConfigSource.defaultValue,
      'preset' => CcConfigSource.system,
      _ => CcConfigSource.inherited,
    };
  }

  String _sourceLabel(AppLocalizations l10n, String source, bool isLocal) {
    if (isLocal) {
      return l10n.guardrailSourceThisScope;
    }
    return switch (source) {
      'default' => l10n.guardrailSourceDefault,
      'preset' => l10n.guardrailSourcePreset,
      _ => l10n.guardrailSourceInherited,
    };
  }
}
