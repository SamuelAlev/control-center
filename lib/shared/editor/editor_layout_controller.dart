import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';

/// Owns the editor split tree and every operation that mutates it.
///
/// The tree is a tiling layout (see [EditorNode]); leaves are tab groups. This
/// controller is the single source of truth for structure (splits / moves /
/// closes) and the active leaf and it owns the lifecycle of every leaf's
/// [EditorTabGroupController]: it attaches a listener so any per-leaf tab change
/// re-broadcasts as a layout change and disposes a leaf controller as soon as
/// its leaf is pruned from the tree.
///
/// Ephemeral UI state — not Riverpod-managed. The owning widget creates it and
/// disposes it. Persistence is handled separately (see `editor_layout_snapshot`).
class EditorLayoutController extends ChangeNotifier {
  EditorLayoutController._(this._root, this._activeLeafId, this._idCounter) {
    _reconcileLeaves();
  }

  /// Creates a layout with a single leaf, optionally seeded with [controller].
  factory EditorLayoutController.single({
    EditorTabGroupController? controller,
  }) {
    final c = controller ?? EditorTabGroupController();
    final leaf = EditorLeafNode(id: 'leaf-0', controller: c);
    return EditorLayoutController._(leaf, 'leaf-0', 1);
  }

  /// Creates a layout from a pre-built [root] (e.g. restored from persistence).
  ///
  /// [nextId] must exceed every numeric suffix already used in [root] so newly
  /// generated ids stay unique.
  factory EditorLayoutController.fromTree({
    required EditorNode root,
    required String activeLeafId,
    required int nextId,
  }) {
    return EditorLayoutController._(root, activeLeafId, nextId);
  }

  EditorNode _root;
  String _activeLeafId;
  int _idCounter;

  /// Live controllers keyed by leaf id, so we can dispose the ones whose leaves
  /// vanish after a structural change.
  final Map<String, EditorTabGroupController> _leafControllers = {};

  /// Set while a structural mutation is in flight so the per-leaf change
  /// listener does not emit redundant notifications mid-operation.
  bool _mutating = false;

  /// The current tree root.
  EditorNode get root => _root;

  /// Id of the active (last-focused) leaf — the target for sidebar opens.
  String get activeLeafId => _activeLeafId;

  /// The active leaf node (falls back to the first leaf if the id is stale).
  EditorLeafNode get activeLeaf =>
      _findLeaf(_activeLeafId) ?? _firstLeaf(_root);

  /// Number of leaves currently in the tree.
  int get leafCount {
    var n = 0;
    _forEachLeaf(_root, (_) => n++);
    return n;
  }

  String _nextId(String prefix) => '$prefix-${_idCounter++}';

  // ---------------------------------------------------------------------------
  // Non-structural operations (tab selection / opens within a leaf)
  // ---------------------------------------------------------------------------

  /// Marks [leafId] active (the target for subsequent opens).
  void setActiveLeaf(String leafId) {
    if (_activeLeafId == leafId || _findLeaf(leafId) == null) {
      return;
    }
    _activeLeafId = leafId;
    notifyListeners();
  }

  /// Opens [tab] in the active leaf (de-dupes per [EditorTab.dedupKey]).
  void openInActiveLeaf(EditorTab tab) => activeLeaf.controller.openTab(tab);

  /// In [leafId], selects the first existing tab matching [match], or opens one
  /// built by [build]. The generic primitive behind "focus-or-open" flows (open
  /// chat, focus a terminal, deep-link a code-server file, …): the host supplies
  /// the match predicate and the tab factory, so the engine stays kind-agnostic.
  void focusOrOpenInLeaf(
    String leafId,
    bool Function(EditorTab) match,
    EditorTab Function() build,
  ) {
    final leaf = _findLeaf(leafId);
    if (leaf == null) {
      return;
    }
    final idx = leaf.controller.tabs.indexWhere(match);
    if (idx >= 0) {
      leaf.controller.selectedIndex = idx;
    } else {
      leaf.controller.openTab(build());
    }
  }

