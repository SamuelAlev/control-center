import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:test/test.dart';

/// Exercises how [AgentStreamProcessor] maps the terminal event stream to the
/// persisted `metadata['outcome']`.
///
/// The harness reports a turn-ceiling stop by emitting
/// `DoneEvent(outcome: TurnOutcome.maxTurns)` — the process still exits
/// cleanly, so without that override the turn would be finalized as a silent
/// `completed` and the space would show the agent "stopping for no reason".
void main() {
  late FakeMessagingRepository repo;
  late ActiveStreamRegistry registry;
  late FakeAgentDispatchService dispatchService;
  late AgentStreamProcessor processor;
  late StreamController<AgentProcessEvent> events;

  const messageId = 'msg-1';

  setUp(() {
    repo = FakeMessagingRepository();
    registry = ActiveStreamRegistry();
    dispatchService = FakeAgentDispatchService();
    processor = AgentStreamProcessor(
      agentDispatchService: dispatchService,
      repo: repo,
      streamRegistry: registry,
    );
    events = StreamController<AgentProcessEvent>();
    registry.register(messageId, spaceId: 'chan-1');
    processor.processStream(
      workspaceId: 'ws-1',
      stream: events.stream,
      dispatchResult: AgentDispatchResult(
        stream: const Stream.empty(),
        dispatchId: 'dispatch-1',
        runLog: AgentRunLog(
          id: 'run-1',
          workspaceId: 'ws-1',
          agentId: 'agent-1',
          status: RunStatus.running,
          startedAt: DateTime.utc(2026, 7, 25),
        ),
      ),
      spaceId: 'chan-1',
      agentId: 'agent-1',
      agentName: 'engineer',
      messageId: messageId,
    );
  });

  tearDown(() async {
    await events.close();
  });

  /// Pushes [event] and lets the processor's listener drain it.
  Future<void> emit(AgentProcessEvent event) async {
    events.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  /// Closes the stream and waits for the async finalization to settle.
  Future<void> finish() async {
    await events.close();
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  group('turn outcome', () {
    test('a plain DoneEvent finalizes as completed', () async {
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      expect(repo.lastWorkspaceId, 'ws-1');
      expect(repo.lastMetadata?['streamComplete'], isTrue);
      expect(repo.lastMetadata?['outcome'], 'completed');
      expect(dispatchService.completedRuns, hasLength(1));
      expect(dispatchService.failedRuns, isEmpty);
    });

    test(
      'a DoneEvent carrying maxTurns finalizes as max_turns, not completed',
      () async {
        await emit(TextEvent(content: 'Still investigating…'));
        await emit(DoneEvent(outcome: TurnOutcome.maxTurns));
        await finish();

        expect(repo.lastMetadata?['streamComplete'], isTrue);
        expect(repo.lastMetadata?['outcome'], 'max_turns');
        // The process exited cleanly, so the run row completes — the ceiling is
        // a turn-level fact, not a run failure.
        expect(dispatchService.completedRuns, hasLength(1));
        expect(dispatchService.failedRuns, isEmpty);
        // The turn is not marked as an error turn either: the bubble shows the
        // turn-limit badge, not the failed-run retry affordance.
        expect(repo.lastMetadata?['error'], isNull);
      },
    );

    test(
      'a stream that ends without a DoneEvent finalizes as interrupted',
      () async {
        await emit(TextEvent(content: 'Cut off mid-sentence'));
        await finish();

        expect(repo.lastMetadata?['outcome'], 'interrupted');
      },
    );
  });
}

class FakeMessagingRepository implements MessagingRepository {
  Map<String, dynamic>? lastMetadata;

  /// Workspace the transcript write was scoped to.
  String? lastWorkspaceId;

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    lastWorkspaceId = workspaceId;
    lastMetadata = metadata;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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

class FakeAgentDispatchService implements AgentDispatchService {
  final completedRuns = <AgentRunLog>[];
  final failedRuns = <AgentRunLog>[];

  @override
  Future<void> completeRun(
    AgentRunLog runLog,
    String? summary, {
    RunCost? cost,
  }) async {
    completedRuns.add(runLog);
  }

  @override
  Future<void> failRun(AgentRunLog runLog, String error) async {
    failedRuns.add(runLog);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
