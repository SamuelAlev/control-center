import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('PrOverviewSkeleton', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(testWrap(const PrOverviewSkeleton()));

      expect(find.byType(PrOverviewSkeleton), findsOneWidget);
    });
  });

  group('PrDiffTabSkeleton', () {
    testWidgets('renders the diff-area skeleton under its toolbar', (
      tester,
    ) async {
      await tester.pumpWidget(testWrap(const PrDiffTabSkeleton()));

      expect(find.byType(PrDiffTabSkeleton), findsOneWidget);
      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });
  });

  group('PrPanelSkeleton', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(testWrap(const PrPanelSkeleton()));

      expect(find.byType(PrPanelSkeleton), findsOneWidget);
    });

    testWidgets('renders with custom row count', (tester) async {
      await tester.pumpWidget(testWrap(const PrPanelSkeleton(rows: 2)));

      expect(find.byType(PrPanelSkeleton), findsOneWidget);
    });
  });

  group('PrDiffSkeleton', () {
    testWidgets('renders with default rows', (tester) async {
      await tester.pumpWidget(testWrap(const PrDiffSkeleton()));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });

    testWidgets('renders with custom row count', (tester) async {
      await tester.pumpWidget(testWrap(const PrDiffSkeleton(rows: 3)));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });

    testWidgets('renders with zero rows', (tester) async {
      await tester.pumpWidget(testWrap(const PrDiffSkeleton(rows: 0)));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });

    testWidgets('renders with many rows', (tester) async {
      await tester.pumpWidget(testWrap(const PrDiffSkeleton(rows: 20)));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });
  });
}
