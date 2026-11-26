import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// A thin draggable handle between the editor area and the sidebar.
/// This is the fix for the web iframe pointer-steal: an `<iframe>` platform view swallows
/// raw pointer events the moment the cursor crosses into it, so the drag would die
/// mid-resize.
///
/// It is also one keyboard stop with [CcResizableDivider]'s key map: ←/→ move
/// it by [CcResizableDivider.keyboardStep] (Shift: the large step) and Home /
/// End as far as it goes toward the start / end edge, all through [onDrag].
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
  /// A press far longer than any split; the sidebar clamps it to its bounds.
  static const double _toTheEdge = 1e6;

  final FocusNode _focusNode = FocusNode(debugLabel: 'IdeSidebarDivider');
  bool _active = false;

  /// Focused from the keyboard: sampled when focus arrives, like [FocusRing].
  bool _keyboardFocused = false;
  OverlayEntry? _dragOverlay;

  void _setActive(bool value) {
    if (_active != value) {
      setState(() => _active = value);
    }
  }

  void _onFocusChange(bool focused) {
    final next = focused && FocusModality.instance.isKeyboard;
    if (next != _keyboardFocused && mounted) {
      setState(() => _keyboardFocused = next);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final step = keyboard.isShiftPressed
        ? CcResizableDivider.keyboardLargeStep
        : CcResizableDivider.keyboardStep;
    // Home / End are logical edges: under RTL the start edge is on the right.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final double delta;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        delta = -step;
      case LogicalKeyboardKey.arrowRight:
        delta = step;
      case LogicalKeyboardKey.home:
        delta = rtl ? _toTheEdge : -_toTheEdge;
      case LogicalKeyboardKey.end:
        delta = rtl ? -_toTheEdge : _toTheEdge;
      default:
        return KeyEventResult.ignored;
    }
    widget.onDrag(delta);
    return KeyEventResult.handled;
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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _active || _keyboardFocused;
    final line = AnimatedContainer(
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      width: active ? 2 : 1,
      color: active ? widget.activeColor : widget.color,
    );
    // Touch the tracker so the first key press of a session is seen.
    // ignore: unnecessary_statements
    FocusModality.instance;
    final divider = MouseRegion(
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
    return Semantics(
      container: true,
      slider: true,
      label: context.ccStrings.resize,
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        onFocusChange: _onFocusChange,
        child: divider,
      ),
    );
  }
}
