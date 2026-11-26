import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The focus nodes of a roving-tabindex composite (a tab strip, a segmented
/// toggle): one node per item, exactly one of them a Tab stop.
///
/// Every item stays focusable so an arrow key can move focus to it at once;
/// the items that are not the stop are only skipped by Tab. There is no focus
/// scope around the items, so Tab leaves the composite after its one stop.
class CcRovingFocusNodes {
  /// Creates nodes for [count] items.
  CcRovingFocusNodes(this._debugLabel, int count) {
    sync(count);
  }

  final String _debugLabel;
  final List<FocusNode> _nodes = [];

  /// The node of item [index].
  FocusNode operator [](int index) => _nodes[index];

  /// The number of items.
  int get length => _nodes.length;

  /// The item that holds focus, or null when focus is elsewhere.
  int? get focusedIndex {
    final index = _nodes.indexWhere((node) => node.hasFocus);
    return index < 0 ? null : index;
  }

  /// Grows or shrinks to [count] items. Existing nodes keep their index, so
  /// focus stays on the item it was on. When the focused item is removed,
  /// focus moves to the item now at the end instead of falling out of the
  /// composite.
  void sync(int count) {
    while (_nodes.length < count) {
      _nodes.add(FocusNode(debugLabel: '$_debugLabel ${_nodes.length}'));
    }
    if (_nodes.length <= count) {
      return;
    }
    final removed = _nodes.sublist(count);
    _nodes.removeRange(count, _nodes.length);
    final hadFocus = removed.any((node) => node.hasFocus);
    // The removed items' widgets still hold these nodes until the rebuild
    // that drops them; dispose after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final node in removed) {
        node.dispose();
      }
      if (hadFocus && _nodes.isNotEmpty) {
        _nodes.last.requestFocus();
      }
    });
  }

  /// Makes item [stop] the only one Tab reaches.
  void setStop(int stop) {
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != stop;
    }
  }

  /// Disposes every node.
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _nodes.clear();
  }
}

/// The item an arrow, Home or End key moves to in a roving composite, or null
/// when [event] is not one of those keys, so the caller can return
/// [KeyEventResult.ignored] and the key reaches the app.
///
/// [current] is the item that has focus. Movement wraps and skips items for
/// which [isEnabled] is false. Left and Right follow the reading direction
/// ([rtl] flips them). Up and Down move only when [vertical] is true: a
/// horizontal strip leaves them to directional focus. A key held with Ctrl,
/// Alt, Meta or Shift is left alone, since those chords belong to the app.
int? ccRovingTarget({
  required KeyEvent event,
  required int current,
  required int count,
  required bool rtl,
  bool vertical = false,
  bool Function(int index)? isEnabled,
}) {
  if (event is KeyUpEvent || count == 0) {
    return null;
  }
  final keyboard = HardwareKeyboard.instance;
  if (keyboard.isControlPressed ||
      keyboard.isAltPressed ||
      keyboard.isMetaPressed ||
      keyboard.isShiftPressed) {
    return null;
  }
  bool enabled(int index) => isEnabled?.call(index) ?? true;

  int? step(int from, int delta) {
    var index = from;
    for (var i = 0; i < count; i++) {
      index = (index + delta) % count;
      if (enabled(index)) {
        return index;
      }
    }
    return null;
  }

  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.arrowRight) {
    return step(current, rtl ? -1 : 1);
  }
  if (key == LogicalKeyboardKey.arrowLeft) {
    return step(current, rtl ? 1 : -1);
  }
  if (vertical && key == LogicalKeyboardKey.arrowDown) {
    return step(current, 1);
  }
  if (vertical && key == LogicalKeyboardKey.arrowUp) {
    return step(current, -1);
  }
  if (key == LogicalKeyboardKey.home) {
    return step(count - 1, 1);
  }
  if (key == LogicalKeyboardKey.end) {
    return step(0, -1);
  }
  return null;
}
