import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/context.dart'
    show ToolCallForms, plainToolForm;
import 'package:cc_harness/loop.dart' show SteeringQueue;
import 'package:cc_infra/src/dispatch/peer_ask_service.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/dispatch/wake_queue_service.dart';

import 'fake_wake_repository.dart';

/// An in-memory [PeerAskRepository] with the stored one's semantics: one map
/// per workspace (a foreign id is not found) and every marker conditional
/// on a `pending` ask.
class InMemoryPeerAskRepository implements PeerAskRepository {
  final Map<String, Map<String, PeerAsk>> _byWs = {};
  final _changes = StreamController<void>.broadcast();

  Map<String, PeerAsk> _ws(String workspaceId) =>
      _byWs.putIfAbsent(workspaceId, () => {});

  /// Every ask of [workspaceId].
  List<PeerAsk> all(String workspaceId) => _ws(workspaceId).values.toList();

  bool _replace(String ws, String id, PeerAsk? Function(PeerAsk ask) change) {
    final ask = _ws(ws)[id];
    if (ask == null || ask.status != PeerAskStatus.pending) {
      return false;
    }
    final next = change(ask);
    if (next == null) {
      return false;
    }
    _ws(ws)[id] = next;
    _changes.add(null);
    return true;
  }

  /// Seeds [ask] past the limits (test setup).
  Future<void> insert(PeerAsk ask) async {
    if (_ws(ask.workspaceId).containsKey(ask.id)) {
      throw StateError('ask ${ask.id} exists');
    }
    _ws(ask.workspaceId)[ask.id] = ask;
    _changes.add(null);
  }

  @override
  Future<PeerAskLimitHit?> insertWithinLimits(
    PeerAsk ask, {
    required PeerAskInsertLimits limits,
  }) async {
    // No await between the checks and the write: one step, as the stored
    // repository's transaction is.
    final ws = ask.workspaceId;
    final pending = _pending(ws);
    for (final a in pending.reversed) {
      if (a.askerAgentId == ask.askerAgentId &&
          a.recipientAgentId == ask.recipientAgentId &&
          a.questionHash == ask.questionHash &&
          !a.createdAt.isBefore(limits.duplicateSince)) {
        return PeerAskLimitHit(PeerAskLimit.duplicate, duplicateAskId: a.id);
      }
    }
    if (pending.where((a) => a.askerAgentId == ask.askerAgentId).length >=
        limits.perAsker) {
      return PeerAskLimitHit(PeerAskLimit.asker);
    }
    if (pending
            .where((a) => a.recipientAgentId == ask.recipientAgentId)
            .length >=
        limits.perRecipient) {
      return PeerAskLimitHit(PeerAskLimit.recipient);
    }
    await insert(ask);
    return null;
  }

  @override
  Future<bool> setDispatched(
    String workspaceId, {
    required String id,
    required String dispatchedRunId,
    String? recipientConversationId,
    String? recipientSpaceId,
    String? questionMessageId,
  }) async => _replace(
    workspaceId,
    id,
    (a) => a.copyWith(
      dispatchedRunId: dispatchedRunId,
      recipientConversationId: recipientConversationId,
      recipientSpaceId: recipientSpaceId,
      questionMessageId: questionMessageId,
    ),
  );

  @override
  Future<PeerAsk?> getById(String workspaceId, String id) async =>
      _ws(workspaceId)[id];

  @override
  Future<PeerAsk?> getByDispatchedRun(String workspaceId, String runId) async {
    for (final ask in _ws(workspaceId).values) {
      if (ask.dispatchedRunId == runId) {
        return ask;
      }
    }
    return null;
  }

