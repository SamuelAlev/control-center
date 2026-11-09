import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// A thin draggable handle between the editor area and the sidebar.
/// This is the fix for the web iframe pointer-steal: an `<iframe>` platform view swallows
/// raw pointer events the moment the cursor crosses into it, so the drag would die
/// mid-resize.
class IdeSidebarDivider extends StatefulWidget {
  /// Creates the divider.
  const IdeSidebarDivider({
    super.key,
    required this.color,
    required this.activeColor,
    required this.onDrag,
    this.hitSize = 8,
  });

  /// The hairline's resting color.
  final Color color;

  /// The hairline's color while hovered or dragged.
  final Color activeColor;

  /// Reports each drag's physical horizontal delta.
  final ValueChanged<double> onDrag;

  /// Width of the invisible pointer hit area centered on the seam.
  final double hitSize;

  @override
  State<IdeSidebarDivider> createState() => _IdeSidebarDividerState();
}

class _IdeSidebarDividerState extends State<IdeSidebarDivider> {
  bool _active = false;
  OverlayEntry? _dragOverlay;

  void _setActive(bool value) {
    if (_active != value) {
      setState(() => _active = value);
    }
  }

  /// Pushes a transparent full-screen [PointerInterceptor] over the IDE so the
  /// embedded iframe/code-server can't swallow pointer events during the drag.
  void _beginDragOverlay() {
    if (_dragOverlay != null) {
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    _dragOverlay = OverlayEntry(
      // PointerInterceptor drops a transparent DOM element above every web
      // platform view so the iframe below can't steal the drag's pointer
      // stream. The inner AbsorbPointer/MouseRegion covers desktop native
      // platform views (where PointerInterceptor is a passthrough) and keeps
      // the resize cursor showing across the whole surface while dragging.
      builder: (_) => Positioned.fill(
        child: PointerInterceptor(
          child: const MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            opaque: false,
            child: AbsorbPointer(),
          ),
        ),
      ),
    );
    overlay.insert(_dragOverlay!);
  }

  void _endDragOverlay() {
    _dragOverlay?.remove();
    _dragOverlay = null;
  }

  @override
  void dispose() {
    _endDragOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = AnimatedContainer(
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      width: _active ? 2 : 1,
      color: _active ? widget.activeColor : widget.color,
    );
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => _setActive(true),
      onExit: (_) => _setActive(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _setActive(true);
          _beginDragOverlay();
        },
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx != 0) {
            widget.onDrag(details.delta.dx);
          }
        },
        onHorizontalDragEnd: (_) {
          _setActive(false);
          _endDragOverlay();
        },
        onHorizontalDragCancel: () {
          _setActive(false);
          _endDragOverlay();
        },
        child: SizedBox(
          width: widget.hitSize,
          child: Center(
            child: SizedBox(height: double.infinity, child: line),
          ),
        ),
      ),
    );
  }
}
