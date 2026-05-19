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
      // No handoff script entry: the provider replays the tool-call turn, and
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
}
