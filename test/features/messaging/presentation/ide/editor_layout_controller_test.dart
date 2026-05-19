import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

EditorTab _tab(String label, [String kind = 'browser']) =>
    EditorTab(kind: kind, label: label);

EditorLayoutController _single(List<EditorTab> tabs) {
  final c = EditorTabGroupController();
  for (final t in tabs) {
    c.insert(c.tabs.length, t);
  }
  return EditorLayoutController.single(controller: c);
}

List<String> _labels(EditorNode node) =>
    (node as EditorLeafNode).controller.tabs.map((t) => t.label).toList();

TabDragData _drag(String leafId, int index, EditorTab tab) =>
    TabDragData(sourceLeafId: leafId, tabIndex: index, tab: tab);

void main() {
  group('reorder within a leaf', () {
    test('moves a tab to the end', () {
      final a = _tab('A');
      final b = _tab('B');
      final c = _tab('C');
      final ctl = _single([a, b, c]);

      ctl.reorderWithin('leaf-0', 0, 3);

      expect(_labels(ctl.root), ['B', 'C', 'A']);
    });

    test('a no-op reorder leaves order unchanged', () {
      final ctl = _single([_tab('A'), _tab('B'), _tab('C')]);
      ctl.reorderWithin('leaf-0', 1, 2); // insert-at-self → no-op
      expect(_labels(ctl.root), ['A', 'B', 'C']);
    });
  });

  group('split with a tab', () {
    test('right edge creates a horizontal split, new pane on the right', () {
      final a = _tab('A');
      final b = _tab('B');
      final ctl = _single([a, b]);

      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 0, a));

      final root = ctl.root;
      expect(root, isA<EditorSplitNode>());
      final split = root as EditorSplitNode;
      expect(split.axis, Axis.horizontal);
      expect(split.children.length, 2);
      expect(_labels(split.children[0]), ['B']);
      expect(_labels(split.children[1]), ['A']);
      // The moved tab's new leaf is active.
      expect(ctl.activeLeaf.controller.tabs.single.label, 'A');
    });

    test('bottom edge creates a vertical split', () {
      final a = _tab('A');
      final ctl = _single([a, _tab('B')]);
      ctl.splitWithTab('leaf-0', DropEdge.bottom, _drag('leaf-0', 0, a));
      expect((ctl.root as EditorSplitNode).axis, Axis.vertical);
    });

    test('left edge puts the new pane before the target', () {
      final a = _tab('A');
      final ctl = _single([a, _tab('B')]);
      ctl.splitWithTab('leaf-0', DropEdge.left, _drag('leaf-0', 0, a));
      final split = ctl.root as EditorSplitNode;
      expect(_labels(split.children[0]), ['A']);
      expect(_labels(split.children[1]), ['B']);
    });

    test('splitting a single-tab leaf off itself is a no-op', () {
      final a = _tab('A');
      final ctl = _single([a]);
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 0, a));
      expect(ctl.root, isA<EditorLeafNode>());
      expect(_labels(ctl.root), ['A']);
    });

    test('center edge moves the tab instead of splitting', () {
      final a = _tab('A');
      final ctl = _single([a, _tab('B')]);
      ctl.splitWithTab('leaf-0', DropEdge.center, _drag('leaf-0', 0, a));
      // Still a single leaf; A moved to the end.
      expect(ctl.root, isA<EditorLeafNode>());
      expect(_labels(ctl.root), ['B', 'A']);
    });
  });

  group('n-ary same-axis insertion', () {
    test('a third right split adds a sibling rather than nesting', () {
      final a = _tab('A');
      final b = _tab('B');
      final c = _tab('C');
      final ctl = _single([a, b, c]);

      // First split → [ (A,B) | (C) ].
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 2, c));
      // Second split of the left leaf to the right → [ (A) | (B) | (C) ].
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 1, b));

      final split = ctl.root as EditorSplitNode;
      expect(split.axis, Axis.horizontal);
      expect(split.children.length, 3);
      expect(_labels(split.children[0]), ['A']);
      expect(_labels(split.children[1]), ['B']);
      expect(_labels(split.children[2]), ['C']);
    });
  });

  group('move between leaves', () {
    test('moves a tab and re-targets the active leaf', () {
      final a = _tab('A');
      final b = _tab('B');
      final c = _tab('C');
      final ctl = _single([a, b, c]);
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 2, c));
      // Now leaf-0=[A,B], leaf-1=[C].

      ctl.moveTab(_drag('leaf-0', 0, a), 'leaf-1', 1);

      final split = ctl.root as EditorSplitNode;
      expect(_labels(split.children[0]), ['B']);
      expect(_labels(split.children[1]), ['C', 'A']);
      expect(ctl.activeLeafId, 'leaf-1');
    });

    test('emptying a leaf by moving its last tab prunes and collapses', () {
      final a = _tab('A');
      final b = _tab('B');
      final ctl = _single([a, b]);
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 1, b));
      // leaf-0=[A], leaf-1=[B].

      ctl.moveTab(_drag('leaf-0', 0, a), 'leaf-1', 1);

      // leaf-0 emptied → pruned → root collapses to the surviving leaf.
      expect(ctl.root, isA<EditorLeafNode>());
      expect(_labels(ctl.root), ['B', 'A']);
      expect(ctl.leafCount, 1);
    });
  });

  group('closing', () {
    test('closing the last tab of a side pane removes that pane', () {
      final a = _tab('A');
      final b = _tab('B');
      final ctl = _single([a, b]);
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 1, b));
      // leaf-0=[A], leaf-1=[B].

      ctl.closeTab('leaf-1', 0);

      expect(ctl.root, isA<EditorLeafNode>());
      expect(_labels(ctl.root), ['A']);
      expect(ctl.leafCount, 1);
    });

    test('closeLeaf removes a pane but never the last one', () {
      final a = _tab('A');
      final b = _tab('B');
      final ctl = _single([a, b]);
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 1, b));

      ctl.closeLeaf('leaf-1');
      expect(ctl.leafCount, 1);
      expect(_labels(ctl.root), ['A']);

      // The last leaf cannot be closed.
      ctl.closeLeaf('leaf-0');
      expect(ctl.leafCount, 1);
    });

    test('closing the last tab of the only leaf keeps an empty leaf', () {
      final a = _tab('A');
      final ctl = _single([a]);
      ctl.closeTab('leaf-0', 0);
      expect(ctl.root, isA<EditorLeafNode>());
      expect((ctl.root as EditorLeafNode).controller.isEmpty, isTrue);
      expect(ctl.leafCount, 1);
    });
  });

  group('split-button (duplicate active toward edge)', () {
    test('duplicates the active tab into a fresh independent instance', () {
      final a = _tab('A', 'terminal');
      final ctl = _single([a]);

      ctl.splitActiveTabToward('leaf-0', DropEdge.right);

      final split = ctl.root as EditorSplitNode;
      expect(split.children.length, 2);
      // Source keeps its tab; the new pane has a copy (same label, new identity).
      expect(_labels(split.children[0]), ['A']);
      expect(_labels(split.children[1]), ['A']);
      final original =
          (split.children[0] as EditorLeafNode).controller.tabs.single;
      final copy = (split.children[1] as EditorLeafNode).controller.tabs.single;
      expect(identical(original, copy), isFalse);
    });
  });

  group('flatten nested same-axis splits on prune', () {
    test('a same-axis child split is flattened into its parent', () {
      // Hand-build horizontal[ La(A,A2), horizontal[ Lb(B), Lc(C) ] ].
      final la = EditorTabGroupController()
        ..insert(0, _tab('A'))
        ..insert(1, _tab('A2'));
      final lb = EditorTabGroupController()..insert(0, _tab('B'));
      final lc = EditorTabGroupController()..insert(0, _tab('C'));
      final inner = EditorSplitNode(
        id: 'split-1',
        axis: Axis.horizontal,
        children: [
          EditorLeafNode(id: 'leaf-1', controller: lb),
          EditorLeafNode(id: 'leaf-2', controller: lc),
        ],
        weights: [0.5, 0.5],
      );
      final root = EditorSplitNode(
        id: 'split-0',
        axis: Axis.horizontal,
        children: [
          EditorLeafNode(id: 'leaf-0', controller: la),
          inner,
        ],
        weights: [0.5, 0.5],
      );
      final ctl = EditorLayoutController.fromTree(
        root: root,
        activeLeafId: 'leaf-0',
        nextId: 3,
      );

      // A structural op triggers the prune/flatten pass.
      ctl.closeTab('leaf-0', 1); // remove A2; leaf-0 still has A.

      final flattened = ctl.root as EditorSplitNode;
      expect(flattened.axis, Axis.horizontal);
      expect(flattened.children.length, 3);
      expect(_labels(flattened.children[0]), ['A']);
      expect(_labels(flattened.children[1]), ['B']);
      expect(_labels(flattened.children[2]), ['C']);
      // Weights re-normalise to sum 1.
      final sum = flattened.weights.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-9));
    });
  });

  group('weights', () {
    test('a fresh split is 50/50', () {
      final a = _tab('A');
      final ctl = _single([a, _tab('B')]);
      ctl.splitWithTab('leaf-0', DropEdge.right, _drag('leaf-0', 0, a));
      final split = ctl.root as EditorSplitNode;
      expect(split.weights[0], closeTo(0.5, 1e-9));
      expect(split.weights[1], closeTo(0.5, 1e-9));
    });
  });

  group('close selection', () {
    // Mirrors how a middle-click / close button / ⌘W reach the controller: a
    // single removeAt(index) on the leaf's controller. Selection must follow
    // the active tab, not the closed one's old position.
    String? label(EditorTabGroupController c) =>
        c.isEmpty ? null : c.tabs[c.selectedIndex].label;

    EditorTabGroupController threeTabsAt(int selected) {
      final c = EditorTabGroupController()
        ..insert(0, _tab('A'))
        ..insert(1, _tab('B'))
        ..insert(2, _tab('C'));
      c.selectedIndex = selected;
      return c;
    }

    test('closing a non-active tab before the active keeps it selected', () {
      // A B C, C active → close A (index 0). B and C shift to 0/1; C stays put.
      final c = threeTabsAt(2);
      c.removeAt(0);
      expect(c.tabs.map((t) => t.label), ['B', 'C']);
      expect(label(c), 'C');
    });

    test('closing a non-active tab after the active keeps it selected', () {
      // A B C, A active → close C (index 2). A stays at 0.
      final c = threeTabsAt(0);
      c.removeAt(2);
      expect(c.tabs.map((t) => t.label), ['A', 'B']);
      expect(label(c), 'A');
    });

    test('closing the active tab returns to the tab you came from', () {
      // Visited A, then C, then B. Closing B goes back to C — NOT to A, which
      // is merely the tab sitting to B's left.
      final c =
          threeTabsAt(0) // visited …A
            ..selectedIndex =
                2 // …A C
            ..selectedIndex = 1; // …A C B
      c.removeAt(1);
      expect(c.tabs.map((t) => t.label), ['A', 'C']);
      expect(label(c), 'C');
    });

    test('the back-stack walks the whole way back, not just one step', () {
      final c =
          threeTabsAt(0) // …A
            ..selectedIndex =
                2 // …A C
            ..selectedIndex = 1; // …A C B
      c.removeAt(1); // B closed → C
      expect(label(c), 'C');
      c.removeAt(c.selectedIndex); // C closed → A
      expect(label(c), 'A');
    });

    test('a tab closed out of order is not re-selected later', () {
      // Visit A then B then C; close A from its context menu (never selected
      // again), then close C. The back-stack must skip the dead A and land on
      // B rather than resurrecting a tab that no longer exists.
      final c =
          threeTabsAt(0) // …A
            ..selectedIndex =
                1 // …A B
            ..selectedIndex = 2; // …A B C
      c.removeAt(0); // close A while C stays active
      expect(label(c), 'C');
      c.removeAt(c.selectedIndex);
      expect(c.tabs.map((t) => t.label), ['B']);
      expect(label(c), 'B');
    });

    test('with no history the tab to the left is selected', () {
      // A restored layout has a tab set but no visit history: closing the
      // active tab falls back to its left neighbour (VS Code behaviour).
      final c = EditorTabGroupController()
        ..insertWithoutFocus(0, _tab('A'))
        ..insertWithoutFocus(1, _tab('B'))
        ..insertWithoutFocus(2, _tab('C'));
      c.removeAt(0); // active is index 0 by default; nothing to go back to
      expect(c.tabs.map((t) => t.label), ['B', 'C']);
      expect(label(c), 'B'); // clamped: the new first tab
    });

    test(
      'closing the first active tab with no history stays at the new first',
      () {
        final c = EditorTabGroupController()
          ..insertWithoutFocus(0, _tab('A'))
          ..insertWithoutFocus(1, _tab('B'));
        c.removeAt(0);
        expect(label(c), 'B');
      },
    );

    test('the back-stack survives a reorder', () {
      // History is keyed by tab identity, so dragging tabs around does not
      // rewrite where ⌘W goes.
      final c =
          threeTabsAt(0) // …A
            ..selectedIndex = 2; // …A C
      c.reorder(0, 3); // A moves to the end: B C A
      c.selectedIndex = c.tabs.indexWhere((t) => t.label == 'B');
      c.removeAt(c.selectedIndex);
      expect(c.tabs.map((t) => t.label), ['C', 'A']);
      expect(label(c), 'A'); // A was visited last, wherever it now sits
    });

    test('closing the last remaining tab empties the group', () {
      final c = EditorTabGroupController()..insert(0, _tab('only'));
      c.removeAt(0);
      expect(c.isEmpty, isTrue);
      expect(c.selectedIndex, 0);
    });
  });

  group('review tab dedupe', () {
    EditorTab reviewTab(String spaceId, String repoId, String anchor) =>
        EditorTab(
          kind: 'review',
          label: 'Review',
          dedupKey: 'review:$spaceId:$repoId',
          args: {'spaceId': spaceId, 'repoId': repoId, 'anchorPath': anchor},
        );

    test('a review tab is unique per (spaceId, repoId) and re-anchors', () {
      final c = EditorTabGroupController();
      c.openTab(reviewTab('ch', 'repo1', 'a.dart'));
      c.openTab(reviewTab('ch', 'repo1', 'b.dart'));
      // Same space+repo → refocus, not stack.
      expect(c.tabs.length, 1);
      expect(c.selectedIndex, 0);
      // The re-opened tab carries the new anchor.
      expect(c.tabs.single.args['anchorPath'], 'b.dart');
    });

    test('different repos open separate review tabs', () {
      final c = EditorTabGroupController();
      c.openTab(reviewTab('ch', 'repo1', 'a.dart'));
      c.openTab(reviewTab('ch', 'repo2', 'c.dart'));
      expect(c.tabs.length, 2);
    });

    test('re-opening an identical payload keeps the live tab instance', () {
      // A tab's identity keys its live body (a rig's video lane, a PTY, a
      // webview) and every host's per-tab bookkeeping, so swapping the instance
      // tears the body down and re-reads as "the old tab left the tree". That
      // is how re-picking a rig entry used to shut down the very machine it was
      // bringing forward.
      EditorTab rigTab() => const EditorTab(
        kind: 'rig',
        label: 'WebKit (VM)',
        dedupKey: 'rig:browser:webkit',
        args: {'surface': 'browser', 'engine': 'webkit'},
      );
      final c = EditorTabGroupController();
      c.openTab(rigTab());
      final live = c.tabs.single;
      c
        ..openTab(_tab('Terminal', 'terminal'))
        ..openTab(rigTab());
      expect(c.tabs.length, 2);
      expect(c.selectedIndex, 0);
      expect(identical(c.tabs.first, live), isTrue);
    });
  });
}
