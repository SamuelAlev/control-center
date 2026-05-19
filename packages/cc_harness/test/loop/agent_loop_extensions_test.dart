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
