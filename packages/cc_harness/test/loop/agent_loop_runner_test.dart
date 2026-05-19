import 'dart:async';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// A provider that replays one scripted list of [LlmEvent]s per `complete()`
/// call. When the script runs out it repeats the last entry (useful for
/// max-turns tests).
class _ScriptedProvider implements LlmProviderPort {
  _ScriptedProvider(this.script);

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
    final index = calls < script.length ? calls : script.length - 1;
    calls++;
    yield* Stream.fromIterable(script[index]);
  }
}

/// A tool that never completes — stands in for a hung/wedged one.
class _HangingTool extends HarnessTool {
  final Completer<HarnessToolResult> _never = Completer<HarnessToolResult>();

  @override
  String get name => 'do_thing';
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  String get description => 'never returns';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) => _never.future;
}

class _RecordingTool extends HarnessTool {
  _RecordingTool({this.result = 'done'});

  final String result;
  final List<Map<String, dynamic>> calls = [];

  @override
  String get name => 'do_thing';
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.write;
  @override
  String get description => 'records calls';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    calls.add(args);
    return HarnessToolResult.success(result);
  }
}

LlmToolUseDelta _toolCall(
  String name, [
  Map<String, dynamic> args = const {},
]) => LlmToolUseDelta(id: 'tc_$name', name: name, argumentsJson: _json(args));

String _json(Map<String, dynamic> m) => m.isEmpty
    ? '{}'
    : '{${m.entries.map((e) => '"${e.key}":"${e.value}"').join(',')}}';