  List<PeerAsk> _pending(String ws) => [
    for (final a in _ws(ws).values)
      if (a.status == PeerAskStatus.pending) a,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<PeerAsk>> listPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
    String? askerConversationId,
  }) async => [
    for (final a in _pending(workspaceId))
      if ((askerAgentId == null || a.askerAgentId == askerAgentId) &&
          (recipientAgentId == null ||
              a.recipientAgentId == recipientAgentId) &&
          (askerConversationId == null ||
              a.askerConversationId == askerConversationId))
        a,
  ];

  @override
  Future<int> countPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
  }) async => (await listPending(
    workspaceId,
    askerAgentId: askerAgentId,
    recipientAgentId: recipientAgentId,
  )).length;

  @override
  Future<PeerAsk?> findPendingDuplicate(
    String workspaceId, {
    required String askerAgentId,
    required String recipientAgentId,
    required String questionHash,
    required DateTime since,
  }) async {
    for (final a in _pending(workspaceId)) {
      if (a.askerAgentId == askerAgentId &&
          a.recipientAgentId == recipientAgentId &&
          a.questionHash == questionHash &&
          !a.createdAt.isBefore(since)) {
        return a;
      }
    }
    return null;
  }

  @override
  Future<bool> settle(
    String workspaceId, {
    required String id,
    required PeerAskStatus status,
    String? replyMessageId,
    String? error,
    bool? replyInline,
    required DateTime now,
  }) async => _replace(
    workspaceId,
    id,
    (a) => a.copyWith(
      status: status,
      replyMessageId: replyMessageId,
      error: error,
      replyInline: replyInline,
      settledAt: now,
    ),
  );

  @override
  Future<bool> markPromised(
    String workspaceId, {
    required String id,
    required DateTime now,
  }) async => _replace(
    workspaceId,
    id,
    (a) => a.promisedAt != null ? null : a.copyWith(promisedAt: now),
  );

  @override
  Future<bool> markBlockedNoticed(
    String workspaceId, {
    required String id,
    required DateTime now,
  }) async => _replace(
    workspaceId,
    id,
    (a) =>
        a.blockedNoticedAt != null ? null : a.copyWith(blockedNoticedAt: now),
  );

  @override
  Future<bool> markStallNoticed(
    String workspaceId, {
    required String id,
    required String runId,
  }) async => _replace(
    workspaceId,
    id,
    (a) => a.stallNoticedRunId != null
        ? null
        : a.copyWith(stallNoticedRunId: runId),
  );

  @override
  Future<List<PeerAsk>> listPendingForRecipientConversation(
    String workspaceId, {
    required String recipientAgentId,
    required String recipientConversationId,
  }) async => [
    for (final a in _pending(workspaceId))
      if (a.recipientAgentId == recipientAgentId &&
          a.recipientConversationId == recipientConversationId)
        a,
  ];

  @override
  Future<List<PeerAsk>> listExpired(
    String workspaceId, {
    required DateTime now,
  }) async => [
    for (final a in _pending(workspaceId))
      if (!a.expiresAt.isAfter(now)) a,
  ];

  @override
  Stream<List<PeerAsk>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) async* {
    List<PeerAsk> rows() => [
      for (final a in _ws(workspaceId).values)
        if (a.askerConversationId == conversationId) a,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield rows();
    await for (final _ in _changes.stream) {
      yield rows();
    }
  }

  @override
  Future<int> deleteSettledBefore(
    String workspaceId, {
    required DateTime cutoff,
  }) async {
    final gone = [
      for (final a in _ws(workspaceId).values)
        if (a.settledAt?.isBefore(cutoff) ?? false) a.id,
    ];
    gone.forEach(_ws(workspaceId).remove);
    return gone.length;
  }

  @override
  Future<List<String>> workspacesWithPendingAsks() async => [
    for (final ws in _byWs.keys)
      if (_pending(ws).isNotEmpty) ws,
  ];
}

class _NoTimer implements Timer {
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

/// A live run a test holds open in a conversation.
class KitSession implements SteeringSessionView {
  /// Creates a session.
  KitSession({
    required this.agentId,
    required this.conversationId,
    required this.runLogId,
    this.workspaceId = PeerKit.ws,
    this.spaceId = 'sp-1',
    this.requestedByUserId,
    this.readOnly = false,
  });

  @override
  final String? workspaceId;
  @override
  final String? agentId;
  @override
  final String? conversationId;
  @override
  final String? spaceId;
  @override
  final String? runLogId;
  @override
  final String? requestedByUserId;
  @override
  final bool readOnly;
  @override
  bool get freshHistory => false;
  @override
  bool get acceptsSteering => true;
  @override
  final SteeringQueue steeringQueue = SteeringQueue();

  @override
  ToolCallForms toolForms = plainToolForm;
}

class _Agents implements AgentRepository {
  _Agents(this.byId);
  final Map<String, Agent> byId;

