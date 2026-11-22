import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/held_steering_repository.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's bindings for long-running work: goals, waiting wakes,
/// schedules and held steering. Each is null until the session has a client,
/// and every call names its workspace; tests override these with fakes.
final phoneGoalRunsRepositoryProvider = Provider<RpcAgentGoalRunRepository?>((
  ref,
) {
  final client = ref.watch(rpcClientProvider).value;
  return client == null ? null : RpcAgentGoalRunRepository(client);
});

final phoneWakesRepositoryProvider = Provider<ConversationWakesRepository?>((
  ref,
) {
  final client = ref.watch(rpcClientProvider).value;
  return client == null ? null : RpcConversationWakesRepository(client);
});

final phoneSchedulesRepositoryProvider = Provider<WakeRuleScheduleRepository?>((
  ref,
) {
  final client = ref.watch(rpcClientProvider).value;
  return client == null ? null : RpcWakeRuleScheduleRepository(client);
});

final phoneHeldSteeringRepositoryProvider = Provider<HeldSteeringRepository?>((
  ref,
) {
  final client = ref.watch(rpcClientProvider).value;
  return client == null ? null : RpcHeldSteeringRepository(client);
});

/// Every schedule and watch of the workspace in a space the viewer may read,
/// newest first. Named by workspace so a switch tears the old stream down.
final phoneSchedulesProvider = StreamProvider.autoDispose
    .family<List<WakeRuleView>, String>((ref, workspaceId) {
      final repo = ref.watch(phoneSchedulesRepositoryProvider);
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (repo == null || active != workspaceId) return const Stream.empty();
      return repo
          .watchForWorkspace(workspaceId)
          .map(
            (rules) => [
              for (final rule in rules)
                if (rule.workspaceId == workspaceId) rule,
            ],
          );
    });

/// The pending and held wakes of one conversation, earliest due first.
final phoneConversationWakesProvider = StreamProvider.autoDispose
    .family<List<WakeView>, ({String workspaceId, String conversationId})>((
      ref,
      key,
    ) {
      final repo = ref.watch(phoneWakesRepositoryProvider);
      final active = ref.watch(activeWorkspaceIdProvider).value;
      if (repo == null || active != key.workspaceId) {
        return const Stream.empty();
      }
      return repo
          .watchForConversation(key.workspaceId, key.conversationId)
          .map(
            (wakes) => [
              for (final wake in wakes)
                if (wake.workspaceId == key.workspaceId &&
                    wake.conversationId == key.conversationId)
                  wake,
            ],
          );
    });
