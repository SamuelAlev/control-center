import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/gestures.dart'
    show PointerDeviceKind, PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart' show Matrix4, TransformationController;

/// Makes a mouse wheel PAN an `InteractiveViewer` canvas, leaving zoom to
/// ⌘/Ctrl + wheel, a trackpad pinch and the on-screen controls.
///
/// ## Why this exists
///
/// `InteractiveViewer` hardwires a mouse wheel to ZOOM, with no flag to change
/// it, while it treats a trackpad two-finger scroll as a PAN — which is exactly
/// why a trackpad already feels right on these canvases and a wheel does not.
/// A pointer signal is delivered directly to every `Listener` on the hit-test
/// path (it is not arena-resolved), so this cannot pre-empt the viewer: it runs
/// after it and rewrites the result. [beginInteraction] must be wired to the
/// viewer's `onInteractionStart`, which fires BEFORE the viewer mutates the
/// matrix, so the snapshot is the pre-zoom transform; a plain wheel restores it
/// and translates instead. Both writes happen inside the same event dispatch,
/// so one frame is painted and nothing flickers.
///
/// Shared by the plan studio DAG and the agent org chart so a wheel behaves the
/// same on both — two canvases that scroll differently is a worse answer than
/// either behaviour on its own.
class CanvasWheelPan {
  /// Creates a [CanvasWheelPan] driving [controller].
  CanvasWheelPan(this.controller);

  /// The canvas transform, shared with the viewer.
  final TransformationController controller;

  /// The transform as it was just BEFORE the interaction the viewer is
  /// applying right now.
  Matrix4? _beforeInteraction;

  /// Wire this to `InteractiveViewer.onInteractionStart`.
  void beginInteraction() => _beforeInteraction = controller.value.clone();

  /// Wire this to a `Listener.onPointerSignal` wrapping the viewer.
  ///
  /// [viewport] is the visible box and [canvas] the scene's own size; together
  /// with [boundaryMargin] they reproduce the viewer's own drag clamp, so a
  /// wheel cannot pan somewhere a drag could not.
  void onPointerSignal(
    PointerSignalEvent event, {
    required Size viewport,
    required Size canvas,
    required double boundaryMargin,
  }) {
    if (event is! PointerScrollEvent ||
        event.kind == PointerDeviceKind.trackpad) {
      return;
    }
    final keys = HardwareKeyboard.instance;
    if (keys.isMetaPressed || keys.isControlPressed) {
      return;
    }
    // The viewer ignores a horizontal-only wheel and returns BEFORE
    // `onInteractionStart`, so in that case the snapshot is stale and the live
    // transform is the base.
    final base = event.scrollDelta.dy == 0
        ? controller.value
        : (_beforeInteraction ?? controller.value);
    final scale = base.getMaxScaleOnAxis();
    if (scale <= 0) {
      return;
    }
    // Shift turns the wheel horizontal (the platform convention), which is also
    // how a mouse with no horizontal wheel crosses a wide graph.
    final delta = keys.isShiftPressed && event.scrollDelta.dx == 0
        ? Offset(event.scrollDelta.dy, 0)
        : event.scrollDelta;
    if (delta == Offset.zero) {
      return;
    }

    // Work in scene coordinates: where the viewport's top-left sits on the
    // canvas. Panning moves it WITH the wheel, so the content moves against it.
    final translation = base.getTranslation();
    final origin = Offset(-translation.x / scale, -translation.y / scale);
    final visible = Size(viewport.width / scale, viewport.height / scale);
    final bounds = Rect.fromLTRB(
      -boundaryMargin,
      -boundaryMargin,
      canvas.width + boundaryMargin,
      canvas.height + boundaryMargin,
    );
    final next = Offset(
      _clampPan(
        origin.dx + delta.dx / scale,
        origin.dx,
        bounds.left,
        bounds.right - visible.width,
      ),
      _clampPan(
        origin.dy + delta.dy / scale,
        origin.dy,
        bounds.top,
        bounds.bottom - visible.height,
      ),
    );
    if (next == origin) {
      // Nothing moved, but the viewer may already have zoomed: restore.
      controller.value = base;
      return;
    }
    controller.value = Matrix4.identity()
      ..translateByDouble(-next.dx * scale, -next.dy * scale, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  /// One axis of the wheel pan, leashed to `[min, max]`.
  ///
  /// Empty range ⇒ the axis has nothing to pan into (the graph is smaller than
  /// the viewport), so it holds still. Inside the range ⇒ take the step. Outside
  /// it, the step is *not* snapped back: a graph shorter than the viewport
  /// starts outside the leash and snapping would make the first wheel tick jump
  /// the canvas hundreds of pixels the wrong way. Only a step that reduces the
  /// excursion is allowed, so the leash is a wall, never a spring.
  static double _clampPan(
    double value,
    double current,
    double min,
    double max,
  ) {
    if (max <= min) {
      return current;
    }
    if (value >= min && value <= max) {
      return value;
    }
    if (value < min) {
      return current < min ? math.max(value, current) : min;
    }
    return current > max ? math.min(value, current) : max;
  }
}
