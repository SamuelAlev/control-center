import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

const _dotsThree = IconData(
  0xe1fe,
  fontFamily: 'PhosphorRegular',
  fontPackage: 'cc_ui',
);
const _dotsThreeVertical = IconData(
  0xe208,
  fontFamily: 'PhosphorRegular',
  fontPackage: 'cc_ui',
);
const _other = IconData(0xe801, fontFamily: 'MaterialIcons');

Finder _ccIcon(IconData icon) =>
    find.byWidgetPredicate((widget) => widget is CcIcon && widget.icon == icon);

Widget _align(Widget child) =>
    Align(alignment: Alignment.topLeft, child: child);

void main() {
  testWidgets('dots-three keeps the requested size and does not use Icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(_align(const CcIcon(_dotsThree, size: 16))),
    );

    expect(tester.getSize(_ccIcon(_dotsThree)), const Size(16, 16));
    expect(find.byType(Icon), findsNothing);
    expect(find.byType(OverflowBox), findsNothing);
    expect(
      find.descendant(
        of: _ccIcon(_dotsThree),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dots-three-vertical is the same size', (tester) async {
    await tester.pumpWidget(
      ccTestApp(_align(const CcIcon(_dotsThreeVertical, size: 16))),
    );

    expect(tester.getSize(_ccIcon(_dotsThreeVertical)), const Size(16, 16));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('other glyphs paint at the requested size through Icon', (
    tester,
  ) async {
    await tester.pumpWidget(ccTestApp(_align(const CcIcon(_other, size: 16))));

    expect(tester.getSize(find.byType(CcIcon)), const Size(16, 16));
    expect(tester.widget<Icon>(find.byType(Icon)).size, 16);
  });

  testWidgets('a 32px request stays 32px', (tester) async {
    await tester.pumpWidget(
      ccTestApp(_align(const CcIcon(_dotsThree, size: 32))),
    );

    expect(tester.getSize(_ccIcon(_dotsThree)), const Size(32, 32));
  });

  testWidgets('tight parents do not scale the SVG up', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        _align(
          const SizedBox(
            width: 32,
            height: 32,
            child: CcIcon(_dotsThree, size: 16),
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: _ccIcon(_dotsThree),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.size, const Size(16, 16));
  });
}