  /// Ensures a background [tab] (deduped by its [EditorTab.dedupKey]) exists
  /// without stealing focus — for auto-injected tabs like a detected deploy
  /// preview.
  ///
  /// * Already open somewhere → its instance is refreshed in place only if the
  ///   payload changed (so a live webview body survives an unchanged reconcile).
  /// * Absent → inserted immediately after the first tab of [afterKind] in that
  ///   tab's leaf; with no such anchor it is appended to the active leaf. Either
  ///   way the current selection is preserved.
  void ensureBackgroundTab(EditorTab tab, {String? afterKind}) {
    final key = tab.dedupKey;
    if (key != null) {
      var refreshed = false;
      _forEachLeaf(_root, (leaf) {
        if (refreshed) {
          return;
        }
        final idx = leaf.controller.tabs.indexWhere((t) => t.dedupKey == key);
        if (idx >= 0) {
          leaf.controller.refreshTabAt(idx, tab);
          refreshed = true;
        }
      });
      if (refreshed) {
        return;
      }
    }

    EditorLeafNode? anchorLeaf;
    var anchorIndex = -1;
    if (afterKind != null) {
      _forEachLeaf(_root, (leaf) {
        if (anchorLeaf != null) {
          return;
        }
        final idx = leaf.controller.tabs.indexWhere((t) => t.kind == afterKind);
        if (idx >= 0) {
          anchorLeaf = leaf;
          anchorIndex = idx;
        }
      });
    }

    final leaf = anchorLeaf ?? activeLeaf;
    final at = anchorLeaf != null
        ? anchorIndex + 1
        : leaf.controller.tabs.length;
    leaf.controller.insertWithoutFocus(at, tab);
  }

  /// Focuses the first tab (across all leaves) matching [match]: makes its leaf
  /// active and selects it there. Returns true when a match was found. Used to
  /// jump to a fixed tab by kind (e.g. the PR page's Overview / Diff / Actions).
  bool focusTab(bool Function(EditorTab) match) {
    var found = false;
    _forEachLeaf(_root, (leaf) {
      if (found) {
        return;
      }
      final idx = leaf.controller.tabs.indexWhere(match);
      if (idx >= 0) {
        _activeLeafId = leaf.id;
        leaf.controller.selectedIndex = idx;
        found = true;
      }
    });
    if (found) {
      notifyListeners();
    }
    return found;
  }

