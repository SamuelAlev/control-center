import 'package:cc_domain/cc_domain.dart' show AgentDto, SpaceDto;
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The space (when no conversation is given) and agent a new goal or
/// schedule runs with. Only the workspace's spaces and active agents show.
class WorkTargetPicker extends ConsumerWidget {
  const WorkTargetPicker({
    super.key,
    required this.workspaceId,
    required this.askSpace,
    required this.spaceId,
    required this.agentId,
    required this.onSpace,
    required this.onAgent,
  });

  final String workspaceId;
  final bool askSpace;
  final String? spaceId;
  final String? agentId;
  final ValueChanged<String> onSpace;
  final ValueChanged<String> onAgent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final spaces = ref.watch(spacesProvider);
    final items = (spaces.value ?? const <SpaceDto>[])
        .where((s) => s.workspaceId == workspaceId)
        .toList();
    final agents = ref.watch(agentsProvider);
    final eligible = (agents.value ?? const <AgentDto>[])
        .where(
          (a) => a.workspaceId == workspaceId && a.lifecycleStatus == 'active',
        )
        .toList();
    final secondary = CcTypography.bodySm.copyWith(color: t.textSecondary);
    final danger = CcTypography.bodySm.copyWith(color: t.textErrorPrimary);
    Widget choice(String label, bool selected, VoidCallback onPressed) =>
        CcButton(
          size: CcButtonSize.lg,
          variant: selected
              ? CcButtonVariant.primary
              : CcButtonVariant.secondary,
          onPressed: onPressed,
          child: Text(label),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (askSpace) ...[
          Text(l10n.mobileGoalChooseSpace, style: secondary),
          const SizedBox(height: 6),
          if (spaces.isLoading) const Center(child: CcSpinner(size: 20)),
          if (spaces.hasError) Text(spaces.error.toString(), style: danger),
          if (spaces.hasValue && items.isEmpty)
            Text(l10n.mobileGoalNoSpaces, style: secondary),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final space in items)
                choice(
                  spaceId == space.id
                      ? l10n.mobileGoalSelectedSpace(space.name)
                      : space.name,
                  spaceId == space.id,
                  () => onSpace(space.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Text(l10n.mobileGoalChooseAgent, style: secondary),
        const SizedBox(height: 6),
        if (agents.isLoading) const Center(child: CcSpinner(size: 20)),
        if (agents.hasError) Text(agents.error.toString(), style: danger),
        if (agents.hasValue && eligible.isEmpty)
          Text(l10n.mobileGoalNoAgents, style: secondary),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final agent in eligible)
              choice(
                agentId == agent.id
                    ? l10n.mobileGoalSelectedAgent(agent.name)
                    : agent.name,
                agentId == agent.id,
                () => onAgent(agent.id),
              ),
          ],
        ),
      ],
    );
  }
}
