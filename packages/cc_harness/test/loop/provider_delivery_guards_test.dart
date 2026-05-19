import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// A provider that replays one scripted list of [LlmEvent]s per `complete()`
/// call, repeating the last entry once the script runs out.
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

/// The loop's two provider-delivery guards.
///
/// Both exist because a provider failure used to be indistinguishable from the
/// model finishing its turn — the worst available reading, since it reports
/// someone else's fault as a completed answer.
void main() {
  Future<List<AgentLoopEvent>> drain(
    _ScriptedProvider provider, {
    AgentLoopConfig config = const AgentLoopConfig(maxTurns: 4),
  }) => const AgentLoopRunner()
      .run(
        history: [],
        userMessage: 'go',
        tools: const <HarnessTool>[],
        provider: provider,
        config: config,
      )
      .toList();

  group('empty-stream guard', () {
    test('an empty stream is retried, not banked as a finished turn', () async {
      // Nothing at all: no content, no tool call, no error, no stop reason —
      // the shape a local server returns when its tool-call parser aborts.
      final provider = _ScriptedProvider([
        [const LlmDone()],
        [
          const LlmTextDelta('recovered'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await drain(provider);

      expect(provider.calls, 2, reason: 'the empty turn must be retried');
      expect(
        events.whereType<LoopNotice>().map((e) => e.message).join(),
        contains('empty_response'),
      );
      expect(
        events.whereType<LoopDone>().single.reason,
        LoopDoneReason.completed,
      );
    });

    test('a persistently empty stream fails the run out loud', () async {
      final provider = _ScriptedProvider([
        [const LlmDone()],
      ]);
      final events = await drain(
        provider,
        config: const AgentLoopConfig(maxTurns: 4, maxProviderRetries: 1),
      );

      final error = events.whereType<LoopError>().single;
      expect(error.code, 'empty_response');
      expect(error.message, contains('empty response'));
      expect(events.whereType<LoopDone>().single.reason, LoopDoneReason.error);
    });

    test('a turn that stopped cleanly with no text is NOT flagged', () async {
      // An explicit `stop` with empty content is a real (if terse) answer. Only
      // the absence of a stop reason marks a transport failure.
      final provider = _ScriptedProvider([
        [const LlmDone(stopReason: LlmStopReason.endTurn)],
      ]);
      final events = await drain(provider);

      expect(provider.calls, 1);
      expect(events.whereType<LoopError>(), isEmpty);
      expect(
        events.whereType<LoopDone>().single.reason,
        LoopDoneReason.completed,
      );
    });

    test('a stream that delivered only thinking is NOT flagged', () async {
      final provider = _ScriptedProvider([
        [const LlmThinkingDelta('pondering'), const LlmDone()],
      ]);
      final events = await drain(provider);

      expect(provider.calls, 1);
      expect(events.whereType<LoopError>(), isEmpty);
    });
  });

  group('output-loss guard', () {
    test(
      'tokens billed with nothing delivered ends the run, not a retry',
      () async {
        // The production signature: thousands of output tokens, a truncated turn,
        // and two newlines to show for it. Re-rolling the same ceiling reproduces
        // it exactly, which is how one run burned four turns this way.
        final provider = _ScriptedProvider([
          [
            const LlmTextDelta('\n\n'),
            const LlmUsage(outputTokens: 8192),
            const LlmDone(stopReason: LlmStopReason.maxTokens),
          ],
        ]);
        final events = await drain(provider);

        expect(provider.calls, 1, reason: 'must not re-roll the same ceiling');
        final error = events.whereType<LoopError>().single;
        expect(error.code, 'provider_output_lost');
        expect(error.message, contains('8192'));
        expect(
          events.whereType<LoopDone>().single.reason,
          LoopDoneReason.providerOutputLost,
        );
      },
    );

    test(
      'a truncated turn that DID deliver text is continued as before',
      () async {
        // The legitimate case the truncation-continue feature exists for: a long
        // answer cut off mid-sentence. 400 tokens against ~2000 characters is a
        // normal ratio, so the guard must stay out of the way.
        final provider = _ScriptedProvider([
          [
            LlmTextDelta('x' * 2000),
            const LlmUsage(outputTokens: 400),
            const LlmDone(stopReason: LlmStopReason.maxTokens),
          ],
          [
            const LlmTextDelta('...and the rest.'),
            const LlmDone(stopReason: LlmStopReason.endTurn),
          ],
        ]);
        final events = await drain(provider);

        expect(provider.calls, 2, reason: 'the continue path must still work');
        expect(
          events.whereType<LoopNotice>().map((e) => e.message).join(),
          contains('truncated at the output limit'),
        );
        expect(events.whereType<LoopError>(), isEmpty);
      },
    );

    test('a small truncated turn is below the check threshold', () async {
      // Too few tokens for a ratio to mean anything; continuing is right.
      final provider = _ScriptedProvider([
        [
          const LlmTextDelta(''),
          const LlmUsage(outputTokens: 40),
          const LlmDone(stopReason: LlmStopReason.maxTokens),
        ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await drain(provider);

      expect(events.whereType<LoopError>(), isEmpty);
      expect(provider.calls, 2);
    });

    test('thinking counts as delivered output', () async {
      // Reasoning arriving on a separate channel is still the provider handing
      // us what it billed for.
      final provider = _ScriptedProvider([
        [
          LlmThinkingDelta('t' * 3000),
          const LlmUsage(outputTokens: 600),
          const LlmDone(stopReason: LlmStopReason.maxTokens),
        ],
        [
          const LlmTextDelta('done'),
          const LlmDone(stopReason: LlmStopReason.endTurn),
        ],
      ]);
      final events = await drain(provider);

      expect(events.whereType<LoopError>(), isEmpty);
    });
  });
}
