import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Localized display label for an [ActionClass] (sentence case). The
/// [ActionClass.wire] value is a stable identifier; this maps it to prose.
String guardrailClassLabel(AppLocalizations l10n, ActionClass cls) =>
    switch (cls) {
      ActionClass.fileDelete => l10n.guardrailClassFileDelete,
      ActionClass.fileWriteOutsideWorktree =>
        l10n.guardrailClassFileWriteOutsideWorktree,
      ActionClass.gitCommit => l10n.guardrailClassGitCommit,
      ActionClass.gitPush => l10n.guardrailClassGitPush,
      ActionClass.prCreate => l10n.guardrailClassPrCreate,
      ActionClass.prPublish => l10n.guardrailClassPrPublish,
      ActionClass.vendorSyncWrite => l10n.guardrailClassVendorSyncWrite,
      ActionClass.networkEgress => l10n.guardrailClassNetworkEgress,
      ActionClass.secretAccess => l10n.guardrailClassSecretAccess,
      ActionClass.packageInstall => l10n.guardrailClassPackageInstall,
      ActionClass.processSpawn => l10n.guardrailClassProcessSpawn,
      ActionClass.workspaceMutation => l10n.guardrailClassWorkspaceMutation,
    };

/// Localized decision label (allow / ask first / deny).
String guardrailDecisionLabel(AppLocalizations l10n, ActionDecision decision) =>
    switch (decision) {
      ActionDecision.allow => l10n.guardrailDecisionAllow,
      ActionDecision.prompt => l10n.guardrailDecisionPrompt,
      ActionDecision.deny => l10n.guardrailDecisionDeny,
    };

/// The status tone for a decision (never color-alone — always paired with the
/// localized label).
CcStatusTone guardrailDecisionTone(ActionDecision decision) =>
    switch (decision) {
      ActionDecision.allow => CcStatusTone.positive,
      ActionDecision.prompt => CcStatusTone.caution,
      ActionDecision.deny => CcStatusTone.negative,
    };

/// The allow / ask-first / deny options for a [CcSelect].
List<CcSelectOption<ActionDecision>> guardrailDecisionOptions(
  AppLocalizations l10n,
) => [
  for (final d in ActionDecision.values)
    CcSelectOption(value: d, label: guardrailDecisionLabel(l10n, d)),
];

/// The editable agent-permission matrix (PRD 24 §2): one row per [ActionClass],
/// resolved client-side against the workspace's live rule set with a
/// [PolicyResolver]. A scope selector (workspace / a chosen agent / a chosen
/// channel) rebases the whole matrix; each cell shows the effective decision +
/// where it came from, and an inline picker upserts a rule at the current scope.
class AgentPermissionsSection extends ConsumerStatefulWidget {
  /// Creates an [AgentPermissionsSection].
  const AgentPermissionsSection({super.key});

  @override
  ConsumerState<AgentPermissionsSection> createState() =>
      _AgentPermissionsSectionState();
}

class _AgentPermissionsSectionState
    extends ConsumerState<AgentPermissionsSection> {
  static const PolicyResolver _resolver = PolicyResolver();

  ActionScopeType _scope = ActionScopeType.workspace;
  String? _agentId;
  String? _channelId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final rulesAsync = ref.watch(workspaceActionPoliciesProvider);

    return SectionCard(
      label: l10n.agentPermissions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.agentPermissionsMatrixDescription,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedToggle<ActionScopeType>(
              value: _scope,
              onChanged: (s) => setState(() => _scope = s),
              segments: [
                (
                  value: ActionScopeType.workspace,
                  label: l10n.guardrailScopeWorkspace,
                ),
                (value: ActionScopeType.agent, label: l10n.guardrailScopeAgent),
                (
                  value: ActionScopeType.channel,
                  label: l10n.guardrailScopeChannel,
                ),
              ],
            ),
          ),
          if (_scope != ActionScopeType.workspace) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildScopeTargetPicker(l10n),
          ],
          const SizedBox(height: AppSpacing.md),
          rulesAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.guardrailLoading,
                style: CcTypography.bodySm.copyWith(color: t.textTertiary),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n.guardrailRulesLoadFailed,
                style: CcTypography.bodySm.copyWith(color: t.danger),
              ),
            ),
            data: (rules) => _buildMatrix(l10n, t, rules),
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
    final channels =
        ref.watch(workspaceChannelsProvider(workspaceId)).asData?.value ??
        const <Channel>[];
    return CcSelect<String>(
      options: [
        for (final c in channels) CcSelectOption(value: c.id, label: c.name),
      ],
      value: _effectiveChannelId(),
      hintText: l10n.guardrailSelectChannel,
      onChanged: (id) => setState(() => _channelId = id),
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

  String? _effectiveChannelId() {
    if (_channelId != null) {
      return _channelId;
    }
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return null;
    }
    final channels =
        ref.read(workspaceChannelsProvider(workspaceId)).asData?.value ??
        const <Channel>[];
    return channels.isEmpty ? null : channels.first.id;
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
      case ActionScopeType.channel:
        final id = _effectiveChannelId();
        return id == null ? null : (ActionScopeType.channel, id);
    }
  }

  Widget _buildMatrix(
    AppLocalizations l10n,
    DesignSystemTokens t,
    List<ActionPolicyRule> rules,
  ) {
    final scope = _currentScope();
    if (scope == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          _scope == ActionScopeType.agent
              ? l10n.guardrailNoAgents
              : l10n.guardrailNoChannels,
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
      );
    }
    final (scopeType, scopeId) = scope;
    final channelId = scopeType == ActionScopeType.channel ? scopeId : null;
    final agentId = scopeType == ActionScopeType.agent ? scopeId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final cls in ActionClass.values)
          _buildRow(
            l10n,
            t,
            rules,
            cls,
            scopeType,
            scopeId,
            channelId,
            agentId,
          ),
      ],
    );
  }

  Widget _buildRow(
    AppLocalizations l10n,
    DesignSystemTokens t,
    List<ActionPolicyRule> rules,
    ActionClass cls,
    ActionScopeType scopeType,
    String scopeId,
    String? channelId,
    String? agentId,
  ) {
    final resolution = _resolver.resolveClass(
      cls,
      rules: rules,
      channelId: channelId,
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
                  _setDecision(cls, scopeType, scopeId, localRule, d),
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
