import 'package:cc_infra/src/messaging/vision/vision_normalize.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeForBitmap', () {
    test('passes printable ASCII through unchanged', () {
      expect(normalizeForBitmap('Hello, World! 123'), 'Hello, World! 123');
    });

    test('collapses horizontal whitespace runs to a single space', () {
      expect(normalizeForBitmap('a    b\t\tc'), 'a b c');
    });

    test('collapses newline-bearing runs to a single newline glyph', () {
      expect(normalizeForBitmap('a\n\nb'), 'a${newlineGlyph}b');
      expect(normalizeForBitmap('a \n b'), 'a${newlineGlyph}b');
    });

    test('trims leading and trailing spaces and newline glyphs', () {
      expect(normalizeForBitmap('  hi  '), 'hi');
      expect(normalizeForBitmap('\n\nhi\n\n'), 'hi');
    });

    test('folds smart quotes to ASCII quotes', () {
      expect(normalizeForBitmap('“quoted”'), '"quoted"');
      expect(normalizeForBitmap('it’s'), "it's");
    });

    test('folds dashes to hyphen', () {
      expect(normalizeForBitmap('a–b—c'), 'a-b-c');
    });

    test('folds ellipsis to three dots', () {
      expect(normalizeForBitmap('wait…'), 'wait...');
    });

    test('folds bullets to asterisk and arrows to ASCII', () {
      expect(normalizeForBitmap('• item'), '* item');
      expect(normalizeForBitmap('a → b'), 'a -> b');
    });

    test('folds non-breaking space to a regular space', () {
      expect(normalizeForBitmap('a b'), 'a b');
    });

    test('replaces unsupported non-ASCII graphics with question mark', () {
      // CJK character has no fold and is graphic, so it becomes '?'.
      expect(normalizeForBitmap('a中b'), 'a?b');
    });

    test('drops control characters without emitting a glyph', () {
      expect(normalizeForBitmap('ab'), 'ab');
      expect(normalizeForBitmap('a​b'), 'ab');
    });

    test('strips ANSI escape sequences', () {
      expect(normalizeForBitmap('[31mred[0m'), 'red');
    });

    test('keeps the dim sentinels passing through', () {
      const input = '${dimOn}dim$dimOff';
      final result = normalizeForBitmap(input);
      expect(result.contains(dimOn), isTrue);
      expect(result.contains(dimOff), isTrue);
      expect(result, '${dimOn}dim$dimOff');
    });

    test('keeps the newline glyph sentinel passing through', () {
      expect(normalizeForBitmap('a${newlineGlyph}b'), 'a${newlineGlyph}b');
    });

    test('folds box-drawing characters to ASCII skeletons', () {
      expect(normalizeForBitmap('│'), '|');
      expect(normalizeForBitmap('─'), '-');
      expect(normalizeForBitmap('┌'), '+');
    });
  });

  group('stripDimMarkers', () {
    test('removes dim toggles from text', () {
      expect(stripDimMarkers('${dimOn}x${dimOff}y'), 'xy');
    });
  });
}
