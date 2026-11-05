import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void _noop() {}

CcSidebarItem _item(IconData icon, String label) =>
    CcSidebarItem(icon: icon, label: label, onPressed: _noop);

Widget _strip({double width = 223, bool transitioning = false}) => Align(
  alignment: AlignmentDirectional.bottomStart,
  child: SizedBox(
    width: width,
    child: CcSidebarScope(
      collapsed: false,
      transitioning: transitioning,
      child: CcSidebarToolbar(
        leading: [
          _item(CcIcons.house, 'Home'),
          _item(CcIcons.search, 'Search'),
          _item(CcIcons.plus, 'Add'),
        ],
        trailing: [
          _item(CcIcons.check, 'Check'),
          _item(CcIcons.x, 'Close'),
          _item(CcIcons.copy, 'Copy'),
          _item(CcIcons.settings, 'Settings'),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('splits icon-only items across the strip', (tester) async {
    await tester.pumpWidget(ccTestApp(_strip(width: 400)));

    expect(find.text('Home'), findsNothing);
    final home = tester.getRect(find.byIcon(CcIcons.house));
    final settings = tester.getRect(find.byIcon(CcIcons.settings));
    expect(settings.center.dy, home.center.dy);
    expect(home.center.dx, kCcSidebarItemIconCenter);
    expect(settings.center.dx, 400 - kCcSidebarItemIconCenter);
  });

  testWidgets('seven items fit the narrowest sidebar', (tester) async {
    await tester.pumpWidget(ccTestApp(_strip()));

    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byIcon(CcIcons.settings)).right,
      lessThanOrEqualTo(223),
    );
  });

  testWidgets('mirrors under RTL', (tester) async {
    await tester.pumpWidget(
      ccTestApp(_strip(), textDirection: TextDirection.rtl),
    );

    final home = tester.getRect(find.byIcon(CcIcons.house));
    final settings = tester.getRect(find.byIcon(CcIcons.settings));
    expect(settings.center.dx, lessThan(home.center.dx));
  });

  testWidgets('clips instead of overflowing while the width animates', (
    tester,
  ) async {
    await tester.pumpWidget(ccTestApp(_strip(width: 38, transitioning: true)));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(CcSidebarToolbar)).width, 38);
  });

  testWidgets('opens the label tooltip above the item', (tester) async {
    await tester.pumpWidget(ccTestApp(_strip()));

    final tooltip = tester.widget<CcTooltip>(find.byType(CcTooltip).first);
    expect(tooltip.placement, CcTooltipPlacement.top);
  });
}
