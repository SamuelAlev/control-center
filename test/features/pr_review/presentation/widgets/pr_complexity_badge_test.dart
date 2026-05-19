import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_complexity_badge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// The size tag carries the changed-line count ALONE. The file count moved into
/// the tooltip (it has its own home in the "Files changed" section, so repeating
/// it in the tag only crowds the row) and severity is carried by the badge
/// variant rather than by any text.
void main() {
  CcBadge badgeOf(WidgetTester tester) =>
      tester.widget<CcBadge>(find.byType(CcBadge));

  String tooltipOf(WidgetTester tester) =>
      tester.widget<CcTooltip>(find.byType(CcTooltip)).message!;

  group('PrComplexityBadge label', () {
    testWidgets('shows the LOC count without the file count', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 50, fileCount: 3)),
      );

      expect(find.text('50 LOC'), findsOneWidget);
      expect(find.textContaining('3 files'), findsNothing);
    });

    testWidgets('abbreviates past 1k', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 1500, fileCount: 30)),
      );

      expect(find.text('1.5k LOC'), findsOneWidget);
    });

    testWidgets('renders zero LOC', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 0, fileCount: 0)),
      );

      expect(find.text('0 LOC'), findsOneWidget);
    });
  });

  group('PrComplexityBadge severity variant', () {
    // Thresholds from the Cisco/SmartBear review-quality research: amber at
    // ≥200 LOC, red at ≥400. Boundaries are inclusive.
    testWidgets('low below 200 LOC', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 199, fileCount: 5)),
      );
      expect(badgeOf(tester).variant, CcBadgeVariant.success);
    });

    testWidgets('medium exactly at 200 LOC', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 200, fileCount: 5)),
      );
      expect(badgeOf(tester).variant, CcBadgeVariant.warning);
    });

    testWidgets('medium below 400 LOC', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 399, fileCount: 8)),
      );
      expect(badgeOf(tester).variant, CcBadgeVariant.warning);
    });

    testWidgets('high exactly at 400 LOC', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 400, fileCount: 8)),
      );
      expect(badgeOf(tester).variant, CcBadgeVariant.danger);
    });
  });

  group('PrComplexityBadge tooltip', () {
    testWidgets('a small PR gets a review-time estimate + file count', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 100, fileCount: 1)),
      );

      final tip = tooltipOf(tester);
      expect(tip, contains('Small PR'));
      // Singular, via the shared `diffFilesCount` plural.
      expect(tip, contains('1 file'));
      // 100 LOC × 15 min/100 LOC = 15 min.
      expect(tip, contains('15 min'));
    });

    testWidgets('a medium PR asks the reviewer to block time', (tester) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 250, fileCount: 10)),
      );

      final tip = tooltipOf(tester);
      expect(tip, contains('Medium PR'));
      expect(tip, contains('10 files'));
      expect(tip, contains('block'));
    });

    testWidgets('a large PR recommends splitting instead of a time estimate', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 500, fileCount: 25)),
      );

      final tip = tooltipOf(tester);
      expect(tip, contains('Large PR'));
      expect(tip, contains('25 files'));
      expect(tip, contains('splitting'));
      expect(tip, isNot(contains('min to review')));
    });

    testWidgets('the estimate is clamped to a sane floor and ceiling', (
      tester,
    ) async {
      // 1 LOC would estimate 0 min; the floor is 5.
      await tester.pumpWidget(
        testWrap(const PrComplexityBadge(totalLoc: 1, fileCount: 1)),
      );
      expect(tooltipOf(tester), contains('5 min'));
    });
  });

  testWidgets('fromFiles sums additions + deletions across files', (
    tester,
  ) async {
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

    await tester.pumpWidget(testWrap(PrComplexityBadge.fromFiles(files)));

    // 30 + 10 + 50 + 0 = 90 LOC across 2 files.
    expect(find.text('90 LOC'), findsOneWidget);
    expect(tooltipOf(tester), contains('2 files'));
  });
}
