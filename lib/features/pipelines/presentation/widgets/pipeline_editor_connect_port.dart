import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Right-edge output handle on an editor tile. Dragging it draws an arrow
/// and dropping on another node creates the edge.
///
/// A [Listener] starts the wire on pointer down (no pan slop), a pointer
/// route keeps it after the cursor leaves the hit target, and a claim
/// recognizer wins the arena so [InteractiveViewer] cannot pan the first
/// drag. Hover reports out so the viewer can disable pan *before* down.
class PipelineEditorConnectPort extends StatefulWidget {
  /// Creates a [PipelineEditorConnectPort].
  const PipelineEditorConnectPort({
    super.key,
    required this.tooltip,
    required this.emphasized,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onDragCancel,
    this.onHoverChange,
  });

  /// Key for the output handle of [stepId], used by widget tests.
  static Key keyFor(String stepId) => ValueKey('pipeline-connect-from-$stepId');

  /// Localized "drag to connect" copy (semantics).
  final String tooltip;

  /// Selected or currently the connect source — fill, not colour alone.
  final bool emphasized;

  /// Pointer landed on the handle.
  final VoidCallback onDragStart;

  /// Port-drag pointer, in global coordinates.
  final void Function(Offset globalPosition) onDragUpdate;

  /// Pointer released.
  final void Function(Offset globalPosition) onDragEnd;

  /// Gesture cancelled (should not create an edge).
  final VoidCallback? onDragCancel;

  /// True while the pointer is over the handle (or a connect-drag from it
  /// is in flight). Lets the canvas lock viewer pan before pointer down.
  final ValueChanged<bool>? onHoverChange;

  @override
  State<PipelineEditorConnectPort> createState() =>
      _PipelineEditorConnectPortState();
}

class _PipelineEditorConnectPortState extends State<PipelineEditorConnectPort> {
  int? _pointer;

  @override
  void dispose() {
    if (_pointer != null) {
      _releasePointer();
      widget.onDragCancel?.call();
    }
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) {
      return;
    }
    _pointer = event.pointer;
    GestureBinding.instance.pointerRouter.addRoute(
      event.pointer,
      _onRoutedPointer,
    );
    widget.onHoverChange?.call(true);
    widget.onDragStart();
    widget.onDragUpdate(event.position);
  }

  void _releasePointer() {
    final pointer = _pointer;
    if (pointer == null) {
      return;
    }
    GestureBinding.instance.pointerRouter.removeRoute(pointer, _onRoutedPointer);
    _pointer = null;
  }

  void _syncHover(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    final hovering =
        box != null &&
        box.hasSize &&
        (Offset.zero & box.size).contains(box.globalToLocal(global));
    widget.onHoverChange?.call(hovering);
  }

  void _onRoutedPointer(PointerEvent event) {
    if (event is PointerMoveEvent) {
      widget.onDragUpdate(event.position);
      return;
    }
    if (event is PointerUpEvent) {
      final position = event.position;
      _releasePointer();
      _syncHover(position);
      widget.onDragEnd(position);
      return;
    }
    if (event is PointerCancelEvent) {
      _releasePointer();
      widget.onHoverChange?.call(false);
      widget.onDragCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final diameter = widget.emphasized ? 14.0 : 12.0;
    return Semantics(
      label: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        onEnter: (_) => widget.onHoverChange?.call(true),
        onExit: (_) {
          if (_pointer == null) {
            widget.onHoverChange?.call(false);
          }
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              _ClaimPointerRecognizer:
                  GestureRecognizerFactoryWithHandlers<_ClaimPointerRecognizer>(
                    _ClaimPointerRecognizer.new,
                    (_) {},
                  ),
            },
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.emphasized
                        ? tokens.accent
                        : tokens.bgPrimary,
                    border: Border.all(color: tokens.accent, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Left-edge input marker. Visual only — the tile itself is the drop target.
class PipelineEditorInputPort extends StatelessWidget {
  /// Creates a [PipelineEditorInputPort].
  const PipelineEditorInputPort({super.key, required this.emphasized});

  /// True when a connect-drag is hovering this tile.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final diameter = emphasized ? 14.0 : 10.0;
    return IgnorePointer(
      child: SizedBox(
        width: 16,
        height: 16,
        child: Center(
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emphasized ? tokens.accent : tokens.bgPrimary,
              border: Border.all(
                color: emphasized ? tokens.accent : tokens.borderSecondary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wins the arena on pointer down so an ancestor [ScaleGestureRecognizer]
/// (InteractiveViewer) cannot steal the connect-drag.
class _ClaimPointerRecognizer extends OneSequenceGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'pipeline-connect-claim';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
