import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('the actions sit on a node that wraps the row', (tester) async {
    final handle = tester.ensureSemantics();
    final fired = <String>[];
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 300,
            height: 48,
            child: CcSwipeActions(
              startAction: CcSwipeAction(
                icon: const IconData(0xe800),
                label: 'Delete',
                background: const Color(0xFFCC0000),
                foreground: const Color(0xFFFFFFFF),
                onTriggered: () => fired.add('delete'),
              ),
              endAction: CcSwipeAction(
                icon: const IconData(0xe801),
                label: 'Mark as read',
                background: const Color(0xFF00AA00),
                foreground: const Color(0xFFFFFFFF),
                onTriggered: () => fired.add('read'),
              ),
              child: CcTappable(
                onPressed: () {},
                semanticLabel: 'Build finished',
                builder: (context, states) => const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(CcSwipeActions));
    // The row's own node, not the screen's root.
    expect(node.rect.size, const Size(300, 48));
    final data = node.getSemanticsData();
    final labels = [
      for (final id in data.customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label,
    ];
    expect(labels, unorderedEquals(['Delete', 'Mark as read']));

    final deleteId = data.customSemanticsActionIds!.firstWhere(
      (id) => CustomSemanticsAction.getAction(id)!.label == 'Delete',
    );
    tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.customAction,
      deleteId,
    );
    await tester.pumpAndSettle();
    expect(fired, ['delete']);
    handle.dispose();
  });
}
