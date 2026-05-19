import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/context/llm_harness_summarizer.dart';
import 'package:test/test.dart';

/// Exercises [LlmHarnessSummarizer] — the LLM-backed anchored summary that
/// drains the provider's completion stream and falls back to the deterministic
/// structural summarizer on any error or empty output. The provider is faked
/// so no network runs; covers: success (text emitted), empty → fallback,
/// error mid-stream → fallback, and the previous-summary branch.
void main() {
  HarnessCompactionInput input({String? previousSummary}) =>
      HarnessCompactionInput(
        messages: [
          HarnessMessage.user('hello'),
          HarnessMessage.assistant('hi'),
        ],
        previousSummary: previousSummary,
        selfAgentName: 'Pi',
      );

  group('LlmHarnessSummarizer.summarize', () {
    test('returns the provider-emitted text when non-empty', () async {
      final s = LlmHarnessSummarizer(
        _FakeProvider([
          const LlmTextDelta('anchored '),
          const LlmTextDelta('summary'),
        ]),
      );
      expect(await s.summarize(input()), 'anchored summary');
    });

    test(
      'falls back to the structural summarizer on an empty stream',
      () async {
        final s = LlmHarnessSummarizer(_FakeProvider(const []));
        final out = await s.summarize(input());
        // Structural fallback is non-empty and deterministic.
        expect(out, isNotEmpty);
      },
    );

    test('falls back when the provider stream emits an error', () async {
      final s = LlmHarnessSummarizer(
        _FakeProvider([const LlmError('rate limited')]),
      );
      final out = await s.summarize(input());
      expect(out, isNotEmpty);
    });

    test('falls back when the provider throws outright', () async {
      final s = LlmHarnessSummarizer(_ThrowingProvider());
      final out = await s.summarize(input());
      expect(out, isNotEmpty);
    });

    test('honors a previous summary (renders the update branch)', () async {
      // Provider emits an updated summary that incorporates the prior context.
      final s = LlmHarnessSummarizer(
        _FakeProvider([const LlmTextDelta('updated summary')]),
      );
      final out = await s.summarize(input(previousSummary: 'old summary'));
      expect(out, 'updated summary');
    });
  });
}

class _FakeProvider implements LlmProviderPort {
  _FakeProvider(this.events);
  final List<LlmEvent> events;

  @override
  String get displayName => 'Fake';

  @override
  String get defaultModel => 'fake-1';

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema>? tools,
    LlmCompleteConfig? config,
  }) {
    return Stream<LlmEvent>.fromIterable(events);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingProvider implements LlmProviderPort {
  @override
  String get displayName => 'Throwing';

  @override
  String get defaultModel => 'throw-1';

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema>? tools,
    LlmCompleteConfig? config,
  }) => throw StateError('provider exploded');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
