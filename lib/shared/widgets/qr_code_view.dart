import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

/// A square QR code for [data], painted dark-on-light at [size] logical pixels.
///
/// Replaces `qr_flutter`'s `QrImageView` (unmaintained, pinned to `qr` 3).
/// Like it, the version is picked to fit [data] at [errorCorrectLevel] and no
/// quiet zone is drawn — callers wrap the code in light padding.
class QrCodeView extends StatelessWidget {
  /// Creates a QR code view.
  const QrCodeView({
    super.key,
    required this.data,
    required this.size,
    this.errorCorrectLevel = QrErrorCorrectLevel.low,
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
  });

  /// The encoded text, typically a deep link.
  final String data;

  /// The edge length in logical pixels.
  final double size;

  /// The recovery level; low keeps the modules large for camera scanning.
  final QrErrorCorrectLevel errorCorrectLevel;

  /// The dark module color.
  final Color foregroundColor;

  /// The light module color.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final image = QrImage(
      QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: errorCorrectLevel,
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: QrCodePainter(
          image: image,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

/// Paints a [QrImage]'s modules edge to edge over the canvas.
@visibleForTesting
class QrCodePainter extends CustomPainter {
  /// Creates a painter for [image].
  const QrCodePainter({
    required this.image,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  /// The module matrix.
  final QrImage image;

  /// The dark module color.
  final Color foregroundColor;

  /// The light module color.
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    // RTL carve-out: a QR matrix is physical geometry; it must never mirror.
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    final n = image.moduleCount;
    final module = size.shortestSide / n;
    final dark = Paint()
      ..color = foregroundColor
      ..isAntiAlias = false;
    // One rect per horizontal run, so adjacent modules leave no hairline seams.
    for (var row = 0; row < n; row++) {
      var col = 0;
      while (col < n) {
        if (!image.isDark(row, col)) {
          col++;
          continue;
        }
        final start = col;
        while (col < n && image.isDark(row, col)) {
          col++;
        }
        canvas.drawRect(
          Rect.fromLTRB(
            start * module,
            row * module,
            col * module,
            (row + 1) * module,
          ),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(QrCodePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.foregroundColor != foregroundColor ||
      oldDelegate.backgroundColor != backgroundColor;
}
