import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Replays one scripted list of events per `complete()` call; repeats the last.
class _Scripted implements LlmProviderPort {
  _Scripted(this.script);
  final List<List<LlmEvent>> script;
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
    yield* Stream.fromIterable(script[i]);
  }
}

/// A read-tier tool that records every call (parallel-eligible).
class _ReadTool extends HarnessTool {
  _ReadTool(this._name);
  final String _name;
  int calls = 0;

  @override
  String get name => _name;
  @override
  String get description => 'reads';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    calls++;
    return HarnessToolResult.success('$_name ok');
  }
}

/// A compactor that folds only when forced (models reactive overflow recovery).
class _FakeCompactor implements HarnessCompactor {
  int forced = 0;

  @override
  Future<HarnessCompactionResult> maybeCompact(
    List<HarnessMessage> history, {
    required int? contextWindow,
    int overheadTokens = 0,
    String selfAgentName = 'assistant',
    bool force = false,
  }) async {
    if (force) {
      forced++;
      return const HarnessCompactionResult(
        changed: true,
        summarized: true,
        messagesFolded: 1,
        tokensBefore: 1000,
        tokensAfter: 100,
      );
    }
    return const HarnessCompactionResult.unchanged(0);
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) => 0;
}

/// Shared overlap meter: records how many sibling calls are in flight at once.
class _Meter {
  int active = 0;
  int peak = 0;
}

/// Mimics the `task` tool: read-tier, self-guarding, explicitly parallel-safe.
/// Self-guarding alone used to exclude it from the loop's parallel batch, which
/// serialized a subagent fan-out the model had asked to run at once.
class _SpawnTool extends HarnessTool {
  _SpawnTool(this._name, this._meter);
  final String _name;
  final _Meter _meter;
  int calls = 0;

  @override
  String get name => _name;
  @override
  String get description => 'spawns a subagent';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get selfGuards => true;
  @override
  bool get parallelSafe => true;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    calls++;
    _meter.active++;
    if (_meter.active > _meter.peak) {
      _meter.peak = _meter.active;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _meter.active--;
    return HarnessToolResult.success('$_name ok');
  }
}

/// Read-tiered but effectful — a bridged MCP tool that under-declares its tier
/// while declaring a real effect class. Batching it would bypass its approval.
class _EffectfulReadTool extends HarnessTool {
  _EffectfulReadTool(this._name);
  final String _name;
  int calls = 0;

  @override
  String get name => _name;
  @override
  String get description => 'publishes, despite the tier';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.prPublish};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    calls++;
    return HarnessToolResult.success('$_name ok');
  }
}

/// Hooks that handle ONLY session start. Nothing here observes an individual
/// tool call, so the loop must keep batching read-only tools.
class _LifecycleOnlyHooks implements AgentLoopHooks {
  bool started = false;

  @override
  bool get interceptsTools => false;
  @override
  Future<void> onSessionStart() async => started = true;
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async =>
      true;
  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}

/// Hooks that gate every tool call, so batching must be off.
class _ToolGatingHooks implements AgentLoopHooks {
  final List<String> seen = [];

  @override
  bool get interceptsTools => true;
  @override
  Future<void> onSessionStart() async {}
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    seen.add(toolName);
    return true;
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {}
}

LlmToolUseDelta _call(String name) =>
    LlmToolUseDelta(id: 'tc_$name', name: name, argumentsJson: '{}');

/// Three parallel-safe tools called in one turn, run under [hooks]; returns the
/// peak observed concurrency.
Future<int> _peakConcurrencyWithHooks(AgentLoopHooks? hooks) async {
  final meter = _Meter();
  final tools = [
    _SpawnTool('task_a', meter),
    _SpawnTool('task_b', meter),
    _SpawnTool('task_c', meter),
  ];
  final provider = _Scripted([
    [
      _call('task_a'),
      _call('task_b'),
      _call('task_c'),
      const LlmDone(stopReason: LlmStopReason.toolUse),
    ],
    [
      const LlmTextDelta('done'),
      const LlmDone(stopReason: LlmStopReason.endTurn),
    ],
  ]);
  await const AgentLoopRunner()
      .run(
        history: [],
        userMessage: 'go',
        tools: tools,
        provider: provider,
        config: AgentLoopConfig(hooks: hooks),
      )
      .toList();
  return meter.peak;
}

