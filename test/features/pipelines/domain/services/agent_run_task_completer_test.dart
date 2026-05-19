
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/agent_run_task_completer.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _RecordingRunLogRepo implements AgentRunLogRepository {
  final Map<String, AgentRunLog> _store = {};
  int upsertCount = 0;

  void seed(AgentRunLog log) => _store[log.id] = log;

  @override
  Future<AgentRunLog?> getById(String id) async => _store[id];

  @override
  Future<void> upsert(AgentRunLog log) async {
    upsertCount++;
    _store[log.id] = log;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeMessagingRepo implements MessagingRepository {
  List<ChannelMessage> messages = const [];

  @override
  Future<List<ChannelMessage>> getMessages(String channelId) async => messages;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

AgentRunLog _run({
  String id = 'run-1',
  String agentId = 'agent-1',
  String workspaceId = 'ws-1',
  String conversationId = 'chan-1',
  String? pipelineRunId = 'pr-1',
  String? pipelineStepRunId = 'step-1',
  Map<String, dynamic>? expectedOutputSchema,
  Map<String, dynamic>? outputJson,
}) =>
    AgentRunLog(
      id: id,
      agentId: agentId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      pipelineRunId: pipelineRunId,
      pipelineStepRunId: pipelineStepRunId,
      expectedOutputSchema: expectedOutputSchema,
      outputJson: outputJson,
      startedAt: DateTime(2026, 1, 1),
      status: RunStatus.completed,
    );

ChannelMessage _agentMsg(
  String content, {
  String senderId = 'agent-1',
  DateTime? at,
  String channelId = 'chan-1',
}) =>
    ChannelMessage(
      id: 'm-$content',
      channelId: channelId,
      senderId: senderId,
      senderType: ChannelSenderType.agent,
      content: content,
      messageType: ChannelMessageType.text,
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

  Future<void> complete(String? runId, {String? conversationId = 'chan-1'}) async {
    bus.publish(AgentRunCompleted(
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: conversationId,
      runId: runId,
      occurredAt: DateTime.now(),
    ));
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
      runLogs.seed(_run(pipelineRunId: null, pipelineStepRunId: null));
      await complete('run-1');
      expect(runLogs.upsertCount, 0);
    });

    test('run already has outputJson → ignored', () async {
      runLogs.seed(_run(outputJson: {'result': 'already here'}));
      await complete('run-1');
      expect(runLogs.upsertCount, 0);
    });

    test('schema-declaring run without output → left alone (step fails on harvest)',
        () async {
      runLogs.seed(_run(expectedOutputSchema: {'type': 'object'}));
      await complete('run-1');
      expect(runLogs.upsertCount, 0);
    });
  });

  group('schemaless fallback harvest', () {
    test('harvests the agent last message as {result}', () async {
      runLogs.seed(_run());
      messaging.messages = [
        _agentMsg('first attempt'),
        _agentMsg('final answer', at: DateTime(2026, 1, 1, 13)),
        ChannelMessage(
          id: 'u1',
          channelId: 'chan-1',
          senderId: 'user',
          senderType: ChannelSenderType.user,
          content: 'thanks',
          messageType: ChannelMessageType.text,
          createdAt: DateTime(2026, 1, 1, 14),
        ),
      ];

      await complete('run-1');

      expect(runLogs.upsertCount, 1);
      final updated = await runLogs.getById('run-1');
      expect(updated!.outputJson, {'result': 'final answer'});
    });

    test('no agent message → harvests empty string', () async {
      runLogs.seed(_run());
      messaging.messages = const [];

      await complete('run-1');

      final updated = await runLogs.getById('run-1');
      expect(updated!.outputJson, {'result': ''});
    });

    test('ignores messages from other senders / non-agent types', () async {
      runLogs.seed(_run());
      messaging.messages = [
        ChannelMessage(
          id: 'other',
          channelId: 'chan-1',
          senderId: 'agent-1',
          senderType: ChannelSenderType.user,
          content: 'wrong',
          messageType: ChannelMessageType.text,
          createdAt: DateTime(2026, 1, 1, 12),
        ),
        _agentMsg('the real one', at: DateTime(2026, 1, 1, 13)),
      ];

      await complete('run-1');

      final updated = await runLogs.getById('run-1');
      expect(updated!.outputJson, {'result': 'the real one'});
    });
  });
}
