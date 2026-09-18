import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcProgressBar', () {
    testWidgets('renders a determinate value without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const SizedBox(width: 200, child: CcProgressBar(value: 0.5))),
      );
      expect(find.byType(CcProgressBar), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('clamps out-of-range values', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const SizedBox(width: 200, child: CcProgressBar(value: 2))),
      );
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 1.0);
    });

    testWidgets('animates when indeterminate', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const SizedBox(width: 200, child: CcProgressBar())),
      );
      expect(find.byType(CcProgressBar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets(
      'indeterminate reverses at the end instead of wrapping to the start',
      (tester) async {
        await tester.pumpWidget(
          ccTestApp(
            const Center(child: SizedBox(width: 200, child: CcProgressBar())),
          ),
        );

        double segmentLeft() => tester
            .widget<Positioned>(
              find.descendant(
                of: find.byType(CcProgressBar),
                matching: find.byType(Positioned),
              ),
            )
            .left!;

        // One duration minus 100ms lands near the far edge (travel is 140).
        await tester.pump(const Duration(milliseconds: 1000));
        final nearEnd = segmentLeft();
        expect(nearEnd, greaterThan(100));

        // 300ms past the turnaround a wrap would be back near the start
        // (~38px); a reverse loop is still on the far side, coming back.
        await tester.pump(const Duration(milliseconds: 400));
        final afterTurn = segmentLeft();
        expect(afterTurn, greaterThan(80));
        expect(afterTurn, lessThan(nearEnd));
      },
    );

    testWidgets('indeterminate is static when motion is reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const SizedBox(width: 200, child: CcProgressBar()),
          theme: CcThemeData.light(reducedMotion: true),
        ),
      );
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 0.3);
      await tester.pumpAndSettle();
    });

    testWidgets(
      'rebuilding between determinate and indeterminate re-syncs the animation',
      (tester) async {
        double? value;
        late void Function(void Function()) mutate;
        await tester.pumpWidget(
          ccTestApp(
            StatefulBuilder(
              builder: (context, setState) {
                mutate = setState;
                return SizedBox(width: 200, child: CcProgressBar(value: value));
              },
            ),
          ),
        );

        // Start indeterminate (value null) -> controller repeats.
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to determinate -> didUpdateWidget runs _syncAnimation which
        // stops the controller because the bar is no longer indeterminate.
        mutate(() => value = 0.4);
        await tester.pumpAndSettle();
        final fill = tester.widget<FractionallySizedBox>(
          find.byType(FractionallySizedBox),
        );
        expect(fill.widthFactor, closeTo(0.4, 0.001));

        // Back to indeterminate restarts the animation without throwing.
        mutate(() => value = null);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