void main() {
  const runner = AgentLoopRunner();

  group('hook-aware tool batching', () {
    test('a session-start-only hook does not serialize tool calls', () async {
      final hooks = _LifecycleOnlyHooks();
      final peak = await _peakConcurrencyWithHooks(hooks);
      expect(
        peak,
        3,
        reason:
            'a hook that observes no individual tool call must not cost the '
            'run its read-only batching',
      );
      expect(hooks.started, isTrue, reason: 'the hook still ran');
    });

    test('a tool-gating hook still serializes tool calls', () async {
      final hooks = _ToolGatingHooks();
      final peak = await _peakConcurrencyWithHooks(hooks);
      expect(
        peak,
        1,
        reason: 'a per-tool veto has to run in the model call order',
      );
      expect(hooks.seen, ['task_a', 'task_b', 'task_c']);
    });

    test('no hooks at all batches, as before', () async {
      expect(await _peakConcurrencyWithHooks(null), 3);
    });
  });

  test(
    'a max_tokens-truncated answer auto-continues instead of stopping',
    () async {
      final provider = _Scripted([
        [
          const LlmTextDelta('half a'),
          const LlmDone(stopReason: LlmStopReason.maxTokens),
        ],
        [
          const LlmTextDelta('nswer'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: [],
            userMessage: 'go',
            tools: const [],
            provider: provider,
          )
          .toList();
      expect(provider.calls, 2, reason: 'should continue after truncation');
      expect(
        events.whereType<LoopNotice>().any(
          (n) => n.message.contains('truncated'),
        ),
        isTrue,
      );
      expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    },
  );

  test(
    'doom-loop: repeated identical tool calls trigger a steering notice',
    () async {
      final tool = _ReadTool('probe');
      final provider = _Scripted([
        [_call('probe'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      ]);
      final events = await runner
          .run(
            history: [],
            userMessage: 'go',
            tools: [tool],
            provider: provider,
            config: const AgentLoopConfig(maxTurns: 5),
          )
          .toList();
      expect(
        events.whereType<LoopNotice>().any(
          (n) => n.message.contains('Repetition'),
        ),
        isTrue,
      );
    },
  );

  test(
    'follow-up steering message continues the run after completion',
    () async {
      final steering = SteeringQueue()..pushFollowUp('now do the second thing');
      final provider = _Scripted([
        [
          const LlmTextDelta('done one'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
        [
          const LlmTextDelta('done two'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final history = <HarnessMessage>[];
      await runner
          .run(
            history: history,
            userMessage: 'do the first thing',
            tools: const [],
            provider: provider,
            config: AgentLoopConfig(steering: steering),
          )
          .toList();
      expect(provider.calls, 2, reason: 'follow-up should drive a second turn');
      expect(
        history.any(
          (m) =>
              m.role == HarnessRole.user &&
              m.textContent.contains('second thing'),
        ),
        isTrue,
      );
    },
  );

  test(
    'read-tier tools in one turn execute concurrently and both run',
    () async {
      final a = _ReadTool('read_a');
      final b = _ReadTool('read_b');
      final provider = _Scripted([
        [
          _call('read_a'),
          _call('read_b'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: [],
            userMessage: 'go',
            tools: [a, b],
            provider: provider,
          )
          .toList();
      expect(a.calls, 1);
      expect(b.calls, 1);
      // Both results are paired back in the model's original call order.
      final results = events.whereType<LoopToolCallResult>().toList();
      expect(results.map((r) => r.toolUseId), ['tc_read_a', 'tc_read_b']);
    },
  );

  test(
    'sibling task-style calls in one turn overlap instead of serializing',
    () async {
      final meter = _Meter();
      final tools = [
        _SpawnTool('task_a', meter),
        _SpawnTool('task_b', meter),
        _SpawnTool('task_c', meter),
      ];
      final provider = _Scripted([
        [
          _call('task_a'),
          _call('task_b'),
          _call('task_c'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(history: [], userMessage: 'go', tools: tools, provider: provider)
          .toList();
      expect(
        meter.peak,
        3,
        reason: 'self-guarding parallel-safe tools must run concurrently',
      );
      expect(tools.map((t) => t.calls), [1, 1, 1]);
      // Results are still paired back in the model's original call order.
      final results = events.whereType<LoopToolCallResult>().toList();
      expect(results.map((r) => r.toolUseId), [
        'tc_task_a',
        'tc_task_b',
        'tc_task_c',
      ]);
    },
  );

  test(
    'parallel fan-out is capped at maxParallelToolCalls, in waves',
    () async {
      final meter = _Meter();
      final tools = [
        _SpawnTool('task_a', meter),
        _SpawnTool('task_b', meter),
        _SpawnTool('task_c', meter),
        _SpawnTool('task_d', meter),
        _SpawnTool('task_e', meter),
      ];
      final provider = _Scripted([
        [
          for (final t in tools) _call(t.name),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: [],
            userMessage: 'go',
            tools: tools,
            provider: provider,
            config: const AgentLoopConfig(maxParallelToolCalls: 2),
          )
          .toList();
      expect(meter.peak, 2, reason: 'the cap bounds each wave');
      expect(tools.map((t) => t.calls), [
        1,
        1,
        1,
        1,
        1,
      ], reason: 'the cap defers the remainder, it does not drop it');
      final results = events.whereType<LoopToolCallResult>().toList();
      expect(results.map((r) => r.toolUseId), tools.map((t) => 'tc_${t.name}'));
    },
  );

  test(
    'a read-tiered effectful tool is not batched and still needs approval',
    () async {
      final tool = _EffectfulReadTool('publish_pr');
      final provider = _Scripted([
        [_call('publish_pr'), const LlmDone(stopReason: LlmStopReason.toolUse)],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: [],
            userMessage: 'go',
            tools: [tool],
            provider: provider,
            config: AgentLoopConfig(
              approvalCallback: (_, _) async =>
                  const ToolGateDecision.deny(reason: 'not this time'),
            ),
          )
          .toList();
      expect(
        tool.calls,
        0,
        reason: 'the batch path must not bypass the approval gate',
      );
      final results = events.whereType<LoopToolCallResult>().toList();
      expect(results.single.result.isError, isTrue);
      expect(results.single.result.content, contains('not this time'));
    },
  );

  test('reactive context-overflow: compact then retry the same turn', () async {
    final compactor = _FakeCompactor();
    final provider = _Scripted([
      [
        const LlmError(
          'prompt is too long: 250000 tokens > 200000 maximum context',
          code: 'invalid_request_error',
          retryable: false,
        ),
        const LlmDone(stopReason: LlmStopReason.unknown),
      ],
      [
        const LlmTextDelta('recovered'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: [],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          config: AgentLoopConfig(contextWindow: 200000, compactor: compactor),
        )
        .toList();
    expect(compactor.forced, 1, reason: 'overflow should force a compaction');
    expect(
      provider.calls,
      2,
      reason: 'turn should be retried after compaction',
    );
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
  });

  test('overflow-recovery compaction re-primes the advisor', () async {
    final compactor = _FakeCompactor();
    final advisor = _ResetRecordingAdvisor();
    final provider = _Scripted([
      [
        const LlmError(
          'prompt is too long: 250000 tokens > 200000 maximum context',
          code: 'invalid_request_error',
        ),
        const LlmDone(),
      ],
      [
        const LlmTextDelta('recovered'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    await runner
        .run(
          history: [],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          config: AgentLoopConfig(
            contextWindow: 200000,
            compactor: compactor,
            advisor: advisor,
          ),
        )
        .toList();
    // The forced compaction rewrote history under the advisor's cursor, so the
    // loop must have re-primed it (parity with the loop-top compaction path).
    expect(advisor.resets, greaterThanOrEqualTo(1));
  });
}

class _ResetRecordingAdvisor implements Advisor {
  int resets = 0;
  @override
  Future<AdvisorNote?> review(List<HarnessMessage> history) async => null;
  @override
  void reset() => resets++;
}
