import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/run_credential_gate_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart'
    show WakeStateReasons;
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_host/cc_host.dart'
    show PendingCredentialBlockRegistry, RemoteRunCredentialGate;
import 'package:cc_infra/cc_infra.dart'
    show
        GoalStore,
        LimitParkCredentialGate,
        LimitParkRowStamp,
        LimitParkService,
        MessagingService,
        PersonRemovalService,
        SandboxedAgentDispatchAdapter,
        SteeringQueueService,
        SteeringSessionView,
        SteeringWriterName,
        WakeDispatchRequest,
        WakeQueuePorts,
        WakeQueueService,
        WakeRunDispatcher,
        kRunStoppedPersonRemovedSummary;
import 'package:cc_persistence/cc_persistence.dart'
    show
        DaoAgentRunLogRepository,
        DaoMessagingRepository,
        WorkspaceRegistryDao;
import 'package:uuid/uuid.dart';

/// The run queues of the server: the durable steering queue (a person's
/// messages to a live run) and the wake queue (every run the server starts
/// without a person typing), wired to the messaging and dispatch layers.
///
/// Built in two steps because the wake queue's admission needs services the
/// runtime constructs late (the budget enforcement), while the steering
/// queue and the late-bound hooks it shares with the wake queue must exist
/// as soon as the messaging service does: [wireSteering] first,
/// [buildWakeQueue] just before boot recovery (its settlement subscription
/// must hear the reaper).
class ServerRunQueues {
  WakeQueueService? _wakes;
  AgentRepository? _agents;
  LimitParkService? _limitParks;
  SteeringQueueService? _steering;
  WorkspaceRegistryDao? _workspaces;

  /// The park at a provider's usage limit (a person's run, the credential
  /// park's durable record), or null before [buildWakeQueue] ran.
  LimitParkService? get limitParksOrNull => _limitParks;

  /// The credential gate over [registry] (runs parked on a credential that
  /// cannot serve them), with the durable record of a park at a provider's
  /// usage limit ([LimitParkCredentialGate]); the record is written once
  /// the wake queue is built.
  RunCredentialGatePort limitParkGate(
    PendingCredentialBlockRegistry registry,
    AgentRunLogRepository runLogs,
  ) => LimitParkCredentialGate(
    RemoteRunCredentialGate(registry),
    parks: () => _limitParks,
    runLogs: runLogs,
  );

  /// Wraps every wake-started run's dispatch when set (the goal supervisor:
  /// it caps a goal's segment and attaches it to the goal); it calls the
  /// plain dispatch it is handed.
  Future<String?> Function(WakeDispatchRequest run, WakeRunDispatcher plain)?
  dispatchThrough;

  /// The wake queue, once [buildWakeQueue] ran.
  WakeQueueService get wakeQueue =>
      _wakes ?? (throw StateError('The wake queue is not built yet'));

  /// The wake queue, or null before [buildWakeQueue] ran.
  WakeQueueService? get wakeQueueOrNull => _wakes;

  static const _uuid = Uuid();

