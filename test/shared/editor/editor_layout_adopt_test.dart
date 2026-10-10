import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter_test/flutter_test.dart';

EditorTab _tab(String kind, {Map<String, Object?> args = const {}}) =>
    EditorTab(kind: kind, label: kind, args: args, dedupKey: kind);

EditorLayoutController _single(List<EditorTab> tabs) {
  final c = EditorTabGroupController();
  for (final t in tabs) {
    c.insert(c.tabs.length, t);
  }
  return EditorLayoutController.single(controller: c);
}

List<EditorTab> _leafTabs(EditorNode node) =>
    (node as EditorLeafNode).controller.tabs;

void main() {
  group('sameStructureAs', () {
    test('equal tabs in the same order are the same layout', () {
      final a = _single([_tab('overview'), _tab('diff')]);
      final b = _single([_tab('overview'), _tab('diff')]);
      expect(a.sameStructureAs(b), isTrue);
    });

    test('selection does not matter', () {
      final a = _single([_tab('overview'), _tab('diff')]);
      final b = _single([_tab('overview'), _tab('diff')]);
      b.activeLeaf.controller.selectedIndex = 1;
      expect(a.sameStructureAs(b), isTrue);
    });

    test('a different order, arg or split is a different layout', () {
      final base = _single([_tab('overview'), _tab('diff')]);
      expect(
        base.sameStructureAs(_single([_tab('diff'), _tab('overview')])),
        isFalse,
      );
      expect(
        base.sameStructureAs(
          _single([
            _tab('overview'),
            _tab('diff', args: {'path': 'a'}),
          ]),
        ),
        isFalse,
      );
      final split = _single([_tab('overview'), _tab('diff')])
        ..splitTabToward('leaf-0', 1, DropEdge.right);
      expect(base.sameStructureAs(split), isFalse);
    });
  });

  group('adoptTabInstances', () {
    test('restored tabs take over the live instances', () {
      final overview = _tab('overview');
      final diff = _tab('diff');
      final live = _single([overview, diff]);
      final restored = _single([_tab('diff'), _tab('overview')]);

      restored.adoptTabInstances(live.allTabs());

      final tabs = _leafTabs(restored.root);
      expect(identical(tabs[0], diff), isTrue);
      expect(identical(tabs[1], overview), isTrue);
    });

    test('a tab whose payload changed keeps its restored instance', () {
      final live = _single([
        _tab('file', args: {'path': 'a'}),
      ]);
      final restored = _single([
        _tab('file', args: {'path': 'b'}),
      ]);
      final before = _leafTabs(restored.root).single;

      restored.adoptTabInstances(live.allTabs());

      expect(identical(_leafTabs(restored.root).single, before), isTrue);
    });

    test('tabs without a dedup key are never matched', () {
      EditorTab terminal() => EditorTab(
        kind: 'terminal',
        label: 'Terminal',
        args: Map<String, Object?>.of(const {}),
      );
      final liveTab = terminal();
      final live = _single([liveTab]);
      final restored = _single([terminal()]);

      restored.adoptTabInstances(live.allTabs());

      expect(identical(_leafTabs(restored.root).single, liveTab), isFalse);
    });
  });
}
