import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Agent sidebar item.
class AgentSidebarItem extends ConsumerWidget {
  /// Creates a new [AgentSidebarItem].
  const AgentSidebarItem({
    super.key,
    required this.agent,
    required this.isSelected,
    required this.onTap,
  });

  /// The agent to display.
  final Agent agent;
  /// Whether this item is currently selected.
  final bool isSelected;
  /// Called when the user taps this item.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final isRunning = ref.watch(
      agentIsRunningProvider((
        workspaceId: agent.workspaceId,
        agentId: agent.id,
      )),
    );
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: tokens.textPrimary.withValues(alpha: 0.1),
                border: Border(
                  left: BorderSide(color: tokens.textPrimary, width: 2),
                ),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    agent.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRunning)
                  CcSpinner(size: 12, color: tokens.textPrimary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              agent.title,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: tokens.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

