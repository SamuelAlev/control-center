import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Takes pointer input in an area of at least [minSize], centred on a child
/// that is drawn and laid out smaller (an 18px radio, a 14px close glyph).
///
/// Layout is untouched: a press in the margin around the child is handed to
/// the child as if it landed on the child's nearest edge. The margin only
/// works where the enclosing widgets have room, since every ancestor still
/// refuses a press outside its own box.
class CcHitTarget extends SingleChildRenderObjectWidget {
  /// Grows [child]'s pointer target to at least [minSize].
  const CcHitTarget({
    super.key,
    this.minSize = const Size.square(24),
    required super.child,
  });

  /// The smallest area, centred on the child, that takes pointer input.
  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCcHitTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderCcHitTarget).minSize = minSize;
  }
}

class _RenderCcHitTarget extends RenderProxyBox {
  _RenderCcHitTarget(this._minSize);

  Size _minSize;

  // Only hit testing reads it, so a change needs no relayout or repaint.
  set minSize(Size value) => _minSize = value;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final target = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.max(size.width, _minSize.width),
      height: math.max(size.height, _minSize.height),
    );
    if (!target.contains(position)) {
      return false;
    }
    // A point in the margin is pulled onto the child's own box, just inside
    // its far edges (a box contains its left/top edge but not right/bottom).
    final inside = Offset(
      position.dx.clamp(0.0, math.max(0.0, size.width - 0.01)),
      position.dy.clamp(0.0, math.max(0.0, size.height - 0.01)),
    );
    if (hitTestChildren(result, position: inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
