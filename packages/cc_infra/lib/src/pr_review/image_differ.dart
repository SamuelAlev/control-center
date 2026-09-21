import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Default pixel budget for a comparison walk. 4K screenshots are downscaled
/// to this before pixels are visited so a `repo/call` cannot stall the isolate.
const int kImageDiffMaxPixels = 2 * 1000 * 1000;

/// The pixel-diff outcome for one before/after image pair.
class ImageDiffResult {
  /// Creates an [ImageDiffResult].
  const ImageDiffResult({
    required this.changedPercent,
    required this.identical,
    this.overlayPng,
  });

  /// Percentage of pixels that differ beyond [ImageDiffer.tolerance] (0..100).
  final double changedPercent;

  /// Whether the two images are byte- or pixel-identical.
  final bool identical;

  /// PNG bytes of a changed-region highlight overlay (head image tinted where
  /// it changed), or null when the images are identical, undecodable, or
  /// differ in size (2-up / swipe still work; difference mode is hidden).
  final Uint8List? overlayPng;
}

/// Packed isolate payload — records of sendable types, not [ImageDiffResult].
typedef _PackedDiff = ({
  double changedPercent,
  bool identical,
  Uint8List? overlayPng,
});

/// Pure-Dart image comparison for the PR visual-diff harness (PRD 18 §4) and
/// the Diff-tab image overlay. Computes a changed-region percentage and a
/// highlight overlay from two raster encodings. Deterministic; no tokens, no
/// Flutter. Decode is format-agnostic ([img.decodeImage]); GIF uses the first
/// frame. Overlay is always PNG.
class ImageDiffer {
  /// Creates an [ImageDiffer].
  const ImageDiffer({
    this.tolerance = 12,
    this.maxPixels = kImageDiffMaxPixels,
  });

  /// Per-space absolute difference below which a pixel is "unchanged"
  /// (absorbs sub-pixel antialiasing jitter without hiding real changes).
  final int tolerance;

  /// Combined width×height ceiling. Both sides are downscaled to the same
  /// target before the pixel walk when they exceed this.
  final int maxPixels;

  /// Compares [baseBytes] and [headBytes] (any raster [img.decodeImage]
  /// supports). When dimensions differ the change is reported as 100% with
  /// no overlay. On undecodable input, returns a conservative "changed, no
  /// overlay" result (never silently "unchanged").
  ImageDiffResult compare(Uint8List baseBytes, Uint8List headBytes) {
    if (_bytesEqual(baseBytes, headBytes)) {
      return const ImageDiffResult(changedPercent: 0, identical: true);
    }
    final base = _tryDecode(baseBytes);
    final head = _tryDecode(headBytes);
    if (base == null || head == null) {
      return const ImageDiffResult(changedPercent: 100, identical: false);
    }
    if (base.width != head.width || base.height != head.height) {
      return const ImageDiffResult(changedPercent: 100, identical: false);
    }

    final capped = _capPair(base, head, maxPixels);
    final left = capped.$1;
    final right = capped.$2;

    final overlay = img.Image.from(right);
    var changed = 0;
    final total = right.width * right.height;
    for (var y = 0; y < right.height; y++) {
      for (var x = 0; x < right.width; x++) {
        final a = left.getPixel(x, y);
        final b = right.getPixel(x, y);
        if (_pixelDiffers(a, b)) {
          changed++;
          // Tint the changed pixel toward the accent (single-orange) so the
          // reviewer sees exactly what moved.
          overlay.setPixelRgba(
            x,
            y,
            ((b.r + 255 * 2) / 3).round().clamp(0, 255),
            ((b.g + 90 * 2) / 3).round().clamp(0, 255),
            ((b.b) / 3).round().clamp(0, 255),
            255,
          );
        }
      }
    }
    final percent = total == 0 ? 0.0 : (changed / total) * 100.0;
    return ImageDiffResult(
      changedPercent: percent,
      identical: changed == 0,
      overlayPng: changed == 0
          ? null
          : Uint8List.fromList(img.encodePng(overlay)),
    );
  }

  /// Runs [compare] off the caller's isolate so a 4K screenshot cannot stall
  /// `repo/call`.
  Future<ImageDiffResult> compareAsync(
    Uint8List baseBytes,
    Uint8List headBytes,
  ) async {
    final packed = await Isolate.run(
      () => _comparePacked(baseBytes, headBytes, tolerance, maxPixels),
    );
    return ImageDiffResult(
      changedPercent: packed.changedPercent,
      identical: packed.identical,
      overlayPng: packed.overlayPng,
    );
  }

  /// [img.decodeImage] walks every registered decoder; some (e.g. PSD)
  /// throw [RangeError] on short garbage rather than returning null.
  static img.Image? _tryDecode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static _PackedDiff _comparePacked(
    Uint8List baseBytes,
    Uint8List headBytes,
    int tolerance,
    int maxPixels,
  ) {
    final result = ImageDiffer(
      tolerance: tolerance,
      maxPixels: maxPixels,
    ).compare(baseBytes, headBytes);
    return (
      changedPercent: result.changedPercent,
      identical: result.identical,
      overlayPng: result.overlayPng,
    );
  }

  static (img.Image, img.Image) _capPair(
    img.Image base,
    img.Image head,
    int maxPixels,
  ) {
    final total = base.width * base.height;
    if (maxPixels <= 0 || total <= maxPixels) {
      return (base, head);
    }
    final scale = math.sqrt(maxPixels / total);
    final width = math.max(1, (base.width * scale).round());
    final height = math.max(1, (base.height * scale).round());
    return (
      img.copyResize(base, width: width, height: height),
      img.copyResize(head, width: width, height: height),
    );
  }

  bool _pixelDiffers(img.Pixel a, img.Pixel b) =>
      (a.r - b.r).abs() > tolerance ||
      (a.g - b.g).abs() > tolerance ||
      (a.b - b.b).abs() > tolerance ||
      (a.a - b.a).abs() > tolerance;

  bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
