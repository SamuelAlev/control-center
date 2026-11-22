import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown when the conversation a goal or schedule was asked for is no longer
/// in the workspace.
class WorkTargetMissing implements Exception {
  const WorkTargetMissing();
}

/// A conversation to start work in.
typedef WorkTarget = ({String spaceId, String conversationId});

/// How the phone starts long-running work: it resolves the conversation
/// (the given one, or the space's standing conversation) and sends a person's
/// `/goal` the way a conversation turn does. The server parses and decides.
class PhoneWorkLauncher {
  PhoneWorkLauncher(this._client);

  final RemoteRpcClient _client;

  /// The conversation [conversationId] (checked to be in the workspace) or
  /// the standing conversation of [spaceId].
  Future<WorkTarget> target({
    required String workspaceId,
    String? conversationId,
    String? spaceId,
  }) async {
    final conversations = RpcConversationRepository(_client);
    if (conversationId != null) {
      final conversation = await conversations.getById(
        workspaceId: workspaceId,
        conversationId: conversationId,
      );
      final space = conversation?.spaceId;
      if (space == null || space.isEmpty) throw const WorkTargetMissing();
      return (spaceId: space, conversationId: conversationId);
    }
    if (spaceId == null || spaceId.isEmpty) throw const WorkTargetMissing();
    final ensured = await conversations.ensure(
      workspaceId: workspaceId,
      spaceId: spaceId,
    );
    return (spaceId: spaceId, conversationId: ensured.id);
  }

  /// Sends `/goal <body>` for [agentId]. The run id, or null when no run
  /// started (the server says why in the conversation).
  Future<String?> startGoal({
    required String workspaceId,
    required WorkTarget target,
    required String agentId,
    required String body,
  }) => RemoteMessagingDispatch(_client).dispatchAgent(
    workspaceId: workspaceId,
    spaceId: target.spaceId,
    agentId: agentId,
    prompt: '/goal $body',
    conversationId: target.conversationId,
  );
}

final phoneWorkLauncherProvider = Provider<PhoneWorkLauncher?>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  return client == null ? null : PhoneWorkLauncher(client);
});

/// The `/goal` body for the phone's form: the flags first, then the
/// objective, then the checks as the guided `## Checks` section (which the
/// server's parser reads back to the same commands, so no command needs
/// quoting). Throws [ArgumentError] for a check the contract refuses.
String phoneGoalCommandBody({
  required String objective,
  required int budgetMicros,
  int? maxRuns,
  List<String> checks = const [],
}) {
  final cents = budgetMicros ~/ 10000;
  final budget = '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
  final out = StringBuffer('--budget $budget ');
  if (maxRuns != null) out.write('--max $maxRuns ');
  out.write(objective.trim());
  final commands = [
    for (final run in checks)
      if (run.trim().isNotEmpty) GoalCheck(run: run.trim()),
  ];
  if (commands.isNotEmpty) {
    out
      ..write('\n\n')
      ..write(GoalCommand.checksSection(commands));
  }
  return out.toString();
}
