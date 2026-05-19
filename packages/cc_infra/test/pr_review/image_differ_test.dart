import 'dart:typed_data';

import 'package:cc_infra/src/pr_review/image_differ.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// Exercises [ImageDiffer] — the pure-Dart pixel comparator for the PR
/// visual-diff harness. Builds PNG inputs in-memory so the test never touches
/// disk. Pins: identical bytes → 0%; undecodable → conservative 100%;
/// dimension mismatch → 100%; real pixel diff reports a percentage and an
/// overlay PNG; sub-tolerance jitter counts as identical.
void main() {
  const differ = ImageDiffer();
  const tolerance = 12; // matches the default tolerance

  Uint8List png(int width, int height, int Function(int x, int y) rgba) {
    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final c = rgba(x, y);
        image.setPixelRgba(
          x,
          y,
          (c >> 24) & 0xff,
          (c >> 16) & 0xff,
          (c >> 8) & 0xff,
          c & 0xff,
        );
      }
    }
    return Uint8List.fromList(img.encodePng(image));
  }

  group('ImageDiffer.compare — identical inputs', () {
    test('byte-identical PNGs report 0% and identical', () {
      final a = png(4, 4, (_, _) => 0xff0000ff);
      final result = differ.compare(a, a);
      expect(result.changedPercent, 0);
      expect(result.identical, isTrue);
      expect(result.overlayPng, isNull);
    });
  });

  group('ImageDiffer.compare — undecodable inputs', () {
    test('returns 100% with no overlay when bytes are not PNGs', () {
      final junk = Uint8List.fromList([0, 1, 2, 3]);
      final result = differ.compare(junk, Uint8List.fromList([4, 5, 6]));
      expect(result.changedPercent, 100);
      expect(result.identical, isFalse);
      expect(result.overlayPng, isNull);
    });

    test('returns 100% when only one side decodes', () {
      final a = png(2, 2, (_, _) => 0xff0000ff);
      final result = differ.compare(a, Uint8List.fromList([0, 1, 2]));
      expect(result.changedPercent, 100);
      expect(result.identical, isFalse);
    });
  });

  group('ImageDiffer.compare — dimension mismatch', () {
    test('reports 100% when widths differ', () {
      final a = png(2, 2, (_, _) => 0xff0000ff);
      final b = png(4, 2, (_, _) => 0xff0000ff);
      final result = differ.compare(a, b);
      expect(result.changedPercent, 100);
      expect(result.identical, isFalse);
    });

    test('reports 100% when heights differ', () {
      final a = png(2, 2, (_, _) => 0xff0000ff);
      final b = png(2, 4, (_, _) => 0xff0000ff);
      final result = differ.compare(a, b);
      expect(result.changedPercent, 100);
    });
  });

  group('ImageDiffer.compare — pixel diffs', () {
    test('fully-changed images report ~100% and an overlay PNG', () {
      final a = png(4, 4, (_, _) => 0xff0000ff); // red
      final b = png(4, 4, (_, _) => 0xff00ff00); // green, fully different
      final result = differ.compare(a, b);
      expect(result.changedPercent, 100);
      expect(result.identical, isFalse);
      expect(result.overlayPng, isNotNull);
      // The overlay decodes to a PNG of the same dimensions.
      final overlay = img.decodePng(result.overlayPng!);
      expect(overlay, isNotNull);
      expect(overlay!.width, 4);
      expect(overlay.height, 4);
    });

    test('partially-changed images report a fractional percentage', () {
      // 4x4 = 16 pixels; change exactly 4 → 25%.
      final base = png(4, 4, (_, _) => 0xff0000ff);
      final head = png(4, 4, (x, y) {
        // Change only the first column (x == 0) to a fully-different color.
        if (x == 0) {
          return 0xff00ff00;
        }
        return 0xff0000ff;
      });
      final result = differ.compare(base, head);
      expect(result.changedPercent, closeTo(25.0, 0.01));
      expect(result.identical, isFalse);
      expect(result.overlayPng, isNotNull);
    });

    test('sub-tolerance jitter counts as identical', () {
      const delta = tolerance - 1; // just under the default tolerance of 12
      // base R=0; head R=delta. G/B/A identical → only one space moves by
      // less than tolerance, so the pixel is treated as unchanged.
      final base = png(2, 2, (_, _) => 0x000000ff);
      final head = png(2, 2, (_, _) => (delta << 24) | 0xff);
      final result = differ.compare(base, head);
      expect(result.changedPercent, 0);
      expect(result.identical, isTrue);
      expect(result.overlayPng, isNull);
    });

    test('above-tolerance change counts as different', () {
      const delta = tolerance + 10;
      final base = png(1, 1, (_, _) => 0x000000ff);
      final head = png(1, 1, (_, _) => (delta << 24) | 0xff);
      final result = differ.compare(base, head);
      expect(result.changedPercent, 100);
      expect(result.identical, isFalse);
    });
  });

  group('ImageDiffer.tolerance', () {
    test('a custom tolerance widens the unchanged band', () {
      const lenient = ImageDiffer(tolerance: 100);
      final base = png(1, 1, (_, _) => 0xff0000ff);
      final head = png(1, 1, (_, _) => 0xff00ffff);
      final result = lenient.compare(base, head);
      // All spaces differ by 0xff=255 > 100 → still flagged.
      expect(result.changedPercent, 100);
    });

    test('a custom tolerance of 0 flags any change', () {
      const strict = ImageDiffer(tolerance: 0);
      final base = png(1, 1, (_, _) => 0xff0000ff);
      final head = png(1, 1, (_, _) {
        // +1 in the red space.
        return (0xff << 24) | (0x00 << 16) | (0x01 << 8) | 0xff;
      });
      final result = strict.compare(base, head);
      expect(result.changedPercent, 100);
    });
  });
}
