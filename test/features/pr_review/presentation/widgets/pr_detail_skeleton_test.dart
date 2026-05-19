import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('PrDetailSkeleton', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrDetailSkeleton(),
      ));

      // Should render without throwing - skeleton contains Container widgets
      expect(find.byType(PrDetailSkeleton), findsOneWidget);
    });

    testWidgets('contains diff skeleton', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrDetailSkeleton(),
      ));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });
  });

  group('PrDiffSkeleton', () {
    testWidgets('renders with default rows', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrDiffSkeleton(),
      ));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });

    testWidgets('renders with custom row count', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrDiffSkeleton(rows: 3),
      ));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });

    testWidgets('renders with zero rows', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrDiffSkeleton(rows: 0),
      ));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });

    testWidgets('renders with many rows', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrDiffSkeleton(rows: 20),
      ));

      expect(find.byType(PrDiffSkeleton), findsOneWidget);
    });
  });
}
