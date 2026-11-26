import 'package:flutter/widgets.dart';

/// The focus lifecycle of a floating surface (popover, menu, dropdown panel):
/// focus moves into it when it opens, Tab and Shift+Tab stay inside it, and
/// focus returns to whatever had it before once the surface closes.
///
/// `FocusScope(autofocus: true)` cannot do the first part on its own: Flutter
/// applies an autofocus only while the enclosing scope has no focused child,
/// and the trigger that opened the surface usually is that child. The trap
/// asks for focus outright instead. A descendant with `autofocus: true` (a
/// search field, a list's key handler) still wins, because the trap's own
/// scope starts empty.
///
/// Focus goes back to the opener only when the surface still held it at the
/// moment it closed. A close caused by focus moving elsewhere leaves focus
/// where the person put it.
class CcFocusTrap extends StatefulWidget {
  /// Creates a focus trap around [child].
  const CcFocusTrap({
    super.key,
    required this.child,
    this.node,
    this.autofocus = true,
    this.restoreFocus = true,
    this.debugLabel,
  });

  /// The surface.
  final Widget child;

  /// The scope to use. Its `traversalEdgeBehavior` decides whether Tab is
  /// held inside; when null the trap owns a `closedLoop` scope.
  final FocusScopeNode? node;

  /// Whether focus moves into the surface when it mounts. A surface whose
  /// keyboard owner stays outside it (a filter field in the trigger) passes
  /// false.
  final bool autofocus;

  /// Whether focus returns to the previous owner when the surface closes.
  final bool restoreFocus;

  /// Debug label for the owned scope.
  final String? debugLabel;

  @override
  State<CcFocusTrap> createState() => _CcFocusTrapState();
}

class _CcFocusTrapState extends State<CcFocusTrap> {
  FocusScopeNode? _owned;
  FocusNode? _previous;
  bool _heldFocusAtClose = false;

  FocusScopeNode get _node =>
      widget.node ??
      (_owned ??= FocusScopeNode(
        debugLabel: widget.debugLabel ?? 'CcFocusTrap',
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      ));

  @override
  void initState() {
    super.initState();
    _previous = FocusManager.instance.primaryFocus;
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_node.hasFocus) {
          _node.requestFocus();
        }
      });
    }
  }

  @override
  void activate() {
    super.activate();
    _heldFocusAtClose = false;
  }

  @override
  void deactivate() {
    // Read while the subtree is still attached: by dispose the scope's
    // children have detached and focus has already left them.
    _heldFocusAtClose = _node.hasFocus;
    super.deactivate();
  }

  @override
  void dispose() {
    _owned?.dispose();
    final previous = _previous;
    // `context != null` is not liveness (a detached node keeps it); a parent
    // is. Focusing a detached node re-registers a dead focused child.
    if (widget.restoreFocus &&
        _heldFocusAtClose &&
        previous != null &&
        previous.parent != null &&
        previous.context != null &&
        previous.canRequestFocus) {
      previous.requestFocus();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(node: _node, child: widget.child);
  }
}
