import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A subscription always names the active workspace explicitly; changing
/// workspaces tears down the old stream even while a detail route remains open.
final phonePlansProvider = StreamProvider.autoDispose
    .family<List<PlanDocument>, String>((ref, workspaceId) {
      final client = ref.watch(rpcClientProvider).value;
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || active != workspaceId) return const Stream.empty();
      return RemotePlanStudioRepository(
        client,
      ).watchPlanDocuments(workspaceId: workspaceId);
    });

typedef PhonePlanKey = ({String workspaceId, String planId});

final phonePlanProvider = StreamProvider.autoDispose
    .family<PlanDocument?, PhonePlanKey>((ref, key) {
      final client = ref.watch(rpcClientProvider).value;
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || active != key.workspaceId) {
        return const Stream.empty();
      }
      return RemotePlanStudioRepository(
        client,
      ).watchPlanById(key.planId, workspaceId: key.workspaceId);
    });

final phonePlanExecutionProvider = StreamProvider.autoDispose
    .family<OrchestrationDto?, PhonePlanKey>((ref, key) {
      final client = ref.watch(rpcClientProvider).value;
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || active != key.workspaceId) {
        return const Stream.empty();
      }
      return RemoteOrchestrationRepository(client).watchById(
        PlanDocumentCompiler.orchestrationIdFor(key.planId),
        workspaceId: key.workspaceId,
      );
    });

final phonePlanStepsProvider = StreamProvider.autoDispose
    .family<List<PipelineStepRunDto>, ({String workspaceId, String runId})>((
      ref,
      key,
    ) {
      final client = ref.watch(rpcClientProvider).value;
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || active != key.workspaceId) {
        return const Stream.empty();
      }
      return RemotePipelineRunRepository(
        client,
      ).watchStepRunsForPipeline(key.runId, workspaceId: key.workspaceId);
    });

final phoneWorkspaceGoalsProvider = StreamProvider.autoDispose
    .family<List<AgentGoalRun>, String>((ref, workspaceId) {
      final client = ref.watch(rpcClientProvider).value;
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || active != workspaceId) return const Stream.empty();
      return RpcAgentGoalRunRepository(client).watchForWorkspace(workspaceId);
    });

/// Context-filtered goals use the original conversation watch (older hosts
/// can still serve the conversation detail without the workspace inventory).
final phoneConversationGoalsProvider = StreamProvider.autoDispose
    .family<List<AgentGoalRun>, ({String workspaceId, String conversationId})>((
      ref,
      key,
    ) {
      final client = ref.watch(rpcClientProvider).value;
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || active != key.workspaceId) {
        return const Stream.empty();
      }
      return RpcAgentGoalRunRepository(
        client,
      ).watchForConversation(key.workspaceId, key.conversationId);
    });
