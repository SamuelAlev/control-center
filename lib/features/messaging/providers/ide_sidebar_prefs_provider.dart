import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The panels the messaging IDE sidebar can host, in canonical strip order.
///
/// The enum order *is* the display order: pinning a view never reshuffles the
/// strip, it only decides whether the view has a cell of its own or lives in
/// the overflow menu. Names are persisted (see [ideSidebarPinnedViewsKey]), so
/// renaming a value silently unpins it — add new views at the end instead.
enum IdeSidebarView {
  /// Session dashboard: todos, agents, terminals.
  general,

  /// The workspace's linked repos as a file tree.
  explorer,

  /// The conversation worktree's working-tree diff.
  sourceControl,

  /// The space's environment: status, URLs, components, scripts and runs.
  environment,

  /// The shared per-space handoff doc.
  notes,

  /// Conversation-scoped artifacts (tables, charts, views).
  artifacts,
}

/// Which sidebar views own a cell in the icon strip.
///
/// Persisted per user through [AppPreferences] (same pattern as the PR queue's
/// display prefs) so an operator's rail survives restarts. Every view ships
/// pinned, so the strip starts fully populated until the operator unpins
/// something.
class IdeSidebarPinsNotifier extends Notifier<Set<IdeSidebarView>> {
  late AppPreferences _prefs;

  /// The out-of-the-box strip: every view pinned.
  static Set<IdeSidebarView> get defaultPinned => IdeSidebarView.values.toSet();

  @override
  Set<IdeSidebarView> build() {
    _prefs = ref.watch(appPreferencesProvider);
    final names = _prefs.getStringList(ideSidebarPinnedViewsKey);
    if (names == null) {
      return defaultPinned;
    }
    final viewByName = IdeSidebarView.values.asNameMap();
    // A view added after the list was saved was never offered for unpinning,
    // so it starts pinned like every view does on a fresh install.
    final known =
        _prefs.getStringList(ideSidebarKnownViewsKey) ?? _viewsBeforeKnownList;
    return {
      for (final name in names)
        if (viewByName[name] != null) viewByName[name]!,
      for (final view in IdeSidebarView.values)
        if (!known.contains(view.name)) view,
    };
  }

  /// The views that existed before the strip recorded which ones it knew.
  static const List<String> _viewsBeforeKnownList = [
    'general',
    'explorer',
    'sourceControl',
    'notes',
    'artifacts',
  ];

  /// Pins [view] to the strip when it is unpinned and removes its cell when it
  /// is already pinned. Unpinning every view is allowed — the strip then shows
  /// only the active view's transient cell plus the overflow caret.
  void toggle(IdeSidebarView view) {
    final next = Set<IdeSidebarView>.from(state);
    if (!next.add(view)) {
      next.remove(view);
    }
    // Persist in canonical order so the stored list reads the way the strip
    // renders and a future reorder feature has an ordered list to build on.
    _prefs
      ..setStringList(ideSidebarPinnedViewsKey, [
        for (final v in IdeSidebarView.values)
          if (next.contains(v)) v.name,
      ])
      ..setStringList(ideSidebarKnownViewsKey, [
        for (final v in IdeSidebarView.values) v.name,
      ]);
    state = next;
  }
}

/// The operator's pinned sidebar views.
final ideSidebarPinsProvider =
    NotifierProvider<IdeSidebarPinsNotifier, Set<IdeSidebarView>>(
      IdeSidebarPinsNotifier.new,
    );
