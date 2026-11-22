import 'dart:async';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Regression coverage for the loop's terminal contract and the per-turn
/// recovery state: every exit flushes the transcript and emits exactly one
/// LoopDone (plus one LoopError on failure), rewinds keep their checkpoints
/// honest, recovery counters reset per turn, discarded attempts are announced
/// and the cache anchor survives a provider retry.

class _Scripted extends LlmProviderPort {
  _Scripted(this.script);
  final List<List<LlmEvent>> script;
  final List<LlmCompleteConfig> configs = [];
  int calls = 0;

  @override
  String get displayName => 'Scripted';
  @override
  String get defaultModel => 'mock';
  @override
  Future<List<ProviderModel>> listModels() async => const [];
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final i = calls < script.length ? calls : script.length - 1;
    calls++;
    configs.add(config);
    yield* Stream.fromIterable(script[i]);
  }
}

class _EchoTool extends HarnessTool {
  _EchoTool();
  @override
  String get name => 'echo';
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  String get description => 'echo';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ok');
}

/// Cooperative tool: finishes as soon as its own call token is cancelled.
class _CooperativeTool extends HarnessTool {
  final Completer<Object?> sawCancel = Completer<Object?>();
  @override
  String get name => 'slow';
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  String get description => 'slow';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    await context.cancel!.whenCancelled;
    sawCancel.complete(context.cancel!.reason);
    return HarnessToolResult.error('stopped');
  }
}

class _ThrowingForcedCompactor implements HarnessCompactor {
  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
    CancellationToken cancel = CancellationToken.none,
    Future<String?> Function()? focus,
  }) async {
    if (force) {
      throw StateError('summarizer exploded');
    }
    return const HarnessCompactionResult.unchanged(0);
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) => 0;
}

/// Folds one message whenever forced and records forced prunes.
class _CountingCompactor implements HarnessCompactor {
  int forced = 0;
  int forcedPrunes = 0;
  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    int reservedOutputTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
    CancellationToken cancel = CancellationToken.none,
    Future<String?> Function()? focus,
  }) async {
    if (!force) {
      return const HarnessCompactionResult.unchanged(0);
    }
    forced++;
    return const HarnessCompactionResult(
      changed: true,
      summarized: false,
      messagesFolded: 0,
      tokensBefore: 10,
      tokensAfter: 5,
    );
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) {
    if (force) {
      forcedPrunes++;
    }
    return 0;
  }
}

class _HangingAdvisor implements Advisor {
  CancellationToken? token;
  @override
  Future<AdvisorNote?> review(
    List<HarnessMessage> history, {
    CancellationToken cancel = CancellationToken.none,
  }) {
    token = cancel;
    return Completer<AdvisorNote?>().future;
  }

  @override
  void reset() {}
}

LlmToolUseDelta _call(String id, String name, [String args = '{}']) =>
    LlmToolUseDelta(id: id, name: name, argumentsJson: args);

const _done = LlmDone(stopReason: LlmStopReason.endTurn);
const _toolDone = LlmDone(stopReason: LlmStopReason.toolUse);

void _expectOneTerminal(List<AgentLoopEvent> events) {
  expect(events.whereType<LoopDone>(), hasLength(1));
  expect(events.last, isA<LoopDone>());
}

