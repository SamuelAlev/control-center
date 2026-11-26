import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

/// Where keyboard focus sits, in the terms the test cares about: a pane's tab
/// strip, a tab body's control, or null for any other chrome (split button,
/// `[+]` menu, the seam between panes).
String? _focusPlace() {
  final node = FocusManager.instance.primaryFocus;
  final label = node?.debugLabel;
  if (label != null && label.startsWith('body:')) {
    return label;
  }
  final group = node?.context?.findAncestorWidgetOfExactType<EditorTabGroup>();
  if (label == 'editor-tab' && group != null) {
    return 'strip:${group.leafId}';
  }
  return null;
}

void main() {
  testWidgets('Tab finishes one pane, strip and body, before the next', (
    tester,
  ) async {
    const a = EditorTab(kind: 'chat', label: 'A');
    const b = EditorTab(kind: 'chat', label: 'B');
    final group = EditorTabGroupController()
      ..insert(0, a)
      ..insert(1, b);
    final layout = EditorLayoutController.single(controller: group);
    addTearDown(layout.dispose);

    await tester.pumpWidget(
      testWrap(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 800,
                height: 600,
                child: EditorWorkspace(
                  layout: layout,
                  chrome: const EditorChrome(),
                  buildBody: (tab, {required isVisible}) => Center(
                    child: Focus(
                      debugLabel: 'body:${tab.label}',
                      child: const SizedBox(width: 40, height: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Two panes side by side: their strips share a row above both bodies, so
    // ordering by position alone would visit both strips before either body.
    layout.splitWithTab(
      'leaf-0',
      DropEdge.right,
      const TabDragData(sourceLeafId: 'leaf-0', tabIndex: 1, tab: b),
    );
    await tester.pumpAndSettle();
    final right = layout.activeLeafId;
    expect(right, isNot('leaf-0'));

    final stripA = FocusManager.instance.rootScope.descendants.firstWhere(
      (node) =>
          node.debugLabel == 'editor-tab' &&
          node.context
                  ?.findAncestorWidgetOfExactType<EditorTabGroup>()
                  ?.leafId ==
              'leaf-0',
    );
    stripA.requestFocus();
    await tester.pump();

    final visited = <String>[_focusPlace()!];
    for (var i = 0; i < 20 && visited.last != 'body:B'; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final place = _focusPlace();
      if (place != null && place != visited.last) {
        visited.add(place);
      }
    }

    expect(visited, ['strip:leaf-0', 'body:A', 'strip:$right', 'body:B']);
  });
}
