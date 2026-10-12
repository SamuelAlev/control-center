import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/usage_scope.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation_tree.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/observability/domain/run_stage.dart';
import 'package:cc_domain/features/observability/domain/run_verification.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:test/test.dart';

/// Pins the ACCOUNTING and LATENCY semantics of [AgentStreamProcessor].
///
/// Three things were wrong before and are asserted here so they cannot come
/// back:
/// * a cumulative CLI report was ADDED to the per-turn deltas, doubling a
///   resumed run's spend on every turn;
/// * `timeToFirstTokenMs` was derived from the first visible TEXT event and
///   presented as a provider latency it never measured;
/// * the run's stage timings had nowhere to go, so "first useful work" — the
///   number an efficiency claim is about — was not recorded at all.
void main() {
  late _FakeRepo repo;
  late ActiveStreamRegistry registry;
  late _FakeDispatch dispatch;
  late AgentStreamProcessor processor;
  late StreamController<AgentProcessEvent> events;

  final startedAt = DateTime.utc(2026, 10, 11, 12);

  setUp(() {
    repo = _FakeRepo();
    registry = ActiveStreamRegistry();
    dispatch = _FakeDispatch();
    processor = AgentStreamProcessor(
      agentDispatchService: dispatch,
      repo: repo,
      streamRegistry: registry,
    );
    events = StreamController<AgentProcessEvent>();
    registry.register('msg-1', spaceId: 'chan-1');
    processor.processStream(
      workspaceId: 'ws-1',
      stream: events.stream,
      dispatchResult: AgentDispatchResult(
        stream: const Stream.empty(),
        dispatchId: 'dispatch-1',
        runLog: AgentRunLog(
          id: 'run-1',
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          agentId: 'agent-1',
          status: RunStatus.running,
          startedAt: startedAt,
        ),
      ),
      spaceId: 'chan-1',
      agentId: 'agent-1',
      agentName: 'engineer',
      messageId: 'msg-1',
    );
  });

  tearDown(() async {
    await events.close();
  });

  Future<void> emit(AgentProcessEvent event) async {
    events.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> finish() async {
    await events.close();
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  Map<String, dynamic>? turnMetadata() =>
      repo.lastMetadata?['turn'] as Map<String, dynamic>?;

  group('usage scope', () {
    test('additive reports sum', () async {
      await emit(
        UsageEvent(usage: const RunUsage(inputTokens: 100, costMicros: 3000)),
      );
      await emit(
        UsageEvent(usage: const RunUsage(inputTokens: 50, costMicros: 7000)),
      );
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      final cost = dispatch.lastCost!;
      expect(cost.inputTokens, 150);
      expect(cost.costMicros, 10000);
      expect(turnMetadata()?['totalTokens'], 150);
      expect(turnMetadata()?['costMicros'], 10000);
    });

    test(
      'a runCumulative report REPLACES the totals instead of adding to them',
      () async {
        // The CLI's own ledger is absolute: turn 1 says 100, turn 2 (after a
        // resume) says 260 for the WHOLE process. Adding it to the deltas would
        // report 360.
        await emit(
          UsageEvent(
            usage: const RunUsage(
              inputTokens: 100,
              costMicros: 20000,
              costBasis: CostBasis.subscription,
            ),
            scope: UsageScope.runCumulative,
            provider: 'claude-cli',
            modelId: 'claude-opus-4-8',
          ),
        );
        await emit(
          UsageEvent(
            usage: const RunUsage(
              inputTokens: 260,
              costMicros: 52000,
              costBasis: CostBasis.subscription,
            ),
            scope: UsageScope.runCumulative,
            provider: 'claude-cli',
            modelId: 'claude-opus-4-8',
          ),
        );
        await emit(TextEvent(content: 'Done.'));
        await emit(DoneEvent());
        await finish();

        final cost = dispatch.lastCost!;
        expect(cost.inputTokens, 260);
        expect(cost.costMicros, 52000);
        expect(cost.costBasis, CostBasis.subscription);
        // The legacy cents projection is derived from the exact figure, so a
        // cents-summing consumer sees the same, undoubled number.
        expect(cost.estimatedCostCents, 5);
      },
    );

    test(
      'a cumulative snapshot that carries no duration keeps the earlier one',
      () async {
        await emit(
          UsageEvent(
            usage: const RunUsage(inputTokens: 10),
            durationMs: 1200,
            scope: UsageScope.runCumulative,
          ),
        );
        await emit(
          UsageEvent(
            usage: const RunUsage(inputTokens: 20),
            scope: UsageScope.runCumulative,
          ),
        );
        await emit(TextEvent(content: 'Done.'));
        await emit(DoneEvent());
        await finish();

        expect(dispatch.lastCost!.durationMs, 1200);
        expect(dispatch.lastCost!.inputTokens, 20);
      },
    );
  });

  group('sub-agent usage attribution is not lost', () {
    test('a compaction report keeps its purpose and provider', () async {
      await emit(
        UsageEvent(
          usage: const RunUsage(inputTokens: 900, costMicros: 4000),
          purpose: LlmCallPurpose.compaction,
          provider: 'anthropic',
          modelId: 'claude-haiku-4-5',
          attempt: 2,
          requestId: 'compact-1',
        ),
      );
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      // The auxiliary call is real spend: the run cost must include it, not
      // only the main-thread tokens.
      expect(dispatch.lastCost!.inputTokens, 900);
      expect(dispatch.lastCost!.costMicros, 4000);
    });
  });

  group('adapter session lineage', () {
    test(
      'a reported native session id and resume flag reach the run',
      () async {
        await emit(
          UsageEvent(
            usage: const RunUsage(inputTokens: 30),
            provider: 'claude-cli',
            modelId: 'claude-opus-4-8',
            nativeSessionId: 'sess-abc',
            resumedNativeSession: true,
          ),
        );
        await emit(TextEvent(content: 'Done.'));
        await emit(DoneEvent());
        await finish();

        // Lineage is DATA on the run, not a debug line: the resume-vs-fresh
        // comparison has to be groupable.
        expect(dispatch.lastNativeSessionId, 'sess-abc');
        expect(dispatch.lastResumedNativeSession, isTrue);
      },
    );

    test(
      'a run that reported no session carries none and is not "resumed"',
      () async {
        await emit(UsageEvent(usage: const RunUsage(inputTokens: 5)));
        await emit(TextEvent(content: 'Done.'));
        await emit(DoneEvent());
        await finish();

        expect(dispatch.lastNativeSessionId, isNull);
        expect(dispatch.lastResumedNativeSession, isFalse);
      },
    );
  });

  group('latency boundaries', () {
    test(
      'provider TTFT is reported only when a boundary was observed',
      () async {
        await emit(
          StageTimingEvent(
            stage: RunStage.requestSent,
            offsetMs: 400,
            source: RunTimingSource.harness,
          ),
        );
        // No firstResponseByte / firstModelDelta: nothing observed a provider
        // latency, so the run must record NONE rather than the text-derived
        // number.
        await emit(TextEvent(content: 'Done.'));
        await emit(DoneEvent());
        await finish();

        expect(dispatch.lastCost!.timeToFirstTokenMs, isNull);
        expect(turnMetadata()?.containsKey('ttfbMs'), isFalse);
      },
    );

    test('an observed transport byte yields a real TTFB', () async {
      await emit(
        StageTimingEvent(
          stage: RunStage.requestSent,
          offsetMs: 300,
          source: RunTimingSource.transport,
        ),
      );
      await emit(
        StageTimingEvent(
          stage: RunStage.firstResponseByte,
          offsetMs: 520,
          source: RunTimingSource.transport,
        ),
      );
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      expect(dispatch.lastCost!.timeToFirstTokenMs, 220);
      expect(turnMetadata()?['ttfbMs'], 220);
      expect(dispatch.lastLatency?.offsetMs(RunStage.requestSent), 300);
    });

    test('a THINKING-first run is not "unstarted" and a tool call is useful '
        'work', () async {
      await emit(
        ThinkingEvent(
          content: 'weighing options',
          timestamp: startedAt.add(const Duration(milliseconds: 900)),
        ),
      );
      await emit(
        ToolCallEvent(
          toolName: 'Read',
          toolCallId: 't1',
          timestamp: startedAt.add(const Duration(milliseconds: 1500)),
        ),
      );
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      final profile = dispatch.lastLatency!;
      // The first MODEL DELTA is the thinking block, not the eventual text.
      expect(profile.offsetMs(RunStage.firstModelDelta), 900);
      // A tool call IS useful work: a tool-first turn is not idle.
      expect(profile.offsetMs(RunStage.firstUsefulText), 1500);
      expect(profile.timeToFirstUsefulWorkMs, 1500);
      expect(turnMetadata()?['timeToFirstUsefulWorkMs'], 1500);
    });

    test('the earliest observation of a stage wins over a later one', () async {
      await emit(
        StageTimingEvent(
          stage: RunStage.firstUsefulText,
          offsetMs: 750,
          source: RunTimingSource.adapter,
        ),
      );
      await emit(
        TextEvent(
          content: 'real answer',
          timestamp: startedAt.add(const Duration(milliseconds: 3000)),
        ),
      );
      await emit(DoneEvent());
      await finish();

      expect(dispatch.lastLatency!.offsetMs(RunStage.firstUsefulText), 750);
    });

    test('a stage is always stamped and referenced from run start', () async {
      await emit(TextEvent(content: 'Done.'));
      await emit(DoneEvent());
      await finish();

      expect(dispatch.lastLatency!.offsetMs(RunStage.submitted), 0);
    });
  });
}

class _FakeRepo implements MessagingRepository {
  Map<String, dynamic>? lastMetadata;

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? messageType,
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    lastMetadata = metadata;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

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

class _FakeDispatch implements AgentDispatchService {
  RunCost? lastCost;
  RunLatencyProfile? lastLatency;
  String? lastNativeSessionId;
  bool lastResumedNativeSession = false;

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
    lastCost = cost;
    lastLatency = latency;
    lastNativeSessionId = nativeSessionId;
    lastResumedNativeSession = resumedNativeSession;
  }

  @override
  Future<void> failRun(AgentRunLog runLog, String error) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
