import 'package:flutter/widgets.dart';

/// A single tab in an editor tab-group.
///
/// [kind] is an opaque, caller-defined string (e.g. messaging's `chat` /
/// `terminal`, or the PR page's `overview` / `diff`). The editor engine never
/// interprets it — the host's body builder switches on it to render a body and
/// the host may use it plus [args] to look tabs up. Keeping it a string is what
/// lets the split/drag-and-drop engine be reused across features without the
/// engine knowing any feature's tab vocabulary.
///
/// [args] carries the kind-specific payload the host's body builder needs.
/// [icon] is an optional leading glyph shown in the tab strip. [dedupKey], when
/// non-null, makes the tab unique within a group: opening another tab with the
/// same key refocuses (and replaces) the existing one instead of stacking.
///
/// **Identity matters.** [EditorTab] deliberately does NOT override `==`/
/// `hashCode`: instances are compared by identity. The layout uses a tab's
/// identity as the stable key for its live body (terminal PTY, webview, a
/// scrolled diff), so the *same* instance must travel as it is reordered or
/// moved between panes — that is what lets the body be reparented rather than
/// rebuilt. Never copy a tab to move it; move the instance.
@immutable
class EditorTab {
  /// Creates an [EditorTab].
  const EditorTab({
    required this.kind,
    required this.label,
    this.args = const {},
    this.icon,
    this.dedupKey,
  });

  /// Opaque, caller-defined content kind — drives the host's body builder and
  /// (optionally) its de-dupe / focus logic.
  final String kind;

  /// Header label (already localised).
  final String label;

  /// Kind-specific payload (interpreted by the host's body builder).
  final Map<String, Object?> args;

  /// Optional leading icon rendered in the tab strip.
  final IconData? icon;

  /// When non-null, the tab is unique within its group by this key: opening a
  /// second tab with the same key refocuses/replaces the existing one.
  final String? dedupKey;
}

/// Owns the open tabs + selection for one editor tab-group (one leaf of the
/// editor split tree).
///
/// Held by the layout controller so the tab set survives pane rebuilds; this is
/// ephemeral UI state, NOT Riverpod-managed.
class EditorTabGroupController extends ChangeNotifier {
  final List<EditorTab> _tabs = [];
  int _selectedIndex = 0;

  /// Visit order, most recent first, compared by IDENTITY — the back-stack that
  /// makes closing the active tab return to the tab you came from rather than
  /// always falling to the left neighbour.
  ///
  /// Identity (not index) is what survives everything that shuffles this list:
  /// reorders, a background insert shifting every index up, a cross-leaf move.
  /// Entries are pruned as tabs leave and rewritten when a tab's instance is
  /// replaced, so the head is always a live tab of this group.
  final List<EditorTab> _visitOrder = [];

  /// The current tabs (unmodifiable view).
  List<EditorTab> get tabs => List.unmodifiable(_tabs);

  /// Whether this group holds no tabs.
  bool get isEmpty => _tabs.isEmpty;

  /// Selected tab index, clamped to the valid range (0 when empty).
  int get selectedIndex =>
      _tabs.isEmpty ? 0 : _selectedIndex.clamp(0, _tabs.length - 1);

  set selectedIndex(int value) {
    _selectedIndex = value;
    _visit(value);
    notifyListeners();
  }

  /// Records the tab at [index] as the most recently visited one.
  void _visit(int index) {
    if (index < 0 || index >= _tabs.length) {
      return;
    }
    final tab = _tabs[index];
    _visitOrder
      ..removeWhere((t) => identical(t, tab))
      ..insert(0, tab);
  }

  /// Drops [tab] from the visit order (it left the group, or its instance was
  /// replaced).
  void _forget(EditorTab tab) =>
      _visitOrder.removeWhere((t) => identical(t, tab));

  /// Appends [tab] and selects it. When [EditorTab.dedupKey] is non-null and a
  /// tab with the same key already exists, that tab is refocused instead of
  /// stacking a duplicate — and replaced in place only when the payload
  /// actually changed (same rule as [refreshTabAt]).
  ///
  /// The unchanged-payload guard is not an optimisation. A tab's identity keys
  /// its live body AND the host's per-tab bookkeeping, so swapping in a fresh
  /// instance reads downstream as "the old tab left the tree": the messaging
  /// IDE destroys the machine of a browser-rig tab that leaves, which is how
  /// re-picking "WebKit (VM)" from the `[+]` menu shut down the very machine it
  /// was meant to bring forward.
  void openTab(EditorTab tab) {
    final key = tab.dedupKey;
    if (key != null) {
      final idx = _tabs.indexWhere((t) => t.dedupKey == key);
      if (idx >= 0) {
        final current = _tabs[idx];
        if (current.label != tab.label || !_sameArgs(current.args, tab.args)) {
          _tabs[idx] = tab;
          _forget(current);
        }
        _selectedIndex = idx;
        _visit(idx);
        notifyListeners();
        return;
      }
    }
    _tabs.add(tab);
    _selectedIndex = _tabs.length - 1;
    _visit(_selectedIndex);
    notifyListeners();
  }

