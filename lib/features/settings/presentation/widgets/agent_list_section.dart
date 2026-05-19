import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_filter_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Agent list section.
class AgentListSection extends StatelessWidget {
  /// Creates a new [AgentListSection].
  const AgentListSection({
    super.key,
    required this.agents,
    required this.selectedAgentId,
    required this.filterController,
    required this.onAgentSelected,
    required this.onCreateAgent,
  });

  /// Agents to display in the list.
  final List<Agent> agents;
  /// ID of the currently selected agent, if any.
  final String? selectedAgentId;
  /// Controller for the filter text field.
  final TextEditingController filterController;
  /// Called when the user selects an agent.
  final void Function(String agentId) onAgentSelected;
  /// Called when the user presses the 'New agent' button.
  final VoidCallback onCreateAgent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: FButton(
              onPress: onCreateAgent,
              variant: FButtonVariant.outline,
              size: FButtonSizeVariant.sm,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.newAgent),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: FTextField(
              control: FTextFieldControl.managed(controller: filterController),
              hint: l10n.filterAgents,
              size: FTextFieldSizeVariant.sm,
            ),
          ),
          const FDivider(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: agents.length,
              separatorBuilder: (_, _) => const FDivider(),
              itemBuilder: (context, index) {
                final agent = agents[index];
                final isSelected = agent.id == selectedAgentId;
                return AgentSidebarItem(
                  agent: agent,
                  isSelected: isSelected,
                  onTap: () => onAgentSelected(agent.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