  /// Reorders a tab within a single leaf and makes that leaf active.
  void reorderWithin(String leafId, int oldIndex, int newIndex) {
    final leaf = _findLeaf(leafId);
    if (leaf == null) {
      return;
    }
    leaf.controller.reorder(oldIndex, newIndex);
    _activeLeafId = leafId;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Structural operations
  // ---------------------------------------------------------------------------

  /// Moves the dragged tab into [toLeafId] at [toIndex].
  ///
  /// Same-leaf moves are treated as reorders. Cross-leaf moves remove the tab
  /// from its source (pruning the source leaf if it empties).
  void moveTab(TabDragData from, String toLeafId, int toIndex) {
    final source = _findLeaf(from.sourceLeafId);
    final target = _findLeaf(toLeafId);
    if (source == null || target == null) {
      return;
    }
    final srcIndex = source.controller.indexOfIdentity(from.tab);
    if (srcIndex < 0) {
      return;
    }
    if (identical(source, target)) {
      reorderWithin(toLeafId, srcIndex, toIndex);
      return;
    }
    _mutating = true;
    final tab = source.controller.removeAt(srcIndex);
    if (tab != null) {
      target.controller.insert(toIndex, tab);
    }
    _activeLeafId = toLeafId;
    _finishMutation();
  }

  /// Splits [targetLeafId] along [edge], placing the dragged tab in the new
  /// sibling leaf. A [DropEdge.center] drop is a plain move into the target.
  void splitWithTab(String targetLeafId, DropEdge edge, TabDragData from) {
    if (edge == DropEdge.center) {
      final target = _findLeaf(targetLeafId);
      moveTab(from, targetLeafId, target?.controller.tabs.length ?? 0);
      return;
    }
    final target = _findLeaf(targetLeafId);
    final source = _findLeaf(from.sourceLeafId);
    if (target == null || source == null) {
      return;
    }
    final srcIndex = source.controller.indexOfIdentity(from.tab);
    if (srcIndex < 0) {
      return;
    }
    // Splitting a single-tab leaf off itself would just empty then re-create
    // the same pane — a no-op. Reject it.
    if (identical(source, target) && source.controller.tabs.length <= 1) {
      return;
    }
    _mutating = true;
    final tab = source.controller.removeAt(srcIndex);
    if (tab == null) {
      _finishMutation();
      return;
    }
    final newCtrl = EditorTabGroupController()..insert(0, tab);
    final newLeaf = EditorLeafNode(id: _nextId('leaf'), controller: newCtrl);
    final axis = (edge == DropEdge.left || edge == DropEdge.right)
        ? Axis.horizontal
        : Axis.vertical;
    final before = edge == DropEdge.left || edge == DropEdge.top;
    _insertSibling(target, newLeaf, axis, before);
    _activeLeafId = newLeaf.id;
    _finishMutation();
  }

  /// Duplicates the tab at [index] in [leafId] into a new leaf on the [edge]
  /// side. Duplication makes a fresh tab instance (independent body) so both
  /// panes show live, separate content. A [DropEdge.center] edge is a no-op
  /// (there is nothing to split toward); an out-of-range [index] opens the new
  /// pane empty.
  void splitTabToward(String leafId, int index, DropEdge edge) {
    if (edge == DropEdge.center) {
      return;
    }
    final leaf = _findLeaf(leafId);
    if (leaf == null) {
      return;
    }
    _mutating = true;
    final newCtrl = EditorTabGroupController();
    final tabs = leaf.controller.tabs;
    if (index >= 0 && index < tabs.length) {
      final source = tabs[index];
      newCtrl.insert(
        0,
        EditorTab(
          kind: source.kind,
          label: source.label,
          args: source.args,
          icon: source.icon,
          dedupKey: source.dedupKey,
        ),
      );
    }
    final newLeaf = EditorLeafNode(id: _nextId('leaf'), controller: newCtrl);
    final axis = (edge == DropEdge.left || edge == DropEdge.right)
        ? Axis.horizontal
        : Axis.vertical;
    final before = edge == DropEdge.left || edge == DropEdge.top;
    _insertSibling(leaf, newLeaf, axis, before);
    _activeLeafId = newLeaf.id;
    _finishMutation();
  }

  /// The split-button behaviour: [splitTabToward] applied to [leafId]'s
  /// currently selected tab.
  void splitActiveTabToward(String leafId, DropEdge edge) {
    final leaf = _findLeaf(leafId);
    if (leaf == null) {
      return;
    }
    splitTabToward(leafId, leaf.controller.selectedIndex, edge);
  }

  /// Closes the tab at [index] in [leafId]; prunes the leaf if it empties.
  void closeTab(String leafId, int index) {
    final leaf = _findLeaf(leafId);
    if (leaf == null) {
      return;
    }
    _mutating = true;
    leaf.controller.removeAt(index);
    _finishMutation();
  }

  /// Closes the tab matching [tab] by identity wherever it lives. Used by the
  /// terminal's shell-exit callback.
  void closeTabByIdentity(EditorTab tab) {
    final leafId = leafIdContaining(tab);
    if (leafId == null) {
      return;
    }
    final leaf = _findLeaf(leafId)!;
    final idx = leaf.controller.indexOfIdentity(tab);
    if (idx < 0) {
      return;
    }
    _mutating = true;
    leaf.controller.removeAt(idx);
    _finishMutation();
  }

  /// Closes an entire leaf (and its tabs). Never removes the last leaf.
  void closeLeaf(String leafId) {
    if (leafCount <= 1) {
      return;
    }
    final leaf = _findLeaf(leafId);
    if (leaf == null) {
      return;
    }
    _mutating = true;
    // Emptying the controller lets the shared prune pass remove the leaf and
    // collapse its parent.
    while (!leaf.controller.isEmpty) {
      leaf.controller.removeAt(0);
    }
    _finishMutation();
  }

  /// Id of the leaf holding [tab] (by identity), or null.
  String? leafIdContaining(EditorTab tab) {
    String? result;
    _forEachLeaf(_root, (leaf) {
      if (result == null && leaf.controller.indexOfIdentity(tab) >= 0) {
        result = leaf.id;
      }
    });
    return result;
  }

  // ---------------------------------------------------------------------------
  // Tree maintenance
  // ---------------------------------------------------------------------------

  void _insertSibling(
    EditorNode target,
    EditorNode newNode,
    Axis axis,
    bool before,
  ) {
    final parentRef = _findParent(target);
    if (parentRef == null) {
      // Target is the root: wrap both in a fresh split.
      final children = before ? [newNode, target] : [target, newNode];
      _root = EditorSplitNode(
        id: _nextId('split'),
        axis: axis,
        children: children,
        weights: [0.5, 0.5],
      );
      return;
    }
    final (parent, idx) = parentRef;
    if (parent.axis == axis) {
      // Same axis: add a sibling, halving the target slot to make room (n-ary).
      final half = parent.weights[idx] / 2;
      parent.weights[idx] = half;
      final insertAt = before ? idx : idx + 1;
      parent.children.insert(insertAt, newNode);
      parent.weights.insert(insertAt, half);
    } else {
      // Perpendicular: replace the target with a new split holding both,
      // inheriting the target's weight slot in the parent.
      final children = before ? [newNode, target] : [target, newNode];
      parent.children[idx] = EditorSplitNode(
        id: _nextId('split'),
        axis: axis,
        children: children,
        weights: [0.5, 0.5],
      );
    }
  }

  /// Finalises a structural mutation: prune empty leaves, collapse single-child
  /// splits, flatten same-axis nesting, renormalise weights, reconcile leaf
  /// controllers, repair the active id, then notify once.
  void _finishMutation() {
    final pruned = _pruneNode(_root);
    // If everything emptied, keep one (empty) leaf so the surface stays usable.
    _root = pruned ?? (_findLeaf(_activeLeafId) ?? _firstLeaf(_root));
    _renormalize(_root);
    _reconcileLeaves();
    if (_findLeaf(_activeLeafId) == null) {
      _activeLeafId = _firstLeaf(_root).id;
    }
    _mutating = false;
    notifyListeners();
  }

  EditorNode? _pruneNode(EditorNode node) {
    if (node is EditorLeafNode) {
      return node.controller.isEmpty ? null : node;
    }
    final split = node as EditorSplitNode;
    final keptChildren = <EditorNode>[];
    final keptWeights = <double>[];
    for (var i = 0; i < split.children.length; i++) {
      final pruned = _pruneNode(split.children[i]);
      if (pruned != null) {
        keptChildren.add(pruned);
        keptWeights.add(split.weights[i]);
      }
    }
    if (keptChildren.isEmpty) {
      return null;
    }
    if (keptChildren.length == 1) {
      return keptChildren.first;
    }
    // Flatten any same-axis child split into this level.
    final flatChildren = <EditorNode>[];
    final flatWeights = <double>[];
    for (var i = 0; i < keptChildren.length; i++) {
      final child = keptChildren[i];
      if (child is EditorSplitNode && child.axis == split.axis) {
        final slot = keptWeights[i];
        final childSum = child.weights.fold<double>(
          0,
          (a, b) => a + (b <= 0 ? 0 : b),
        );
        for (var j = 0; j < child.children.length; j++) {
          flatChildren.add(child.children[j]);
          flatWeights.add(
            childSum <= 0
                ? slot / child.children.length
                : slot * child.weights[j] / childSum,
          );
        }
      } else {
        flatChildren.add(child);
        flatWeights.add(keptWeights[i]);
      }
    }
    return EditorSplitNode(
      id: split.id,
      axis: split.axis,
      children: flatChildren,
      weights: flatWeights,
    );
  }

  void _renormalize(EditorNode node) {
    if (node is EditorSplitNode) {
      final norm = _normalizeWeights(node.weights);
      for (var i = 0; i < norm.length; i++) {
        node.weights[i] = norm[i];
      }
      for (final c in node.children) {
        _renormalize(c);
      }
    }
  }

  static List<double> _normalizeWeights(List<double> w) {
    final clamped = [for (final x in w) x <= 0 ? 0.0 : x];
    final sum = clamped.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) {
      return List.filled(w.length, 1 / w.length);
    }
    return [for (final x in clamped) x / sum];
  }

