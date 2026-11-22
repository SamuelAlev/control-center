import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Which run would end its turn: what a server [WouldStopHandler] reads.
class ServerWouldStop {
  /// Creates the context.
  const ServerWouldStop({
    required this.workspaceId,
    required this.agentId,
    required this.conversationId,
    required this.runId,
    required this.loop,
  });

  /// The run's workspace.
  final String workspaceId;

  /// The run's agent.
  final String agentId;

  /// The run's conversation, when it has one.
  final String? conversationId;

  /// The run's id (its run log row).
  final String runId;

  /// What the loop knows: the turn and the model's final message.
  final WouldStopContext loop;
}

/// Server code that may keep a run from ending its turn (a peer's question
/// still unanswered). Returns null, or [WouldStopEnd], to let the next
/// handler decide. A throw is logged and counts as null.
typedef WouldStopHandler = Future<WouldStop?> Function(ServerWouldStop stop);

/// The server's [WouldStopHandler]s, in registration order. One registry per
/// dispatch stack: the server adds its handlers once at boot and every main
/// run's [ServerTurnHooks] reads them.
class WouldStopHandlers {
  final List<WouldStopHandler> _handlers = [];

  /// Adds [handler] after the ones already registered.
  void add(WouldStopHandler handler) => _handlers.add(handler);

  /// Whether any handler is registered.
  bool get isEmpty => _handlers.isEmpty;

  /// The handlers, in order.
  List<WouldStopHandler> get all => List.unmodifiable(_handlers);
}

/// The turn hooks of a main run: the server's [WouldStopHandlers] first,
/// then the owner's `stop` hook ([owner]). The first handler that answers
/// anything but [WouldStopEnd] decides; the owner's hook runs only when
/// every server handler let the turn end. `preCompact` is the owner's.
class ServerTurnHooks implements AgentLoopTurnHooks {
  /// Composes [handlers] for the run [workspaceId]/[agentId]/[runId] with
  /// the owner's [owner] hooks.
  const ServerTurnHooks({
    required this.handlers,
    required this.workspaceId,
    required this.agentId,
    required this.conversationId,
    required this.runId,
    this.owner,
  });

  /// The turn hooks of [run], a main run, or [owner] alone when the run
  /// lacks the identity a server handler needs (no workspace, agent or run
  /// row) or no handler is registered.
  static AgentLoopTurnHooks? compose(
    WouldStopHandlers handlers,
    SteeringSessionView run, {
    required Object? owner,
  }) {
    final ownerHooks = switch (owner) {
      final AgentLoopTurnHooks hooks => hooks,
      _ => null,
    };
    final (workspaceId, agentId, runId) = (
      run.workspaceId,
      run.agentId,
      run.runLogId,
    );
    if (handlers.isEmpty ||
        workspaceId == null ||
        agentId == null ||
        runId == null) {
      return ownerHooks;
    }
    return ServerTurnHooks(
      handlers: handlers,
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: run.conversationId,
      runId: runId,
      owner: ownerHooks,
    );
  }

  /// The server's handlers.
  final WouldStopHandlers handlers;

  /// The run's workspace.
  final String workspaceId;

  /// The run's agent.
  final String agentId;

  /// The run's conversation.
  final String? conversationId;

  /// The run's id.
  final String runId;

  /// The owner's hooks (its `stop` and `preCompact` scripts), or null.
  final AgentLoopTurnHooks? owner;

  @override
  Future<WouldStop> onWouldStop(WouldStopContext context) async {
    final stop = ServerWouldStop(
      workspaceId: workspaceId,
      agentId: agentId,
      conversationId: conversationId,
      runId: runId,
      loop: context,
    );
    for (final handler in handlers.all) {
      WouldStop? answer;
      try {
        answer = await handler(stop);
      } on Object catch (e, st) {
        CcInfraLog.error('would-stop handler failed for run $runId', e, st);
      }
      if (answer != null && answer is! WouldStopEnd) {
        return answer;
      }
    }
    final owner = this.owner;
    return owner == null ? const WouldStopEnd() : owner.onWouldStop(context);
  }

  @override
  Future<String?> preCompact() async => await owner?.preCompact();
}
