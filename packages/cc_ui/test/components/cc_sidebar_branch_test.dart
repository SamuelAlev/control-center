import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  const railKey = ValueKey<String>('cc-sidebar-branch-rail');

  Widget tree({
    TextDirection textDirection = TextDirection.ltr,
    bool collapsed = false,
  }) {
    return ccTestApp(
      Center(
        child: SizedBox(
          width: 240,
          child: CcSidebarScope(
            collapsed: collapsed,
            child: CcSidebarGroup(
              children: [
                CcSidebarItem(
                  icon: CcIcons.folder,
                  label: 'Parent',
                  onPressed: () {},
                ),
                CcSidebarBranch(
                  children: [
                    CcSidebarItem(
                      icon: CcIcons.fileCode,
                      label: 'Child A',
                      onPressed: () {},
                    ),
                    CcSidebarItem(
                      icon: CcIcons.play,
                      label: 'Child B',
                      onPressed: () {},
                    ),
                  ],
                ),
                CcSidebarItem(
                  icon: CcIcons.layers,
                  label: 'Uncle',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      textDirection: textDirection,
    );
  }

  Rect itemRect(WidgetTester tester, String label) {
    final item = find.ancestor(
      of: find.text(label),
      matching: find.byType(CcSidebarItem),
    );
    return tester.getRect(
      find.descendant(of: item, matching: find.byType(AnimatedContainer)),
    );
  }

  testWidgets('sits flush under the parent and between nested children', (
    tester,
  ) async {
    await tester.pumpWidget(tree());

    final parent = itemRect(tester, 'Parent');
    final childA = itemRect(tester, 'Child A');
    final childB = itemRect(tester, 'Child B');
    final uncle = itemRect(tester, 'Uncle');

    expect(childA.top - parent.bottom, 0);
    expect(childB.top - childA.bottom, 0);
    expect(
      uncle.top - childB.bottom,
      0,
      reason: 'expanded group rows stay flush, including after a branch',
    );
  });

  testWidgets('pins the rail to the parent icon center and indents children', (
    tester,
  ) async {
    await tester.pumpWidget(tree());

    final parent = itemRect(tester, 'Parent');
    final childA = itemRect(tester, 'Child A');
    final rail = tester.getRect(find.byKey(railKey));

    expect(childA.left - parent.left, AppSpacing.xl);
    expect(rail.left - parent.left, kCcSidebarItemIconCenter);
    expect(rail.width, 1);
    expect(rail.height, childA.height + itemRect(tester, 'Child B').height);
    expect(
      tester.widget<ColoredBox>(find.byKey(railKey)).color,
      DesignSystemTokens.light().lineStrong,
    );
  });

  testWidgets('mirrors the rail and indent in RTL', (tester) async {
    await tester.pumpWidget(tree(textDirection: TextDirection.rtl));

    final parent = itemRect(tester, 'Parent');
    final childA = itemRect(tester, 'Child A');
    final rail = tester.getRect(find.byKey(railKey));

    expect(parent.right - childA.right, AppSpacing.xl);
    expect(parent.right - rail.right, kCcSidebarItemIconCenter);
  });

  testWidgets('drops the rail and indent in the collapsed icon rail', (
    tester,
  ) async {
    await tester.pumpWidget(tree(collapsed: true));

    expect(find.byKey(railKey), findsNothing);
    // Labels hide in the icon rail, so the squares are identified by glyph.
    final parent = tester.getRect(find.byIcon(CcIcons.folder));
    final childA = tester.getRect(find.byIcon(CcIcons.fileCode));
    expect(childA.left, parent.left);
    expect(childA.width, 18);
  });

  testWidgets('nested children keep their own hover wash', (tester) async {
    await tester.pumpWidget(tree());

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: tester.getCenter(find.text('Child A')));
    await tester.pump();
    await tester.pump();
    await tester.pump(CcMotion.fast);

    Rect? activeHighlight;
    for (final element
        in find
            .byKey(const ValueKey<String>('cc-fluid-hover-highlight'))
            .evaluate()) {
      final opacity = element.widget as AnimatedOpacity;
      if (opacity.opacity != 1) {
        continue;
      }
      activeHighlight = tester.getRect(find.byWidget(opacity));
    }
    expect(activeHighlight, isNotNull);
    expect(activeHighlight!.overlaps(itemRect(tester, 'Child A')), isTrue);
    expect(activeHighlight.overlaps(itemRect(tester, 'Uncle')), isFalse);
    expect(activeHighlight.overlaps(itemRect(tester, 'Parent')), isFalse);
  });
}
