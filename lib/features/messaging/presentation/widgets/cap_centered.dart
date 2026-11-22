import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/widgets.dart';

/// Cap height over font size for the UI fonts (Manrope 0.72, Inter 0.73).
const double kCapHeight = 0.72;

/// Reports [baseline] as its child's alphabetic baseline, so a baseline
/// placeholder puts the child exactly where the digits beside it sit.
class CapCentered extends SingleChildRenderObjectWidget {
  /// Creates a [CapCentered].
  const CapCentered({super.key, required this.baseline, required super.child});

  /// Distance from the child's top to the baseline it should share.
  final double baseline;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCapCentered(baseline);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderCapCentered).baseline = baseline;
  }
}

class _RenderCapCentered extends RenderProxyBox {
  _RenderCapCentered(this._baseline);

  double _baseline;
  set baseline(double value) {
    if (value != _baseline) {
      _baseline = value;
      markNeedsLayout();
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => _baseline;

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) => _baseline;
}
