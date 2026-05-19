import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/agent_run_task_completer.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _RecordingRunLogRepo implements AgentRunLogRepository {
  final Map<String, AgentRunLog> _store = {};
  int upsertCount = 0;

  void seed(AgentRunLog log) => _store[log.id] = log;

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      _store[id];

  @override
  Future<void> upsert(AgentRunLog log) async {
    upsertCount++;
    _store[log.id] = log;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeMessagingRepo implements MessagingRepository {
  @override
  Future<Space?> getSpaceById(String workspaceId, String spaceId) async => null;

  List<Message> messages = const [];

  /// What the last `getMessages` call addressed, so a test can pin that the
  /// conversation is named explicitly rather than smuggled in the space slot.
  String? lastSpaceId;
  String? lastConversationId;

  @override
  Future<List<Message>> getMessages(
    String workspaceId,
    String spaceId, {
    String? conversationId,
  }) async {
    lastSpaceId = spaceId;
    lastConversationId = conversationId;
    return messages;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);

  /// The tree is not exercised by this fake — a branch it silently accepted
  /// would be a pointer move nothing could observe, so it refuses instead.
  @override
  Future<ConversationTree> conversationTree({
    required String workspaceId,
    required String conversationId,
  }) async => throw UnimplementedError();

  @override
  Future<void> branchConversationAt({
    required String workspaceId,
    required String conversationId,
    required String messageId,
  }) async => throw UnimplementedError();

  @override
  Future<String> forkConversation({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    String? messageId,
    String? title,
  }) async => throw UnimplementedError();
}

AgentRunLog _run({
  String id = 'run-1',
  String agentId = 'agent-1',
  String workspaceId = 'ws-1',
  String conversationId = 'chan-1',
  String? spaceId,
  String? pipelineRunId = 'pr-1',
  String? pipelineStepId = 'step-1',
  Map<String, dynamic>? expectedOutputSchema,
  Map<String, dynamic>? outputJson,
  RunStatus status = RunStatus.completed,
}) => AgentRunLog(
  id: id,
  agentId: agentId,
  workspaceId: workspaceId,
  conversationId: conversationId,
  spaceId: spaceId,
  pipelineRunId: pipelineRunId,
  pipelineStepId: pipelineStepId,
  expectedOutputSchema: expectedOutputSchema,
  outputJson: outputJson,
  startedAt: DateTime(2026, 1, 1),
  status: status,
);

Message _agentMsg(
  String content, {
  String senderId = 'agent-1',
  DateTime? at,
  String spaceId = 'chan-1',
}) => Message(
  id: 'm-$content',
  spaceId: spaceId,
  conversationId: spaceId,
  senderId: senderId,
  senderType: SenderType.agent,
  content: content,
  messageType: MessageType.text,
  createdAt: at ?? DateTime(2026, 1, 1, 12),
);

void main() {
  late DomainEventBus bus;
  late _RecordingRunLogRepo runLogs;
  late _FakeMessagingRepo messaging;
  late AgentRunTaskCompleter completer;

  setUp(() {
    bus = DomainEventBus();
    runLogs = _RecordingRunLogRepo();
    messaging = _FakeMessagingRepo();
    completer = AgentRunTaskCompleter(
      eventBus: bus,
      runLogRepository: runLogs,
      messagingRepository: messaging,
    )..start();
  });

  tearDown(() => completer.dispose());

  Future<void> complete(
    String? runId, {
    String? conversationId = 'chan-1',
  }) async {
    bus.publish(
      AgentRunCompleted(
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: conversationId,
        runId: runId,
        occurredAt: DateTime.now(),
      ),
    );
    // The bus delivers asynchronously; flush.
    for (var i = 0; i < 5; i++) {
      await Future.microtask(() {});
    }
  }

  group('early exits', () {
    test('no runId → ignored', () async {
      runLogs.seed(_run());
      await complete(null);
      expect(runLogs.upsertCount, 0);
    });

    test('no conversationId → ignored', () async {
      runLogs.seed(_run());
      await complete('run-1', conversationId: null);
      expect(runLogs.upsertCount, 0);
    });

    test('run not found → ignored', () async {
      await complete('missing');
      expect(runLogs.upsertCount, 0);
    });

    test('non-pipeline run → ignored', () async {
      runLogs.seed(_run(pipelineRunId: null, pipelineStepId: null));
      await complete('run-1');
      expect(runLogs.upsertCount, 0);
    });

    test('run already has outputJson → ignored', () async {
      runLogs.seed(_run(outputJson: {'result': 'already here'}));
      await complete('run-1');
      expect(runLogs.upsertCount, 0);
    });

    test(
      'schema-declaring run without output → left alone (step fails on harvest)',
      () async {
        runLogs.seed(_run(expectedOutputSchema: {'type': 'object'}));
        await complete('run-1');
        expect(runLogs.upsertCount, 0);
      },
    );
  });

  group('schemaless fallback harvest', () {
    test('harvests the agent last message as {result}', () async {
      runLogs.seed(_run());
      messaging.messages = [
        _agentMsg('first attempt'),
        _agentMsg('final answer', at: DateTime(2026, 1, 1, 13)),
        Message(
          id: 'u1',
          spaceId: 'chan-1',
          conversationId: 'chan-1',
          senderId: 'user',
          senderType: SenderType.user,
          content: 'thanks',
          messageType: MessageType.text,
          createdAt: DateTime(2026, 1, 1, 14),
        ),
      ];

      await complete('run-1');

      expect(runLogs.upsertCount, 1);
      final updated = await runLogs.getById('ws-1', 'run-1');
      expect(updated!.outputJson, {'result': 'final answer'});
    });

    // The regression this replaced: an agent that died before its first token
    // (an expired credential, a denied command, the silence watchdog) left no
    // message, `{result: ''}` was invented for it, and the engine's harvest
    // could no longer tell that from a reviewer who genuinely found nothing —
    // so a run that failed after 15 seconds reached the canvas as a green node.
    test(
      'no agent message → NOTHING is harvested, so the step fails',
      () async {
        runLogs.seed(_run());
        messaging.messages = const [];

        await complete('run-1');

        expect(runLogs.upsertCount, 0);
        final updated = await runLogs.getById('ws-1', 'run-1');
        expect(updated!.outputJson, isNull);
      },
    );

    test('a blank agent message is not a payload either', () async {
      runLogs.seed(_run());
      messaging.messages = [_agentMsg('   \n  ')];

      await complete('run-1');

      expect(runLogs.upsertCount, 0);
    });

    test('a run already recorded as failed is not harvested', () async {
      // Whatever it managed to say before dying is not a deliverable.
      runLogs.seed(_run(status: RunStatus.error));
      messaging.messages = [_agentMsg('half an answer before the crash')];

      await complete('run-1');

      expect(runLogs.upsertCount, 0);
      expect((await runLogs.getById('ws-1', 'run-1'))!.outputJson, isNull);
    });

    test(
      'reads the run CONVERSATION, addressing its space separately',
      () async {
        // The regression: a space holds many conversations, and this run's
        // conversation id was passed in the space slot. The read then tried to
        // mint a standing conversation whose `space_id` was a conversation id,
        // SQLite refused the foreign key and the harvest was lost — which is
        // how a pipeline step ended up with no payload at all.
        runLogs.seed(_run(conversationId: 'conv-qa', spaceId: 'space-1'));
        messaging.messages = [_agentMsg('qa verdict', spaceId: 'conv-qa')];

        await complete('run-1', conversationId: 'conv-qa');

        expect(messaging.lastConversationId, 'conv-qa');
        expect(messaging.lastSpaceId, 'space-1');
        final updated = await runLogs.getById('ws-1', 'run-1');
        expect(updated!.outputJson, {'result': 'qa verdict'});
      },
    );

    test(
      'run with no recorded space still harvests its conversation',
      () async {
        runLogs.seed(_run(conversationId: 'conv-qa'));
        messaging.messages = [_agentMsg('verdict', spaceId: 'conv-qa')];

        await complete('run-1', conversationId: 'conv-qa');

        expect(messaging.lastConversationId, 'conv-qa');
        final updated = await runLogs.getById('ws-1', 'run-1');
        expect(updated!.outputJson, {'result': 'verdict'});
      },
    );

    test('ignores messages from other senders / non-agent types', () async {
      runLogs.seed(_run());
      messaging.messages = [
        Message(
          id: 'other',
          spaceId: 'chan-1',
          conversationId: 'chan-1',
          senderId: 'agent-1',
          senderType: SenderType.user,
          content: 'wrong',
          messageType: MessageType.text,
          createdAt: DateTime(2026, 1, 1, 12),
        ),
        _agentMsg('the real one', at: DateTime(2026, 1, 1, 13)),
      ];

      await complete('run-1');

      final updated = await runLogs.getById('ws-1', 'run-1');
      expect(updated!.outputJson, {'result': 'the real one'});
    });
  });
}