  @override
  Future<Agent?> getById(String workspaceId, String id) async {
    final agent = byId[id];
    return agent?.workspaceId == workspaceId ? agent : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RunLogs implements AgentRunLogRepository {
  _RunLogs(this.byId);
  final Map<String, AgentRunLog> byId;

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    final run = byId[id];
    return run?.workspaceId == workspaceId ? run : null;
  }

  @override
  Future<AgentRunLog?> latestForTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final runs = [
      for (final r in byId.values)
        if (r.workspaceId == workspaceId && r.ticketId == ticketId) r,
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return runs.lastOrNull;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messages implements MessagingRepository {
  _Messages(this.byId);
  final Map<String, Message> byId;

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async =>
      byId[messageId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations implements ConversationRepository {
  _Conversations(this.byId);
  final Map<String, Conversation> byId;

  @override
  Future<Conversation?> getById({
    required String workspaceId,
    required String conversationId,
  }) async {
    final c = byId[conversationId];
    return c?.workspaceId == workspaceId ? c : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A real [WakeQueueService] and [PeerAskService] over in-memory rows: runs
/// start when the queue dispatches (`run-1`, `run-2`, …) and end when a test
/// calls [finish].
class PeerKit {
  /// Builds the kit at [now]. [store] replaces the in-memory [asks] as the
  /// service's repository (a test on the stored one).
  PeerKit({DateTime? now, PeerAskRepository? store})
    : now = now ?? DateTime.utc(2026, 11, 19, 14) {
    queue = WakeQueueService(
      wakes: wakes,
      runLedger: ledger,
      eventBus: bus,
      clock: () => this.now,
      timerFactory: (delay, fire) => _NoTimer(),
      nonce: () => 'nonce1',
      newId: () => 'gen-${_ids++}',
      ports: WakeQueuePorts(
        workspaceActive: (ws) async => ws == PeerKit.ws || ws == PeerKit.other,
        conversationSpace: (ws, conv) async {
          final c = conversations[conv];
          return c?.workspaceId == ws ? c?.spaceId : null;
        },
        agent: (ws, id) async {
          final a = agents[id];
          return a?.workspaceId == ws ? a : null;
        },
        isMember: (ws, user) async => true,
        takenOver: (ws, space) async => false,
        budgetBlocked: (ws, agentId) async => false,
        liveSessions: (conv) => [
          for (final s in sessions)
            if (s.conversationId == conv) s,
        ],
        hasLiveRun: (ws, conv, agentId) async => sessions.any(
          (s) =>
              s.workspaceId == ws &&
              s.conversationId == conv &&
              s.agentId == agentId,
        ),
        dispatch: (run) async {
          dispatched.add(run);
          onDispatch?.call(run);
          final id = 'run-${dispatched.length}';
          runs[id] = AgentRunLog(
            id: id,
            agentId: run.agentId,
            workspaceId: run.workspaceId,
            spaceId: run.spaceId,
            conversationId: run.conversationId,
            startedAt: this.now,
            status: RunStatus.running,
            requestedByUserId: run.requestedByUserId,
            wakeReason: run.wakeContext.wakeReason,
          );
          return id;
        },
        postSystemRow:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String content,
              required Map<String, Object?> metadata,
            }) async => systemRows.add(content),
      ),
    );
    service = PeerAskService(
      asks: store ?? asks,
      wakes: wakes,
      runLogs: runLogRepository,
      messages: messageRepository,
      agents: agentRepository,
      conversations: conversationRepository,
      runSetWake:
          (
            ws, {
            required conversationId,
            required agentId,
            required runId,
          }) async => wakeRuleSet,
      queue: () => queue,
      eventBus: bus,
      clock: () => this.now,
      newId: () => 'ask-${++_asks}',
    );
  }

  /// The main workspace.
  static const String ws = 'ws-1';

  /// A second workspace.
  static const String other = 'ws-2';

  /// The clock.
  DateTime now;
  int _ids = 0;
  int _asks = 0;

  /// The asks.
  final asks = InMemoryPeerAskRepository();

  /// The wakes.
  final wakes = FakeWakeRepository();

  /// The ledger.
  final ledger = FakeWakeRunLedger();

  /// The bus.
  final bus = DomainEventBus();

  /// Agents by id.
  final Map<String, Agent> agents = {};

  /// Conversations by id.
  final Map<String, Conversation> conversations = {};

  /// Run rows by id.
  final Map<String, AgentRunLog> runs = {};

  /// Messages by id (a run's final message has the run's id).
  final Map<String, Message> messages = {};

  /// Live sessions.
  final List<KitSession> sessions = [];

  /// Runs the queue started.
  final List<WakeDispatchRequest> dispatched = [];

  /// System rows posted.
  final List<String> systemRows = [];

  /// Called with every run the queue starts.
  void Function(WakeDispatchRequest run)? onDispatch;

  /// Whether the answering run set an active `wake_me` rule.
  bool wakeRuleSet = false;

  /// The queue.
  late final WakeQueueService queue;

  /// The service.
  late final PeerAskService service;

  /// Agent repository over [agents].
  late final AgentRepository agentRepository = _Agents(agents);

  /// Run repository over [runs].
  late final AgentRunLogRepository runLogRepository = _RunLogs(runs);

  /// Message repository over [messages].
  late final MessagingRepository messageRepository = _Messages(messages);

  /// Conversation repository over [conversations].
  late final ConversationRepository conversationRepository = _Conversations(
    conversations,
  );

  /// Adds agent [id] named [name] to [workspaceId].
  Agent agent(String id, String name, {String workspaceId = ws}) =>
      agents[id] = Agent(
        id: id,
        name: name,
        title: 'Engineer',
        agentMdPath: '$workspaceId/agents/$name/AGENTS.md',
        workspaceId: workspaceId,
        skills: AgentSkills(const []),
        createdAt: DateTime.utc(2026),
      );

  /// Adds conversation [id] in space [spaceId].
  Conversation conversation(
    String id, {
    String spaceId = 'sp-1',
    String workspaceId = ws,
  }) => conversations[id] = Conversation(
    id: id,
    workspaceId: workspaceId,
    spaceId: spaceId,
    title: id,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  /// A run row of [agentId] in [conversationId], acting for [requester].
  AgentRunLog run(
    String id, {
    required String agentId,
    required String conversationId,
    String? requester,
    String workspaceId = ws,
  }) => runs[id] = AgentRunLog(
    id: id,
    agentId: agentId,
    workspaceId: workspaceId,
    spaceId: conversations[conversationId]?.spaceId ?? 'sp-1',
    conversationId: conversationId,
    startedAt: now,
    status: RunStatus.running,
    requestedByUserId: requester,
  );

  /// Starts the queue (nothing is delivered before).
  Future<void> start() async {
    service.attachQueue(queue);
    await queue.start();
  }

  /// Moves the clock past the queue's quiet window and runs a sweep, so a
  /// wake inserted with `enqueue` is delivered.
  Future<void> deliver() async {
    now = now.add(WakeQueueService.quietWindow + const Duration(seconds: 1));
    await queue.tick();
    await pump();
  }

  /// Lets every listener run.
  Future<void> pump() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Ends run [runId] with [answer] as its final message.
  Future<void> finish(
    String runId, {
    String answer = '',
    RunEndReason endReason = RunEndReason.completed,
    DateTime? limitResetsAt,
    String? summary,
  }) async {
    final run = runs[runId]!;
    final status = switch (endReason) {
      RunEndReason.completed => RunStatus.completed,
      _ => RunStatus.error,
    };
    final wakeIds = [
      for (final w in wakes.all(run.workspaceId!))
        if (w.deliveredRunId == runId && w.state == WakeState.delivered) w.id,
    ];
    runs[runId] = AgentRunLog(
      id: runId,
      agentId: run.agentId,
      workspaceId: run.workspaceId,
      spaceId: run.spaceId,
      conversationId: run.conversationId,
      startedAt: run.startedAt,
      completedAt: now,
      status: status,
      endReason: endReason,
      summary: summary,
      wakeIds: wakeIds,
      requestedByUserId: run.requestedByUserId,
      wakeReason: run.wakeReason,
    );
    messages[runId] = Message(
      id: runId,
      spaceId: run.spaceId ?? 'sp-1',
      conversationId: run.conversationId!,
      senderId: run.agentId,
      senderType: SenderType.agent,
      content: answer,
      messageType: MessageType.text,
      createdAt: now,
    );
    sessions.removeWhere((s) => s.runLogId == runId);
    bus.publish(
      AgentRunSettled(
        agentId: run.agentId,
        workspaceId: run.workspaceId!,
        spaceId: run.spaceId,
        conversationId: run.conversationId,
        runId: runId,
        status: status,
        endReason: endReason,
        costMicros: 0,
        limitResetsAt: limitResetsAt,
        wakeIds: wakeIds,
        requestedByUserId: run.requestedByUserId,
        wakeReason: run.wakeReason,
        occurredAt: now,
      ),
    );
    await pump();
  }
}
