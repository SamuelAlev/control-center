import 'package:cc_domain/cc_domain.dart' show SteeringNotYoursException;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/steering_texts.dart';
import 'package:cc_harness/context.dart'
    show ToolCallForms, plainToolForm;
import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/person_removal_service.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/messaging/steering_queue_service.dart';
import 'package:test/test.dart';

/// In-memory [MessagingRepository] covering the steering queue surface.
class _FakeMessagingRepo implements MessagingRepository {
  final List<Message> messages = [];
  final List<Map<String, dynamic>> inserts = [];
  final List<String> deletes = [];
  int idSeq = 0;
  bool scanThrows = false;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async {
    if (scanThrows) {
      throw StateError('full scan');
    }
    return messages
        .where(
          (m) =>
              m.conversationId == (conversationId ?? 'conv') &&
              m.spaceId == spaceId,
        )
        .toList();
  }

  @override
  Future<String> insertSteeringMessage({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String content,
    required String senderId,
    required Map<String, dynamic> metadata,
    String? id,
  }) async {
    final messageId = id ?? 'steer-${idSeq++}';
    inserts.add({
      'workspaceId': workspaceId,
      'spaceId': spaceId,
      'conversationId': conversationId,
      'content': content,
      'senderId': senderId,
      'metadata': metadata,
    });
    messages.add(
      Message(
        id: messageId,
        spaceId: spaceId,
        conversationId: conversationId,
        senderId: senderId,
        senderType: SenderType.user,
        content: content,
        messageType: MessageType.steering,
        metadata: metadata,
        createdAt: DateTime.utc(2026, 1, 1, 0, idSeq),
      ),
    );
    return messageId;
  }

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? messageType,
    String? idempotencyKey,
  }) async {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) {
      return;
    }
    final old = messages[index];
    messages[index] = Message(
      id: old.id,
      spaceId: old.spaceId,
      conversationId: old.conversationId,
      senderId: old.senderId,
      senderType: old.senderType,
      content: content ?? old.content,
      messageType: switch (messageType) {
        'steering' => MessageType.steering,
        'text' => MessageType.text,
        null => old.messageType,
        _ => old.messageType,
      },
      metadata: metadata ?? old.metadata,
      compacted: old.compacted,
      reverted: old.reverted,
      revertedAt: old.revertedAt,
      createdAt: old.createdAt,
    );
  }

  @override
  Future<void> deleteSteeringMessage(
    String workspaceId,
    String messageId,
  ) async {
    deletes.add(messageId);
    messages.removeWhere((m) => m.id == messageId);
  }

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) async {
    for (final message in messages) {
      if (message.id == messageId) {
        return message;
      }
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// In-memory [AgentRunLogRepository] answering a fixed active-run roster.
class _FakeRunLogRepo implements AgentRunLogRepository {
  _FakeRunLogRepo(this.active);

  List<AgentRunLog> active;

  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => active.where((r) => r.conversationId == conversationId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// A fake harness session: a real [SteeringQueue] plus the view fields.
class _FakeSession implements SteeringSessionView {
  _FakeSession({
    this.runLogId = 'run-1',
    this.workspaceId = 'ws',
    this.readOnly = false,
    this.freshHistory = false,
    this.requestedByUserId = 'user-1',
  });

  @override
  final String? workspaceId;
  @override
  final String? conversationId = 'conv';
  @override
  final String? agentId = 'agent-1';
  @override
  final String? spaceId = 'space';
  @override
  final String? runLogId;
  @override
  final String? requestedByUserId;
  @override
  final bool readOnly;
  @override
  final bool freshHistory;
  bool harnessActive = true;
  @override
  bool get acceptsSteering => harnessActive;
  @override
  final SteeringQueue steeringQueue = SteeringQueue();

  @override
  ToolCallForms toolForms = plainToolForm;
}

AgentRunLog _activeRun({
  String conversationId = 'conv',
  String spaceId = 'space',
}) => AgentRunLog(
  id: 'run-${_runSeq++}',
  agentId: 'agent-1',
  workspaceId: 'ws',
  conversationId: conversationId,
  spaceId: spaceId,
  startedAt: DateTime.utc(2026, 1, 1),
  status: RunStatus.running,
);

int _runSeq = 0;

// The two cards whose writer a run acting for no one is told about.
const _logs = 'also check the logs';
const _tests = 'look at the tests too';

AgentRunSettled _settled(
  RunEndReason reason, {
  DateTime? limitResetsAt,
  String runId = 'run-ended',
  WakeReason? wakeReason,
}) => AgentRunSettled(
  agentId: 'agent-1',
  workspaceId: 'ws',
  spaceId: 'space',
  conversationId: 'conv',
  runId: runId,
  status: reason == RunEndReason.completed
      ? RunStatus.completed
      : RunStatus.error,
  endReason: reason,
  costMicros: 0,
  limitResetsAt: limitResetsAt,
  wakeIds: const [],
  requestedByUserId: 'user-1',
  wakeReason: wakeReason,
  occurredAt: DateTime.utc(2026, 1, 1),
);

void main() {
  late _FakeMessagingRepo messaging;
  late _FakeRunLogRepo runLogs;
  late List<_FakeSession> sessions;
  List<String> dispatched = [];
  List<MessageAttachment> dispatchedAttachments = [];
  List<String> dispatchedImages = [];
  List<String?> dispatchedFor = [];
  Set<String> dispatchFailsFor = {};
  late SteeringQueueService service;
  late DomainEventBus bus;

  setUp(() {
    bus = DomainEventBus();
    messaging = _FakeMessagingRepo();
    runLogs = _FakeRunLogRepo([_activeRun()]);
    sessions = [];
    dispatched = [];
    dispatchedAttachments = [];
    dispatchedImages = [];
    dispatchedFor = [];
    dispatchFailsFor = {};
    service = SteeringQueueService(
      messagingRepository: messaging,
      runLogRepository: runLogs,
      dispatchResponder:
          ({
            required String workspaceId,
            required String spaceId,
            String? conversationId,
            required String content,
            String? senderUserId,
            List<MessageAttachment> attachments = const [],
            List<String> promptImageRefs = const [],
          }) async {
            if (dispatchFailsFor.contains(senderUserId)) {
              throw StateError('no agent');
            }
            dispatched.add(content);
            dispatchedAttachments.addAll(attachments);
            dispatchedImages.addAll(promptImageRefs);
            dispatchedFor.add(senderUserId);
          },
      sessionsForConversation: (conversationId) => [
        for (final s in sessions)
          if (s.conversationId == conversationId) s,
      ],
      eventBus: bus,
      writerName: (_, id) async => 'Name of $id',
    );
  });

  tearDown(() {
    service.dispose();
    bus.dispose();
  });

  group('enqueue', () {
    test('refuses (null) when no run is active', () async {
      runLogs.active = [];
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      expect(result, isNull);
      expect(messaging.inserts, isEmpty);
    });

    test('stores no card without a writer', () async {
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: ' ',
        writerMayDirect: true,
      );
      expect(result, isNull);
      expect(messaging.inserts, isEmpty);
    });

    test('refuses blank content', () async {
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: '   ',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      expect(result, isNull);
    });

    test(
      'persists a queued row even with no steerable session (CLI run)',
      () async {
        sessions.add(_FakeSession()..harnessActive = false);
        final result = await service.enqueue(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          content: 'nudge',
          senderUserId: 'user-1',
          writerMayDirect: true,
        );
        expect(result, isNotNull);
        expect(
          result!.steerable,
          isFalse,
          reason: 'a CLI transport cannot take mid-run steering',
        );
        expect(
          (messaging.inserts.single['metadata'] as Map)['steerState'],
          'queued',
        );
        expect(
          sessions.single.steeringQueue.isEmpty,
          isTrue,
          reason: 'nothing may be pushed into a queue nobody drains',
        );
      },
    );

    test('pushes into live harness sessions carrying the row ref', () async {
      final session = _FakeSession();
      sessions.add(session);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      expect(result!.steerable, isTrue);
      final lane = session.steeringQueue.peek(SteeringChannel.steering);
      expect(lane.single.content, 'nudge');
      expect(lane.single.ref, result.messageId);
    });
  });

  group('drain flips the row to injected (handleHarnessStarted wiring)', () {
    test('a drained message flips steerState and stamps run + time', () async {
      final session = _FakeSession();
      sessions.add(session);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      // The harness-start wiring (drain notifications) — normally attached by
      // the runtime's onSessionHarnessStarted.
      service.handleHarnessStarted(session);
      session.steeringQueue.drainSteering();
      // The flip is fire-and-forget; let it land.
      await Future<void>.delayed(Duration.zero);
      final row = messaging.messages.singleWhere(
        (m) => m.id == result!.messageId,
      );
      expect(row.steerState, 'injected');
      expect(row.steerRunId, 'run-1');
      expect(row.steerInjectedAt, isNotNull);
    });

    test('is idempotent when two sessions each hold a copy', () async {
      final a = _FakeSession();
      final b = _FakeSession(runLogId: 'run-2');
      sessions.addAll([a, b]);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      service.handleHarnessStarted(a);
      service.handleHarnessStarted(b);
      a.steeringQueue.drainSteering();
      b.steeringQueue.drainSteering();
      await Future<void>.delayed(Duration.zero);
      expect(messaging.messages.single.isSteeringInjected, isTrue);
      expect(messaging.messages.single.steerRunId, anyOf('run-1', 'run-2'));
    });
  });

  group('handleHarnessStarted flush', () {
    test('flushes persisted queued rows into a newly started run', () async {
      // Row queued while only a CLI session was live.
      sessions.add(_FakeSession()..harnessActive = false);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'leftover',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );

      // The CLI run ends; a harness run starts in the same conversation.
      final harness = _FakeSession(runLogId: 'run-next');
      sessions
        ..clear()
        ..add(harness);
      service.handleHarnessStarted(harness);
      await Future<void>.delayed(Duration.zero);
      final lane = harness.steeringQueue.peek(SteeringChannel.steering);
      expect(lane.map((m) => m.ref), [result!.messageId]);
    });

    test('does not double-push a row the run already holds', () async {
      final session = _FakeSession();
      sessions.add(session);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      service.handleHarnessStarted(session);
      await Future<void>.delayed(Duration.zero);
      expect(
        session.steeringQueue.peek(SteeringChannel.steering),
        hasLength(1),
        reason: 'enqueue pushed it; the flush must not duplicate it',
      );
    });
  });

  group('edit / delete', () {
    test('edit rewrites the row and the live queue', () async {
      final session = _FakeSession();
      sessions.add(session);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'old text',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final ok = await service.edit(
        workspaceId: 'ws',
        conversationId: 'conv',
        messageId: result!.messageId,
        content: 'new text',
        callerId: 'user-1',
      );
      expect(ok, isTrue);
      expect(messaging.messages.single.content, 'new text');
      expect(
        session.steeringQueue.peek(SteeringChannel.steering).single.content,
        'new text',
      );
    });

    test('edit refuses an injected row', () async {
      final session = _FakeSession();
      sessions.add(session);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      service.handleHarnessStarted(session);
      session.steeringQueue.drainSteering();
      await Future<void>.delayed(Duration.zero);

      final ok = await service.edit(
        workspaceId: 'ws',
        conversationId: 'conv',
        messageId: result!.messageId,
        content: 'rewrite',
        callerId: 'user-1',
      );
      expect(ok, isFalse);
      expect(messaging.messages.single.content, 'nudge');
    });

    test('delete removes the row and the live queue entry', () async {
      final session = _FakeSession();
      sessions.add(session);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'gone soon',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final ok = await service.delete(
        workspaceId: 'ws',
        conversationId: 'conv',
        messageId: result!.messageId,
      );
      expect(ok, isTrue);
      expect(messaging.messages, isEmpty);
      expect(session.steeringQueue.isEmpty, isTrue);
    });
  });

  group('reorder + deliver', () {
    test('reorder stamps steerOrder and rebuilds the lane', () async {
      final session = _FakeSession();
      sessions.add(session);
      final first = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'first',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final second = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'second',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );

      await service.reorder(
        workspaceId: 'ws',
        conversationId: 'conv',
        orderedIds: [second!.messageId, first!.messageId],
      );
      expect(
        session.steeringQueue
            .peek(SteeringChannel.steering)
            .map((m) => m.content),
        ['second', 'first'],
      );
      final rows = messaging.messages
        ..sort((a, b) => a.steerOrder.compareTo(b.steerOrder));
      expect(rows.map((m) => m.content), ['second', 'first']);
    });

    test('deliver jumps a row to the front of live queues', () async {
      final session = _FakeSession();
      sessions.add(session);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'first',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final urgent = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'urgent',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );

      final delivered = await service.deliver(
        workspaceId: 'ws',
        conversationId: 'conv',
        messageId: urgent!.messageId,
      );
      expect(delivered, isTrue);
      expect(
        session.steeringQueue
            .peek(SteeringChannel.steering)
            .map((m) => m.content),
        ['urgent', 'first'],
      );
    });

    test(
      'deliver returns false with no live harness session (CLI run)',
      () async {
        sessions.add(_FakeSession()..harnessActive = false);
        final result = await service.enqueue(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          content: 'nudge',
          senderUserId: 'user-1',
          writerMayDirect: true,
        );
        final delivered = await service.deliver(
          workspaceId: 'ws',
          conversationId: 'conv',
          messageId: result!.messageId,
        );
        expect(delivered, isFalse);
      },
    );
  });

  group('handleRunEnded conversion', () {
    test('converts queued rows to text in order and dispatches once', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'one',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'two',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );

      runLogs.active = [];
      await service.handleRunEnded('ws', 'conv', 'space');

      expect(
        messaging.messages.map((m) => m.messageType),
        everyElement(MessageType.text),
      );
      expect(
        messaging.messages.map((m) => m.convertedFromSteering),
        everyElement(isTrue),
      );
      expect(dispatched, ['one\n\ntwo']);
    });

    test('the turn a card becomes acts for the card\'s author', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'push it',
        senderUserId: 'member-7',
        writerMayDirect: true,
      );

      runLogs.active = [];
      await service.handleRunEnded('ws', 'conv', 'space');

      expect(messaging.messages.single.senderId, 'member-7');
      expect(dispatchedFor, ['member-7']);
    });

    test('cards of two writers become two turns, in queue order, each as '
        'its writer', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      for (final (text, sender) in [
        ('q one', 'user-q'),
        ('p one', 'user-p'),
        ('q two', 'user-q'),
      ]) {
        await service.enqueue(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          content: text,
          senderUserId: sender,
          writerMayDirect: true,
        );
      }

      runLogs.active = [];
      await service.handleRunEnded('ws', 'conv', 'space');

      expect(dispatched, ['q one\n\nq two', 'p one']);
      expect(dispatchedFor, ['user-q', 'user-p']);
    });

    test("a failed turn rolls back only its writer's cards", () async {
      sessions.add(_FakeSession()..harnessActive = false);
      for (final (text, sender) in [('q', 'user-q'), ('p', 'user-p')]) {
        await service.enqueue(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          content: text,
          senderUserId: sender,
          writerMayDirect: true,
        );
      }
      dispatchFailsFor = {'user-q'};

      runLogs.active = [];
      await service.handleRunEnded('ws', 'conv', 'space');

      expect(dispatchedFor, ['user-p']);
      final q = messaging.messages.firstWhere((m) => m.content == 'q');
      final p = messaging.messages.firstWhere((m) => m.content == 'p');
      expect(q.isSteeringQueued, isTrue);
      expect(p.messageType, MessageType.text);
    });

    test('a card with no writer is never sent: it is held for a member to '
        'delete', () async {
      await messaging.insertSteeringMessage(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nobody',
        senderId: '',
        metadata: {'steerState': 'queued', 'steerOrder': 0},
      );

      runLogs.active = [];
      await service.handleRunEnded('ws', 'conv', 'space');

      expect(dispatched, isEmpty);
      final row = messaging.messages.single;
      expect(row.isSteeringHeld, isTrue);
      expect(
        row.metadata?[SteeringQueueService.heldByKey],
        SteeringQueueService.heldByStop,
      );
    });

    test('keeps rows queued while another run is still active', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'hold',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );

      // A sibling run is still live.
      await service.handleRunEnded('ws', 'conv', 'space');
      expect(messaging.messages.single.isSteeringQueued, isTrue);
      expect(dispatched, isEmpty);
    });

    test('does nothing when the conversation has no queued rows', () async {
      runLogs.active = [];
      await service.handleRunEnded('ws', 'conv', 'space');
      expect(dispatched, isEmpty);
    });

    test('fast queue lookup does not scan the conversation', () async {
      messaging.scanThrows = true;
      final fast = SteeringQueueService(
        messagingRepository: messaging,
        runLogRepository: runLogs,
        eventBus: null,
        writerName: (_, id) async => 'Name of $id',
        dispatchResponder:
            ({
              required String workspaceId,
              required String spaceId,
              String? conversationId,
              required String content,
              String? senderUserId,
              List<MessageAttachment> attachments = const [],
              List<String> promptImageRefs = const [],
            }) async {
              dispatched.add(content);
            },
        sessionsForConversation: (conversationId) => const [],
        queuedSteering:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
            }) async => messaging.messages
                .where((m) => m.conversationId == conversationId)
                .toList(),
      );
      await fast.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'nudge',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      runLogs.active = [];
      await fast.handleRunEnded('ws', 'conv', 'space');
      expect(messaging.messages.single.messageType, MessageType.text);
      expect(dispatched, ['nudge']);
    });
  });

  group('run settlement (AgentRunSettled)', () {
    Future<void> queue(
      String content, {
      String sender = 'user-1',
      bool write = true,
    }) async {
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: content,
        senderUserId: sender,
        writerMayDirect: write,
      );
    }

    Message card(String content) =>
        messaging.messages.singleWhere((m) => m.content == content);

    /// A park service that finds a waiting pause for [paused] runs, acting
    /// for [person] (null: a bot's pause).
    void pausesFor(
      Set<String> paused,
      DateTime reset, {
      String? person = 'user-1',
    }) =>
        service.limitHoldReconciler =
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String runId,
            }) => service.holdRunCards(
              workspaceId: workspaceId,
              spaceId: spaceId,
              conversationId: conversationId,
              runId: runId,
              heldBy: paused.contains(runId)
                  ? 'limit:$runId'
                  : SteeringQueueService.heldByStop,
              resetsAt: paused.contains(runId) ? reset : null,
              pausePerson: paused.contains(runId) ? person : null,
            );

    test('a person stopping the run holds the queue instead of sending it, '
        'and release sends it', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('one');
      await queue('two');
      runLogs.active = [];

      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));

      expect(dispatched, isEmpty);
      expect(
        messaging.messages.map((m) => m.metadata?['steerState']),
        everyElement('held'),
      );
      expect(messaging.messages.every((m) => m.isSteeringHeld), isTrue);

      final released = await service.releaseHeldBy(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        heldBy: SteeringQueueService.heldByStop,
        senderId: 'user-1',
      );

      expect(released, 2);
      expect(dispatched, ['one\n\ntwo']);
      expect(
        messaging.messages.map((m) => m.messageType),
        everyElement(MessageType.text),
      );
    });

    test('a release while a run is live hands the cards to its lane', () async {
      final session = _FakeSession();
      sessions.add(session);
      await queue('later');
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));
      // The drained copy from enqueue is gone with the stopped run.
      session.steeringQueue
        ..drainSteering()
        ..drainAside()
        ..drainFollowUp();
      runLogs.active = [_activeRun()];

      expect(
        await service.releaseHeldBy(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          heldBy: SteeringQueueService.heldByStop,
          senderId: 'user-1',
        ),
        1,
      );

      expect(dispatched, isEmpty);
      expect(messaging.messages.single.isSteeringQueued, isTrue);
      expect(session.steeringQueue.isEmpty, isFalse);
    });

    test('a held card can be deleted', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      final card = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'drop me',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));
      expect(messaging.messages.single.isSteeringHeld, isTrue);

      final ok = await service.delete(
        workspaceId: 'ws',
        conversationId: 'conv',
        messageId: card!.messageId,
      );

      expect(ok, isTrue);
      expect(messaging.messages, isEmpty);
    });

    test("a release sends only the caller's own cards; another person's "
        'stay held', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('from p');
      await queue('from q', sender: 'user-2');
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));

      expect(
        await service.releaseHeldBy(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          heldBy: SteeringQueueService.heldByStop,
          senderId: 'user-2',
        ),
        1,
      );

      expect(dispatched, ['from q']);
      expect(dispatchedFor, ['user-2']);
      expect(card('from p').isSteeringHeld, isTrue);
    });

    for (final reason in [
      RunEndReason.completed,
      RunEndReason.error,
      RunEndReason.budget,
      RunEndReason.silence,
    ]) {
      test('a run that ended with ${reason.name} converts the queue', () async {
        sessions.add(_FakeSession()..harnessActive = false);
        await queue('next');
        runLogs.active = [];

        await service.handleRunSettled(_settled(reason));

        expect(dispatched, ['next']);
      });
    }

    for (final reset in [null, DateTime.utc(2026, 1, 1, 2)]) {
      test('a usage limit with no pause (reset: $reset) holds the queue as a '
          "Stop's, marked with the run, and sends nothing", () async {
        sessions.add(_FakeSession()..harnessActive = false);
        await queue('next');
        runLogs.active = [];
        pausesFor(const {}, DateTime.utc(2026));

        await service.handleRunSettled(
          _settled(RunEndReason.usageLimit, limitResetsAt: reset),
        );

        expect(dispatched, isEmpty);
        final meta = messaging.messages.single.metadata;
        expect(messaging.messages.single.isSteeringHeld, isTrue);
        expect(meta?[SteeringQueueService.heldByKey], 'stop');
        expect(meta?[SteeringQueueService.heldRunKey], 'run-ended');
      });
    }

    test("a usage limit whose run's pause waits: its pause holds the queue "
        'with the reset', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('next');
      runLogs.active = [];
      final reset = DateTime.utc(2026, 1, 1, 2);
      pausesFor({'run-ended'}, reset);

      await service.handleRunSettled(
        _settled(RunEndReason.usageLimit, limitResetsAt: reset),
      );

      expect(dispatched, isEmpty);
      expect(messaging.messages.single.isSteeringHeld, isTrue);
      expect(
        messaging.messages.single.metadata?[SteeringQueueService.heldByKey],
        'limit:run-ended',
      );
      // The reset rides on the card, for a refusal that names it.
      expect(
        await service.heldResetAt(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          heldBy: 'limit:run-ended',
        ),
        isNotNull,
      );
    });

    test("the park's resume releases only the cards held at it, in order, "
        "into the resumed run; a stop's cards stay held", () async {
      final session = _FakeSession();
      sessions.add(session);
      await queue('stopped');
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));
      // A new run takes two more cards, then stops at the limit.
      runLogs.active = [_activeRun()];
      await queue('first');
      await queue('second');
      runLogs.active = [];
      final reset = DateTime.now().add(const Duration(hours: 1));
      pausesFor({'run-ended'}, reset);
      await service.handleRunSettled(
        _settled(RunEndReason.usageLimit, limitResetsAt: reset),
      );
      expect(messaging.messages.every((m) => m.isSteeringHeld), isTrue);
      session.steeringQueue
        ..drainSteering()
        ..drainAside()
        ..drainFollowUp();
      // The park's wake was delivered: its run is live.
      runLogs.active = [_activeRun()];

      expect(
        await service.releaseHeldBy(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          heldBy: 'limit:run-ended',
          senderId: 'user-1',
        ),
        2,
      );

      expect(dispatched, isEmpty, reason: 'no second run');
      final byContent = {for (final m in messaging.messages) m.content: m};
      expect(byContent['stopped']!.isSteeringHeld, isTrue);
      expect(
        byContent['stopped']!.metadata?[SteeringQueueService.heldByKey],
        SteeringQueueService.heldByStop,
      );
      expect(byContent['first']!.isSteeringQueued, isTrue);
      expect(byContent['second']!.isSteeringQueued, isTrue);
      final lane = [
        ...session.steeringQueue.drainSteering(),
        ...session.steeringQueue.drainAside(),
        ...session.steeringQueue.drainFollowUp(),
      ].map((m) => m.content).join('|');
      expect(lane.indexOf('first'), lessThan(lane.indexOf('second')));
      expect(lane, isNot(contains('stopped')));
    });

    test('a pause that ends without resuming leaves its cards to their '
        "person: Stop-held, unsent, sent by 'Send held messages'; another "
        "pause's cards stay", () async {
      final reset = DateTime.now().add(const Duration(hours: 1));
      pausesFor({'run-a', 'run-b'}, reset);
      Future<void> pause(String content, String runId) async {
        runLogs.active = [_activeRun()];
        await queue(content);
        runLogs.active = [];
        await service.handleRunSettled(
          _settled(RunEndReason.usageLimit, limitResetsAt: reset, runId: runId),
        );
      }

      await pause('first', 'run-a');
      await pause('other', 'run-b');

      expect(
        await service.holdRunCards(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          runId: 'run-a',
          heldBy: SteeringQueueService.heldByStop,
          resetsAt: null,
          pausePerson: null,
        ),
        1,
      );

      expect(dispatched, isEmpty, reason: 'nothing is sent');
      expect(card('first').isSteeringHeld, isTrue);
      expect(
        card('first').metadata?[SteeringQueueService.heldByKey],
        SteeringQueueService.heldByStop,
      );
      expect(
        card('first').metadata?[SteeringQueueService.heldResetsAtKey],
        isNull,
      );
      expect(
        card('other').metadata?[SteeringQueueService.heldByKey],
        'limit:run-b',
      );
      expect(
        card('other').metadata?[SteeringQueueService.heldResetsAtKey],
        isNotNull,
      );

      expect(
        await service.releaseHeldBy(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          heldBy: SteeringQueueService.heldByStop,
          senderId: 'user-1',
        ),
        1,
      );
      expect(dispatched, hasLength(1));
      expect(card('first').isSteeringHeld, isFalse);
      expect(card('other').isSteeringHeld, isTrue);
    });

    group("a goal's review or another workspace's run never takes a card",
        () {
      final judges = {
        'read-only': () => _FakeSession(readOnly: true),
        'another workspace': () => _FakeSession(workspaceId: 'ws-2'),
      };
      for (final MapEntry(:key, :value) in judges.entries) {
        test('$key: not pushed at enqueue, not flushed at its start; the '
            "worker's next run takes it", () async {
          final judge = value();
          sessions.add(judge);
          final result = await service.enqueue(
            workspaceId: 'ws',
            spaceId: 'space',
            conversationId: 'conv',
            content: 'for the worker',
            senderUserId: 'user-1',
            writerMayDirect: true,
          );
          expect(result!.steerable, isFalse);
          // Its start reads its own workspace's queue (this fake has one
          // store), so only a judge of this workspace is started here.
          if (judge.workspaceId == 'ws') {
            service.handleHarnessStarted(judge);
          }
          for (var i = 0; i < 20; i++) {
            await Future<void>.delayed(Duration.zero);
          }
          expect(judge.steeringQueue.isEmpty, isTrue);
          expect(card('for the worker').isSteeringQueued, isTrue);

          final worker = _FakeSession(runLogId: 'run-2');
          sessions.add(worker);
          service.handleHarnessStarted(worker);
          for (var i = 0; i < 20; i++) {
            await Future<void>.delayed(Duration.zero);
          }
          expect(
            worker.steeringQueue.drainSteering().map((m) => m.content),
            ['for the worker'],
          );
        });
      }
    });

    test("a fresh goal segment is its person's worker: it takes the card at "
        'enqueue and at its start', () async {
      final segment = _FakeSession(freshHistory: true);
      sessions.add(segment);
      service.handleHarnessStarted(segment);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'use v2',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      expect(result!.steerable, isTrue);
      expect(
        segment.steeringQueue.drainSteering().map((m) => m.content),
        ['use v2'],
      );
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(card('use v2').isSteeringQueued, isFalse);

      sessions.remove(segment);
      final next = _FakeSession(runLogId: 'run-2', freshHistory: true)
        ..harnessActive = false;
      sessions.add(next);
      await queue('then v3');
      next.harnessActive = true;
      service.handleHarnessStarted(next);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        next.steeringQueue.drainSteering().map((m) => m.content),
        ['then v3'],
      );
    });

    test("a bot run (no requester) still takes a person's card mid-run",
        () async {
      final bot = _FakeSession(requestedByUserId: null);
      sessions.add(bot);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'also check the logs',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      expect(result!.steerable, isTrue);
      expect(
        bot.steeringQueue.drainSteering().map((m) => m.content),
        // It acts for no one, so the model is told whose words these are.
        ['${steeringFromAnotherPerson('Name of user-1')}\n\n$_logs'],
      );
    });

    test("a space's checker takes a card mid-run, and its end sends what is "
        "left as its writer's turn", () async {
      // A checker run, as `wakeChecker` starts it: an ordinary run with no
      // requester.
      final checker = _FakeSession(
        runLogId: 'run-check',
        requestedByUserId: null,
      );
      sessions.add(checker);
      service.handleHarnessStarted(checker);
      await queue('look at the tests too');
      expect(
        checker.steeringQueue.drainSteering().map((m) => m.content),
        // It acts for no one, so the model is told whose words these are.
        ['${steeringFromAnotherPerson('Name of user-1')}\n\n$_tests'],
      );
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      checker.harnessActive = false;
      await queue('and the docs', sender: 'user-q');

      runLogs.active = [];
      sessions.remove(checker);
      await service.handleRunSettled(
        _settled(RunEndReason.completed, runId: 'run-check'),
      );

      expect(dispatched, ['and the docs']);
      expect(dispatchedFor, ['user-q']);
    });

    test("a goal review's end sends nothing; the goal's next segment takes "
        'the card', () async {
      final review = _FakeSession(runLogId: 'run-review', readOnly: true);
      sessions.add(review);
      service.handleHarnessStarted(review);
      await queue('for the worker');
      runLogs.active = [];
      sessions.remove(review);

      await service.handleRunSettled(
        _settled(
          RunEndReason.completed,
          runId: 'run-review',
          wakeReason: WakeReason.goalReview,
        ),
      );

      expect(dispatched, isEmpty);
      expect(card('for the worker').isSteeringQueued, isTrue);

      final worker = _FakeSession(runLogId: 'run-seg', freshHistory: true);
      sessions.add(worker);
      runLogs.active = [_activeRun()];
      service.handleHarnessStarted(worker);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        worker.steeringQueue.drainSteering().map((m) => m.content),
        ['for the worker'],
      );
    });

    Future<void> reviewEnded() async {
      final review = _FakeSession(runLogId: 'run-review', readOnly: true);
      sessions.add(review);
      service.handleHarnessStarted(review);
      await queue('for the worker');
      runLogs.active = [];
      sessions.remove(review);
      await service.handleRunSettled(
        _settled(
          RunEndReason.completed,
          runId: 'run-review',
          wakeReason: WakeReason.goalReview,
        ),
      );
    }

    Future<void> settleTurns() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('a passing review: the goal completes, so the card a review kept is '
        "a Stop's, not taken by another person's next run", () async {
      // The verifier closed the goal before the review's settlement.
      service.goalContinues = (_, _) async => false;
      await reviewEnded();

      expect(dispatched, isEmpty);
      expect(card('for the worker').isSteeringHeld, isTrue);
      expect(
        card('for the worker').metadata?[SteeringQueueService.heldByKey],
        SteeringQueueService.heldByStop,
      );
      final other = _FakeSession(
        runLogId: 'run-other',
        requestedByUserId: 'user-2',
      );
      sessions.add(other);
      runLogs.active = [_activeRun()];
      service.handleHarnessStarted(other);
      await settleTurns();
      expect(other.steeringQueue.isEmpty, isTrue);
    });

    test('the goal completes after the review settled: the goal side holds '
        'the kept card the same way', () async {
      service.goalContinues = (_, _) async => true;
      await reviewEnded();
      expect(card('for the worker').isSteeringQueued, isTrue);

      expect(await service.holdKeptCards('ws', 'space', 'conv'), 1);
      expect(card('for the worker').isSteeringHeld, isTrue);
    });

    test('a rejecting review with rounds left: the card goes into the next '
        'segment', () async {
      service.goalContinues = (_, _) async => true;
      await reviewEnded();
      expect(card('for the worker').isSteeringQueued, isTrue);

      final worker = _FakeSession(runLogId: 'run-seg', freshHistory: true);
      sessions.add(worker);
      runLogs.active = [_activeRun()];
      service.handleHarnessStarted(worker);
      await settleTurns();
      expect(
        worker.steeringQueue.drainSteering().map((m) => m.content),
        ['for the worker'],
      );
    });

    test("under a person's pause only that person's cards wait with it; "
        "another writer's are a Stop's at once, theirs to send without "
        'ending the pause', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('mine');
      await queue('theirs', sender: 'user-2');
      runLogs.active = [];
      final reset = DateTime.utc(2026, 1, 1, 2);
      pausesFor({'run-ended'}, reset);

      await service.handleRunSettled(
        _settled(RunEndReason.usageLimit, limitResetsAt: reset),
      );

      expect(
        card('mine').metadata?[SteeringQueueService.heldByKey],
        'limit:run-ended',
      );
      expect(
        card('mine').metadata?[SteeringQueueService.heldResetsAtKey],
        reset.toIso8601String(),
      );
      expect(
        card('theirs').metadata?[SteeringQueueService.heldByKey],
        SteeringQueueService.heldByStop,
      );
      expect(
        card('theirs').metadata?[SteeringQueueService.heldResetsAtKey],
        isNull,
      );

      expect(
        await service.releaseHeldBy(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          heldBy: SteeringQueueService.heldByStop,
          senderId: 'user-2',
        ),
        1,
      );
      expect(dispatched, ['theirs']);
      expect(dispatchedFor, ['user-2']);
      expect(
        card('mine').metadata?[SteeringQueueService.heldByKey],
        'limit:run-ended',
      );
    });

    test("a bot run's pause gives every card back as a Stop's", () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('one');
      await queue('two', sender: 'user-2');
      runLogs.active = [];
      final reset = DateTime.utc(2026, 1, 1, 2);
      pausesFor({'run-ended'}, reset, person: null);

      await service.handleRunSettled(
        _settled(RunEndReason.usageLimit, limitResetsAt: reset),
      );

      for (final c in ['one', 'two']) {
        expect(card(c).isSteeringHeld, isTrue);
        expect(
          card(c).metadata?[SteeringQueueService.heldByKey],
          SteeringQueueService.heldByStop,
        );
      }
    });

    test("a removed writer's queued and held cards are deleted: the run's "
        "end sends only the others', and nothing is sent as them", () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('held mine', sender: 'user-gone');
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));
      runLogs.active = [_activeRun()];
      await queue('queued mine', sender: 'user-gone');
      await queue('queued theirs', sender: 'user-2');
      final removal = PersonRemovalService(
        eventBus: null,
        isMember: (_, _) async => false,
        cancelWakes: (_, _) async => 0,
        liveRuns: (_) async => const [],
        stopRun: (_, _) async => false,
        cardsOf: (ws, user) async => [
          for (final m in messaging.messages)
            if (m.senderId == user && (m.isSteeringQueued || m.isSteeringHeld))
              m,
        ],
        deleteCard: (ws, card) => service.delete(
          workspaceId: ws,
          conversationId: card.conversationId,
          messageId: card.id,
        ),
      );

      final outcome = await removal.handle(
        WorkspaceMemberRemoved(
          workspaceId: 'ws',
          userId: 'user-gone',
          occurredAt: DateTime.utc(2026, 1, 1),
        ),
      );
      expect(outcome.cards, 2);
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.completed));

      expect(dispatched, ['queued theirs']);
      expect(dispatchedFor, ['user-2']);
      expect(
        messaging.messages.where((m) => m.senderId == 'user-gone'),
        isEmpty,
      );
      expect(
        await service.releaseHeldBy(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          heldBy: SteeringQueueService.heldByStop,
          senderId: 'user-gone',
        ),
        0,
      );
    });

    test('a learning review takes no card mid-run and is not stopped for '
        "one; its end sends the card as its writer's turn", () async {
      final review = _FakeSession(runLogId: 'run-learn', readOnly: true);
      sessions.add(review);
      service.handleHarnessStarted(review);
      final queued = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'also the flaky test',
        senderUserId: 'user-q',
        writerMayDirect: true,
      );
      expect(queued!.steerable, isFalse);
      expect(review.steeringQueue.isEmpty, isTrue);
      runLogs.active = [_activeRun().copyWith(id: 'run-learn')];
      final stopped = <String>[];
      expect(
        await service.forceSend(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          messageId: queued.messageId,
          callerId: 'user-q',
          mayStop: true,
          stopRun: (id) async => stopped.add(id),
        ),
        SteeringForceOutcome.notQueued,
      );
      expect(stopped, isEmpty);

      runLogs.active = [];
      sessions.remove(review);
      await service.handleRunSettled(
        _settled(
          RunEndReason.completed,
          runId: 'run-learn',
          wakeReason: WakeReason.improvementReview,
        ),
      );

      expect(dispatched, ['also the flaky test']);
      expect(dispatchedFor, ['user-q']);
    });

    test("a learning review's usage limit holds its cards as a Stop's, like "
        "any run's", () async {
      final review = _FakeSession(runLogId: 'run-learn', readOnly: true);
      sessions.add(review);
      service.handleHarnessStarted(review);
      await queue('later');
      runLogs.active = [];
      sessions.remove(review);

      await service.handleRunSettled(
        _settled(
          RunEndReason.usageLimit,
          runId: 'run-learn',
          wakeReason: WakeReason.improvementReview,
        ),
      );

      expect(dispatched, isEmpty);
      final row = card('later');
      expect(row.isSteeringHeld, isTrue);
      expect(
        row.metadata?[SteeringQueueService.heldByKey],
        SteeringQueueService.heldByStop,
      );
    });

    test("a goal review's usage limit holds nothing: the card stays queued "
        'for the worker', () async {
      final review = _FakeSession(runLogId: 'run-review', readOnly: true);
      sessions.add(review);
      service.handleHarnessStarted(review);
      await queue('for the worker');
      runLogs.active = [];
      var reconciled = 0;
      service.limitHoldReconciler =
          ({
            required String workspaceId,
            required String spaceId,
            required String conversationId,
            required String runId,
          }) async => ++reconciled;

      await service.handleRunSettled(
        _settled(
          RunEndReason.usageLimit,
          runId: 'run-review',
          limitResetsAt: DateTime.utc(2026, 11, 20, 18),
          wakeReason: WakeReason.goalReview,
        ),
      );

      expect(reconciled, 0);
      expect(dispatched, isEmpty);
      final row = card('for the worker');
      expect(row.isSteeringQueued, isTrue);
      expect(row.metadata?[SteeringQueueService.heldByKey], isNull);
    });

    test('releasing your held cards sends only yours, as you: another '
        "person's leftover queued card stays queued", () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('p held', sender: 'user-p');
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));
      // Q's card typed in a later run that the server's stop ended.
      runLogs.active = [_activeRun()];
      await queue('q leftover', sender: 'user-q');
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.serverStopped));
      expect(card('q leftover').isSteeringQueued, isTrue);

      final released = await service.releaseHeldBy(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        heldBy: SteeringQueueService.heldByStop,
        senderId: 'user-p',
      );

      expect(released, 1);
      expect(dispatched, ['p held']);
      expect(dispatchedFor, ['user-p']);
      expect(card('q leftover').isSteeringQueued, isTrue);
    });

    test("after a failed turn's rollback, a release still sends only the "
        "releaser's card", () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('p held', sender: 'user-p');
      runLogs.active = [];
      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));
      runLogs.active = [_activeRun()];
      await queue('q card', sender: 'user-q');
      runLogs.active = [];
      dispatchFailsFor = {'user-q'};
      await service.handleRunSettled(_settled(RunEndReason.completed));
      expect(card('q card').isSteeringQueued, isTrue);
      dispatchFailsFor = {};

      await service.releaseHeldBy(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        heldBy: SteeringQueueService.heldByStop,
        senderId: 'user-p',
      );

      expect(dispatched, ['p held']);
      expect(dispatchedFor, ['user-p']);
      expect(card('q card').isSteeringQueued, isTrue);
    });

    test("a stop holds the queue while a subagent's row is still open",
        () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('one');
      // The parent settled; its child's row closes later, in teardown.
      runLogs.active = [_activeRun().copyWith(parentRunId: 'run-parent')];

      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));

      expect(dispatched, isEmpty);
      expect(messaging.messages.single.isSteeringHeld, isTrue);
    });

    test("'Send now' sends when the parent settles, whatever its subagents' "
        'rows say', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('older');
      final card = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'urgent',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final parent = _activeRun();
      final child = _activeRun().copyWith(
        role: AgentRunRole.sub,
        parentRunId: parent.id,
      );
      runLogs.active = [parent, child];
      final stoppedRuns = <String>[];
      final outcome = await service.forceSend(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        messageId: card!.messageId,
        callerId: 'user-1',
        mayStop: true,
        stopRun: (id) async => stoppedRuns.add(id),
      );
      expect(outcome, SteeringForceOutcome.stopping);
      // Only the conversation's own run is stopped; its child ends with it.
      expect(stoppedRuns, [parent.id]);
      runLogs.active = [child];

      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));

      expect(dispatched, ['urgent\n\nolder']);
    });

    test('a server stop leaves the queue for the next run', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('keep');
      runLogs.active = [];

      await service.handleRunSettled(_settled(RunEndReason.serverStopped));

      expect(dispatched, isEmpty);
      expect(messaging.messages.single.isSteeringQueued, isTrue);
    });

    test("forceSend's own stop sends the queue rather than holding it", () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('older');
      final card = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'urgent',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final outcome = await service.forceSend(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        messageId: card!.messageId,
        callerId: 'user-1',
        mayStop: true,
        stopRun: (_) async {},
      );
      expect(outcome, SteeringForceOutcome.stopping);
      runLogs.active = [];

      await service.handleRunSettled(_settled(RunEndReason.stoppedByUser));

      expect(dispatched, ['urgent\n\nolder']);
    });

    test('the service reacts to the event on the bus', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await queue('via bus');
      runLogs.active = [];

      bus.publish(_settled(RunEndReason.completed));
      for (var i = 0; i < 50 && dispatched.isEmpty; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(dispatched, ['via bus']);
    });
  });

  group('races and failures', () {
    test('a reorder never writes a drained card back to queued', () async {
      final session = _FakeSession(runLogId: 'run-x');
      sessions.add(session);
      final first = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'first',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final second = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'second',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      // The reorder's read happened before the run drained the cards: its
      // queue lookup returns that stale snapshot.
      final stale = messaging.messages.toList();
      final racing = SteeringQueueService(
        messagingRepository: messaging,
        runLogRepository: runLogs,
        eventBus: null,
        writerName: (_, id) async => 'Name of $id',
        dispatchResponder:
            ({
              required String workspaceId,
              required String spaceId,
              String? conversationId,
              required String content,
              String? senderUserId,
              List<MessageAttachment> attachments = const [],
              List<String> promptImageRefs = const [],
            }) async {},
        sessionsForConversation: (_) => [session],
        queuedSteering:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
            }) async => stale,
      );
      racing.handleHarnessStarted(session);
      await pumpEventQueue();
      session.steeringQueue.drainSteering();
      await pumpEventQueue();
      expect(messaging.messages.every((m) => m.isSteeringInjected), isTrue);

      await racing.reorder(
        workspaceId: 'ws',
        conversationId: 'conv',
        orderedIds: [second!.messageId, first!.messageId],
      );
      expect(messaging.messages.every((m) => m.isSteeringInjected), isTrue);
      expect(session.steeringQueue.isEmpty, isTrue);
    });

    test('a failed run-end send puts the cards back and says so', () async {
      final notices = <String>[];
      final failing = SteeringQueueService(
        messagingRepository: messaging,
        runLogRepository: runLogs,
        eventBus: null,
        writerName: (_, id) async => 'Name of $id',
        dispatchResponder:
            ({
              required String workspaceId,
              required String spaceId,
              String? conversationId,
              required String content,
              String? senderUserId,
              List<MessageAttachment> attachments = const [],
              List<String> promptImageRefs = const [],
            }) async => throw StateError('no agent'),
        sessionsForConversation: (_) => const [],
        postNotice:
            ({
              required String workspaceId,
              required String spaceId,
              required String conversationId,
              required String text,
            }) async => notices.add(text),
      );
      await failing.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'one',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      runLogs.active = [];
      await failing.handleRunEnded('ws', 'conv', 'space');

      final row = messaging.messages.single;
      expect(row.messageType, MessageType.steering);
      expect(row.isSteeringQueued, isTrue);
      expect(notices.single, contains('still in the queue'));
    });

    test('forceSend: a live run takes the card', () async {
      sessions.add(_FakeSession());
      final card = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'now',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final stopped = <String>[];
      final outcome = await service.forceSend(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        messageId: card!.messageId,
        callerId: 'user-1',
        mayStop: true,
        stopRun: (id) async => stopped.add(id),
      );
      expect(outcome, SteeringForceOutcome.delivered);
      expect(stopped, isEmpty);
    });

    test('forceSend: no mid-run lane promotes the card and stops the runs, '
        'unless the caller may not stop runs', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'older',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final card = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'urgent',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      final stopped = <String>[];
      Future<SteeringForceOutcome> force({required bool mayStop}) =>
          service.forceSend(
            workspaceId: 'ws',
            spaceId: 'space',
            conversationId: 'conv',
            messageId: card!.messageId,
            callerId: 'user-1',
            mayStop: mayStop,
            stopRun: (id) async => stopped.add(id),
          );

      expect(await force(mayStop: false), SteeringForceOutcome.stopRefused);
      expect(stopped, isEmpty);

      expect(await force(mayStop: true), SteeringForceOutcome.stopping);
      expect(stopped, [runLogs.active.single.id]);
      final queued = messaging.messages.toList()
        ..sort((a, b) => a.steerOrder.compareTo(b.steerOrder));
      expect(queued.first.content, 'urgent');
    });

    test('forceSend: with no live run the queue is sent at once', () async {
      final card = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'go',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      runLogs.active = [];
      final outcome = await service.forceSend(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        messageId: card!.messageId,
        callerId: 'user-1',
        mayStop: false,
        stopRun: (_) async {},
      );
      expect(outcome, SteeringForceOutcome.sent);
      expect(dispatched, ['go']);
    });

    test("forceSend with no live run sends only the caller's cards, as the "
        "caller; another writer's card is refused as not theirs", () async {
      final mine = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'mine',
        senderUserId: 'user-p',
        writerMayDirect: true,
      );
      final theirs = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'theirs',
        senderUserId: 'user-q',
        writerMayDirect: true,
      );
      runLogs.active = [];
      Future<SteeringForceOutcome> force(String id) => service.forceSend(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        messageId: id,
        callerId: 'user-p',
        mayStop: true,
        stopRun: (_) async {},
      );

      await expectLater(
        force(theirs!.messageId),
        throwsA(
          isA<SteeringNotYoursException>().having(
            (e) => e.code,
            'code',
            'steering_not_yours',
          ),
        ),
      );
      expect(dispatched, isEmpty);

      expect(await force(mine!.messageId), SteeringForceOutcome.sent);
      expect(dispatched, ['mine']);
      expect(dispatchedFor, ['user-p']);
      expect(
        messaging.messages.firstWhere((m) => m.content == 'theirs')
            .isSteeringQueued,
        isTrue,
      );
    });

    test('forceSend never stops a review for a card: it stays queued',
        () async {
      final review = _FakeSession(readOnly: true);
      sessions.add(review);
      service.handleHarnessStarted(review);
      final card = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'later',
        senderUserId: 'user-1',
        writerMayDirect: true,
      );
      runLogs.active = [_activeRun().copyWith(id: 'run-1')];
      final stopped = <String>[];
      final outcome = await service.forceSend(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        messageId: card!.messageId,
        callerId: 'user-1',
        mayStop: true,
        stopRun: (id) async => stopped.add(id),
      );
      expect(outcome, SteeringForceOutcome.notQueued);
      expect(stopped, isEmpty);
      expect(messaging.messages.single.isSteeringQueued, isTrue);
    });
  });

  group('whose words a card is', () {
    Future<String> enqueueAs(String sender, {required bool write}) async =>
        (await service.enqueue(
          workspaceId: 'ws',
          spaceId: 'space',
          conversationId: 'conv',
          content: 'look at the flaky test',
          senderUserId: sender,
          writerMayDirect: write,
        ))!.messageId;

    test("another writer's edit is refused with steering_not_yours; the row "
        'and the lane are unchanged', () async {
      final session = _FakeSession();
      sessions.add(session);
      final id = await enqueueAs('user-1', write: true);

      await expectLater(
        service.edit(
          workspaceId: 'ws',
          conversationId: 'conv',
          messageId: id,
          content: 'merge it now',
          callerId: 'user-2',
        ),
        throwsA(isA<SteeringNotYoursException>()),
      );
      expect(messaging.messages.single.content, 'look at the flaky test');
      expect(
        session.steeringQueue.peek(SteeringChannel.steering).single.content,
        'look at the flaky test',
      );
    });

    test("the requester's own card reaches the run as typed", () async {
      final session = _FakeSession();
      sessions.add(session);
      await enqueueAs('user-1', write: false);
      expect(
        session.steeringQueue.peek(SteeringChannel.steering).single.content,
        'look at the flaky test',
      );
    });

    test("another writer's card is preceded by a line naming them; the "
        'stored row keeps the text as typed', () async {
      final session = _FakeSession();
      sessions.add(session);
      await enqueueAs('user-2', write: true);
      final text = session.steeringQueue
          .peek(SteeringChannel.steering)
          .single
          .content;
      expect(text, startsWith(steeringFromAnotherPerson('Name of user-2')));
      expect(text, contains('Name of user-2'));
      expect(text, endsWith('\n\nlook at the flaky test'));
      expect(messaging.messages.single.content, 'look at the flaky test');
    });

    test('a run acting for no one names every writer', () async {
      final bot = _FakeSession(requestedByUserId: null);
      sessions.add(bot);
      await enqueueAs('user-1', write: true);
      expect(
        bot.steeringQueue.peek(SteeringChannel.steering).single.content,
        startsWith('[Message from Name of user-1,'),
      );
    });

    test('a card queued without the write grant never enters another '
        "person's run: not at enqueue, not at a run's start; its writer's "
        'own run takes it', () async {
      final theirs = _FakeSession();
      sessions.add(theirs);
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'read-only words',
        senderUserId: 'user-2',
        writerMayDirect: false,
      );
      expect(result!.steerable, isFalse);
      expect(theirs.steeringQueue.isEmpty, isTrue);
      expect(await service.steersAnother('ws', 'conv', 'user-2'), isTrue);
      expect(await service.steersAnother('ws', 'conv', 'user-1'), isFalse);

      final next = _FakeSession(runLogId: 'run-next');
      sessions.add(next);
      service.handleHarnessStarted(next);
      await Future<void>.delayed(Duration.zero);
      expect(next.steeringQueue.isEmpty, isTrue);

      final own = _FakeSession(runLogId: 'run-own', requestedByUserId: 'user-2');
      sessions.add(own);
      service.handleHarnessStarted(own);
      await Future<void>.delayed(Duration.zero);
      expect(
        own.steeringQueue.peek(SteeringChannel.steering).single.content,
        'read-only words',
      );
    });

    test('a review takes no card, so it is no run the gate counts', () async {
      sessions.add(
        _FakeSession(readOnly: true, requestedByUserId: null),
      );
      expect(await service.steersAnother('ws', 'conv', 'user-2'), isFalse);
    });
  });

  group('attachments', () {
    const shot = {
      'id': 'a1',
      'path':
          'blob:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'name': 'shot.png',
      'kind': 'image',
      'mediaType': 'image/png',
    };

    SteeringQueueService resolving() => SteeringQueueService(
      messagingRepository: messaging,
      runLogRepository: runLogs,
      eventBus: null,
      writerName: (_, id) async => 'Name of $id',
      dispatchResponder:
          ({
            required String workspaceId,
            required String spaceId,
            String? conversationId,
            required String content,
            String? senderUserId,
            List<MessageAttachment> attachments = const [],
            List<String> promptImageRefs = const [],
          }) async {},
      sessionsForConversation: (conversationId) => [
        for (final s in sessions)
          if (s.conversationId == conversationId) s,
      ],
      resolveAttachmentPaths:
          ({
            required String workspaceId,
            required String spaceId,
            required String text,
            required List<MessageAttachment> attachments,
          }) async => text.replaceAll(
            '@[file:shot.png]',
            '/space/attachments/shot.png',
          ),
    );

    test('a card can be attachments alone, stored on the row', () async {
      final result = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: '',
        senderUserId: 'user-1',
        writerMayDirect: true,
        attachments: const [shot],
      );
      expect(result, isNotNull);
      final row = messaging.messages.single;
      expect(row.attachments.single.name, 'shot.png');
      expect(row.isSteeringQueued, isTrue);
    });

    test('a live run is handed the attachment paths, in place', () async {
      final session = _FakeSession();
      sessions.add(session);
      await resolving().enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'too big: @[file:shot.png]',
        senderUserId: 'user-1',
        writerMayDirect: true,
        attachments: const [shot],
      );
      expect(
        session.steeringQueue.peek(SteeringChannel.steering).single.content,
        'too big: /space/attachments/shot.png',
      );
      // The stored card keeps the reference, so it still renders as a chip.
      expect(messaging.messages.single.content, 'too big: @[file:shot.png]');
    });

    test("another writer's card with an attachment: the line, then the "
        'resolved text', () async {
      final session = _FakeSession();
      sessions.add(session);
      await resolving().enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'see @[file:shot.png]',
        senderUserId: 'user-2',
        writerMayDirect: true,
        attachments: const [shot],
      );
      expect(
        session.steeringQueue.peek(SteeringChannel.steering).single.content,
        '${steeringFromAnotherPerson('Name of user-2')}\n\n'
        'see /space/attachments/shot.png',
      );
      expect(messaging.messages.single.content, 'see @[file:shot.png]');
    });

    test('an attachment the text never names still reaches the run', () async {
      final session = _FakeSession();
      sessions.add(session);
      await resolving().enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'look',
        senderUserId: 'user-1',
        writerMayDirect: true,
        attachments: const [shot],
      );
      expect(
        session.steeringQueue.peek(SteeringChannel.steering).single.content,
        'look\n/space/attachments/shot.png',
      );
    });

    test('run-end conversion hands the attachments to the follow-up', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'see @[file:shot.png]',
        senderUserId: 'user-1',
        writerMayDirect: true,
        attachments: const [shot],
      );
      runLogs.active = [];
      await service.handleRunEnded('ws', 'conv', 'space');

      expect(dispatched, ['see @[file:shot.png]']);
      expect(dispatchedAttachments.single.name, 'shot.png');
      expect(dispatchedImages, [
        'blob:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ]);
      expect(messaging.messages.single.attachments, hasLength(1));
    });
  });
}
