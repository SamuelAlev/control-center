import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_infra/src/dispatch/steering_session_view.dart';
import 'package:cc_infra/src/messaging/steering_queue_service.dart';
import 'package:test/test.dart';

/// In-memory [MessagingRepository] covering the steering queue surface.
class _FakeMessagingRepo implements MessagingRepository {
  final List<Message> messages = [];
  final List<Map<String, dynamic>> inserts = [];
  final List<String> deletes = [];
  int idSeq = 0;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async => messages
      .where(
        (m) =>
            m.conversationId == (conversationId ?? 'conv') &&
            m.spaceId == spaceId,
      )
      .toList();

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
  _FakeSession({this.runLogId = 'run-1'});

  @override
  final String? workspaceId = 'ws';
  @override
  final String? conversationId = 'conv';
  @override
  final String? spaceId = 'space';
  @override
  final String? runLogId;
  bool harnessActive = true;
  @override
  bool get isHarnessActive => harnessActive;
  @override
  final SteeringQueue steeringQueue = SteeringQueue();
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

void main() {
  late _FakeMessagingRepo messaging;
  late _FakeRunLogRepo runLogs;
  late List<_FakeSession> sessions;
  List<String> dispatched = [];
  late SteeringQueueService service;

  setUp(() {
    messaging = _FakeMessagingRepo();
    runLogs = _FakeRunLogRepo([_activeRun()]);
    sessions = [];
    dispatched = [];
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
          }) async {
            dispatched.add(content);
          },
      sessionsForConversation: (conversationId) => [
        for (final s in sessions)
          if (s.conversationId == conversationId) s,
      ],
    );
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
      );
      final ok = await service.edit(
        workspaceId: 'ws',
        conversationId: 'conv',
        messageId: result!.messageId,
        content: 'new text',
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
      );
      service.handleHarnessStarted(session);
      session.steeringQueue.drainSteering();
      await Future<void>.delayed(Duration.zero);

      final ok = await service.edit(
        workspaceId: 'ws',
        conversationId: 'conv',
        messageId: result!.messageId,
        content: 'rewrite',
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
      );
      final second = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'second',
        senderUserId: 'user-1',
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
      );
      final urgent = await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'urgent',
        senderUserId: 'user-1',
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
      );
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'two',
        senderUserId: 'user-1',
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

    test('keeps rows queued while another run is still active', () async {
      sessions.add(_FakeSession()..harnessActive = false);
      await service.enqueue(
        workspaceId: 'ws',
        spaceId: 'space',
        conversationId: 'conv',
        content: 'hold',
        senderUserId: 'user-1',
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
  });
}
