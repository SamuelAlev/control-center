import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _long =
    'Work toward a goal until it is done, with checks and a spending cap';

Widget _host(
  String text, {
  required bool active,
  TextDirection dir = TextDirection.ltr,
  bool reduced = false,
  int reducedMotionLines = 1,
}) =>
    // Not ccTestApp: its Overlay keeps the first entry, so a second pumpWidget
    // would never reach the widget under test.
    CcTheme(
      data: CcThemeData.light(),
      child: Directionality(
        textDirection: dir,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(
            child: SizedBox(
              width: 120,
              child: CcMarqueeText(
                text,
                active: active,
                reducedMotionLines: reducedMotionLines,
              ),
            ),
          ),
        ),
      ),
    );

double _offset(WidgetTester tester) => tester
    .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
    .controller!
    .offset;

void main() {
  group('CcMarqueeText', () {
    testWidgets('rests on the ellipsis while the row is not active', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_long, active: false));
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        tester.widget<Text>(find.text(_long)).overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('an active row travels to the end once, then rests', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_long, active: true));
      // Nothing moves before the delay: arrowing through sets off no motion.
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(SingleChildScrollView), findsNothing);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final mid = _offset(tester);
      expect(mid, greaterThan(0));

      await tester.pump(const Duration(seconds: 1));
      expect(_offset(tester), greaterThan(mid));

      // One pass, never a loop.
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        tester.widget<Text>(find.text(_long)).overflow,
        TextOverflow.ellipsis,
      );
    });

    testWidgets('leaving the row stops the motion', (tester) async {
      await tester.pumpWidget(_host(_long, active: true));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_offset(tester), greaterThan(0));

      // Well inside the pass: only leaving the row can have ended it.
      await tester.pumpWidget(_host(_long, active: false));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('text that fits never moves, nor swaps for a frame', (
      tester,
    ) async {
      await tester.pumpWidget(_host('Short', active: true));
      final text = tester.widget<Text>(find.text('Short'));
      // The frame the delay ends on: a swap here cross-fades, which blinks.
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.widget<Text>(find.text('Short')), same(text));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion keeps the ellipsis', (tester) async {
      await tester.pumpWidget(_host(_long, active: true, reduced: true));
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('reduced motion wraps the active text when given lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_long, active: false, reduced: true, reducedMotionLines: 3),
      );
      final oneLine = tester.getSize(find.text(_long)).height;

      await tester.pumpWidget(
        _host(_long, active: true, reduced: true, reducedMotionLines: 3),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.getSize(find.text(_long)).height, greaterThan(oneLine));
    });

    testWidgets('exposes the whole text as one label throughout', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_long, active: true));
      expect(find.bySemanticsLabel(_long), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.bySemanticsLabel(_long), findsOneWidget);
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('travels right to left without errors', (tester) async {
      await tester.pumpWidget(
        _host(_long, active: true, dir: TextDirection.rtl),
      );
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_offset(tester), greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });
}
