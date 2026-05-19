import 'package:control_center/shared/widgets/composer/composer_history.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit coverage for the [ComposerHistory] state machine — the terminal-style
/// ↑/↓ recall behind the composer. Deliberately free of widget-tree imports:
/// the widget-level behaviour (focus plumbing, key interception) is covered by
/// `composer_history_test.dart`, which needs the full app graph.
void main() {
  const entries = ['first prompt', 'second prompt'];

  TextSelection caret(int offset) => TextSelection.collapsed(offset: offset);

  group('up', () {
    test('recalls the newest prompt, walks back, and clamps at the oldest', () {
      final history = ComposerHistory();

      expect(
        history.up(entries, text: '', selection: caret(0)),
        'second prompt',
      );
      expect(
        history.up(entries, text: 'second prompt', selection: caret(13)),
        'first prompt',
      );
      // At the oldest entry, one more up stays put — like a shell.
      expect(
        history.up(entries, text: 'first prompt', selection: caret(12)),
        'first prompt',
      );
    });

    test('parks the draft it displaced', () {
      final history = ComposerHistory();
      history.up(entries, text: 'a brand new draft', selection: caret(18));
      history.up(entries, text: 'second prompt', selection: caret(13));

      // Walking forward past the newest restores it (see `down`).
      expect(history.down(entries), 'second prompt');
      expect(history.down(entries), 'a brand new draft');
    });

    test('declines while the caret sits below the first line', () {
      final history = ComposerHistory();
      const text = 'line one\nline two';

      // Caret on the second line: ArrowUp still belongs to the caret.
      expect(history.up(entries, text: text, selection: caret(19)), isNull);
      expect(history.isBrowsing, isFalse,
          reason: 'a declined up must not park a draft either');

      // Caret on the first line: ArrowUp recalls.
      expect(history.up(entries, text: text, selection: caret(8)), isNotNull);
    });

    test('a non-collapsed selection is left to the field', () {
      final history = ComposerHistory();
      expect(
        history.up(
          entries,
          text: 'hello',
          selection: const TextSelection(baseOffset: 0, extentOffset: 5),
        ),
        isNull,
      );
    });

    test('an invalid selection is treated as recallable', () {
      final history = ComposerHistory();
      expect(
        history.up(entries, text: '', selection: const TextSelection.collapsed(offset: -1)),
        'second prompt',
      );
    });

    test('an empty history never starts a browse', () {
      final history = ComposerHistory();
      expect(history.up(const [], text: '', selection: caret(0)), isNull);
      expect(history.isBrowsing, isFalse);
    });
  });

  group('down', () {
    test('is a caret key when not browsing', () {
      final history = ComposerHistory();
      expect(history.down(entries), isNull);
    });

    test('walks towards the present and past the newest restores the draft', () {
      final history = ComposerHistory();
      history.up(entries, text: 'draft', selection: caret(5));
      history.up(entries, text: 'first prompt', selection: caret(12));

      expect(history.down(entries), 'second prompt');
      expect(history.down(entries), 'draft');
      expect(history.isBrowsing, isFalse,
          reason: 'past the newest entry the browse is over');

      // Leaving browsing means down is a caret key again.
      expect(history.down(entries), isNull);
    });

    test('a list that grew mid-browse keeps the position valid', () {
      final history = ComposerHistory();
      history.up(entries, text: '', selection: caret(0));
      history.up(entries, text: '', selection: caret(0));
      expect(history.isBrowsing, isTrue);

      // The conversation gained a prompt while browsing: the next down lands
      // on it rather than leaving the browse early.
      final grown = [...entries, 'third prompt'];
      expect(history.down(grown), 'second prompt');
      expect(history.down(grown), 'third prompt');
      expect(history.down(grown), '',
          reason: 'the parked draft was an empty field');
    });
  });

  group('abandon', () {
    test('restores the parked draft and ends the browse', () {
      final history = ComposerHistory();
      history.up(entries, text: 'keep me', selection: caret(7));

      expect(history.abandon(), 'keep me');
      expect(history.isBrowsing, isFalse);

      // The next recall starts from the newest again.
      expect(history.up(entries, text: 'keep me', selection: caret(7)), 'second prompt');
    });

    test('is null when not browsing', () {
      expect(ComposerHistory().abandon(), isNull);
    });
  });

  group('reset', () {
    test('drops the position without restoring anything', () {
      final history = ComposerHistory();
      history.up(entries, text: 'draft', selection: caret(5));
      history.reset();

      expect(history.isBrowsing, isFalse);
      expect(history.down(entries), isNull,
          reason: 'reset must not park a restorable draft');
      expect(history.up(entries, text: 'draft', selection: caret(5)), 'second prompt');
    });
  });
}
