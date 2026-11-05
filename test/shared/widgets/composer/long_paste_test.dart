import 'package:control_center/shared/widgets/composer/long_paste.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(String text, [int? caret]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret ?? text.length),
);

void main() {
  group('insertedText', () {
    test('reports what a paste at the caret put in', () {
      expect(LongPasteFormatter.insertedText('ab', 'aXYZb'), 'XYZ');
    });

    test('reports only the replacement when a selection is pasted over', () {
      expect(LongPasteFormatter.insertedText('a12345b', 'aXb'), 'X');
    });

    test('is null for a pure deletion', () {
      expect(LongPasteFormatter.insertedText('abc', 'ac'), isNull);
    });
  });

  group('isLongPaste', () {
    test('takes long text or many lines, not a few paragraphs', () {
      expect(isLongPaste('x' * (kLongPasteMinChars - 1)), isFalse);
      expect(isLongPaste('x' * kLongPasteMinChars), isTrue);
      expect(
        isLongPaste(List.filled(kLongPasteMinLines, 'l').join('\n')),
        isTrue,
      );
      expect(
        isLongPaste(List.filled(kLongPasteMinLines - 1, 'l').join('\n')),
        isFalse,
      );
    });
  });

  group('LongPasteFormatter', () {
    final long = 'y' * kLongPasteMinChars;

    test('keeps the old value and hands over the text when taken', () {
      String? taken;
      final formatter = LongPasteFormatter(
        onLongPaste: (text) {
          taken = text;
          return true;
        },
      );
      final old = _value('ask: ');
      final result = formatter.formatEditUpdate(old, _value('ask: $long'));
      expect(result, old);
      expect(taken, long);
    });

    test('lets the paste through when declined', () {
      final formatter = LongPasteFormatter(onLongPaste: (_) => false);
      final next = _value('ask: $long');
      expect(formatter.formatEditUpdate(_value('ask: '), next), next);
    });

    test('ignores typing and IME composition', () {
      var calls = 0;
      final formatter = LongPasteFormatter(
        onLongPaste: (_) {
          calls++;
          return true;
        },
      );
      final typed = _value('ask: a');
      expect(formatter.formatEditUpdate(_value('ask: '), typed), typed);
      final composing = TextEditingValue(
        text: long,
        composing: TextRange(start: 0, end: long.length),
      );
      expect(formatter.formatEditUpdate(_value(''), composing), composing);
      expect(calls, 0);
    });
  });
}
