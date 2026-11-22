import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

class _Scripted extends LlmProviderPort {
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

/// Summarizes once (asking for its focus, as a real summarizer does right
/// before it writes) when [onlyForced] allows; a structural compactor never
/// asks.
class _Summarizer implements HarnessCompactor {
  _Summarizer({required this.summarizes, this.onlyForced = false});
  final bool summarizes;
  final bool onlyForced;
  int passes = 0;

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
    if ((onlyForced && !force) || passes > 0) {
      return const HarnessCompactionResult.unchanged(0);
    }
    passes++;
    if (summarizes) {
      await focus?.call();
    }
    return HarnessCompactionResult(
      changed: true,
      summarized: summarizes,
      messagesFolded: 1,
      tokensBefore: 10,
      tokensAfter: 5,
    );
  }

  @override
  int pruneToolResults(List<HarnessMessage> history, {bool force = false}) => 0;
}

const _done = LlmDone(stopReason: LlmStopReason.endTurn);

/// The loop says when a compaction that summarizes starts and ends
/// (`LoopCompacting`), so `agent_activity` can report it; a structural
/// pass is not announced.
void main() {
  const runner = AgentLoopRunner();

  Future<List<AgentLoopEvent>> run(
    HarnessCompactor compactor,
    List<List<LlmEvent>> script,
  ) => runner
      .run(
        history: <HarnessMessage>[],
        userMessage: 'task',
        tools: const [],
        provider: _Scripted(script),
        config: AgentLoopConfig(
          compaction: LoopCompactionConfig(
            contextWindow: 1000,
            compactor: compactor,
          ),
        ),
      )
      .toList();

  List<bool> compacting(List<AgentLoopEvent> events) => [
    for (final e in events.whereType<LoopCompacting>()) e.started,
  ];

  test('a summarizing pass near the window is bracketed', () async {
    final events = await run(_Summarizer(summarizes: true), [
      [const LlmTextDelta('done'), _done],
    ]);
    expect(compacting(events), [true, false]);
    final start = events.indexWhere((e) => e is LoopCompacting && e.started);
    final end = events.indexWhere((e) => e is LoopCompacting && !e.started);
    final folded = events.indexWhere((e) => e is LoopCompaction);
    expect(start, lessThan(end));
    expect(end, lessThan(folded));
  });

  test('a summarizing overflow recovery is bracketed', () async {
    final events = await run(_Summarizer(summarizes: true, onlyForced: true), [
      [
        const LlmError(
          'prompt is too long: 300000 tokens > 200000 maximum',
          code: 'invalid_request_error',
        ),
      ],
      [const LlmTextDelta('done'), _done],
    ]);
    expect(compacting(events), [true, false]);
    expect((events.last as LoopDone).reason, isNot(LoopDoneReason.error));
  });

  test('a structural pass is not announced', () async {
    final events = await run(_Summarizer(summarizes: false), [
      [const LlmTextDelta('done'), _done],
    ]);
    expect(compacting(events), isEmpty);
  });
}
