import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_infra/src/context/snapcompact_compactor.dart';
import 'package:test/test.dart';

// The original exceeds the window; the retained head/tail plus pages fits it.
List<HarnessMessage> _history(int count, {int textChars = 1000}) => [
  for (var i = 0; i < count; i++)
    i.isEven
        ? HarnessMessage.user('turn $i ${'u' * textChars}')
        : HarnessMessage.assistant('turn $i ${'a' * textChars}'),
];

bool _hasImage(List<HarnessMessage> history) =>
    history.any((m) => m.content.whereType<HarnessImageBlock>().isNotEmpty);

SnapcompactCompactor _compactor({
  bool prefer = true,
  bool? vision,
  int? maxFrames,
  int? imageLimit,
}) => SnapcompactCompactor(
  fallback: const DefaultHarnessCompactor(),
  modelId: 'gpt-5',
  readerHasVision: vision ?? true,
  preferSnapshots: prefer,
  config: const CompactionConfig(buffer: 100),
  maxFrames: maxFrames ?? 6,
  imageLimit: imageLimit,
);

void main() {
  group('SnapcompactCompactor opt-in', () {
    test(
      'does not image unless preferSnapshots is set, even when forced',
      () async {
        final history = _history(30);
        final result = await _compactor(
          prefer: false,
        ).maybeCompact(history, contextWindow: 5000, force: true);
        expect(result.changed, isTrue);
        expect(_hasImage(history), isFalse);
        expect(history.first.textContent, startsWith(harnessSummaryMarker));
      },
    );

    test('does not image when the reader has no vision', () async {
      final history = _history(30);
      await _compactor(
        vision: false,
      ).maybeCompact(history, contextWindow: 5000);
      expect(_hasImage(history), isFalse);
    });

    test('images the middle when explicitly opted in', () async {
      final history = _history(30);
      final result = await _compactor().maybeCompact(
        history,
        contextWindow: 5000,
      );
      expect(result.changed, isTrue);
      expect(result.summarized, isFalse);
      expect(result.reclaimedTokens, greaterThan(0));
      expect(_hasImage(history), isTrue);
      expect(
        history.first.textContent,
        isNot(startsWith(harnessSummaryMarker)),
      );
    });

    test(
      'a second pass re-renders from the retained source, not the pixels',
      () async {
        final compactor = _compactor();
        final first = _history(30);
        await compactor.maybeCompact(first, contextWindow: 5000);
        final originalSource = compactor.retainedSource;
        final second = [...first, ..._history(20)];
        await compactor.maybeCompact(second, contextWindow: 5000);
        // Still a single image block carrying pages, never an image of an image.
        expect(_hasImage(second), isTrue);
        expect(compactor.retainedSource, contains(originalSource));
        expect(
          second.where((message) => message.isSnapshotCarrier),
          hasLength(1),
        );
      },
    );
  });

  group('SnapcompactCompactor budgets', () {
    test(
      'refuses and summarizes when the page cap would be exceeded',
      () async {
        final history = _history(30);
        final result = await _compactor(
          maxFrames: 0,
        ).maybeCompact(history, contextWindow: 5000);
        expect(result.changed, isTrue);
        expect(_hasImage(history), isFalse);
        expect(result.summarized, isTrue, reason: 'fell back to the text path');
      },
    );

    test('refuses when the provider image limit would be exceeded', () async {
      final history = _history(30);
      await _compactor(
        imageLimit: 0,
      ).maybeCompact(history, contextWindow: 5000);
      expect(_hasImage(history), isFalse);
    });

    test('refuses a fold that does not actually reduce the prompt', () async {
      // Tiny text folded into a full page costs more tokens than it removed;
      // the pass must not be reported as a change.
      final history = _history(30, textChars: 1);
      final result = await _compactor().maybeCompact(
        history,
        contextWindow: 100,
      );
      expect(_hasImage(history), isFalse);
      expect(result.summarized, isTrue, reason: 'text path ran instead');
    });
    test('refuses when the output reservation leaves no room', () async {
      // The text fold would fit the window, but reserving the whole output
      // budget leaves nothing for it, so the snapshot path must not claim a fit.
      final history = _history(30);
      final result = await _compactor().maybeCompact(
        history,
        contextWindow: 5000,
        reservedOutputTokens: 100000,
      );
      expect(_hasImage(history), isFalse);
      expect(result.changed, isTrue, reason: 'the text fallback still ran');
      expect(result.summarized, isTrue);
    });
  });

  group('Snapshot rehydration and retention (#6)', () {
    test('reports the folded index and the retained source', () async {
      final history = _history(30);
      final result = await _compactor().maybeCompact(
        history,
        contextWindow: 5000,
      );
      expect(result.changed, isTrue);
      expect(
        result.foldedFromIndex,
        greaterThan(0),
        reason:
            'a snapshot keeps a verbatim head, so the fold does not start at 0',
      );
      expect(result.retainedSnapshotSource, isNotEmpty);
      // The replacement sits at the reported index and carries the page
      // identity the host's source-persistence rule keys on.
      expect(history[result.foldedFromIndex].isSnapshotCarrier, isTrue);
    });

    test(
      'a refused later pass rehydrates the first snapshot as text',
      () async {
        final first = _compactor();
        final history = _history(30);
        await first.maybeCompact(history, contextWindow: 5000);
        expect(_hasImage(history), isTrue);

        // A pass that must be refused (page cap), with the retained source
        // restored — the state a host persists across turns/restarts.
        final second = SnapcompactCompactor(
          fallback: const DefaultHarnessCompactor(),
          modelId: 'gpt-5',
          readerHasVision: true,
          preferSnapshots: true,
          config: const CompactionConfig(buffer: 100),
          maxFrames: 0,
          retainedSource: first.retainedSource,
        );
        final r = await second.maybeCompact(
          history,
          contextWindow: 5000,
          force: true,
        );
        expect(r.changed, isTrue);
        expect(_hasImage(history), isFalse);
        // The first snapshot's TEXT survived into the text path.
        final folded = history.map((m) => m.textContent).join('\n');
        expect(folded, contains('turn 2'));
        // No page remains, so the host drops the retained source.
        expect(history.any((m) => m.isSnapshotCarrier), isFalse);
      },
    );

    test(
      'a refused pass without source drops unusable pages but retains current turns',
      () async {
        final first = _compactor();
        final history = _history(30);
        await first.maybeCompact(history, contextWindow: 5000);
        // No retainedSource — as after a restart that did not persist it.
        final second = SnapcompactCompactor(
          fallback: const DefaultHarnessCompactor(),
          modelId: 'gpt-5',
          readerHasVision: true,
          preferSnapshots: true,
          config: const CompactionConfig(buffer: 100),
          maxFrames: 0,
        );
        await second.maybeCompact(history, contextWindow: 5000, force: true);
        final folded = history.map((m) => m.textContent).join('\n');
        expect(_hasImage(history), isFalse);
        expect(history.any((message) => message.isSnapshotCarrier), isFalse);
        expect(folded, contains('turn 29'));
      },
    );
  });
}
