import 'package:cc_domain/core/utils/string_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('oneLineLabel', () {
    // Build control/format characters by code point so the source stays pure
    // ASCII (no invisible bytes that an editor or transport could mangle).
    final esc = String.fromCharCode(0x1B); // ESC, category Cc
    final nel = String.fromCharCode(0x85); // NEXT LINE, category Cc
    final zwj = String.fromCharCode(0x200D); // ZERO WIDTH JOINER, category Cf
    final bom = String.fromCharCode(0xFEFF); // ZERO WIDTH NO-BREAK, category Cf
    final grin = String.fromCharCode(0x1F600); // 😀 — one rune, two UTF-16 units

    test('collapses runs of whitespace to a single space', () {
      expect(oneLineLabel('hello   world'), 'hello world');
      expect(oneLineLabel('a\t\tb'), 'a b');
      expect(oneLineLabel('a\n\nb'), 'a b');
    });

    test('trims leading and trailing whitespace', () {
      expect(oneLineLabel('  trim me  '), 'trim me');
      expect(oneLineLabel('\n\tpadded\t\n'), 'padded');
    });

    test('collapses newlines so the label is always one line', () {
      expect(oneLineLabel('line one\nline two'), 'line one line two');
      expect(oneLineLabel('a\r\nb'), 'a b');
    });

    test('collapses control characters including ESC / ANSI', () {
      // ESC is a control char; the bracket-color-code chars are not, so only
      // the ESC run itself becomes a space.
      expect(oneLineLabel('a${esc}b'), 'a b');
      expect(oneLineLabel('red$esc[31mtext'), 'red [31mtext');
    });

    test('collapses zero-width / format characters that \\s misses', () {
      expect(oneLineLabel('a${zwj}b'), 'a b');
      expect(oneLineLabel('a${bom}b'), 'a b');
      expect(oneLineLabel('a${nel}b'), 'a b');
    });

    test('leaves a short, already-clean label unchanged', () {
      expect(oneLineLabel('reviewer'), 'reviewer');
      expect(oneLineLabel('hi'), 'hi');
    });

    test('returns empty for empty or whitespace-only input', () {
      expect(oneLineLabel(''), '');
      expect(oneLineLabel('     '), '');
      expect(oneLineLabel('\n\t  '), '');
    });

    test('caps length at the default and appends an ellipsis', () {
      final result = oneLineLabel('a' * 100);
      expect(result.runes.length, kOneLineLabelMax);
      expect(result.endsWith('…'), isTrue);
      expect(result, '${'a' * (kOneLineLabelMax - 1)}…');
    });

    test('respects a custom max', () {
      expect(oneLineLabel('abcdefghij', max: 5), 'abcd…');
      expect(oneLineLabel('abcde', max: 5), 'abcde');
    });

    test('clamps max to at least 1', () {
      expect(oneLineLabel('abcdef', max: 0), '…');
      expect(oneLineLabel('abcdef', max: -10), '…');
    });

    test('truncates by code point, never splitting an astral character', () {
      final result = oneLineLabel(grin * 100, max: 5);
      expect(result.runes.length, 5);
      // 4 emoji + ellipsis; the rest are whole emoji (no lone surrogate).
      expect(result, '${grin * 4}…');
      // Round-tripping through runes proves there is no orphaned surrogate.
      expect(String.fromCharCodes(result.runes), result);
    });
  });
}
