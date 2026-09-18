import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/charts/chart_hover.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chartHoverIndexForFx', () {
    test('line charts pick the nearest edge-aligned column', () {
      expect(
        chartHoverIndexForFx(0.12, 5, ChartHoverAxis.line),
        0,
      );
      expect(
        chartHoverIndexForFx(0.5, 5, ChartHoverAxis.line),
        2,
      );
      expect(
        chartHoverIndexForFx(0.9, 5, ChartHoverAxis.line),
        4,
      );
    });

    test('bar spaceAround maps each slot onto its group', () {
      expect(
        chartHoverIndexForFx(0.05, 4, ChartHoverAxis.barSpaceAround),
        0,
      );
      expect(
        chartHoverIndexForFx(0.49, 4, ChartHoverAxis.barSpaceAround),
        1,
      );
      expect(
        chartHoverIndexForFx(0.99, 4, ChartHoverAxis.barSpaceAround),
        3,
      );
    });
  });

  group('chartHoverGeometry', () {
    const padding = EdgeInsets.only(left: 44, bottom: 28);
    const size = Size(440, 228);

    test('the first line point sits on the plot start edge, not in the gutter', () {
      final geometry = chartHoverGeometry(
        size: size,
        plotPadding: padding,
        index: 0,
        count: 5,
        axis: ChartHoverAxis.line,
        seriesAt: [(value: 0, color: const Color(0xFFFF0000))],
        maxY: 100,
      );
      expect(geometry.x, 44);
      expect(geometry.dots.single.y, 200);
    });

    test('a peak sits on the plot’s top edge', () {
      final geometry = chartHoverGeometry(
        size: size,
        plotPadding: padding,
        index: 2,
        count: 5,
        axis: ChartHoverAxis.line,
        seriesAt: [(value: 100, color: const Color(0xFFFF0000))],
        maxY: 100,
      );
      expect(geometry.x, 44 + 0.5 * 396);
      expect(geometry.dots.single.y, 0);
    });
  });

  group('ChartHoverController', () {
    testWidgets('hides only after the grace, and a re-enter cancels the hide', (
      tester,
    ) async {
      final hover = ChartHoverController();
      addTearDown(hover.dispose);
      hover.pointerAt(1);
      expect(hover.index, 1);

      hover.pointerLeft();
      await tester.pump(const Duration(milliseconds: 40));
      expect(hover.index, 1);

      hover.pointerAt(2);
      await tester.pump(CcMotion.fast);
      expect(hover.index, 2);

      hover.pointerLeft();
      await tester.pump(CcMotion.fast);
      expect(hover.index, isNull);
    });
  });
}
