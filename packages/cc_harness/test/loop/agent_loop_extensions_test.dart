import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

class _Provider implements LlmProviderPort {
  _Provider(this.script);
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

class _EchoTool extends HarnessTool {
  int runs = 0;
  @override
  String get name => 'do_thing';
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  String get description => 'x';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    runs++;
    return HarnessToolResult.success('ran');
  }
}

class _DenyHooks implements AgentLoopHooks {
  bool started = false;
  final List<String> post = [];
  @override
  bool get interceptsTools => true;
  @override
  Future<void> onSessionStart() async => started = true;
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async =>
      false;
  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async => post.add('$toolName:$isError');
}

/// Hooks that throw at every extension point.
class _ThrowingHooks implements AgentLoopHooks {
  _ThrowingHooks({
    this.onStart = false,
    this.onPre = false,
    this.onPost = false,
  });

  final bool onStart;
  final bool onPre;
  final bool onPost;

  @override
  bool get interceptsTools => true;

  @override
  Future<void> onSessionStart() async {
    if (onStart) {
      throw StateError('hook exploded');
    }
  }

  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    if (onPre) {
      throw StateError('gate exploded');
    }
    return true;
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async {
    if (onPost) {
      throw StateError('observer exploded');
    }
  }
}

/// An advisor that throws instead of reviewing.
class _ThrowingAdvisor implements Advisor {
  @override
  Future<AdvisorNote?> review(List<HarnessMessage> history) async =>
      throw StateError('advisor exploded');

  @override
  void reset() {}
}

class _OnceAdvisor implements Advisor {
  int calls = 0;
  @override
  Future<AdvisorNote?> review(List<HarnessMessage> history) async {
    calls++;
    return calls == 1 ? const AdvisorNote('consider edge cases') : null;
  }

  @override
  void reset() {}
}

