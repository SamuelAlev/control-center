import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_complexity_badge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('PrComplexityBadge', () {
    testWidgets('renders low complexity (small PR)', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 50, fileCount: 3),
      ));

      expect(find.text('50 LOC  ·  3 files'), findsOneWidget);
    });

    testWidgets('renders medium complexity (warning range)', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 250, fileCount: 10),
      ));

      expect(find.text('250 LOC  ·  10 files'), findsOneWidget);
    });

    testWidgets('renders high complexity (block range)', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 500, fileCount: 25),
      ));

      expect(find.text('500 LOC  ·  25 files'), findsOneWidget);
    });

    testWidgets('renders with k suffix for large PRs', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 1500, fileCount: 30),
      ));

      expect(find.text('1.5k LOC  ·  30 files'), findsOneWidget);
    });

    testWidgets('renders single file with singular label', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 100, fileCount: 1),
      ));

      expect(find.text('100 LOC  ·  1 file'), findsOneWidget);
    });

    testWidgets('renders zero LOC', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 0, fileCount: 0),
      ));

      expect(find.text('0 LOC  ·  0 files'), findsOneWidget);
    });

    testWidgets('border at 200 LOC (medium threshold)', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 200, fileCount: 5),
      ));

      expect(find.text('200 LOC  ·  5 files'), findsOneWidget);
    });

    testWidgets('border at 400 LOC (high threshold)', (tester) async {
      await tester.pumpWidget(testWrap(
        const PrComplexityBadge(totalLoc: 400, fileCount: 8),
      ));

      expect(find.text('400 LOC  ·  8 files'), findsOneWidget);
    });

    testWidgets('renders from factory with PrFile list', (tester) async {
      final files = [
        PrFile(
          filename: 'src/main.dart',
          status: PrFileStatus.modified,
          additions: 30,
          deletions: 10,
          patch: 'dummy patch',
        ),
        PrFile(
          filename: 'src/utils.dart',
          status: PrFileStatus.added,
          additions: 50,
          deletions: 0,
          patch: 'dummy patch',
        ),
      ];

      await tester.pumpWidget(testWrap(
        PrComplexityBadge.fromFiles(files),
      ));

      // total LOC = 30+10+50+0 = 90, files = 2
      expect(find.text('90 LOC  ·  2 files'), findsOneWidget);
    });
  });
}
