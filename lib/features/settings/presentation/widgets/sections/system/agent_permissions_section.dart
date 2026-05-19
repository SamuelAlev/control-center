import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/guardrail_matrix.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The editable agent-permission matrix (PRD 24 §2): one row per [ActionClass],
/// resolved client-side against the workspace's live rule set with a
/// [PolicyResolver]. A scope selector (workspace / a chosen agent / a chosen
/// space) rebases the whole matrix; each cell shows the effective decision +
/// where it came from and an inline picker upserts a rule at the current scope.
///
/// The matrix opens with the tally — how many classes are allowed, ask-first
/// and denied at the chosen scope, and how many of those verdicts were set
/// *here* rather than inherited. Thirteen dropdowns cannot tell you your
/// posture; four numbers can.
class AgentPermissionsSection extends ConsumerStatefulWidget {
  /// Creates an [AgentPermissionsSection].
  const AgentPermissionsSection({super.key});

  @override
  ConsumerState<AgentPermissionsSection> createState() =>
      _AgentPermissionsSectionState();
}

class _AgentPermissionsSectionState
    extends ConsumerState<AgentPermissionsSection> {
  ActionScopeType _scope = ActionScopeType.workspace;
  String? _agentId;
  String? _spaceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final rulesAsync = ref.watch(workspaceActionPoliciesProvider);

    return SectionCard(
      label: l10n.agentPermissions,
      subtitle: Text(l10n.agentPermissionsMatrixDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsField(
            label: l10n.guardrailScopeFieldLabel,
            description: l10n.guardrailScopeFieldDescription,
            layout: SettingsFieldLayout.stacked,
            child: Row(
              children: [
                CcSegmentedToggle<ActionScopeType>(
                  value: _scope,
                  onChanged: (s) => setState(() => _scope = s),
                  // Shares the row with the scope-target select, so it takes
                  // the field-height step of the ramp.
                  size: CcSegmentedToggleSize.md,
                  segments: [
                    CcSegment(
                      value: ActionScopeType.workspace,
                      label: l10n.guardrailScopeWorkspace,
                    ),
                    CcSegment(
                      value: ActionScopeType.agent,
                      label: l10n.guardrailScopeAgent,
                    ),
                    CcSegment(
                      value: ActionScopeType.space,
                      label: l10n.guardrailScopeSpace,
                    ),
                  ],
                ),
                if (_scope != ActionScopeType.workspace) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildScopeTargetPicker(l10n)),
                ] else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          rulesAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.guardrailLoading,
                style: CcTypography.bodySm.copyWith(color: t.textTertiary),
              ),
            ),
            error: (e, _) => CcAlert(
              title: l10n.guardrailRulesLoadFailed,
              variant: CcAlertVariant.danger,
            ),
            data: (rules) => GuardrailMatrix(
              rules: rules,
              currentScope: _currentScope(),
              scopeKind: _scope,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeTargetPicker(AppLocalizations l10n) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    if (_scope == ActionScopeType.agent) {
      final agents =
          ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
          const [];
      return CcSelect<String>(
        options: [
          for (final a in agents) CcSelectOption(value: a.id, label: a.name),
        ],
        value: _effectiveAgentId(),
        hintText: l10n.guardrailSelectAgent,
        onChanged: (id) => setState(() => _agentId = id),
      );
    }
    final spaces =
        ref.watch(workspaceSpacesProvider(workspaceId)).asData?.value ??
        const <Space>[];
    return CcSelect<String>(
      options: [
        for (final c in spaces) CcSelectOption(value: c.id, label: c.name),
      ],
      value: _effectiveSpaceId(),
      hintText: l10n.guardrailSelectSpace,
      onChanged: (id) => setState(() => _spaceId = id),
    );
  }

  String? _effectiveAgentId() {
    if (_agentId != null) {
      return _agentId;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return null;
    }
    final agents =
        ref.read(workspaceAgentsProvider(workspaceId)).asData?.value ??
        const [];
    return agents.isEmpty ? null : agents.first.id;
  }

  String? _effectiveSpaceId() {
    if (_spaceId != null) {
      return _spaceId;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return null;
    }
    final spaces =
        ref.read(workspaceSpacesProvider(workspaceId)).asData?.value ??
        const <Space>[];
    return spaces.isEmpty ? null : spaces.first.id;
  }

  /// The (scopeType, scopeId) the matrix is currently editing, or null when the
  /// selected scope has no target chosen (e.g. agent scope with no agents).
  (ActionScopeType, String)? _currentScope() {
    switch (_scope) {
      case ActionScopeType.workspace:
        return (ActionScopeType.workspace, '');
      case ActionScopeType.agent:
        final id = _effectiveAgentId();
        return id == null ? null : (ActionScopeType.agent, id);
      case ActionScopeType.space:
        final id = _effectiveSpaceId();
        return id == null ? null : (ActionScopeType.space, id);
    }
  }
}
