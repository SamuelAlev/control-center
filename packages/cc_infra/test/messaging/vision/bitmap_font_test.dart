import 'package:cc_infra/src/messaging/vision/bitmap_font.dart';
import 'package:test/test.dart';

void main() {
  group('font8x8Basic', () {
    test('covers every printable ASCII code point with 8-byte glyphs', () {
      const count = lastPrintableAscii - firstPrintableAscii + 1;
      expect(font8x8Basic.length, count);
      for (final glyph in font8x8Basic) {
        expect(glyph.length, 8);
        for (final row in glyph) {
          expect(row, inInclusiveRange(0, 0xFF));
        }
      }
    });

    test('space (0x20) is a blank glyph', () {
      expect(glyphForCodePoint(0x20), List<int>.filled(8, 0));
    });

    test('a glyph with ink exists for visible characters', () {
      // The letter "A" must have at least one set pixel.
      final glyph = glyphForCodePoint('A'.codeUnitAt(0))!;
      expect(glyph.any((row) => row != 0), isTrue);
    });
  });

  group('glyphForCodePoint', () {
    test('returns null outside the printable range', () {
      expect(glyphForCodePoint(0x1F), isNull);
      expect(glyphForCodePoint(0x7F), isNull);
      expect(glyphForCodePoint(0x2588), isNull);
    });
  });

  group('glyphPixel', () {
    test('reads ink with LSB = leftmost pixel', () {
      // Row 0x01 has only bit 0 set → leftmost pixel (x=0) is ink.
      // Use "_" (0x5F): rows are all 0 except the last which is 0xFF.
      expect(glyphPixel('_'.codeUnitAt(0), 0, 7), isTrue); // bottom-left ink
      expect(glyphPixel('_'.codeUnitAt(0), 7, 7), isTrue); // bottom-right ink
      expect(glyphPixel('_'.codeUnitAt(0), 0, 0), isFalse); // top-left blank
    });

    test('out-of-range coordinates and code points return false', () {
      expect(glyphPixel('A'.codeUnitAt(0), -1, 0), isFalse);
      expect(glyphPixel('A'.codeUnitAt(0), 8, 0), isFalse);
      expect(glyphPixel(0x2588, 0, 0), isFalse);
    });
  });
}
