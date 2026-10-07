import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

// Shared fixtures for the CcImageViewer / CcExpandableImage stories.
//
// The sample is painted rather than fetched: a network image in a gallery
// entry is a story that fails on a plane.

/// English labels for the viewer chrome.
const sampleImageViewerLabels = CcImageViewerLabels(
  expand: 'Expand',
  zoomIn: 'Zoom in',
  zoomOut: 'Zoom out',
  resetZoom: 'Reset zoom',
  close: 'Close',
);

/// A stand-in "photo": a diagonal wash with a grid, so pan and zoom are
/// legible without shipping a raster into the repo.
class SampleImage extends StatelessWidget {
  /// Paints the sample with [label] centred on it.
  const SampleImage({this.label = 'sample.png', super.key});

  /// The caption drawn over the sample.
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return CustomPaint(
      painter: _GridPainter(
        line: t.borderSecondary,
        from: t.bgBrandSecondary,
        to: t.bgTertiary,
      ),
      child: Center(
        child: Text(
          label,
          style: CcTypography.title.copyWith(color: t.textTertiary),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.line,
    required this.from,
    required this.to,
  });

  final Color line;
  final Color from;
  final Color to;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [from, to],
        ).createShader(rect),
    );
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stroke);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.line != line || old.from != from || old.to != to;
}
