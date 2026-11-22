import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_run_row.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The agent registry's "Logs" tab: one agent's run history and the kill
/// control for anything still running. Each run is an `AgentRunRow`, which
/// opens the per-run NDJSON viewer (`AgentRunViewerDialog`).
///
/// Split out of `agent_registry_screen.dart`, which was over a thousand lines
/// against a 250-line convention. Nothing here is shared with the roster or the
/// config form, so it is a file rather than a region.
class AgentLogsTab extends ConsumerWidget {
  /// Creates an [AgentLogsTab] for [agent].
  const AgentLogsTab({super.key, required this.agent});

  /// The agent whose runs to list.
  final Agent agent;

  /// Asks the HOST to stop every process belonging to this agent.
  ///
  /// The agent's processes live in the SERVER's process table, so this is one
  /// RPC op, not a local `Process.killPid` loop: killing pids client-side only
  /// ever worked when the server happened to be co-located, and against a
  /// remote server it silently killed nothing (or an unrelated recycled pid on
  /// the operator's own machine).
  Future<void> _killAgentProcesses(WidgetRef ref) async {
    await ref
        .read(remoteAgentOpsProvider)
        .killProcesses(agent.workspaceId, agent.id);
    ref.invalidate(
      agentRunLogsProvider((workspaceId: agent.workspaceId, agentId: agent.id)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(
      agentRunLogsProvider((workspaceId: agent.workspaceId, agentId: agent.id)),
    );
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return logsAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(child: Text(l10n.failedToLoadLogs('$e'))),
      data: (logs) {
        final runningCount = logs.where((l) => l.isRunning).length;
        final hasRunning = runningCount > 0;

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(AppIcons.scrollText, size: 40, color: tokens.textTertiary),
                const SizedBox(height: 8),
                Text(
                  l10n.noExecutionLogsYet,
                  style: TextStyle(fontSize: 14, color: tokens.textTertiary),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${l10n.runsLabel}${hasRunning ? ' ($runningCount ${l10n.runningLabel})' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textTertiary,
                    ),
                  ),
                  if (hasRunning) ...[
                    const Spacer(),
                    CcButton(
                      variant: CcButtonVariant.destructive,
                      size: CcButtonSize.sm,
                      onPressed: () => unawaited(_killAgentProcesses(ref)),
                      icon: AppIcons.skull,
                      child: Text(l10n.killRunning),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: logs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    AgentRunRow(log: logs[i], workspaceId: agent.workspaceId),
              ),
            ),
          ],
        );
      },
    );
  }
}
