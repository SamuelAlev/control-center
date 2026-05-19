import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/agent_permissions_section.dart';
import 'package:control_center/features/settings/providers/guardrail_policy_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "what if?" probe (PRD 24 §4): pick an [ActionClass] (and optionally a
/// command, an agent/channel scope and a [Mode]) and see exactly how the live
/// rule set would resolve it — decision, reason and the winning rule's
/// provenance. Runs the same [PolicyResolver] the enforcement path uses, fully
/// client-side against the watched rules.
class WhatIfProbeSection extends ConsumerStatefulWidget {
  /// Creates a [WhatIfProbeSection].
  const WhatIfProbeSection({super.key});

  @override
  ConsumerState<WhatIfProbeSection> createState() => _WhatIfProbeSectionState();
}

class _WhatIfProbeSectionState extends ConsumerState<WhatIfProbeSection> {
  static const PolicyResolver _resolver = PolicyResolver();
  static const String _none = '';

  final TextEditingController _commandController = TextEditingController();

  ActionClass _cls = ActionClass.fileDelete;
  String _agentId = _none;
  String _channelId = _none;
  Mode _mode = Mode.chat;

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  String _modeLabel(AppLocalizations l10n, Mode mode) => switch (mode) {
    Mode.chat => l10n.modeChat,
    Mode.plan => l10n.modePlan,
    Mode.review => l10n.modeReview,
    Mode.orchestrate => l10n.modeOrchestrate,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final rules =
        ref.watch(workspaceActionPoliciesProvider).asData?.value ?? const [];
    final List<Agent> agents = workspaceId == null
        ? const <Agent>[]
        : ref.watch(workspaceAgentsProvider(workspaceId)).asData?.value ??
              const <Agent>[];
    final List<Channel> channels = workspaceId == null
        ? const <Channel>[]
        : ref.watch(workspaceChannelsProvider(workspaceId)).asData?.value ??
              const <Channel>[];

    final command = _commandController.text.trim();
    final resolution = _probe(rules, command);

    return SectionCard(
      label: l10n.guardrailWhatIf,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.guardrailWhatIfDescription,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            ),
          ),
          CcSelect<ActionClass>(
            label: l10n.guardrailProbeActionLabel,
            options: [
              for (final c in ActionClass.values)
                CcSelectOption(value: c, label: guardrailClassLabel(l10n, c)),
            ],
            value: _cls,
            onChanged: (c) => setState(() => _cls = c),
          ),
          const SizedBox(height: AppSpacing.md),
          CcTextField(
            label: l10n.guardrailProbeCommandLabel,
            hintText: l10n.guardrailProbeCommandHint,
            controller: _commandController,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          CcSelect<String>(
            label: l10n.guardrailProbeAgentLabel,
            options: [
              CcSelectOption(value: _none, label: l10n.guardrailProbeNone),
              for (final a in agents)
                CcSelectOption(value: a.id, label: a.name),
            ],
            value: _agentId,
            onChanged: (id) => setState(() => _agentId = id),
          ),
          const SizedBox(height: AppSpacing.md),
          CcSelect<String>(
            label: l10n.guardrailProbeChannelLabel,
            options: [
              CcSelectOption(value: _none, label: l10n.guardrailProbeNone),
              for (final c in channels)
                CcSelectOption(value: c.id, label: c.name),
            ],
            value: _channelId,
            onChanged: (id) => setState(() => _channelId = id),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.guardrailProbeModeLabel,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedToggle<Mode>(
              value: _mode,
              onChanged: (m) => setState(() => _mode = m),
              segments: [
                for (final m in Mode.values)
                  (value: m, label: _modeLabel(l10n, m)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildResult(l10n, t, resolution),
        ],
      ),
    );
  }

  PolicyResolution _probe(List<ActionPolicyRule> rules, String command) {
    final agentId = _agentId == _none ? null : _agentId;
    final channelId = _channelId == _none ? null : _channelId;
    if (command.isNotEmpty) {
      return _resolver
          .resolveAction(
            {_cls},
            rules: rules,
            command: command,
            channelId: channelId,
            agentId: agentId,
            mode: _mode,
          )
          .driving;
    }
    return _resolver.resolveClass(
      _cls,
      rules: rules,
      channelId: channelId,
      agentId: agentId,
      mode: _mode,
    );
  }

  Widget _buildResult(
    AppLocalizations l10n,
    DesignSystemTokens t,
    PolicyResolution resolution,
  ) {
    final provenance = resolution.rule?.provenanceLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.guardrailProbeResult,
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcStatusTag(
                  label: guardrailDecisionLabel(l10n, resolution.decision),
                  tone: guardrailDecisionTone(resolution.decision),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              resolution.reason,
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  l10n.guardrailProbeSource,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  provenance ?? resolution.source,
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
