import 'dart:async';

import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_class_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_rule_kinds.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_standing_list.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_vocabulary.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The action classes at one scope: a tally, then four families of rows, each
/// with its effective decision, where that decision came from, an inline
/// picker for the plain rule at the scope being edited, and the standing
/// approvals set there. Command rules at this scope follow in their own group.
class GuardrailMatrix extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<GuardrailMatrix> createState() => _GuardrailMatrixState();
}

class _GuardrailMatrixState extends ConsumerState<GuardrailMatrix> {
  static const PolicyResolver _resolver = PolicyResolver();

  /// Rebuilds when the next approval runs out, so an ended approval leaves
  /// the list and its row falls back without waiting for another change.
  Timer? _expiryTick;

  @override
  void dispose() {
    _expiryTick?.cancel();
    super.dispose();
  }

  void _scheduleExpiryTick(DateTime now) {
    _expiryTick?.cancel();
    DateTime? next;
    for (final r in widget.rules) {
      final at = r.expiresAt;
      if (at != null &&
          at.isAfter(now) &&
          (next == null || at.isBefore(next))) {
        next = at;
      }
    }
    if (next != null) {
      _expiryTick = Timer(next.difference(now), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final scope = widget.currentScope;
    if (scope == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          widget.scopeKind == ActionScopeType.agent
              ? l10n.guardrailNoAgents
              : l10n.guardrailNoSpaces,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
      );
    }
    final (scopeType, scopeId) = scope;
    // An approval given "for 8 hours" stops applying when it expires, and the
    // matrix shows what an action would meet now, as enforcement does.
    final now = DateTime.now();
    _scheduleExpiryTick(now);
    final rules = [
      for (final r in widget.rules)
        if (!r.isExpiredAt(now)) r,
    ];

    // The tally, computed over the same resolution the rows below render, so
    // the summary can never disagree with the matrix it summarizes.
    final counts = <ActionDecision, int>{
      for (final d in ActionDecision.values) d: 0,
    };
    for (final cls in ActionClass.values) {
      final decision = _resolver
          .resolveClassSetting(
            cls,
            rules: rules,
            spaceId: scopeType == ActionScopeType.space ? scopeId : null,
            agentId: scopeType == ActionScopeType.agent ? scopeId : null,
          )
          .decision;
      counts[decision] = counts[decision]! + 1;
    }
    // "Set here" and "Clear all" are about the picker's plain rules only;
    // standing approvals keep their own revoke actions.
    final plainHere = [
      for (final r in rules)
        if (r.isAt(scopeType, scopeId) && r.isPlainClassRule) r,
    ];
    final commandsHere = [
      for (final r in rules)
        if (r.isAt(scopeType, scopeId) && r.commandPrefix != null) r,
    ];

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
              value: '${plainHere.length}',
              tone: plainHere.isEmpty ? null : CcStatusTone.info,
            ),
          ],
          note: _otherScopesNote(l10n, rules, scopeType),
          trailing: plainHere.isEmpty
              ? null
              : CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  icon: AppIcons.rotateCcw,
                  onPressed: () {
                    for (final rule in plainHere) {
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
                GuardrailClassRow(
                  actionClass: cls,
                  rules: rules,
                  scopeType: scopeType,
                  scopeId: scopeId,
                ),
            ],
          ),
        if (commandsHere.isNotEmpty)
          SettingsGroup(
            title: l10n.guardrailFamilyCommands,
            showRule: true,
            separator: SettingsGroupSeparator.none,
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            children: [GuardrailStandingList(rules: commandsHere)],
          ),
      ],
    );
  }

  /// Standing approvals that are not listed here but matter here: the whole
  /// workspace's ones when a space or agent is being edited (they apply to it
  /// too), or single spaces' and agents' ones when the workspace is.
  String? _otherScopesNote(
    AppLocalizations l10n,
    List<ActionPolicyRule> rules,
    ActionScopeType scopeType,
  ) {
    final editingWorkspace = scopeType == ActionScopeType.workspace;
    final count = rules
        .where(
          (r) =>
              r.isStandingApproval &&
              (r.scopeType == ActionScopeType.workspace) != editingWorkspace,
        )
        .length;
    if (count == 0) {
      return null;
    }
    return editingWorkspace
        ? l10n.guardrailStandingInNarrowerScopes(count)
        : l10n.guardrailStandingFromWorkspace(count);
  }
}
