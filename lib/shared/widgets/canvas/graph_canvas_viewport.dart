import 'dart:math' as math;

import 'package:control_center/shared/widgets/canvas/canvas_wheel_pan.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:control_center/shared/widgets/dot_grid_background.dart';
import 'package:flutter/widgets.dart';

/// A retained scene for read-only node graphs. Camera gestures transform the
/// scene without rebuilding node widgets, measuring labels or rerunning layout.
class GraphCanvasViewport extends StatefulWidget {
  /// [bounds] encloses the nodes in graph coordinates. [sceneBuilder] receives
  /// the translation that places those coordinates inside the padded scene.
  const GraphCanvasViewport({
    required this.bounds,
    required this.sceneBuilder,
    super.key,
  });

  /// Graph-space content bounds, including nodes with negative coordinates.
  final Rect bounds;

  /// Builds the edge and node layers, independently of the camera transform.
  final Widget Function(Offset shift) sceneBuilder;

  @override
  State<GraphCanvasViewport> createState() => _GraphCanvasViewportState();
}

class _GraphCanvasViewportState extends State<GraphCanvasViewport> {
  static const _padding = 48.0;
  final _transform = TransformationController();
  late final _wheel = CanvasWheelPan(_transform);
  Size _viewport = Size.zero;
  Size _sceneSize = Size.zero;
  Offset _shift = Offset.zero;
  Matrix4? _home;
  int _revision = 0;

  @override
  void dispose() {
    _revision++;
    _transform.dispose();
    super.dispose();
  }

  Matrix4 _matrix(double scale, Offset translation) => Matrix4.identity()
    ..translateByDouble(translation.dx, translation.dy, 0, 1)
    ..scaleByDouble(scale, scale, scale, 1);

  double get _fitScale => math.min(
    1.0,
    math.min(
      _viewport.width / _sceneSize.width,
      _viewport.height / _sceneSize.height,
    ),
  );

  void _fit() {
    if (_viewport.isEmpty) {
      return;
    }
    final scale = _fitScale;
    _transform.value = _matrix(
      scale,
      Offset(
        (_viewport.width - _sceneSize.width * scale) / 2,
        (_viewport.height - _sceneSize.height * scale) / 2,
      ),
    );
  }

  void _layout(Size viewport, Size sceneSize, Offset shift) {
    if (_viewport == viewport && _sceneSize == sceneSize && _shift == shift) {
      return;
    }
    final previousViewport = _viewport;
    final previousShift = _shift;
    _viewport = viewport;
    _sceneSize = sceneSize;
    _shift = shift;
    final revision = ++_revision;
    // Controls listen to the matrix: publish after layout, not while a sibling
    // is building. A status-only update never enters this path.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _revision || viewport.isEmpty) {
        return;
      }
      final wasHome = _home == null || _transform.value == _home;
      _home = _matrix(
        1,
        Offset(
          math.max(0, (viewport.width - sceneSize.width) / 2),
          (viewport.height - sceneSize.height) / 2,
        ),
      );
      if (wasHome) {
        // Native-size labels on opening; wide graphs start at their roots.
        _transform.value = _home!.clone();
      } else {
        // A sidebar resize or a widened node must not discard the user's pan.
        final scale = _transform.value.getMaxScaleOnAxis();
        final translation = _transform.value.getTranslation();
        _transform.value = _matrix(
          scale,
          Offset(translation.x, translation.y) +
              (previousShift - shift) * scale +
              Offset(
                (viewport.width - previousViewport.width) / 2,
                (viewport.height - previousViewport.height) / 2,
              ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.bounds;
    final shift = const Offset(_padding, _padding) - bounds.topLeft;
    final sceneSize = Size(
      bounds.width + _padding * 2,
      bounds.height + _padding * 2,
    );
    final scene = RepaintBoundary(
      child: SizedBox.fromSize(
        size: sceneSize,
        child: widget.sceneBuilder(shift),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        _layout(viewport, sceneSize, shift);
        if (viewport.isEmpty) {
          return const SizedBox.shrink();
        }
        final minScale = math.min(0.25, _fitScale);
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: _transform,
                    builder: (context, _) {
                      final matrix = _transform.value;
                      final translation = matrix.getTranslation();
                      return DotGridBackground(
                        offset: Offset(translation.x, translation.y),
                        scale: matrix.getMaxScaleOnAxis(),
                      );
                    },
                  ),
                ),
              ),
              Listener(
                onPointerSignal: (event) => _wheel.onPointerSignal(
                  event,
                  viewport: viewport,
                  canvas: sceneSize,
                  boundaryMargin: double.infinity,
                ),
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  // RTL carve-out: graph coordinates stay physical; chrome mirrors.
                  alignment: Alignment.topLeft,
                  minScale: minScale,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  onInteractionStart: (_) => _wheel.beginInteraction(),
                  child: scene,
                ),
              ),
              PositionedDirectional(
                end: kCanvasControlInset,
                bottom: kCanvasControlInset,
                child: CanvasZoomControls(
                  controller: _transform,
                  viewport: () => _viewport,
                  minScale: minScale,
                  onReset: _fit,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
