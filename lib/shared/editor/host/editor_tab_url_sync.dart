import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart' show VoidCallback;

/// Two-way sync helpers between an [EditorLayoutController]'s focused tab and
/// the `?tab=` query param of a tabbed detail surface (channel conversation,
/// PR detail).
///
/// The URL is the source of truth for *which tab is focused*, the same way the
/// path already is for which channel / PR is open: a tab switch navigates
/// (pushing a back/forward entry) and a refresh or deep-link restores the
/// named tab. Layout persistence (the cached split tree + selection) still
/// owns everything the URL does not name — the URL only carries the focus.
///
/// A `null` key means "no opinion": the surface keeps whatever the seeded /
/// restored layout selected. It never commands a focus change on load.
const String editorTabQueryParam = 'tab';

/// A tab's URL identity: its [EditorTab.dedupKey] when it has one, else its
/// kind. The kind fallback is ambiguous between same-kind siblings (e.g. two
/// terminals), but still restores *a* tab of that kind.
String editorTabKey(EditorTab tab) => tab.dedupKey ?? tab.kind;

/// The URL key of the focused tab — the selected tab of the active leaf — or
/// null when the active leaf holds no tabs.
String? activeEditorTabKey(EditorLayoutController layout) {
  final controller = layout.activeLeaf.controller;
  if (controller.isEmpty) {
    return null;
  }
  return editorTabKey(controller.tabs[controller.selectedIndex]);
}

/// Focuses the first tab (across all leaves) whose [editorTabKey] is [key].
/// Returns false when no open tab matches — a stale key (the tab was closed
/// since the URL was written) degrades to leaving the current selection.
bool focusEditorTabByKey(EditorLayoutController layout, String key) =>
    layout.focusTab((t) => editorTabKey(t) == key);

/// [current] as a navigable location with the `?tab=` param set to [key]
/// (removed when null), every other query param preserved.
String locationWithEditorTab(Uri current, String? key) {
  final params = Map<String, String>.of(current.queryParameters)
    ..remove(editorTabQueryParam);
  if (key != null) {
    params[editorTabQueryParam] = key;
  }
  if (params.isEmpty) {
    // `Uri.replace(queryParameters: …)` cannot CLEAR a query (null keeps the
    // old one, an empty map leaves a dangling '?'), so strip it textually.
    // App routes never carry a fragment, so everything before '?' is the
    // location.
    final raw = current.toString();
    final q = raw.indexOf('?');
    return q < 0 ? raw : raw.substring(0, q);
  }
  return current.replace(queryParameters: params).toString();
}

/// The two-way sync state machine between an [EditorLayoutController]'s
/// focused tab and a `?tab=` query param, shared by the tabbed detail
/// surfaces (channel conversation, PR detail).
///
/// Direction 1 — layout → URL: the host calls [writeFromLayout] from its
/// layout-change listener; when the focused key diverges from the last key
/// this tracker wrote or applied, the USER changed the focus and the write
/// callback fires (the host navigates, pushing a back/forward entry).
///
/// Direction 2 — URL → layout: the host calls [apply] when the route's
/// `?tab=` changes (back/forward, deep-link) and with `force: true` after a
/// layout restore (the URL outranks the restored selection).
///
/// The per-surface differences are injected as callbacks: the focus action
/// (the PR page opens a closed fixed tab, messaging focuses only), the
/// default tab (Overview vs the first tab) and the write action (the host
/// owns the BuildContext / GoRouter).
///
/// Reentrancy: focus mutations notify SYNCHRONOUSLY, so an [apply] would
/// otherwise re-enter [writeFromLayout] mid-apply — before the tracker
/// settles — and push a spurious history entry. The applying flag closes
/// that hole.
class EditorTabUrlTracker {
  /// Creates a tracker seeded with the route's current `?tab=` value.
  EditorTabUrlTracker({
    required String? initialKey,
    required this._focusKey,
    required this._focusDefault,
    required this._writeKey,
  }) : _lastKey = initialKey;

  final void Function(String key) _focusKey;
  final VoidCallback _focusDefault;
  final void Function(String? key) _writeKey;

  /// The last key written to or applied from the URL.
  String? _lastKey;

  /// True while [apply] runs (suppresses the write its notifications trigger).
  bool _applying = false;

  /// The last key this tracker wrote or applied (exposed for tests).
  String? get lastKey => _lastKey;

  /// Re-tracks the layout's current focus WITHOUT navigating or focusing —
  /// used after the tab set was replaced with no URL opinion (conversation
  /// switch, null-key restore), so a later non-focus layout change (drag,
  /// split, title update) doesn't read as a focus change and push a spurious
  /// `?tab=` entry.
  void resync(EditorLayoutController layout) {
    _lastKey = activeEditorTabKey(layout);
  }

  /// URL → layout: focuses the tab [key] names.
  ///
  /// With [force], [key] is applied even when it equals [lastKey] — used
  /// right after a layout restore, which replaces the tab set the tracker was
  /// synced against. A null key means the URL has no opinion: [force] merely
  /// [resync]s (keep the seeded/restored selection), otherwise the surface
  /// returns to its default tab (back/forward landed on a location written
  /// before any tab switch).
  void apply(EditorLayoutController layout, String? key, {bool force = false}) {
    if (_applying) {
      return;
    }
    if (force) {
      if (key == null) {
        resync(layout);
        return;
      }
      _applying = true;
      try {
        _lastKey = key;
        // A stale key (the tab was closed since the URL was written) leaves
        // the restored selection — the host's focus decides.
        _focusKey(key);
      } finally {
        _applying = false;
      }
      return;
    }
    if (key == _lastKey) {
      return;
    }
    _applying = true;
    try {
      if (key != null) {
        _lastKey = key;
        _focusKey(key);
      } else {
        _focusDefault();
        resync(layout);
      }
    } finally {
      _applying = false;
    }
  }

  /// Layout → URL: when the focused key diverges from [lastKey], tracks it
  /// and fires the write callback. A focused key equal to [lastKey]
  /// (including both null) is a no-op.
  void writeFromLayout(EditorLayoutController layout) {
    if (_applying) {
      return;
    }
    final key = activeEditorTabKey(layout);
    if (key == _lastKey) {
      return;
    }
    _lastKey = key;
    _writeKey(key);
  }
}
