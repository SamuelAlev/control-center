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
  String get displayName => 'S';
  @override
  String get defaultModel => 'm';
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

class _NoopTool extends HarnessTool {
  @override
  String get name => 'checkpoint';
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  String get description => 'x';
  @override
  Map<String, dynamic> get inputSchema => {'type': 'object'};
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> a,
    HarnessToolContext c,
  ) async => HarnessToolResult.error('loop-handled');
}

void main() {
  const runner = AgentLoopRunner();

  test('rewind prunes exploration back to the task and continues', () async {
    // Turn 1: explore with a tool. Turn 2: rewind. Turn 3: finish.
    final provider = _Provider([
      [
        const LlmTextDelta('exploring'),
        const LlmToolUseDelta(
          id: 'e1',
          name: 'checkpoint',
          argumentsJson: '{}',
        ),
        const LlmDone(),
      ],
      [
        const LlmToolUseDelta(id: 'r1', name: 'rewind', argumentsJson: '{}'),
        const LlmDone(),
      ],
      [const LlmTextDelta('final answer'), const LlmDone()],
    ]);
    final history = <HarnessMessage>[];
    final events = await runner
        .run(
          history: history,
          userMessage: 'do the task',
          tools: [_NoopTool()],
          provider: provider,
          config: const AgentLoopConfig(),
        )
        .toList();

    // After the run: history starts with the original task, and the
    // exploration turns were pruned + replaced by a rewind marker.
    expect(history.first.role, HarnessRole.user);
    expect(history.first.textContent, 'do the task');
    expect(history.any((m) => m.textContent.contains('Rewound')), isTrue);
    expect(
      events.whereType<LoopNotice>().any((n) => n.message.contains('Rewound')),
      isTrue,
    );
    // The loop reached a normal completion after the rewind.
    expect(events.whereType<LoopDone>().last.reason, LoopDoneReason.completed);
    expect(events.whereType<LoopTextDelta>().last.text, 'final answer');
  });

  test('rewind re-primes the advisor (its cursor was left in a rewritten '
      'timeline)', () async {
    final advisor = _ResetRecordingAdvisor();
    final provider = _Provider([
      [
        const LlmTextDelta('exploring'),
        const LlmToolUseDelta(
          id: 'e1',
          name: 'checkpoint',
          argumentsJson: '{}',
        ),
        const LlmDone(),
      ],
      [
        const LlmToolUseDelta(id: 'r1', name: 'rewind', argumentsJson: '{}'),
        const LlmDone(),
      ],
      [const LlmTextDelta('final answer'), const LlmDone()],
    ]);
    await runner
        .run(
          history: <HarnessMessage>[],
          userMessage: 'do the task',
          tools: [_NoopTool()],
          provider: provider,
          config: AgentLoopConfig(advisor: advisor),
        )
        .toList();
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
