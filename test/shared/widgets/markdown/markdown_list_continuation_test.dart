import 'package:control_center/shared/widgets/markdown/markdown_list_continuation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds the (oldValue, newValue) pair for "Enter pressed at the end of [line]",
/// i.e. a single '\n' inserted at the caret which sits at the end of [line].
({TextEditingValue oldValue, TextEditingValue newValue}) _enterAfter(String line) {
  final oldValue = TextEditingValue(
    text: line,
    selection: TextSelection.collapsed(offset: line.length),
  );
  final newText = '$line\n';
  final newValue = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newText.length),
  );
  return (oldValue: oldValue, newValue: newValue);
}

void main() {
  group('continueMarkdownList', () {
    test('continues a bullet list with the same marker + indent', () {
      final e = _enterAfter('  - first item');
      final r = continueMarkdownList(e.oldValue, e.newValue);
      expect(r, isNotNull);
      expect(r!.text, '  - first item\n  - ');
      expect(r.selection.baseOffset, r.text.length);
    });

    test('continues an ordered list, incrementing the number', () {
      final e = _enterAfter('1. one');
      final r = continueMarkdownList(e.oldValue, e.newValue);
      expect(r, isNotNull);
      expect(r!.text, '1. one\n2. ');
    });

    test('supports the ") " ordered closer', () {
      final e = _enterAfter('3) three');
      final r = continueMarkdownList(e.oldValue, e.newValue);
      expect(r!.text, '3) three\n4) ');
    });

    test('ends the list when Enter is pressed on an empty item', () {
      final e = _enterAfter('- ');
      final r = continueMarkdownList(e.oldValue, e.newValue);
      expect(r, isNotNull);
      expect(r!.text, '');
      expect(r.selection.baseOffset, 0);
    });

    test('returns null for a non-list line', () {
      final e = _enterAfter('just a sentence');
      expect(continueMarkdownList(e.oldValue, e.newValue), isNull);
    });

    test('returns null when the change is not a single newline insert', () {
      const oldValue = TextEditingValue(text: '- a');
      const newValue = TextEditingValue(
        text: '- ab',
        selection: TextSelection.collapsed(offset: 4),
      );
      expect(continueMarkdownList(oldValue, newValue), isNull);
    });

    test('continues a list mid-document, inserting at the caret only', () {
      // Caret sat at the end of "- one" (offset 5); Enter inserted a '\n' there.
      const oldValue = TextEditingValue(
        text: '- one\nmore text',
        selection: TextSelection.collapsed(offset: 5),
      );
      const newValue = TextEditingValue(
        text: '- one\n\nmore text',
        selection: TextSelection.collapsed(offset: 6),
      );
      final r = continueMarkdownList(oldValue, newValue);
      expect(r, isNotNull);
      expect(r!.text, '- one\n- \nmore text');
      expect(r.selection.baseOffset, '- one\n- '.length);
    });
  });

  group('attachListContinuation', () {
    test('rewrites the controller on a newline after a list item', () {
      final controller = TextEditingController(
        text: '- first',
      )..selection = const TextSelection.collapsed(offset: 7);
      final detach = attachListContinuation(controller);

      // Simulate the field inserting a newline at the caret.
      controller.value = const TextEditingValue(
        text: '- first\n',
        selection: TextSelection.collapsed(offset: 8),
      );

      expect(controller.text, '- first\n- ');
      expect(controller.selection.baseOffset, '- first\n- '.length);
      detach();
      controller.dispose();
    });
  });
}