void main() {
  const runner = AgentLoopRunner();

  group('finish flushes the final turn on every terminal path', () {
    Future<HarnessTranscript?> runAndLoad(
      AgentLoopConfig Function(InMemoryHarnessTranscriptStore) build,
      _Scripted provider, {
      CancellationToken? cancel,
      List<HarnessTool> tools = const [],
    }) async {
      final store = InMemoryHarnessTranscriptStore();
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'task',
            tools: tools,
            provider: provider,
            config: build(store),
            cancel: cancel,
          )
          .toList();
      _expectOneTerminal(events);
      return store.load('k');
    }

    test('maxTurns saves the last turn (and the handoff)', () async {
      final t = await runAndLoad(
        (store) => AgentLoopConfig(
          maxTurns: 1,
          transcript: LoopTranscriptConfig(store: store, key: 'k'),
        ),
        _Scripted([
          [_call('a', 'echo'), _toolDone],
          [const LlmTextDelta('handoff text'), _done],
        ]),
        tools: [_EchoTool()],
      );
      // The tool result of the final turn and the handoff are both saved.
      expect(t!.messages.any((m) => m.role == HarnessRole.tool), isTrue);
      expect(t.messages.last.textContent, 'handoff text');
    });

    test('an external budget stop saves the last turn', () async {
      var calls = 0;
      final t = await runAndLoad(
        (store) => AgentLoopConfig(
          guards: LoopGuardConfig(externalBudgetExceeded: () => ++calls > 2),
          transcript: LoopTranscriptConfig(store: store, key: 'k'),
        ),
        _Scripted([
          [_call('a', 'echo'), _toolDone],
        ]),
        tools: [_EchoTool()],
      );
      expect(t!.messages.last.role, HarnessRole.tool);
    });

    test('a provider error saves the history it has', () async {
      final t = await runAndLoad(
        (store) => AgentLoopConfig(
          transcript: LoopTranscriptConfig(store: store, key: 'k'),
        ),
        _Scripted([
          [_call('a', 'echo'), _toolDone],
          [const LlmError('bad request', code: 'invalid_request_error')],
        ]),
        tools: [_EchoTool()],
      );
      expect(t!.messages.last.role, HarnessRole.tool);
    });
  });

  test(
    'a throwing overflow compaction still ends with one error + done',
    () async {
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'task',
            tools: const [],
            provider: _Scripted([
              [
                const LlmError(
                  'prompt is too long: 300000 tokens > 200000 maximum',
                  code: 'invalid_request_error',
                ),
              ],
            ]),
            config: AgentLoopConfig(
              compaction: LoopCompactionConfig(
                contextWindow: 200000,
                compactor: _ThrowingForcedCompactor(),
              ),
            ),
          )
          .toList();
      _expectOneTerminal(events);
      expect((events.last as LoopDone).reason, LoopDoneReason.error);
      expect(events.whereType<LoopError>(), hasLength(1));
      expect(
        events.whereType<LoopNotice>().map((n) => n.message).join(),
        contains('Overflow compaction failed'),
      );
    },
  );

  test(
    'a "tokens per minute exceeded" rate limit is not an overflow',
    () async {
      final compactor = _CountingCompactor();
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'task',
            tools: const [],
            provider: _Scripted([
              [
                const LlmError(
                  'Rate limit reached: tokens per minute exceeded',
                  code: 'http_429',
                ),
              ],
            ]),
            config: AgentLoopConfig(
              compaction: LoopCompactionConfig(
                contextWindow: 1000,
                compactor: compactor,
              ),
            ),
          )
          .toList();
      expect(compactor.forced, 0);
      expect((events.last as LoopDone).reason, LoopDoneReason.error);
      expect(
        LlmErrorKind.classify(message: 'tokens per minute exceeded'),
        LlmErrorKind.rateLimit,
      );
      expect(
        LlmErrorKind.classify(
          code: 'invalid_request_error',
          message: 'prompt is too long: 300000 tokens > 200000 maximum',
        ),
        LlmErrorKind.contextOverflow,
      );
    },
  );

  test('overflow recovery is per turn, not per run', () async {
    // Turn 1 overflows twice then calls a tool; turn 2 overflows twice then
    // answers. A run-wide budget of two would fail turn 2.
    const overflow = LlmError(
      'context_length_exceeded',
      code: 'context_length_exceeded',
    );
    final compactor = _CountingCompactor();
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'task',
          tools: [_EchoTool()],
          provider: _Scripted([
            [overflow],
            [overflow],
            [_call('a', 'echo'), _toolDone],
            [overflow],
            [overflow],
            [const LlmTextDelta('done'), _done],
          ]),
          config: AgentLoopConfig(
            compaction: LoopCompactionConfig(
              contextWindow: 1000,
              compactor: compactor,
            ),
          ),
        )
        .toList();
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    expect(compactor.forced, 4);
    // Compaction forces pruning (ARCH): every fold rides a forced prune.
    expect(compactor.forcedPrunes, 4);
  });

  test('truncation continuations reset after a tool-bearing turn', () async {
    const cut = LlmDone(stopReason: LlmStopReason.maxTokens);
    final provider = _Scripted([
      for (var i = 0; i < 3; i++) [const LlmTextDelta('part'), cut],
      [_call('a', 'echo'), _toolDone],
      for (var i = 0; i < 3; i++) [const LlmTextDelta('part'), cut],
      [const LlmTextDelta('end'), _done],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'task',
          tools: [_EchoTool()],
          provider: provider,
        )
        .toList();
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    // All eight scripted turns ran: the second streak got its own allowance.
    expect(provider.calls, 8);
  });

  group('rewind', () {
    test(
      'an unknown label fails the call instead of rewinding to the task',
      () async {
        final history = <HarnessMessage>[];
        final events = await runner
            .run(
              history: history,
              userMessage: 'task',
              tools: [_EchoTool()],
              provider: _Scripted([
                [_call('e', 'echo'), _toolDone],
                [_call('r', 'rewind', '{"checkpoint":"nope"}'), _toolDone],
                [const LlmTextDelta('done'), _done],
              ]),
            )
            .toList();
        expect((events.last as LoopDone).reason, LoopDoneReason.completed);
        final rewindResult = events.whereType<LoopToolCallResult>().firstWhere(
          (e) => e.toolName == 'rewind',
        );
        expect(rewindResult.result.isError, isTrue);
        expect(
          rewindResult.result.content,
          contains('Unknown checkpoint "nope"'),
        );
        // Nothing was dropped: the exploration is still there.
        expect(history.any((m) => m.textContent.contains('Rewound')), isFalse);
        expect(
          events.whereType<LoopNotice>().any(
            (n) => n.message.contains('Rewound'),
          ),
          isFalse,
        );
      },
    );

    test(
      'labels set after the target are dropped, not left dangling',
      () async {
        final store = InMemoryHarnessTranscriptStore();
        final events = await runner
            .run(
              history: <HarnessMessage>[],
              userMessage: 'task',
              tools: [_EchoTool()],
              provider: _Scripted([
                [_call('c1', 'checkpoint', '{"label":"a"}'), _toolDone],
                [_call('e1', 'echo'), _toolDone],
                [_call('c2', 'checkpoint', '{"label":"b"}'), _toolDone],
                [_call('r', 'rewind', '{"checkpoint":"a"}'), _toolDone],
                [_call('r2', 'rewind', '{"checkpoint":"b"}'), _toolDone],
                [const LlmTextDelta('done'), _done],
              ]),
              config: AgentLoopConfig(
                transcript: LoopTranscriptConfig(store: store, key: 'k'),
              ),
            )
            .toList();
        final saved = await store.load('k');
        expect(saved!.checkpoints.keys, ['a']);
        // The second rewind names a label that died with the first one.
        final second = events
            .whereType<LoopToolCallResult>()
            .where((e) => e.toolName == 'rewind')
            .single;
        expect(second.result.content, contains('Unknown checkpoint "b"'));
      },
    );
  });

  test(
    'a retry after streamed deltas announces the discarded attempt',
    () async {
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'task',
            tools: const [],
            provider: _Scripted([
              [
                const LlmTextDelta('half an ans'),
                const LlmError(
                  'overloaded',
                  code: 'overloaded_error',
                  retryable: true,
                ),
              ],
              [const LlmTextDelta('full answer'), _done],
            ]),
            config: const AgentLoopConfig(
              guards: LoopGuardConfig(maxProviderRetries: 1),
            ),
          )
          .toList();
      final discarded = events.whereType<LoopTurnDiscarded>().single;
      expect(discarded.text, 'half an ans');
      expect(discarded.reason, 'overloaded_error');
      final turn = events.whereType<LoopTurnComplete>().single;
      expect(turn.message.textContent, 'full answer');
    },
  );

  test('a provider retry keeps the previous request\'s cache anchor', () async {
    final provider = _Scripted([
      [_call('a', 'echo'), _toolDone],
      [const LlmError('overloaded', code: 'overloaded_error', retryable: true)],
      [const LlmTextDelta('ok'), _done],
    ]);
    await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'task',
          tools: [_EchoTool()],
          provider: provider,
          config: const AgentLoopConfig(
            guards: LoopGuardConfig(maxProviderRetries: 1),
          ),
        )
        .toList();
    // Request 1 wrote at its tail (index 0: the user message). Both the failed
    // request 2 and its retry read from that anchor.
    expect(provider.configs[0].cacheAnchorIndex, -1);
    expect(provider.configs[1].cacheAnchorIndex, 0);
    expect(provider.configs[2].cacheAnchorIndex, 0);
  });

  test(
    'a cancel during a hanging advisor review ends the run promptly',
    () async {
      final advisor = _HangingAdvisor();
      final source = CancellationTokenSource();
      final events = <AgentLoopEvent>[];
      final done = runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'task',
            tools: [_EchoTool()],
            provider: _Scripted([
              [_call('a', 'echo'), _toolDone],
            ]),
            config: AgentLoopConfig(
              steering: LoopSteeringConfig(
                advisor: advisor,
                advisorEveryTurns: 1,
              ),
            ),
            cancel: source.token,
          )
          .forEach(events.add);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(advisor.token, isNotNull);
      source.cancel('stop');
      await done.timeout(const Duration(seconds: 2));
      expect((events.last as LoopDone).reason, LoopDoneReason.cancelled);
      expect(advisor.token!.isCancelled, isTrue);
    },
  );

  test('a tool timeout cancels the call\'s own token', () async {
    final tool = _CooperativeTool();
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'task',
          tools: [tool],
          provider: _Scripted([
            [_call('a', 'slow'), _toolDone],
            [const LlmTextDelta('done'), _done],
          ]),
          config: const AgentLoopConfig(
            tools: LoopToolConfig(
              toolTimeout: Duration(milliseconds: 30),
              maxParallelToolCalls: 1,
            ),
          ),
        )
        .toList();
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    expect(await tool.sawCancel.future, contains('time limit'));
  });
}
