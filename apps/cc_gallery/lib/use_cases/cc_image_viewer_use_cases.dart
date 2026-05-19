import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcImageViewer] and [CcExpandableImage] — the product-wide
/// "see this image bigger" pair.
///
/// The thing worth looking at is the CONTRACT between them: the inline
/// rendition is whatever the surface could afford (a column-width decode), the
/// expanded one is the full picture, and scale 1 in the viewer always means
/// "the whole image fits" rather than "one image pixel per screen pixel".
///
/// The sample is painted rather than fetched: a network image in a gallery
/// entry is a use case that fails on a plane.

const _path = '[Components]';

const _labels = CcImageViewerLabels(
  expand: 'Expand',
  zoomIn: 'Zoom in',
  zoomOut: 'Zoom out',
  resetZoom: 'Reset zoom',
  close: 'Close',
);

/// A stand-in "photo": a diagonal wash with a grid, so pan and zoom are
/// legible without shipping a raster into the repo.
class _SampleImage extends StatelessWidget {
  const _SampleImage({this.label = 'sample.png'});

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

/// The affordance in situ: hover the thumbnail to reveal the corner chip, click
/// anywhere on it to open the lightbox.
@widgetbook.UseCase(name: 'Expandable', type: CcExpandableImage, path: _path)
Widget ccExpandableImageUseCase(BuildContext context) {
  final t = context.ds;
  final width = context.knobs.double.slider(
    label: 'Inline width',
    initialValue: 320,
    min: 120,
    max: 640,
  );
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: width * 9 / 16,
          child: const CcExpandableImage(
            labels: _labels,
            title: 'sample.png',
            viewerBuilder: _buildViewerSample,
            child: _SampleImage(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Hover for the chip · click to expand',
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ],
    ),
  );
}

Widget _buildViewerSample(BuildContext context) =>
    const _SampleImage(label: 'sample.png · 2560×1440');

/// The viewer body on its own, so the zoom toolbar, the scroll/zoom split and
/// the double-tap toggle can be exercised without a dialog in the way.
///
/// The split is the part worth trying by hand: a plain scroll PANS, and zoom is
/// on ⌥ / ⌘ / Ctrl + scroll — `InteractiveViewer`'s default (wheel always
/// zooms) makes a lightbox lurch under a two-finger flick.
@widgetbook.UseCase(name: 'Viewer', type: CcImageViewer, path: _path)
Widget ccImageViewerUseCase(BuildContext context) {
  final maxScale = context.knobs.double.slider(
    label: 'Max scale',
    initialValue: 8,
    min: 2,
    max: 16,
  );
  return Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: CcImageViewer(
      labels: _labels,
      maxScale: maxScale,
      child: const _SampleImage(label: 'scroll pans · ⌥scroll zooms · ± · 0'),
    ),
  );
}
