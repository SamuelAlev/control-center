import 'dart:async';

import 'package:flutter/widgets.dart';

/// Focuses a field when an inline editor appears, and hands focus back to
/// whatever had it once the editor goes away.
///
/// `autofocus: true` cannot do this inline: Flutter applies an autofocus only
/// while the enclosing scope has no focused child, and the button that opened
/// the editor usually is that child (a pressed button takes focus). This asks
/// for focus outright on the first frame instead.
///
/// [builder] builds the whole editor (the field and its own Save or Cancel
/// buttons) and gives the field the node it is handed. When the editor
/// unmounts while focus is still somewhere inside it, focus returns to the
/// node that held it when the editor opened, if that node is still on screen
/// and in the same focus scope (a field that opens with a dialog must not send
/// focus back behind it). A close caused by focus moving elsewhere leaves
/// focus where it went.
class FocusOnMount extends StatefulWidget {
  /// Creates an editor that takes focus when it mounts.
  const FocusOnMount({
    super.key,
    required this.builder,
    this.focusNode,
    this.autofocus = true,
  });

  /// Builds the editor; `focusNode` goes on the field that takes focus.
  final Widget Function(BuildContext context, FocusNode focusNode) builder;

  /// The field's node when the caller already owns one; otherwise this widget
  /// owns and disposes its own.
  final FocusNode? focusNode;

  /// Whether the field takes focus on this mount. Read once, when it mounts:
  /// a host that builds the same editor again (scrolled back into view) passes
  /// false so focus is not pulled back to it.
  final bool autofocus;

  @override
  State<FocusOnMount> createState() => _FocusOnMountState();
}

class _FocusOnMountState extends State<FocusOnMount> {
  FocusNode? _owned;
  FocusNode? _opener;
  bool _heldFocusAtClose = false;

  // Never takes focus itself: it only reports whether focus is inside.
  final FocusNode _region = FocusNode(
    debugLabel: 'FocusOnMount',
    canRequestFocus: false,
    skipTraversal: true,
  );

  FocusNode get _node =>
      widget.focusNode ?? (_owned ??= FocusNode(debugLabel: 'FocusOnMount'));

  @override
  void initState() {
    super.initState();
    if (!widget.autofocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // One microtask later, so focus moves this frame queued (a menu that
      // closed and gave focus back to its trigger) have landed: the opener
      // is then the trigger, not the menu item that is gone.
      scheduleMicrotask(() {
        if (mounted && !_node.hasFocus) {
          _opener = FocusManager.instance.primaryFocus;
          _node.requestFocus();
        }
      });
    });
  }

  @override
  void activate() {
    super.activate();
    _heldFocusAtClose = false;
  }

  @override
  void deactivate() {
    // Read while the subtree is still attached: by dispose focus has already
    // left it.
    _heldFocusAtClose =
        _region.hasFocus && _opener?.nearestScope == _region.nearestScope;
    super.deactivate();
  }

  @override
  void dispose() {
    _region.dispose();
    _owned?.dispose();
    final opener = _opener;
    // A parent, not a context, is liveness: a detached node keeps its context,
    // and focusing one re-registers a dead focused child.
    if (_heldFocusAtClose &&
        opener != null &&
        opener.parent != null &&
        opener.context != null &&
        opener.canRequestFocus) {
      opener.requestFocus();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _region,
      includeSemantics: false,
      child: widget.builder(context, _node),
    );
  }
}