void main() {
  const runner = AgentLoopRunner();

  test('a denying hook blocks the tool and feeds an error result', () async {
    final tool = _EchoTool();
    final hooks = _DenyHooks();
    final provider = _Provider([
      [
        const LlmToolUseDelta(id: 't1', name: 'do_thing', argumentsJson: '{}'),
        const LlmDone(),
      ],
      [const LlmTextDelta('done'), const LlmDone()],
    ]);
    final events = await runner
        .run(
          history: [],
          userMessage: 'go',
          tools: [tool],
          provider: provider,
          config: AgentLoopConfig(hooks: hooks),
        )
        .toList();
    expect(hooks.started, isTrue);
    expect(tool.runs, 0); // denied → never executed
    expect(hooks.post.single, 'do_thing:true'); // post-hook saw the error
    final result = events.whereType<LoopToolCallResult>().single;
    expect(result.result.isError, isTrue);
  });

  group('a throwing extension point never breaks the terminal contract', () {
    // The loop's documented contract is "exactly one LoopDone (or LoopError
    // then LoopDone)". These are HOST-supplied implementations: an exception
    // escaping the `async*` generator used to surface as a bare stream error
    // with no terminal event at all, leaving the caller's `history` already
    // mutated and nothing to say the run was over.
    Future<List<AgentLoopEvent>> runWith(AgentLoopConfig config) => runner
        .run(
          history: [],
          userMessage: 'go',
          tools: [_EchoTool()],
          provider: _Provider([
            [
              const LlmToolUseDelta(
                id: 't1',
                name: 'do_thing',
                argumentsJson: '{}',
              ),
              const LlmDone(),
            ],
            [const LlmTextDelta('done'), const LlmDone()],
          ]),
          config: config,
        )
        .toList();

    test('onSessionStart failure ends the run with an error + done', () async {
      final events = await runWith(
        AgentLoopConfig(hooks: _ThrowingHooks(onStart: true)),
      );
      expect(events.whereType<LoopError>(), hasLength(1));
      expect(events.last, isA<LoopDone>());
      expect((events.last as LoopDone).reason, LoopDoneReason.error);
    });

    test('a throwing preToolUse gate DENIES rather than killing the run',
        () async {
      final tool = _EchoTool();
      final events = await runner
          .run(
            history: [],
            userMessage: 'go',
            tools: [tool],
            provider: _Provider([
              [
                const LlmToolUseDelta(
                  id: 't1',
                  name: 'do_thing',
                  argumentsJson: '{}',
                ),
                const LlmDone(),
              ],
              [const LlmTextDelta('done'), const LlmDone()],
            ]),
            config: AgentLoopConfig(hooks: _ThrowingHooks(onPre: true)),
          )
          .toList();
      expect(tool.runs, 0, reason: 'a gate that cannot answer is not consent');
      expect(events.whereType<LoopToolCallResult>().single.result.isError, isTrue);
      expect(events.last, isA<LoopDone>());
    });

    test('a throwing postToolUse observer does not undo a finished call',
        () async {
      final events = await runWith(
        AgentLoopConfig(hooks: _ThrowingHooks(onPost: true)),
      );
      expect(
        events.whereType<LoopToolCallResult>().single.result.isError,
        isFalse,
      );
      expect(events.last, isA<LoopDone>());
    });

    test('a throwing advisor costs the note, not the run', () async {
      final events = await runWith(
        AgentLoopConfig(advisor: _ThrowingAdvisor(), advisorEveryTurns: 1),
      );
      expect(events.whereType<LoopAdvisorNote>(), isEmpty);
      expect(
        events.whereType<LoopNotice>().any((n) => n.message.contains('Advisor')),
        isTrue,
      );
      expect(events.last, isA<LoopDone>());
    });
  });

  test('a stream rule aborts and restarts the turn with a reminder', () async {
    final provider = _Provider([
      [const LlmTextDelta('I will use Box::leak here'), const LlmDone()],
      [const LlmTextDelta('Using Arc instead.'), const LlmDone()],
    ]);
    final events = await runner
        .run(
          history: [],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          config: const AgentLoopConfig(
            streamRules: [
              StreamRule(
                pattern: 'Box::leak',
                reminder: 'Do not use Box::leak; use Arc.',
              ),
            ],
          ),
        )
        .toList();
    expect(provider.calls, 2); // restarted once
    expect(
      events.whereType<LoopNotice>().any((n) => n.message.contains('Arc')),
      isTrue,
    );
    final done = events.whereType<LoopDone>().single;
    expect(done.reason, LoopDoneReason.completed);
  });

  test('an advisor injects a note after a turn', () async {
    final tool = _EchoTool();
    final advisor = _OnceAdvisor();
    final provider = _Provider([
      [
        const LlmToolUseDelta(id: 't1', name: 'do_thing', argumentsJson: '{}'),
        const LlmDone(),
      ],
      [const LlmTextDelta('all done'), const LlmDone()],
    ]);
    final events = await runner
        .run(
          history: [],
          userMessage: 'go',
          tools: [tool],
          provider: provider,
          config: AgentLoopConfig(advisor: advisor),
        )
        .toList();
    expect(advisor.calls, greaterThanOrEqualTo(1));
    expect(
      events.whereType<LoopAdvisorNote>().single.note,
      'consider edge cases',
    );
  });

  test(
    'an advisor note is framed as an <advisory> block with its severity',
    () async {
      final tool = _EchoTool();
      final advisor = _BlockerAdvisor();
      final provider = _Provider([
        [
          const LlmToolUseDelta(
            id: 't1',
            name: 'do_thing',
            argumentsJson: '{}',
          ),
          const LlmDone(),
        ],
        [const LlmTextDelta('all done'), const LlmDone()],
      ]);
      final history = <HarnessMessage>[];
      final events = await runner
          .run(
            history: history,
            userMessage: 'go',
            tools: [tool],
            provider: provider,
            config: AgentLoopConfig(advisor: advisor),
          )
          .toList();
      // The event carries the severity through to the UI layer.
      expect(
        events.whereType<LoopAdvisorNote>().single.severity,
        AdvisorSeverity.blocker,
      );
      // And the loop injected it into history as a framed advisory the model
      // will see next turn.
      final injected = history
          .where((m) => m.role == HarnessRole.system)
          .map((m) => m.textContent)
          .firstWhere((t) => t.contains('<advisory'), orElse: () => '');
      expect(injected, contains('severity="blocker"'));
      expect(injected, contains('you left a resource open'));
    },
  );
}

class _BlockerAdvisor implements Advisor {
  int calls = 0;
  @override
  Future<AdvisorNote?> review(List<HarnessMessage> history) async {
    calls++;
    return calls == 1
        ? const AdvisorNote(
            'you left a resource open',
            severity: AdvisorSeverity.blocker,
          )
        : null;
  }

  @override
  void reset() {}
}
