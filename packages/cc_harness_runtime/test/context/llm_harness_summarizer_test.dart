import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/context/llm_harness_summarizer.dart';
import 'package:test/test.dart';

/// Exercises [LlmHarnessSummarizer] — the LLM-backed anchored summary that
/// drains the provider's completion stream and falls back to the deterministic
/// structural summarizer on any error or empty output. The provider is faked
/// so no network runs; covers: success (text emitted), empty → fallback,
/// error mid-stream → fallback and the previous-summary branch.
void main() {
  HarnessCompactionInput input({String? previousSummary}) =>
      HarnessCompactionInput(
        messages: [
          HarnessMessage.user('hello'),
          HarnessMessage.assistant('hi'),
        ],
        previousSummary: previousSummary,
        selfAgentName: 'architect',
      );

  group('LlmHarnessSummarizer.summarize', () {
    test('returns the provider-emitted text when non-empty', () async {
      final s = LlmHarnessSummarizer(
        _FakeProvider([
          const LlmTextDelta('anchored '),
          const LlmTextDelta('summary'),
        ]),
      );
      final out = await s.summarize(input());
      // The model's text, after the pinned evidence the server re-attaches.
      expect(out.text, endsWith('\n\nanchored summary'));
      expect(out.modelWritten, isTrue);
    });

    test(
      'falls back to the structural summarizer on an empty stream',
      () async {
        final s = LlmHarnessSummarizer(_FakeProvider(const []));
        final out = await s.summarize(input());
        // Structural fallback is non-empty and deterministic, and says so.
        expect(out.text, isNotEmpty);
        expect(out.modelWritten, isFalse);
      },
    );

    test('falls back when the provider stream emits an error', () async {
      final s = LlmHarnessSummarizer(
        _FakeProvider([const LlmError('rate limited')]),
      );
      final out = await s.summarize(input());
      expect(out.text, isNotEmpty);
      expect(out.modelWritten, isFalse);
    });

    test('falls back when the provider throws outright', () async {
      final s = LlmHarnessSummarizer(_ThrowingProvider());
      final out = await s.summarize(input());
      expect(out.text, isNotEmpty);
      expect(out.modelWritten, isFalse);
    });

    test('honors a previous summary (renders the update branch)', () async {
      // Provider emits an updated summary that incorporates the prior context.
      final s = LlmHarnessSummarizer(
        _FakeProvider([const LlmTextDelta('updated summary')]),
      );
      final out = await s.summarize(input(previousSummary: 'old summary'));
      expect(out.text, endsWith('\n\nupdated summary'));
    });

    group('pinned evidence (defect 23)', () {
      test('the original request and the steering are re-attached', () async {
        final s = LlmHarnessSummarizer(
          _FakeProvider([const LlmTextDelta('The agent fixed two tests.')]),
        );
        final out = await s.summarize(
          HarnessCompactionInput(
            messages: [
              HarnessMessage.user('Fix the flaky login test. Do not touch CI.'),
              HarnessMessage.assistant('Looking.'),
              HarnessMessage.system('Stay inside packages/auth.'),
              HarnessMessage.assistant('Done.'),
            ],
          ),
        );
        expect(out.modelWritten, isTrue);
        final pinned = splitPinnedEvidence(out.text);
        expect(pinned.pinned, contains('# User (original request)'));
        expect(
          pinned.pinned,
          contains('Fix the flaky login test. Do not touch CI.'),
        );
        expect(pinned.pinned, contains('Stay inside packages/auth.'));
        expect(pinned.rest, 'The agent fixed two tests.');
      });

      test('a later fold carries the earlier pin once, not the model copy',
          () async {
        final first = await LlmHarnessSummarizer(
          _FakeProvider([const LlmTextDelta('first')]),
        ).summarize(
          HarnessCompactionInput(
            messages: [HarnessMessage.user('The original request.')],
          ),
        );
        // The model echoes a pinned block of its own invention.
        final second = await LlmHarnessSummarizer(
          _FakeProvider([
            const LlmTextDelta(
              '$evidencePinBegin\nmade-up requirements\n$evidencePinEnd\n'
              'second',
            ),
          ]),
        ).summarize(
          HarnessCompactionInput(
            messages: [
              HarnessMessage.user('$harnessSummaryMarker\n${first.text}'),
              HarnessMessage.assistant('more work'),
            ],
            previousSummary: first.text,
          ),
        );
        expect(
          evidencePinBegin.allMatches(second.text),
          hasLength(1),
        );
        final pinned = splitPinnedEvidence(second.text);
        expect(pinned.pinned, contains('The original request.'));
        expect(second.text, isNot(contains('made-up requirements')));
        expect(pinned.rest, 'second');
      });
    });

    test('the focus reaches the summarizer\'s prompt', () async {
      final provider = _FakeProvider([const LlmTextDelta('ok')]);
      await LlmHarnessSummarizer(provider).summarize(
        HarnessCompactionInput(
          messages: [HarnessMessage.user('task')],
          focus: 'the failing test names\nKeep the migration plan.',
        ),
      );
      final prompt = provider.requests.single.single.textContent;
      expect(
        prompt,
        contains(
          '<focus>\nthe failing test names\nKeep the migration plan.\n'
          '</focus>',
        ),
      );
      expect(prompt.indexOf('<focus>'), greaterThan(
        prompt.indexOf('</conversation-history>'),
      ));
    });

    test('no focus, no focus block', () async {
      final provider = _FakeProvider([const LlmTextDelta('ok')]);
      await LlmHarnessSummarizer(provider).summarize(
        HarnessCompactionInput(messages: [HarnessMessage.user('task')]),
      );
      expect(
        provider.requests.single.single.textContent,
        isNot(contains('<focus>')),
      );
    });

    test('a cancelled run abandons the request instead of falling back', () {
      final source = CancellationTokenSource()..cancel('stop');
      final s = LlmHarnessSummarizer(
        _FakeProvider([const LlmTextDelta('never read')]),
      );
      expect(
        s.summarize(
          HarnessCompactionInput(
            messages: [HarnessMessage.user('hello')],
            cancel: source.token,
          ),
        ),
        throwsA(isA<CancelledException>()),
      );
    });
  });
}

class _FakeProvider extends LlmProviderPort {
  _FakeProvider(this.events);
  final List<LlmEvent> events;
  final List<List<HarnessMessage>> requests = [];

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
    requests.add(messages);
    return Stream<LlmEvent>.fromIterable(events);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingProvider extends LlmProviderPort {
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
