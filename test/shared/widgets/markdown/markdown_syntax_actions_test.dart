import 'package:control_center/shared/widgets/markdown/markdown_syntax_actions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wrapSelection', () {
    test('wraps a selection', () {
      const v = TextEditingValue(
        text: 'hello world',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final r = wrapSelection(v, '**', '**');
      expect(r.text, '**hello** world');
      expect(r.selection, const TextSelection(baseOffset: 2, extentOffset: 7));
    });

    test('toggles off an already-wrapped selection', () {
      const v = TextEditingValue(
        text: '**hello** world',
        selection: TextSelection(baseOffset: 2, extentOffset: 7),
      );
      final r = wrapSelection(v, '**', '**');
      expect(r.text, 'hello world');
      expect(r.selection, const TextSelection(baseOffset: 0, extentOffset: 5));
    });

    test('inserts an empty pair with the caret between', () {
      const v = TextEditingValue(
        text: 'ab',
        selection: TextSelection.collapsed(offset: 1),
      );
      final r = wrapSelection(v, '`', '`');
      expect(r.text, 'a``b');
      expect(r.selection, const TextSelection.collapsed(offset: 2));
    });
  });

  group('toggleLinePrefix', () {
    test('adds a prefix to every spanned line', () {
      const v = TextEditingValue(
        text: 'line1\nline2',
        selection: TextSelection(baseOffset: 0, extentOffset: 11),
      );
      final r = toggleLinePrefix(v, '- ');
      expect(r.text, '- line1\n- line2');
    });

    test('removes the prefix when all lines already have it', () {
      const v = TextEditingValue(
        text: '## a\n## b',
        selection: TextSelection(baseOffset: 0, extentOffset: 9),
      );
      final r = toggleLinePrefix(v, '## ');
      expect(r.text, 'a\nb');
    });

    test('leaves blank lines untouched', () {
      const v = TextEditingValue(
        text: 'a\n\nb',
        selection: TextSelection(baseOffset: 0, extentOffset: 4),
      );
      final r = toggleLinePrefix(v, '> ');
      expect(r.text, '> a\n\n> b');
    });
  });

  group('insertLink', () {
    test('wraps the selection as a link with url selected', () {
      const v = TextEditingValue(
        text: 'click',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final r = insertLink(v);
      expect(r.text, '[click](url)');
      expect(r.selection, const TextSelection(baseOffset: 8, extentOffset: 11));
      expect(r.text.substring(8, 11), 'url');
    });

    test('uses a placeholder label when nothing is selected', () {
      const v = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      final r = insertLink(v);
      expect(r.text, '[text](url)');
    });
  });
}
