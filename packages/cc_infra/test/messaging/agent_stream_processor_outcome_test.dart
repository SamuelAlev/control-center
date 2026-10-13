import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
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
  late DomainEventBus eventBus;
  late List<MessageReceived> notifications;
  late StreamSubscription<MessageReceived> notificationSub;

  const messageId = 'msg-1';

  setUp(() {
    repo = FakeMessagingRepository();
    registry = ActiveStreamRegistry();
    dispatchService = FakeAgentDispatchService();
    eventBus = DomainEventBus();
    notifications = [];
    notificationSub = eventBus.on<MessageReceived>().listen(notifications.add);
    processor = AgentStreamProcessor(
      agentDispatchService: dispatchService,
      repo: repo,
      streamRegistry: registry,
      eventBus: eventBus,
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
    await notificationSub.cancel();
    eventBus.dispose();
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

    test('a terminal error fails a turn that already emitted prose', () async {
      await emit(TextEvent(content: 'Waiting for your answer.'));
      await emit(ErrorEvent(content: 'Agent silent for 15 min — terminating'));
      await emit(DoneEvent());
      await finish();

      expect(repo.lastMetadata?['outcome'], 'failed');
      expect(repo.lastMetadata?['error'], isTrue);
      expect(repo.lastContent, 'Waiting for your answer.');
      expect(dispatchService.completedRuns, isEmpty);
      expect(dispatchService.failedRuns, hasLength(1));
    });

    test('an answer after a recovered error still completes', () async {
      await emit(ErrorEvent(content: 'Transient provider failure'));
      await emit(TextEvent(content: 'Retried successfully.'));
      await emit(DoneEvent());
      await finish();

      expect(repo.lastMetadata?['outcome'], 'completed');
      expect(repo.lastContent, 'Retried successfully.');
      expect(dispatchService.failedRuns, isEmpty);
    });
  });

  group('completion notification', () {
    test(
      'previews the conclusion without dropping the earlier transcript',
      () async {
        await emit(TextEvent(content: 'I will inspect the sidebar.'));
        await emit(ToolCallEvent(toolName: 'read', toolCallId: 'read-1'));
        await emit(ToolResultEvent(toolCallId: 'read-1', outputs: 'sidebar'));
        await emit(TextEvent(content: 'The spacing needs a change.'));
        await emit(ThinkingEvent(content: 'Compare the layout options.'));
        await emit(TextEvent(content: 'Updated the sidebar. '));
        await emit(TextEvent(content: 'The layout checks passed.'));
        expect(notifications, isEmpty);
        final notification = eventBus.on<MessageReceived>().first;
        await emit(DoneEvent());
        await finish();

        expect(
          (await notification).contentPreview,
          'Updated the sidebar. The layout checks passed.',
        );
        expect(
          repo.lastContent,
          'I will inspect the sidebar.\n\n'
          'The spacing needs a change.\n\n'
          'Updated the sidebar. The layout checks passed.',
        );
      },
    );

    test('skips trailing tools, reasoning and blank text', () async {
      await emit(TextEvent(content: 'Inspecting the change.'));
      await emit(ThinkingEvent(content: 'Check the result.'));
      await emit(TextEvent(content: ' \nThe change is complete.\n '));
      await emit(ToolCallEvent(toolName: 'todo_write', toolCallId: 'todo-1'));
      await emit(ToolResultEvent(toolCallId: 'todo-1', outputs: 'saved'));
      await emit(ThinkingEvent(content: 'No further changes needed.'));
      await emit(TextEvent(content: ' \n '));
      final notification = eventBus.on<MessageReceived>().first;
      await emit(DoneEvent());
      await finish();

      expect((await notification).contentPreview, 'The change is complete.');
    });

    test(
      'applies the preview limit to the conclusion, not the opening',
      () async {
        final conclusion = 'Completed. ${'Verified result. ' * 12}'.trim();
        await emit(TextEvent(content: 'Starting the investigation.'));
        await emit(ThinkingEvent(content: 'Evaluate the results.'));
        await emit(TextEvent(content: conclusion));
        final notification = eventBus.on<MessageReceived>().first;
        await emit(DoneEvent());
        await finish();

        expect(
          (await notification).contentPreview,
          '${conclusion.substring(0, 120)}…',
        );
      },
    );

    test('keeps the failure reason when there is no visible answer', () async {
      await emit(ThinkingEvent(content: 'Attempt the request.'));
      await emit(ErrorEvent(content: 'Provider request failed.'));
      final notification = eventBus.on<MessageReceived>().first;
      await emit(DoneEvent());
      await finish();

      expect((await notification).contentPreview, 'Provider request failed.');
    });

    test('keeps stream errors when there is no visible answer', () async {
      final notification = eventBus.on<MessageReceived>().first;
      events.addError(StateError('Connection closed.'));
      await finish();

      expect(
        (await notification).contentPreview,
        'Bad state: Connection closed.',
      );
    });

    test('does not expose a reasoning-only turn', () async {
      await emit(ThinkingEvent(content: 'No visible answer was produced.'));
      await emit(DoneEvent());
      await finish();

      expect(notifications, isEmpty);
    });
  });

  group('context reading', () {
    test('the newest reported reading is persisted on the turn', () async {
      await emit(
        ContextWindowEvent(contextTokens: 90000, windowTokens: 1000000),
      );
      await emit(
        ContextWindowEvent(
          contextTokens: 120000,
          windowTokens: 1000000,
          compactions: 1,
        ),
      );
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      expect(repo.lastMetadata?['context'], {
        'tokens': 120000,
        'window': 1000000,
        'compactions': 1,
      });
    });

    test('a reading is not spend: it never reaches the run cost', () async {
      await emit(ContextWindowEvent(contextTokens: 500000));
      await emit(DoneEvent());
      await finish();

      final turn = repo.lastMetadata?['turn'] as Map<String, dynamic>?;
      expect(turn?['totalTokens'], 0);
      expect(repo.lastMetadata?['context'], {'tokens': 500000});
    });

    test('a turn that never reported carries no context key', () async {
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      expect(repo.lastMetadata?.containsKey('context'), isFalse);
    });
  });
}

class FakeMessagingRepository implements MessagingRepository {
  Map<String, dynamic>? lastMetadata;
  String? lastContent;

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
    lastContent = content;
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
    RunLatencyProfile? latency,
    RunVerification? verification,
    String? nativeSessionId,
    bool resumedNativeSession = false,
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
