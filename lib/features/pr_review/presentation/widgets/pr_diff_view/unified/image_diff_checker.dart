part of 'image_diff_body.dart';

/// 10×10 tile so a transparent logo does not disappear into the dark surface.
@visibleForTesting
class ImageDiffCheckerPainter extends CustomPainter {
  /// Creates the checker.
  const ImageDiffCheckerPainter();

  /// One square, in logical pixels. Matches one cell of the gif.
  static const double square = 5;

  static const Color _gray = Color(0xFFE5E5E5);
  static const Color _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final white = Paint()
      ..color = _white
      ..isAntiAlias = false;
    final gray = Paint()
      ..color = _gray
      ..isAntiAlias = false;
    final bounds = Offset.zero & size;
    // A Stack clips only when a child overflows layout, and this painter is
    // laid out exactly to the frame. Squares that run past [size] would
    // otherwise paint over the border and the page — a stair of every other
    // cell, worst when the asset is not a multiple of [square].
    canvas.save();
    canvas.clipRect(bounds, doAntiAlias: false);
    canvas.drawRect(bounds, white);

    // Square edges land on device pixels. A 5px logical cell whose origin
    // sits between pixels rasterizes as a blur, which on a 24px or 32px SVG
    // reads as chewed edges.
    final transform = canvas.getTransform();
    final scaleX = transform[0] == 0 ? 1.0 : transform[0].abs();
    final scaleY = transform[5] == 0 ? scaleX : transform[5].abs();
    final originX = transform[12];
    final originY = transform[13];
    final squareX = math.max(1, (square * scaleX).round());
    final squareY = math.max(1, (square * scaleY).round());
    final startX = originX.floorToDouble();
    final startY = originY.floorToDouble();
    final endX = originX + size.width * scaleX;
    final endY = originY + size.height * scaleY;

    var row = 0;
    for (var dy = startY; dy < endY; dy += squareY, row++) {
      var col = 0;
      for (var dx = startX; dx < endX; dx += squareX, col++) {
        if ((col + row).isOdd) {
          continue;
        }
        final rect = Rect.fromLTWH(
          (dx - originX) / scaleX,
          (dy - originY) / scaleY,
          squareX / scaleX,
          squareY / scaleY,
        );
        final clipped = rect.intersect(bounds);
        if (clipped.isEmpty) {
          continue;
        }
        canvas.drawRect(clipped, gray);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ImageDiffCheckerPainter oldDelegate) => false;
}

Size _fitDisplay(Size intrinsic, double maxWidth, double maxHeight) {
  var w = intrinsic.width;
  var h = intrinsic.height;
  if (w <= 0 || h <= 0) {
    return const Size(16, 16);
  }
  if (w > maxWidth || h > maxHeight) {
    final scale = math.min(maxWidth / w, maxHeight / h);
    w *= scale;
    h *= scale;
  }
  return Size(w, h);
}

/// Width/height from the root `<svg>` tag, falling back to `viewBox`.
(double, double) _parseSvgIntrinsicSize(String svg) {
  final m = RegExp(r'<svg\b([^>]*)>', caseSensitive: false).firstMatch(svg);
  if (m == null) {
    return (16, 16);
  }
  final attrs = m.group(1)!;
  final w = _parseSvgDim(_extractSvgAttr(attrs, 'width'));
  final h = _parseSvgDim(_extractSvgAttr(attrs, 'height'));
  if (w != null && h != null) {
    return (w, h);
  }
  final vb = _extractSvgAttr(attrs, 'viewBox');
  if (vb != null) {
    final parts = vb.trim().split(RegExp(r'[\s,]+'));
    if (parts.length == 4) {
      return (
        w ?? double.tryParse(parts[2]) ?? 16,
        h ?? double.tryParse(parts[3]) ?? 16,
      );
    }
  }
  return (w ?? 16, h ?? 16);
}

String? _extractSvgAttr(String attrs, String name) {
  final match = RegExp(
    '\\b$name\\s*=\\s*["\']([^"\']*)["\']',
    caseSensitive: false,
  ).firstMatch(attrs);
  return match?.group(1);
}

double? _parseSvgDim(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.endsWith('%')) {
    return null;
  }
  final match = RegExp(r'^([\d.]+)').firstMatch(trimmed);
  if (match == null) {
    return null;
  }
  return double.tryParse(match.group(1)!);
}
