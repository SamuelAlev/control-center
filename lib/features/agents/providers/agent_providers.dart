import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watches all agents ordered by name.
final agentsProvider = StreamProvider<List<Agent>>((ref) {
  final repo = ref.watch(agentRepositoryProvider);
  return repo.watchAll();
});

/// Watches agents for a specific workspace ordered by name.
final workspaceAgentsProvider =
    StreamProvider.family<List<Agent>, String>((ref, workspaceId) {
  final repo = ref.watch(agentRepositoryProvider);
  return repo.watchByWorkspace(workspaceId);
});

/// Returns a single agent by id.
final agentDetailProvider = FutureProvider.family<Agent?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(agentRepositoryProvider);
  return repo.getById(id);
});

/// Watches run logs for a given agent.
final agentRunLogsProvider = StreamProvider.family<List<AgentRunLog>, String>((
  ref,
  agentId,
) {
  final repo = ref.watch(agentRunLogRepositoryProvider);
  return repo.watchByAgent(agentId);
});

/// Identifies a conversation within a workspace, for conversation-scoped run
/// queries. A record (value equality) so it works as a provider family key.
typedef ConversationRunsKey = ({String workspaceId, String conversationId});

/// Watches the active (not-yet-completed) run logs for a conversation. Empty
/// when no agent is currently working in the channel/ticket.
final conversationActiveRunsProvider = StreamProvider.autoDispose
    .family<List<AgentRunLog>, ConversationRunsKey>((ref, key) {
  return ref
      .watch(agentRunLogRepositoryProvider)
      .watchActiveByConversation(key.workspaceId, key.conversationId);
});

/// Whether any agent is currently running in the conversation. Drives the
/// composer's stop/queue affordance.
final conversationBusyProvider =
    Provider.autoDispose.family<bool, ConversationRunsKey>((ref, key) {
  final runs = ref.watch(conversationActiveRunsProvider(key)).asData?.value;
  return runs != null && runs.isNotEmpty;
});

/// Whether the agent has any run logs that are currently running.
final agentIsRunningProvider = Provider.family<bool, String>((ref, agentId) {
  final logsAsync = ref.watch(agentRunLogsProvider(agentId));
  return logsAsync.whenOrNull(
        data: (logs) => logs.any((log) => log.isRunning),
      ) ??
      false;
});

/// The derived [AgentLiveState] for an agent, computed from its run logs.
///
/// Drives the roster's per-row presence indicator and status sort. While the
/// logs stream is still loading, the agent reads as idle rather than flashing
/// "no runs yet".
final agentLiveStateProvider = Provider.family<AgentLiveState, String>((
  ref,
  agentId,
) {
  final logs = ref.watch(agentRunLogsProvider(agentId)).asData?.value;
  if (logs == null) {
    return AgentLiveState.idle;
  }
  return deriveAgentLiveState(logs);
});

/// The moment an agent last showed activity, or null if it has never run.
final agentLastActiveProvider = Provider.family<DateTime?, String>((
  ref,
  agentId,
) {
  final logs = ref.watch(agentRunLogsProvider(agentId)).asData?.value;
  if (logs == null) {
    return null;
  }
  return agentLastActive(logs);
});
