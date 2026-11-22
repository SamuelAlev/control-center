import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_document_compiler.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/work_providers.dart';
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
    .family<List<GoalRunView>, String>((ref, workspaceId) {
      final repo = ref.watch(phoneGoalRunsRepositoryProvider);
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (repo == null || active != workspaceId) return const Stream.empty();
      return repo.watchForWorkspace(workspaceId);
    });

/// One conversation's goals, over the conversation watch rather than the
/// workspace inventory. Each carries the server's per-viewer `canResume`.
final phoneConversationGoalsProvider = StreamProvider.autoDispose
    .family<List<GoalRunView>, ({String workspaceId, String conversationId})>((
      ref,
      key,
    ) {
      final repo = ref.watch(phoneGoalRunsRepositoryProvider);
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (repo == null || active != key.workspaceId) {
        return const Stream.empty();
      }
      return repo.watchForConversation(key.workspaceId, key.conversationId);
    });
