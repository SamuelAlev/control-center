import 'dart:typed_data';

import 'package:image/image.dart' as img;

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
  /// it changed), or null when the images are identical / undecodable.
  final Uint8List? overlayPng;
}

/// Pure-Dart image comparison for the PR visual-diff harness (PRD 18 §4).
/// Computes a changed-region percentage and a highlight overlay from two PNG
/// renders. Deterministic; no tokens, no Flutter.
class ImageDiffer {
  /// Creates an [ImageDiffer].
  const ImageDiffer({this.tolerance = 12});

  /// Per-channel absolute difference below which a pixel is "unchanged"
  /// (absorbs sub-pixel antialiasing jitter without hiding real changes).
  final int tolerance;

  /// Compares [baseBytes] and [headBytes] (PNG). When dimensions differ the
  /// change is reported as 100%. On undecodable input, returns a conservative
  /// "changed, no overlay" result (never silently "unchanged").
  ImageDiffResult compare(Uint8List baseBytes, Uint8List headBytes) {
    if (_bytesEqual(baseBytes, headBytes)) {
      return const ImageDiffResult(changedPercent: 0, identical: true);
    }
    final base = img.decodePng(baseBytes);
    final head = img.decodePng(headBytes);
    if (base == null || head == null) {
      return const ImageDiffResult(changedPercent: 100, identical: false);
    }
    if (base.width != head.width || base.height != head.height) {
      return const ImageDiffResult(changedPercent: 100, identical: false);
    }

    final overlay = img.Image.from(head);
    var changed = 0;
    final total = head.width * head.height;
    for (var y = 0; y < head.height; y++) {
      for (var x = 0; x < head.width; x++) {
        final a = base.getPixel(x, y);
        final b = head.getPixel(x, y);
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