  /// Attaches listeners to new leaves and disposes controllers of vanished ones.
  void _reconcileLeaves() {
    final live = <String>{};
    _forEachLeaf(_root, (leaf) {
      live.add(leaf.id);
      if (!_leafControllers.containsKey(leaf.id)) {
        _leafControllers[leaf.id] = leaf.controller;
        leaf.controller.addListener(_onLeafChanged);
      }
    });
    final dead = _leafControllers.keys
        .where((id) => !live.contains(id))
        .toList();
    for (final id in dead) {
      final c = _leafControllers.remove(id)!;
      c.removeListener(_onLeafChanged);
      c.dispose();
    }
  }

  void _onLeafChanged() {
    if (_mutating) {
      return;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Tree queries
  // ---------------------------------------------------------------------------

  EditorLeafNode? _findLeaf(String id, [EditorNode? node]) {
    node ??= _root;
    if (node is EditorLeafNode) {
      return node.id == id ? node : null;
    }
    if (node is EditorSplitNode) {
      for (final c in node.children) {
        final found = _findLeaf(id, c);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  (EditorSplitNode, int)? _findParent(EditorNode child, [EditorNode? node]) {
    node ??= _root;
    if (node is EditorSplitNode) {
      for (var i = 0; i < node.children.length; i++) {
        if (identical(node.children[i], child)) {
          return (node, i);
        }
        final found = _findParent(child, node.children[i]);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  EditorLeafNode _firstLeaf(EditorNode node) {
    if (node is EditorLeafNode) {
      return node;
    }
    return _firstLeaf((node as EditorSplitNode).children.first);
  }

  void _forEachLeaf(EditorNode node, void Function(EditorLeafNode) visit) {
    if (node is EditorLeafNode) {
      visit(node);
    } else if (node is EditorSplitNode) {
      for (final c in node.children) {
        _forEachLeaf(c, visit);
      }
    }
  }

  /// Every tab currently in the tree (across all leaves), in no particular
  /// order. Used by the body host to reconcile keep-alive entries.
  List<EditorTab> allTabs() {
    final out = <EditorTab>[];
    _forEachLeaf(_root, (leaf) => out.addAll(leaf.controller.tabs));
    return out;
  }

  @override
  void dispose() {
    for (final c in _leafControllers.values) {
      c.removeListener(_onLeafChanged);
      c.dispose();
    }
    _leafControllers.clear();
    super.dispose();
  }
}
