import 'dart:math' as math;

import 'package:cc_markdown/src/mermaid/layout/scene.dart';
import 'package:flutter/widgets.dart';

/// Controls one interactive `CcMermaidView`'s scene-to-viewport transform.
///
/// The view fits the complete scene on first layout, scene changes and resize.
/// Paint-only changes preserve the operator's pan/zoom. Dispose this controller
/// after removing its view; a controller cannot be shared by mounted views.
class CcMermaidViewportController extends TransformationController {
  Object? _owner;
  Size _viewportSize = Size.zero;
  Matrix4? _fitted;
  double _minScale = 0.5;

  /// Current viewport size, available after layout.
  Size get viewportSize => _viewportSize;

  /// Zoom floor, lowered when needed to fit a large diagram in full.
  double get minScale => _minScale;

  /// Zoom ceiling in logical scene units, independent of the initial fit.
  double get maxScale => 4;

  /// Restores the complete diagram, returning false when no view is laid out.
  bool fit() {
    if (_owner == null || _fitted == null) {
      return false;
    }
    value = _fitted!.clone();
    return true;
  }

  void _attach(Object owner) {
    if (_owner != null && !identical(_owner, owner)) {
      throw StateError(
        'A Mermaid viewport controller can only drive one view.',
      );
    }
    _owner = owner;
  }

  void _detach(Object owner) {
    if (!identical(_owner, owner)) {
      return;
    }
    _owner = null;
    _viewportSize = Size.zero;
    _fitted = null;
  }

  void _fitScene(Size viewport, Size scene, double scale) {
    _viewportSize = viewport;
    _minScale = math.min(0.5, scale);
    _fitted = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - scene.width * scale) / 2,
        (viewport.height - scene.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
    fit();
  }
}

/// Internal viewport; the child is painted at its natural scene size.
class CcMermaidViewport extends StatefulWidget {
  /// Creates a fitted viewport without an inline horizontal scroller.
  const CcMermaidViewport({
    required this.scene,
    required this.child,
    this.controller,
    super.key,
  });

  /// Geometry whose identity determines when the view needs a fresh fit.
  final CcMermaidScene scene;

  /// Canvas at the scene's logical size, with no pre-scaling or scrolling.
  final Widget child;

  /// Host-owned transform; omitted when only gesture navigation is needed.
  final CcMermaidViewportController? controller;

  @override
  State<CcMermaidViewport> createState() => _CcMermaidViewportState();
}

class _CcMermaidViewportState extends State<CcMermaidViewport> {
  late CcMermaidViewportController _controller;
  Size? _viewport;
  CcMermaidScene? _scene;
  int _layoutRevision = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CcMermaidViewportController();
    _controller._attach(this);
  }

  @override
  void didUpdateWidget(CcMermaidViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller._detach(this);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? CcMermaidViewportController();
      _controller._attach(this);
      _viewport = null;
    }
  }

  @override
  void dispose() {
    _layoutRevision++;
    _controller._detach(this);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = widget.scene.size;
        final viewport = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : size.width,
          constraints.hasBoundedHeight ? constraints.maxHeight : size.height,
        );
        if (viewport.isEmpty) {
          return SizedBox.fromSize(size: viewport);
        }
        final fitScale = math.min(
          1.0,
          math.min(viewport.width / size.width, viewport.height / size.height),
        );
        if (_viewport != viewport || !identical(_scene, widget.scene)) {
          _viewport = viewport;
          _scene = widget.scene;
          final revision = ++_layoutRevision;
          // External controls listen to the transform. Notify after layout,
          // never by marking a sibling dirty inside this LayoutBuilder.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && revision == _layoutRevision) {
              _controller._fitScene(viewport, size, fitScale);
            }
          });
        }
        return SizedBox.fromSize(
          size: viewport,
          child: InteractiveViewer(
            transformationController: _controller,
            constrained: false,
            // RTL carve-out: scene coordinates, not interface chrome.
            alignment: Alignment.topLeft,
            minScale: math.min(0.5, fitScale),
            maxScale: _controller.maxScale,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: widget.child,
          ),
        );
      },
    );
  }
}
