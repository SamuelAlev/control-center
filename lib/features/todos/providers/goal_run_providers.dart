import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watches the durable supervised goals ([AgentGoalRun] — `/goal` + `/loop`)
/// for a conversation in the active workspace, streamed live over RPC
/// (`agentGoalRuns.watchForConversation`), each as a [GoalRunView]: the goal
/// and whether this viewer may resume it or raise its budget.
///
/// Returns an empty stream until a workspace is active. `autoDispose` tears
/// the RPC subscription down when no widget is listening.
final conversationAgentGoalRunsProvider = StreamProvider.autoDispose
    .family<List<GoalRunView>, String>((ref, conversationId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null || workspaceId.isEmpty) {
        return const Stream<List<GoalRunView>>.empty();
      }
      return ref
          .watch(agentGoalRunRepositoryProvider)
          .watchForConversation(workspaceId, conversationId);
    });
