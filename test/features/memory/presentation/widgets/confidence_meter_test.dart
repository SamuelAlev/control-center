import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MemoryConfidenceMarker', () {
    testWidgets('its bar fills in step with the value', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const Center(
            child: MemoryConfidenceMarker(
              icon: AppIcons.lightbulb,
              confidence: 0.5,
            ),
          ),
        ),
      );

      final fill = tester.getSize(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill, const Size(14, 3));
    });
  });

  group('ConfidenceMeter', () {
    testWidgets('the fill has height and tracks the value', (tester) async {
      await tester.pumpWidget(
        testWrap(const Center(child: ConfidenceMeter(confidence: 0.5))),
      );

      final fill = tester.getSize(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(fill.height, greaterThan(0));
      expect(fill.width, 20);
    });

    testWidgets('renders high confidence', (tester) async {
      await tester.pumpWidget(
        testWrap(const ConfidenceMeter(confidence: 0.95)),
      );

      expect(find.text('95%'), findsOneWidget);
    });

    testWidgets('renders medium confidence', (tester) async {
      await tester.pumpWidget(
        testWrap(const ConfidenceMeter(confidence: 0.65)),
      );

      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('renders low confidence', (tester) async {
      await tester.pumpWidget(
        testWrap(const ConfidenceMeter(confidence: 0.25)),
      );

      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('renders zero confidence', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 0.0)));

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders full confidence', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 1.0)));

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('clamps above 1.0', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 1.5)));

      // Clamped to 1.0 → 100%
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('clamps below 0.0', (tester) async {
      await tester.pumpWidget(
        testWrap(const ConfidenceMeter(confidence: -0.5)),
      );

      // Clamped to 0.0 → 0%
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders compact variant', (tester) async {
      await tester.pumpWidget(
        testWrap(const ConfidenceMeter(confidence: 0.85, compact: true)),
      );

      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('boundary at 0.8 renders high colors', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 0.8)));

      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('boundary at 0.5 renders medium colors', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 0.5)));

      expect(find.text('50%'), findsOneWidget);
    });
  });

  group('memoryConfidenceColor', () {
    testWidgets('returns success color for high confidence', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 0.9)));

      final color = memoryConfidenceColor(
        tester.element(find.byType(ConfidenceMeter)),
        0.9,
      );
      expect(color, isNotNull);
    });

    testWidgets('returns warning color for medium confidence', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 0.6)));

      final color = memoryConfidenceColor(
        tester.element(find.byType(ConfidenceMeter)),
        0.6,
      );
      expect(color, isNotNull);
    });

    testWidgets('returns error color for low confidence', (tester) async {
      await tester.pumpWidget(testWrap(const ConfidenceMeter(confidence: 0.2)));

      final color = memoryConfidenceColor(
        tester.element(find.byType(ConfidenceMeter)),
        0.2,
      );
      expect(color, isNotNull);
    });
  });
}
