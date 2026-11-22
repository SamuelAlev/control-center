import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/todos/domain/repositories/todo_repository.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        GoalChanges,
        GoalCheckRunner,
        GoalOwedWork,
        GoalProgressObserver,
        GoalStore,
        GoalSupervisor,
        GoalTurnTexts,
        GoalVerifier,
        HostExecutionGate,
        LateEnvironmentPort,
        MessagingService,
        RunToolActivity,
        SandboxManager,
        WakeQueueService,
        WorktreeFingerprints;
import 'package:cc_mcp/cc_mcp.dart' show CompleteGoalTool, GoalStatusTool;
import 'package:cc_persistence/cc_persistence.dart'
    show
        DaoPeerAskRepository,
        DaoSpaceCheckerRepository,
        DaoTicketRepository,
        DaoWakeRuleRepository,
        WorkspaceDatabaseManager;
import 'package:cc_server_core/src/runtime/server_wake_queue_wiring.dart';

/// The durable goals of the server (plan section 8), wired in three steps
/// because their parts are needed at different points of the runtime's
/// construction:
///
/// 1. [ServerGoals.new], before the dispatch use case: the goal rows, the
///    per-turn goal text ([turnTexts]) and the record of each run's tool
///    calls ([toolActivity]) the stream processor fills.
/// 2. [buildSupervisor], once the messaging service and the run queues
///    exist: the supervisor, the verifier, the check runner, and the
///    `complete_goal` and `goal_status` tools.
/// 3. [attachWakeQueue], right after the wake queue is built: the
///    supervisor's admission guard, settled-wake handler and dispatch wrap.
///
/// The sweep starts with the boot recovery ([GoalSupervisor.start]).
class ServerGoals {
  /// Step 1.
  ServerGoals({
    required this.goals,
    required ConversationRepository conversations,
    required WorkspaceFilesystemPort filesystem,
    required TodoRepository todos,
  }) : _filesystem = filesystem,
       _todos = todos,
       fingerprints = WorktreeFingerprints(
         conversations: conversations,
         filesystem: filesystem,
       ),
       turnTexts = GoalTurnTexts(
         goals: goals,
         changes: GoalChanges(
           conversations: conversations,
           filesystem: filesystem,
           todos: todos,
         ),
         now: DateTime.now,
       );

  /// The goal rows.
  final AgentGoalRunRepository goals;

  /// The worktree fingerprints (progress, unchanged-workspace checks).
  final WorktreeFingerprints fingerprints;

  /// What a wake-started run's per-turn prompt says about a goal.
  final GoalTurnTexts turnTexts;

  /// Each run's tool calls, from its stream's end to its settlement.
  final RunToolActivity toolActivity = RunToolActivity();

  final WorkspaceFilesystemPort _filesystem;
  final TodoRepository _todos;

  GoalSupervisor? _supervisor;

  /// The supervisor, once [buildSupervisor] ran.
  GoalSupervisor get supervisor =>
      _supervisor ?? (throw StateError('The goal supervisor is not built'));

  /// Step 2: builds the supervisor and registers the goal tools on
  /// [mcpRegistry].
  GoalSupervisor buildSupervisor({
    required WorkspaceDatabaseManager workspaceDbs,
    required WakeRepository wakes,
    required ServerRunQueues runQueues,
    required MessagingService messagingService,
    required AgentRepository agents,
    required AgentRunLogRepository runLogs,
    required DaoTicketRepository tickets,
    required McpToolRegistry mcpRegistry,
    required DomainEventBus eventBus,
    required HostExecutionGate hostExecution,
    required SandboxManager? sandboxManager,
    required Future<List<String>> Function(String workspaceId) protectedPaths,
    required ActionGuardService? actionGuard,
    required LateEnvironmentPort environments,
  }) {
    final store = GoalStore(
      goals: goals,
      wakes: wakes,
      wakeQueue: () => runQueues.wakeQueue,
      // The take-over refusal's shape: sender and type `system`.
      say:
          ({
            required workspaceId,
            required spaceId,
            required content,
            conversationId,
          }) => messagingService.postSystemMessage(
            workspaceId,
            spaceId,
            content,
            conversationId: conversationId,
          ),
      eventBus: eventBus,
      now: DateTime.now,
      startRefs: turnTexts.changes.startRefs,
    );
    runQueues.bindGoalSteering(store, goals);
    final progress = GoalProgressObserver(
      fingerprints: fingerprints,
      todos: _todos,
      activity: toolActivity,
      mcpClassesOf: (name) =>
          mcpRegistry.lookup(name, view: McpToolView.shared)?.actionClasses,
    );
    final verifier = GoalVerifier(
      store: store,
      runChecks:
          ({
            required workspaceId,
            required spaceId,
            required conversationId,
            required agentId,
            required contract,
          }) =>
              GoalCheckRunner(
                gate: hostExecution,
                sandboxManager: sandboxManager,
                filesystem: _filesystem,
                fingerprints: fingerprints,
                environments: environments.target,
                protectedPaths: protectedPaths,
                actionGuard: actionGuard,
              ).run(
                workspaceId: workspaceId,
                spaceId: spaceId,
                conversationId: conversationId,
                agentId: agentId,
                contract: contract,
              ),
      fingerprintOf: progress.fingerprintOf,
      spaceCheckerOf: DaoSpaceCheckerRepository(workspaceDbs).checkerOf,
      agents: agents,
      runLogs: runLogs,
    );
    final supervisor = GoalSupervisor(
      store: store,
      verifier: verifier,
      progress: progress,
      owedWork: GoalOwedWork(
        wakes: wakes,
        rules: DaoWakeRuleRepository(workspaceDbs),
        asks: DaoPeerAskRepository(workspaceDbs),
        openDelegations: tickets.openDelegatedFrom,
      ),
      agents: agents,
      runLogs: runLogs,
      todos: _todos,
      hasLiveRun: (workspaceId, conversationId, agentId) =>
          ServerRunQueues.agentHasLiveRun(
            runLogs,
            workspaceId,
            conversationId,
            agentId,
          ),
      eventBus: eventBus,
    );
    mcpRegistry
      ..register(CompleteGoalTool(supervisionPort: supervisor))
      ..register(GoalStatusTool(supervisionPort: supervisor, wakes: wakes));
    return _supervisor = supervisor;
  }

  /// Step 3: every goal wake passes the supervisor's guard, every settled
  /// wake reaches its handler, and every wake-started run's dispatch goes
  /// through it.
  void attachWakeQueue(ServerRunQueues runQueues, WakeQueueService queue) {
    final goals = supervisor;
    queue
      ..registerGuard(goals)
      ..registerSettledHandler(goals.onWakeSettled);
    runQueues.dispatchThrough = goals.dispatchWakeRun;
    // A person removed from the workspace: their goals pause first.
    runQueues.personRemovalOrNull?.pauseGoals = goals.pauseForRemovedPerson;
  }
}
