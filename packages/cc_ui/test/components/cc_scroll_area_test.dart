import 'package:cc_ui/src/components/cc_scroll_area.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

Widget _area({int rows = 20, double height = 200}) {
  return SizedBox(
    height: height,
    width: 200,
    child: CcScrollArea(
      child: ListView(
        children: [
          for (var i = 0; i < rows; i++)
            SizedBox(height: 40, child: Text('Row $i')),
        ],
      ),
    ),
  );
}

CcScrollAreaState _state(WidgetTester tester) =>
    tester.state<CcScrollAreaState>(find.byType(CcScrollArea));

void main() {
  group('CcScrollArea', () {
    testWidgets('at the top: hints only the trailing edge', (tester) async {
      await tester.pumpWidget(ccTestApp(_area()));
      await tester.pumpAndSettle();

      expect(_state(tester).startEdgeVisible, isFalse);
      expect(_state(tester).endEdgeVisible, isTrue);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mid-scroll: hints both edges', (tester) async {
      await tester.pumpWidget(ccTestApp(_area()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(_state(tester).startEdgeVisible, isTrue);
      expect(_state(tester).endEdgeVisible, isTrue);
    });

    testWidgets('at the bottom: hints only the leading edge', (tester) async {
      await tester.pumpWidget(ccTestApp(_area()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(_state(tester).startEdgeVisible, isTrue);
      expect(_state(tester).endEdgeVisible, isFalse);
    });

    testWidgets('back at the top the leading hint clears again', (
      tester,
    ) async {
      await tester.pumpWidget(ccTestApp(_area()));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 2000));
      await tester.pumpAndSettle();

      expect(_state(tester).startEdgeVisible, isFalse);
      expect(_state(tester).endEdgeVisible, isTrue);
    });

    testWidgets('content that fits shows no hint at all', (tester) async {
      await tester.pumpWidget(ccTestApp(_area(rows: 3)));
      await tester.pumpAndSettle();

      expect(_state(tester).startEdgeVisible, isFalse);
      expect(_state(tester).endEdgeVisible, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shrinking content below one screenful drops the hint', (
      tester,
    ) async {
      // Mutate the row count inside a stable tree (the filtering scenario):
      // ccTestApp's Overlay keeps its initial entry, so pumping a fresh app
      // would not actually swap the content.
      late StateSetter setRows;
      var rows = 20;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              setRows = setState;
              return _area(rows: rows);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_state(tester).endEdgeVisible, isTrue);

      setRows(() => rows = 3);
      await tester.pumpAndSettle();

      expect(_state(tester).startEdgeVisible, isFalse);
      expect(_state(tester).endEdgeVisible, isFalse);
    });

    testWidgets('a reversed list keeps hints on the correct physical sides', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          SizedBox(
            height: 200,
            width: 200,
            child: CcScrollArea(
              child: ListView(
                reverse: true,
                children: [
                  for (var i = 0; i < 20; i++)
                    SizedBox(height: 40, child: Text('Row $i')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pinned to the newest (bottom) end: only the "before" edge — which is
      // physically the top for a reversed list — has more content.
      expect(_state(tester).startEdgeVisible, isFalse);
      expect(_state(tester).endEdgeVisible, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a nested scrollable does not drive the hints', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          SizedBox(
            height: 200,
            width: 200,
            child: CcScrollArea(
              child: ListView(
                children: [
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var i = 0; i < 20; i++)
                          const SizedBox(width: 60, child: Text('x')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The outer list fits; the scrollable inner one must not flash hints.
      expect(_state(tester).startEdgeVisible, isFalse);
      expect(_state(tester).endEdgeVisible, isFalse);
    });
  });
}