void main() {
  const runner = AgentLoopRunner();

  test('text-only response completes the loop', () async {
    final provider = _ScriptedProvider([
      [
        const LlmTextDelta('Hello'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final history = <HarnessMessage>[];
    final events = await runner
        .run(
          history: history,
          userMessage: 'hi',
          tools: const [],
          provider: provider,
        )
        .toList();

    expect(
      events.whereType<LoopTextDelta>().map((e) => e.text).join(),
      'Hello',
    );
    expect(events.last, isA<LoopDone>());
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    // user turn + assistant turn appended.
    expect(history.length, 2);
    expect(history.first.role, HarnessRole.user);
    expect(history.last.role, HarnessRole.assistant);
  });

  test('executes a tool then continues to a final answer', () async {
    final tool = _RecordingTool(result: 'file contents');
    final provider = _ScriptedProvider([
      [
        _toolCall('do_thing', {'path': 'a'}),
        const LlmDone(stopReason: LlmStopReason.toolUse),
      ],
      [
        const LlmTextDelta('All set'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final history = <HarnessMessage>[];
    final events = await runner
        .run(
          history: history,
          userMessage: 'go',
          tools: [tool],
          provider: provider,
        )
        .toList();

    expect(tool.calls.single, {'path': 'a'});
    expect(events.whereType<LoopToolCallStart>().single.toolName, 'do_thing');
    final result = events.whereType<LoopToolCallResult>().single;
    expect(result.result.content, 'file contents');
    expect(
      events.whereType<LoopTextDelta>().map((e) => e.text).join(),
      'All set',
    );
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    // user, assistant(toolcall), tool-results, assistant(text) = 4
    expect(history.length, 4);
  });

  test('unknown tool returns an error result and keeps going', () async {
    final provider = _ScriptedProvider([
      [_toolCall('missing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [
        const LlmTextDelta('ok'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: const [],
          provider: provider,
        )
        .toList();
    final result = events.whereType<LoopToolCallResult>().single;
    expect(result.result.isError, isTrue);
    expect(result.result.content, contains('Unknown tool'));
  });

  test('denied approval feeds back a denial without executing', () async {
    final tool = _RecordingTool();
    final provider = _ScriptedProvider([
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [
        const LlmTextDelta('adapted'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: [tool],
          provider: provider,
          config: AgentLoopConfig(
            approvalCallback: (t, a) async => const ToolGateDecision.deny(),
          ),
        )
        .toList();
    expect(tool.calls, isEmpty);
    final result = events.whereType<LoopToolCallResult>().single;
    expect(result.result.isError, isTrue);
    // A reasonless denial keeps the legacy wording, so recorded sessions with
    // denials stay byte-compatible.
    expect(result.result.content, contains('Denied by user'));
  });

  test(
    'a denial carries the policy reason and remediation to the model',
    () async {
      final tool = _RecordingTool();
      final provider = _ScriptedProvider([
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [
          const LlmTextDelta('adapted'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [tool],
            provider: provider,
            config: AgentLoopConfig(
              approvalCallback: (t, a) async => const ToolGateDecision.deny(
                reason: 'plan mode denies fileWriteOutsideWorktree',
                remediation: 'Call `submit_plan` instead.',
              ),
            ),
          )
          .toList();
      expect(tool.calls, isEmpty);
      final result = events.whereType<LoopToolCallResult>().single;
      expect(result.result.content, contains('plan mode denies'));
      expect(result.result.content, contains('submit_plan'));
    },
  );

  test('stops at maxTurns when the model keeps calling tools', () async {
    final tool = _RecordingTool();
    final provider = _ScriptedProvider([
      // One tool-calling entry per loop turn; the provider advances per call.
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      // The ceiling handoff turn: tool-free, prose only.
      [
        const LlmTextDelta('handoff: findings so far'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: [tool],
          provider: provider,
          config: const AgentLoopConfig(maxTurns: 3),
        )
        .toList();
    expect((events.last as LoopDone).reason, LoopDoneReason.maxTurns);
    // 3 loop turns + 1 tool-free handoff turn.
    expect(provider.calls, 4);
  });

  test('the ceiling handoff streams as answer text before LoopDone', () async {
    final tool = _RecordingTool();
    final provider = _ScriptedProvider([
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [
        const LlmTextDelta('handoff: findings so far'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: [tool],
          provider: provider,
          config: const AgentLoopConfig(maxTurns: 3),
        )
        .toList();
    final handoff = events.whereType<LoopTextDelta>().single;
    expect(handoff.text, 'handoff: findings so far');
    // The handoff precedes the terminal event, so the turn's persisted
    // content carries the findings a follow-up run rebuilds context from.
    expect(events.indexOf(handoff), lessThan(events.length - 1));
    expect((events.last as LoopDone).reason, LoopDoneReason.maxTurns);
  });

  test(
    'a scripted tool call in the handoff turn is ignored (prose-only)',
    () async {
      final tool = _RecordingTool();
      // No handoff script entry: the provider replays the tool-call turn and
      // the loop must not execute it — the handoff turn is tool-free by
      // construction.
      final provider = _ScriptedProvider([
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
      ]);
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [tool],
            provider: provider,
            config: const AgentLoopConfig(maxTurns: 3),
          )
          .toList();
      expect(tool.calls, hasLength(3));
      expect((events.last as LoopDone).reason, LoopDoneReason.maxTurns);
    },
  );

  test('cancellation stops the loop', () async {
    final source = CancellationTokenSource()..cancel();
    final provider = _ScriptedProvider([
      [
        const LlmTextDelta('x'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          cancel: source.token,
        )
        .toList();
    expect((events.last as LoopDone).reason, LoopDoneReason.cancelled);
  });

  test('a hung tool is bounded by the kernel tool timeout', () async {
    // There was NO kernel-level bound: `_safeExecute` caught throws but never
    // raced a deadline, so correctness rested entirely on each tool
    // self-limiting — and the runtime's own `bash` clamps a model-supplied
    // timeout at one HOUR.
    final provider = _ScriptedProvider([
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [
        const LlmTextDelta('after'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);

    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: [_HangingTool()],
          provider: provider,
          config: const AgentLoopConfig(
            maxTurns: 2,
            toolTimeout: Duration(milliseconds: 50),
          ),
        )
        .toList()
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => fail('a hung tool must not hold the turn forever'),
        );

    final toolResult = events.whereType<LoopToolCallResult>().single;
    expect(toolResult.result.isError, isTrue);
    expect(toolResult.result.content, contains('time limit'));
    // The loop moved ON rather than stalling.
    expect(events.last, isA<LoopDone>());
  });

  test('a hung tool also unblocks on cancellation', () async {
    final source = CancellationTokenSource();
    final provider = _ScriptedProvider([
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [
        const LlmTextDelta('after'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);

    final events = <AgentLoopEvent>[];
    final done = runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: [_HangingTool()],
          provider: provider,
          cancel: source.token,
          config: const AgentLoopConfig(maxTurns: 2),
        )
        .forEach(events.add);

    await pumpEventQueue();
    source.cancel();
    await done.timeout(
      const Duration(seconds: 5),
      onTimeout: () => fail('cancel must not wait on a hung tool'),
    );
    expect((events.last as LoopDone).reason, LoopDoneReason.cancelled);
  });

  test('cancelling a PAUSED run terminates it instead of hanging', () async {
    // Regression: the loop awaited `pauseGate.waitWhilePaused()` alone, which
    // only a `resume()` could wake. A cancel while paused woke nothing — the
    // stream stayed open, no LoopDone was ever emitted, and the run leaked
    // until somebody happened to resume it.
    final gate = PauseGate()..pause();
    final source = CancellationTokenSource();
    final provider = _ScriptedProvider([
      [
        const LlmTextDelta('x'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);

    final events = <AgentLoopEvent>[];
    final done = runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          cancel: source.token,
          config: AgentLoopConfig(pauseGate: gate),
        )
        .forEach(events.add);

    // Let it reach the gate, then cancel WITHOUT resuming.
    await pumpEventQueue();
    expect(
      events.whereType<LoopNotice>().any((n) => n.message.contains('Paused')),
      isTrue,
      reason: 'the loop must actually be holding at the boundary',
    );
    source.cancel();

    await done.timeout(
      const Duration(seconds: 5),
      onTimeout: () => fail('cancelling a paused run must not hang'),
    );
    expect((events.last as LoopDone).reason, LoopDoneReason.cancelled);
  });

  test('cancelling during retry backoff terminates promptly', () async {
    // The backoff slept up to 30s ignoring the token, so a cancelled run
    // stayed alive for the rest of the sleep — per attempt.
    final source = CancellationTokenSource();
    final provider = _ScriptedProvider([
      [const LlmError('rate', code: 'rate_limit_error', retryable: true)],
      [
        const LlmTextDelta('never reached'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);

    final events = <AgentLoopEvent>[];
    final done = runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          cancel: source.token,
          config: const AgentLoopConfig(maxProviderRetries: 2),
        )
        .forEach(events.add);

    await pumpEventQueue();
    source.cancel();
    await done.timeout(
      const Duration(seconds: 5),
      onTimeout: () => fail('a cancelled backoff must not run to completion'),
    );
    expect((events.last as LoopDone).reason, LoopDoneReason.cancelled);
  });

  test('retries a retryable provider error then succeeds', () async {
    final provider = _ScriptedProvider([
      [const LlmError('rate', code: 'rate_limit_error', retryable: true)],
      [
        const LlmTextDelta('recovered'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          config: const AgentLoopConfig(maxProviderRetries: 2),
        )
        .toList();
    expect(
      events.whereType<LoopTextDelta>().map((e) => e.text).join(),
      'recovered',
    );
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
  });

  test('hard token budget stops the loop', () async {
    final tool = _RecordingTool();
    final provider = _ScriptedProvider([
      [
        _toolCall('do_thing'),
        const LlmUsage(inputTokens: 100, outputTokens: 100),
        const LlmDone(stopReason: LlmStopReason.toolUse),
      ],
    ]);
    final events = await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: [tool],
          provider: provider,
          config: const AgentLoopConfig(budget: HarnessBudget(tokenBudget: 50)),
        )
        .toList();
    expect((events.last as LoopDone).reason, LoopDoneReason.budgetExhausted);
  });

  test(
    'budget overshoot on a turn cancels the NEXT turn, not the in-flight one',
    () async {
      // §9.2: a streaming turn can't be halted mid-flight, so a turn that
      // overshoots the budget (200 tokens vs a 50-token ceiling) is allowed to
      // finish — its tool runs. The end-of-iteration budget check then hard-stops
      // BEFORE the loop calls the provider again, so the second turn (which would
      // call the tool a second time) never starts. This pins the "post-turn
      // reconciliation cancels the next turn" contract: exactly one provider call,
      // exactly one tool execution.
      final tool = _RecordingTool();
      final provider = _ScriptedProvider([
        // Turn 1 — overshoots and calls the tool.
        [
          _toolCall('do_thing'),
          const LlmUsage(inputTokens: 100, outputTokens: 100),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        // Turn 2 — must NEVER run (would call the tool again).
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
      ]);

      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [tool],
            provider: provider,
            config: const AgentLoopConfig(
              budget: HarnessBudget(tokenBudget: 50),
            ),
          )
          .toList();

      expect((events.last as LoopDone).reason, LoopDoneReason.budgetExhausted);
      expect(
        provider.calls,
        1,
        reason: 'the next turn must be cancelled, never started',
      );
      expect(
        tool.calls.length,
        1,
        reason: 'the cancelled turn 2 must not re-run the tool',
      );
    },
  );

  test(
    'externalBudgetExceeded stops the loop at the first turn boundary',
    () async {
      // The dispatch layer's priced cost cap rides this hook; with no turn
      // ceiling and no HarnessBudget it is the ONLY automatic stop for an
      // autonomous run on a priced model, so it must fire after turn 1's
      // tools — before the provider is called again.
      final tool = _RecordingTool();
      final provider = _ScriptedProvider([
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        // Turn 2 must NEVER run.
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
      ]);
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [tool],
            provider: provider,
            config: AgentLoopConfig(externalBudgetExceeded: () => true),
          )
          .toList();
      expect((events.last as LoopDone).reason, LoopDoneReason.budgetExhausted);
      expect(provider.calls, 1);
      expect(tool.calls.length, 1);
    },
  );

  test('externalBudgetPressure steers once, then the loop continues', () async {
    // The soft poll fires at ~80% of the host's cap: the model gets one
    // wrap-up steer so it leaves a clean handoff before the hard check ends
    // the run mid-task. The steer must not itself stop the loop.
    final tool = _RecordingTool();
    var pressure = false;
    final provider = _ScriptedProvider([
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [_toolCall('do_thing'), const LlmDone(stopReason: LlmStopReason.toolUse)],
      [
        const LlmTextDelta('done'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final history = <HarnessMessage>[];
    final events = await runner
        .run(
          history: history,
          userMessage: 'go',
          tools: [tool],
          provider: provider,
          config: AgentLoopConfig(
            externalBudgetPressure: () {
              final fired = pressure;
              pressure = true;
              return !fired; // true on the first poll, false after.
            },
          ),
        )
        .toList();
    expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    expect(provider.calls, 3, reason: 'the steer must not stop the loop');
    expect(
      history
          .where((m) => m.role == HarnessRole.system)
          .map((m) => m.textContent)
          .join('\n'),
      contains('approaching this run'),
    );
    expect(
      events.whereType<LoopNotice>().where(
        (e) => e.message.contains('approaching'),
      ),
      hasLength(1),
      reason: 'the pressure steer is one-shot',
    );
  });

  test(
    'the default config has no turn ceiling (runs past the legacy 50)',
    () async {
      // 55 tool turns then a natural end: a 50-turn ceiling would have cut
      // this run at turn 50 with LoopDoneReason.maxTurns; the uncapped default
      // must let it finish on its own.
      final tool = _RecordingTool();
      final provider = _ScriptedProvider([
        for (var i = 0; i < 55; i++)
          [
            _toolCall('do_thing', {'step': i}),
            const LlmDone(stopReason: LlmStopReason.toolUse),
          ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await runner
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: [tool],
            provider: provider,
          )
          .toList();
      expect((events.last as LoopDone).reason, LoopDoneReason.completed);
      expect(provider.calls, 56);
      expect(tool.calls.length, 55);
    },
  );

  test('period-1 repetition injects a corrective reminder', () async {
    // Identical tool calls (same args) three turns running: the guard nudges
    // the model instead of letting it spin forever now that no turn ceiling
    // bounds the loop.
    final tool = _RecordingTool();
    final provider = _ScriptedProvider([
      for (var i = 0; i < 4; i++)
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
      [
        const LlmTextDelta('ok'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ],
    ]);
    final history = <HarnessMessage>[];
    final events = await runner
        .run(
          history: history,
          userMessage: 'go',
          tools: [tool],
          provider: provider,
        )
        .toList();
    expect(
      events.whereType<LoopNotice>().map((e) => e.message),
      contains(contains('Repetition detected')),
    );
    expect(
      history
          .where((m) => m.role == HarnessRole.system)
          .map((m) => m.textContent)
          .join('\n'),
      contains('repeated the same tool call'),
    );
  });

  test(
    'period-2 (A-B-A-B) alternation injects a corrective reminder',
    () async {
      // The ping-pong a period-1 check never sees: two different arg sets
      // alternating. Fires on the fourth return-to-two-back (three cycles).
      final tool = _RecordingTool();
      final provider = _ScriptedProvider([
        for (var i = 0; i < 6; i++)
          [
            _toolCall('do_thing', {'variant': i.isEven ? 'a' : 'b'}),
            const LlmDone(stopReason: LlmStopReason.toolUse),
          ],
        [
          const LlmTextDelta('ok'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final history = <HarnessMessage>[];
      final events = await runner
          .run(
            history: history,
            userMessage: 'go',
            tools: [tool],
            provider: provider,
          )
          .toList();
      expect(
        events.whereType<LoopNotice>().map((e) => e.message),
        contains(contains('Repetition detected')),
      );
      expect(
        history
            .where((m) => m.role == HarnessRole.system)
            .map((m) => m.textContent)
            .join('\n'),
        contains('ping-pong loop'),
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Tool-output budgets. Both are applied by the LOOP, at the point where a
  // result becomes a transcript message, rather than by each tool: a tool that
  // dumps a DOM should not have to know the transcript's economics, and a
  // bridged MCP tool could not know them at all. The per-tool table was
  // documented (and tested as a pure function) long before anything called it.
  // ---------------------------------------------------------------------------
  group('tool output budgets', () {
    test('over-long tool text is truncated in the TRANSCRIPT', () async {
      // 60k > the 50k default character cap.
      final tool = _RecordingTool(result: 'x' * 60000);
      final provider = _ScriptedProvider([
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final history = <HarnessMessage>[];
      final events = await runner
          .run(
            history: history,
            userMessage: 'go',
            tools: [tool],
            provider: provider,
          )
          .toList();

      final block = history
          .expand((m) => m.content)
          .whereType<HarnessToolResultBlock>()
          .single;
      expect(block.content.length, lessThan(60000));
      expect(block.content, contains('characters omitted'));

      // The UI still gets the whole thing: a human looking at a run wants what
      // actually happened, not the model's budgeted copy.
      final surfaced = events.whereType<LoopToolCallResult>().single;
      expect(surfaced.result.content.length, 60000);
    });

    test('tool text within budget is passed through untouched', () async {
      final tool = _RecordingTool(result: 'short and sweet');
      final provider = _ScriptedProvider([
        [
          _toolCall('do_thing'),
          const LlmDone(stopReason: LlmStopReason.toolUse),
        ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final history = <HarnessMessage>[];
      await runner
          .run(
            history: history,
            userMessage: 'go',
            tools: [tool],
            provider: provider,
          )
          .toList();

      expect(
        history
            .expand((m) => m.content)
            .whereType<HarnessToolResultBlock>()
            .single
            .content,
        'short and sweet',
      );
    });
  });

  group('malformed tool-call arguments', () {
    // A model can emit truncated or malformed JSON — a mid-stream cutoff, a
    // stray token, a top-level array. Decoding used to swallow that into `{}`,
    // so the call RAN and each argument surfaced as its own "missing
    // argument" error inside the tool: the model saw a plausible tool failure
    // and no signal that its own JSON was the problem, so it re-emitted the
    // same broken call.
    Future<List<AgentLoopEvent>> runWith(
      String argumentsJson,
      HarnessTool tool,
    ) => const AgentLoopRunner()
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: [tool],
          provider: _ScriptedProvider([
            [
              LlmToolUseDelta(
                id: 'tc_1',
                name: 'do_thing',
                argumentsJson: argumentsJson,
              ),
              const LlmDone(stopReason: LlmStopReason.toolUse),
            ],
            [
              const LlmTextDelta('ok'),
              const LlmDone(stopReason: LlmStopReason.endTurn),
            ],
          ]),
        )
        .toList();

    test('truncated JSON is reported, and the tool never runs', () async {
      final tool = _RecordingTool();
      final events = await runWith('{"path": "a/b/c', tool);

      expect(tool.calls, isEmpty, reason: 'the call must not be dispatched');
      final result = events.whereType<LoopToolCallResult>().single;
      expect(result.result.isError, isTrue);
      expect(result.result.content, contains('not valid JSON'));
      expect(
        result.result.content,
        contains('a/b/c'),
        reason: 'the model needs to see WHAT it emitted to repair it',
      );
    });

    test('a non-object payload is reported as such', () async {
      final tool = _RecordingTool();
      final events = await runWith('[1, 2, 3]', tool);

      expect(tool.calls, isEmpty);
      final result = events.whereType<LoopToolCallResult>().single;
      expect(result.result.isError, isTrue);
      expect(result.result.content, contains('must be a JSON object'));
    });

    test('an empty payload is still a valid zero-argument call', () async {
      final tool = _RecordingTool();
      await runWith('', tool);

      expect(tool.calls, [
        <String, dynamic>{},
      ], reason: 'a zero-arg tool legitimately emits no arguments');
    });

    test(
      'the excerpt is bounded so a runaway blob cannot flood context',
      () async {
        final tool = _RecordingTool();
        final events = await runWith('{"k": "${'x' * 5000}"', tool);

        final content = events
            .whereType<LoopToolCallResult>()
            .single
            .result
            .content;
        expect(content.length, lessThan(400));
        expect(content, endsWith('\u2026'));
      },
    );
  });

  group('per-turn wall-clock cap', () {
    // The transport's timeout is an IDLE timeout and resets on every chunk, so
    // a stream dripping one byte every 100s trips nothing: the turn never
    // ends, the turn-BOUNDARY budget checks never run, and the run holds
    // resources open forever having spent almost no tokens.
    test('a dripping stream is abandoned instead of running forever', () async {
      final events = await const AgentLoopRunner()
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: const [],
            provider: const _DrippingProvider(
              gap: Duration(milliseconds: 20),
              chunks: 100,
            ),
            config: const AgentLoopConfig(
              turnTimeout: Duration(milliseconds: 60),
            ),
          )
          .toList();

      expect(events.last, isA<LoopDone>());
      expect((events.last as LoopDone).reason, LoopDoneReason.error);
      expect(
        events.whereType<LoopNotice>().map((e) => e.message).join(),
        contains('wall-clock'),
        reason: 'the run has to say WHY it stopped, or it reads as a crash',
      );
      // It stopped early: nowhere near all 100 chunks were delivered.
      expect(events.whereType<LoopTextDelta>().length, lessThan(100));
    });

    test('a normal turn is unaffected', () async {
      final events = await const AgentLoopRunner()
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: const [],
            provider: _ScriptedProvider([
              [
                const LlmTextDelta('done'),
                const LlmDone(stopReason: LlmStopReason.endTurn),
              ],
            ]),
            config: const AgentLoopConfig(turnTimeout: Duration(minutes: 30)),
          )
          .toList();

      expect((events.last as LoopDone).reason, LoopDoneReason.completed);
    });

    test('null disables the cap', () async {
      final events = await const AgentLoopRunner()
          .run(
            history: <HarnessMessage>[],
            userMessage: 'go',
            tools: const [],
            provider: const _DrippingProvider(
              gap: Duration(milliseconds: 5),
              chunks: 4,
            ),
            config: const AgentLoopConfig(),
          )
          .toList();

      expect((events.last as LoopDone).reason, LoopDoneReason.completed);
      expect(events.whereType<LoopTextDelta>().length, 4);
    });
  });
}

/// Emits [chunks] tiny text deltas [gap] apart, then finishes — a slow-loris
/// provider stream in miniature.
class _DrippingProvider implements LlmProviderPort {
  const _DrippingProvider({required this.gap, required this.chunks});

  final Duration gap;
  final int chunks;

  @override
  String get displayName => 'Dripping';
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
    for (var i = 0; i < chunks; i++) {
      await Future<void>.delayed(gap);
      yield const LlmTextDelta('.');
    }
    yield const LlmDone(stopReason: LlmStopReason.endTurn);
  }
}