  /// Inserts [tab] at [index] (clamped) and selects it. Used by drag-move /
  /// split, which carry an exact target position — so, unlike [openTab], this
  /// does not de-dupe (a deliberate drag is the user's intent).
  void insert(int index, EditorTab tab) {
    final i = index.clamp(0, _tabs.length);
    _tabs.insert(i, tab);
    _selectedIndex = i;
    _visit(i);
    notifyListeners();
  }

  /// Inserts [tab] at [index] (clamped) WITHOUT changing the selection — for
  /// background/programmatic injection (e.g. an auto-detected deploy preview)
  /// that must not yank focus off the tab the user is on. The selected tab
  /// stays selected: its index shifts up by one when the insertion lands at or
  /// before it.
  void insertWithoutFocus(int index, EditorTab tab) {
    final i = index.clamp(0, _tabs.length);
    final sel = selectedIndex;
    _tabs.insert(i, tab);
    _selectedIndex = i <= sel ? sel + 1 : sel;
    notifyListeners();
  }

  /// Replaces the tab at [index] with [replacement] in place, keeping the
  /// selection — but only when the payload actually changed (same
  /// [EditorTab.dedupKey],
  /// different label/args). Returns whether a replacement happened.
  ///
  /// The no-op guard matters: a tab's identity keys its live body (a webview,
  /// a PTY), so replacing the instance tears that body down and rebuilds it.
  /// A reconcile that re-asserts an unchanged preview must therefore leave the
  /// instance untouched.
  bool refreshTabAt(int index, EditorTab replacement) {
    if (index < 0 || index >= _tabs.length) {
      return false;
    }
    final current = _tabs[index];
    if (current.label == replacement.label &&
        _sameArgs(current.args, replacement.args)) {
      return false;
    }
    _tabs[index] = replacement;
    // Keep the tab's place in the back-stack across the instance swap: the
    // user's sense of "where I came from" is about the tab, not the object.
    final at = _visitOrder.indexWhere((t) => identical(t, current));
    if (at >= 0) {
      _visitOrder[at] = replacement;
    }
    notifyListeners();
    return true;
  }

  static bool _sameArgs(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// Removes and returns the tab at [index]. Selection on close:
  ///   * closing the **active** tab falls back to the tab you were on before
  ///     it ([_visitOrder]) — browser-style, so ⌘W walks back the way you came
  ///     instead of marching left through tabs you never opened. With no
  ///     surviving history (a fresh restore, or every earlier tab closed) it
  ///     selects the tab just before it, the VS Code fallback;
  ///   * closing a tab **before** the active one keeps the active one selected
  ///     (its index shifts down by one to compensate);
  ///   * closing a tab **after** the active one leaves the selection unchanged.
  /// Returns null when [index] is out of range.
  EditorTab? removeAt(int index) {
    if (index < 0 || index >= _tabs.length) {
      return null;
    }
    final current = selectedIndex;
    final removed = _tabs.removeAt(index);
    _forget(removed);
    if (_tabs.isEmpty) {
      _selectedIndex = 0;
    } else if (index == current) {
      // The head of the back-stack is now the tab visited before this one.
      final previous = _visitOrder.isEmpty
          ? -1
          : indexOfIdentity(_visitOrder.first);
      _selectedIndex = previous >= 0
          ? previous
          : (index - 1).clamp(0, _tabs.length - 1);
      _visit(_selectedIndex);
    } else if (index < current) {
      _selectedIndex = current - 1;
    } else {
      _selectedIndex = current;
    }
    notifyListeners();
    return removed;
  }

  /// Moves the tab at [oldIndex] to insertion index [newIndex] and selects it
  /// at its new position.
  ///
  /// [newIndex] uses insertion semantics against the *pre-removal* list (0 ..
  /// length, so `length` means "after the last tab") — matching
  /// `ReorderableListView.onReorder`. A move that lands the tab back in place is
  /// a silent no-op.
  void reorder(int oldIndex, int newIndex) {
    if (_tabs.isEmpty) {
      return;
    }
    final from = oldIndex.clamp(0, _tabs.length - 1);
    final insertAt = newIndex.clamp(0, _tabs.length);
    // Inserting at `from` or `from + 1` leaves the tab exactly where it was.
    if (insertAt == from || insertAt == from + 1) {
      return;
    }
    final tab = _tabs.removeAt(from);
    // Once the source is pulled out, a later target shifts left by one.
    final to = (insertAt > from ? insertAt - 1 : insertAt).clamp(
      0,
      _tabs.length,
    );
    _tabs.insert(to, tab);
    _selectedIndex = to.clamp(0, _tabs.length - 1);
    _visit(_selectedIndex);
    notifyListeners();
  }

  /// Removes the currently-selected tab and clamps the selection.
  void closeSelected() {
    if (_tabs.isEmpty) {
      return;
    }
    removeAt(selectedIndex);
  }

  /// Index of [tab] by identity, or -1 when it is not in this group.
  int indexOfIdentity(EditorTab tab) {
    for (var i = 0; i < _tabs.length; i++) {
      if (identical(_tabs[i], tab)) {
        return i;
      }
    }
    return -1;
  }
}