  /// Builds the steering queue (constructed AFTER the messaging and dispatch
  /// services: its lifecycle hooks are late-bound fields on them), and binds
  /// the hooks both queues share: harness starts reach the steering queue
  /// first (it owns the drain callback the wake queue chains), then the wake
  /// queue; a finished turn's `@mentions` become wakes.
  SteeringQueueService wireSteering({
    required DaoMessagingRepository messagingRepository,
    required AgentRunLogRepository runLogRepository,
    required MessagingService messagingService,
    required SandboxedAgentDispatchAdapter agentDispatch,
    required DomainEventBus eventBus,
    required SteeringWriterName writerName,
  }) {
    final steering = SteeringQueueService(
      messagingRepository: messagingRepository,
      runLogRepository: runLogRepository,
      dispatchResponder: messagingService.dispatchResponderForText,
      sessionsForConversation: agentDispatch.sessionsForConversation,
      // Run endings arrive as `AgentRunSettled`: a person's stop holds the
      // queue, every other end converts it.
      eventBus: eventBus,
      // Names another person's card to the run it steers.
      writerName: writerName,
      // Queue edits and run-start replay only need the queued cards.
      queuedSteering: messagingRepository.queuedSteeringMessages,
      resolveAttachmentPaths: messagingService.withAttachmentPaths,
      // Every queue write is a state-conditional merge onto the current row.
      patchSteering: messagingRepository.patchSteering,
      // A run-end send that failed is said in the conversation, not just
      // logged.
      postNotice:
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String text,
          }) => messagingRepository
              .sendMessage(
                workspaceId: workspaceId,
                spaceId: spaceId,
                conversationId: conversationId,
                content: text,
                senderId: 'system',
                senderType: 'system',
                messageType: 'system',
              )
              .then((_) {}),
    );
    messagingService.steeringQueueService = steering;
    _steering = steering;
    agentDispatch.onSessionHarnessStarted = (SteeringSessionView session) {
      steering.handleHarnessStarted(session);
      _wakes?.handleHarnessStarted(session);
    };
    messagingService.mentionWakes.sink = (wake) => wakeQueue.enqueue(wake);
    return steering;
  }

  /// Builds the wake queue. Subscribes to `AgentRunSettled` at once; call
  /// [WakeQueueService.start] after the boot reaper. [runLogs] is also its
  /// run ledger (`agent_run_logs.wake_ids`).
  WakeQueueService buildWakeQueue({
    required WakeRepository wakes,
    required ConversationRepository conversations,
    required DomainEventBus eventBus,
    required AgentRepository agents,
    required DaoAgentRunLogRepository runLogs,
    required DaoMessagingRepository messagingRepository,
    required MessagingService messagingService,
    required SandboxedAgentDispatchAdapter agentDispatch,
    required WorkspaceRegistryDao workspaces,
    required Future<bool> Function(String workspaceId, String userId) isMember,
    required Future<bool> Function(String workspaceId, String spaceId)
    takenOver,
    required Future<bool> Function(String workspaceId, String agentId)
    budgetBlocked,
  }) {
    // The plain agent dispatch with the wakes' context: the run's turn
    // input is the server's sentence, never stored as a message.
    Future<String?> plain(WakeDispatchRequest run) =>
        messagingService.dispatchAgentRun(
          workspaceId: run.workspaceId,
          spaceId: run.spaceId,
          agentId: run.agentId,
          prompt: run.prompt,
          conversationId: run.conversationId,
          wakeContext: run.wakeContext,
          requestedByUserId: run.requestedByUserId,
          mentionChain: run.mentionChain,
          inReplyToAgentId: run.inReplyToAgentId,
          costCapMicros: run.costCapMicros,
          expectedOutputSchema: run.expectedOutputSchema,
          freshHistory: run.freshHistory,
          readOnly: run.readOnly,
        );
    final queue = WakeQueueService(
      wakes: wakes,
      runLedger: runLogs,
      eventBus: eventBus,
      newId: _uuid.v4,
      ports: WakeQueuePorts(
        workspaceActive: (id) async => await workspaces.getById(id) != null,
        conversationSpace: (workspaceId, conversationId) async {
          final conversation = await conversations.getById(
            workspaceId: workspaceId,
            conversationId: conversationId,
          );
          return conversation?.workspaceId == workspaceId
              ? conversation!.spaceId
              : null;
        },
        agent: agents.getById,
        isMember: isMember,
        takenOver: takenOver,
        budgetBlocked: budgetBlocked,
        liveSessions: agentDispatch.sessionsForConversation,
        hasLiveRun: (workspaceId, conversationId, agentId) =>
            agentHasLiveRun(runLogs, workspaceId, conversationId, agentId),
        dispatch: (run) {
          final through = dispatchThrough;
          return through == null ? plain(run) : through(run, plain);
        },
        postSystemRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) => messagingRepository
                .sendMessage(
                  workspaceId: workspaceId,
                  spaceId: spaceId,
                  conversationId: conversationId,
                  content: content,
                  senderId: 'system',
                  senderType: 'system',
                  messageType: 'system',
                  metadata: metadata,
                )
                .then((_) {}),
      ),
    );
    // A pushed wake's chain extends the live run's mention chain.
    queue.chainCarried = messagingService.mentionWakes.carryChain;
    _wakes = queue;
    _agents = agents;
    // A person's run parked at its provider's usage limit: a held wake and
    // a "Resumes at …" row; the guard of the credential park's wake.
    _limitParks = LimitParkService(
      wakes: wakes,
      queue: queue,
      runLogs: runLogs,
      eventBus: eventBus,
      postRow:
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String content,
            required Map<String, Object?> metadata,
          }) => messagingRepository.sendMessage(
            workspaceId: workspaceId,
            spaceId: spaceId,
            conversationId: conversationId,
            content: content,
            senderId: 'system',
            senderType: 'system',
            messageType: 'system',
            metadata: metadata,
          ),
      // A park's resume releases its person's cards into the resumed run.
      releaseCards:
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String heldBy,
            required String senderId,
          }) async =>
              await _steering?.releaseHeldBy(
                workspaceId: workspaceId,
                spaceId: spaceId,
                conversationId: conversationId,
                heldBy: heldBy,
                senderId: senderId,
              ) ??
              0,
      // The cards held at a run's limit: the pause's while one waits, else
      // a Stop's, unsent ([LimitParkService.reconcileCards]).
      holdCards:
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String runId,
            required String heldBy,
            required DateTime? resetsAt,
            required String? pausePerson,
          }) async =>
              await _steering?.holdRunCards(
                workspaceId: workspaceId,
                spaceId: spaceId,
                conversationId: conversationId,
                runId: runId,
                heldBy: heldBy,
                resetsAt: resetsAt,
                pausePerson: pausePerson,
              ) ??
              0,
      heldCards: messagingRepository.heldSteeringMessages,
      openParkRows: messagingRepository.openLimitParkRows,
      stampRow: LimitParkRowStamp(messagingRepository).call,
    )..start();
    _steering?.limitHoldReconciler = _limitParks!.reconcileCards;
    _workspaces = workspaces;
    _personRemoval = PersonRemovalService(
      eventBus: eventBus,
      isMember: isMember,
      cancelWakes: (workspaceId, userId) => queue.cancelWhere(
        workspaceId,
        requestedByUserId: userId,
        reason: WakeStateReasons.personRemoved,
      ),
      liveRuns: (workspaceId) =>
          runLogs.watchNonTerminalForWorkspace(workspaceId).first,
      stopRun: (workspaceId, runId) => agentDispatch.stopRunAsServer(
        workspaceId,
        runId,
        summary: kRunStoppedPersonRemovedSummary,
      ),
      cardsOf: messagingRepository.openSteeringMessagesOf,
      deleteCard: (workspaceId, card) async =>
          await _steering?.delete(
            workspaceId: workspaceId,
            conversationId: card.conversationId,
            messageId: card.id,
          ) ??
          false,
    );
    return queue;
  }

  /// What a person's removal from a workspace does to their waiting work
  /// (their goals are bound by the goal side), or null before
  /// [buildWakeQueue] ran.
  PersonRemovalService? get personRemovalOrNull => _personRemoval;
  PersonRemovalService? _personRemoval;

  /// Whether [agentId] has a live top-level run in [conversationId] (not a
  /// subagent's).
  static Future<bool> agentHasLiveRun(
    AgentRunLogRepository runLogs,
    String workspaceId,
    String conversationId,
    String agentId,
  ) async {
    final active = await runLogs.activeByConversation(
      workspaceId,
      conversationId,
    );
    return active.any(
      (run) =>
          run.agentId == agentId &&
          run.role != AgentRunRole.sub &&
          run.parentRunId == null,
    );
  }

  /// Asks a space's checker to review a settled run: a `peerMessage` wake
  /// whose source is that run. The run that settled is the checker's
  /// subject, so the dedup key is the run: one review per run.
  Future<void> wakeChecker({
    required String spaceId,
    required String? conversationId,
    required String agentId,
    required String prompt,
    required String workspaceId,
    required String sourceAgentId,
    required String sourceRunId,
  }) async {
    if (conversationId == null) {
      return;
    }
    final now = DateTime.now();
    final source = await _agents?.getById(workspaceId, sourceAgentId);
    await wakeQueue.enqueue(
      Wake(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        agentId: agentId,
        reason: WakeReason.peerMessage,
        payload: prompt,
        detail: WakeDetail(
          sourceAgentId: sourceAgentId,
          sourceRunId: sourceRunId,
          sourceConversationId: conversationId,
          fields: {
            WakeFields.via: WakeFields.viaChecker,
            WakeFields.sourceAgentName: ?source?.name,
          },
        ),
        dedupKey: 'checker:$sourceRunId:$agentId',
        notBefore: now,
        chain: [sourceAgentId],
        createdAt: now,
      ),
    );
  }

  /// Shutdown, before agent runs are stopped: the wake queue delivers
  /// nothing from now on ([WakeQueueService.beginStopping]).
  void beginStopping() => _wakes?.beginStopping();

  /// Whether shutdown began ([beginStopping]).
  bool get stopping => _wakes?.stopping ?? false;

  /// Binds the steering queue to the goals [store] writes: a goal leaving
  /// `active` holds the cards its review kept queued, as a Stop's; a
  /// goal review's end asks [goals] whether the conversation's goal goes on
  /// (else the same hold). Both act after their own write, so the order of
  /// the review's end and the goal's move does not matter.
  void bindGoalSteering(GoalStore store, AgentGoalRunRepository goals) {
    final steering = _steering;
    if (steering == null) {
      return;
    }
    store.onLeftActive = (g) async {
      await steering.holdKeptCards(g.workspaceId, g.spaceId, g.conversationId);
    };
    steering.goalContinues = (ws, conversationId) async =>
        (await goals.listByWorkspace(ws)).any(
          (g) =>
              g.conversationId == conversationId &&
              g.status == AgentGoalStatus.active,
        );
  }

  /// Boot, after the reaper: repairs what a lost settlement left (cards
  /// held at a run's limit, park rows with no outcome;
  /// [LimitParkService.sweepAtBoot]), then starts the wake queue, so no
  /// delivery is in flight while the sweep decides.
  Future<void> startWakeQueue() async {
    final parks = _limitParks;
    final workspaces = _workspaces;
    if (parks == null || workspaces == null) {
      return wakeQueue.start();
    }
    // CROSS-WORKSPACE BY DESIGN: a boot repair, once, before the wake queue
    // starts; each workspace is read and written in its own database.
    await parks.startQueueAfterSweep(workspaces.liveIds);
  }

  /// Stops the wake queue (shutdown).
  Future<void> stop() async {
    await _personRemoval?.dispose();
    await _wakes?.stop();
  }
}
