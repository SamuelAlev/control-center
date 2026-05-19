import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_checks_card.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
    ],
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders empty state when no checks', (tester) async {
    await tester.pumpWidget(_wrap(const PrChecksCard(checks: [])));
    expect(find.text('CI/CD Checks'), findsOneWidget);
    expect(find.text('No checks have run on this commit.'), findsOneWidget);
  });

  testWidgets('renders passing check', (tester) async {
    final checks = [
      CheckRun(
        name: 'build-and-test',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        htmlUrl: '',
        completedAt: DateTime(2024, 6, 15, 10, 0),
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('build-and-test'), findsOneWidget);
    expect(find.text('CI/CD Checks'), findsOneWidget);
  });

  testWidgets('renders failing check with output', (tester) async {
    final checks = [
      CheckRun(
        name: 'lint',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        htmlUrl: 'https://github.com/actions/log',
        completedAt: DateTime(2024, 6, 15, 9, 30),
        output: 'Error: Missing semicolon at line 42',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('lint'), findsOneWidget);
    expect(find.text('1 failing'), findsOneWidget);
    expect(find.text('View logs'), findsOneWidget);
  });

  testWidgets('renders multiple checks with mixed status', (tester) async {
    final checks = [
      CheckRun(
        name: 'build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        htmlUrl: '',
      ),
      CheckRun(
        name: 'test',
        status: CheckRunStatus.inProgress,
        conclusion: null,
        htmlUrl: '',
      ),
      CheckRun(
        name: 'security-scan',
        status: CheckRunStatus.queued,
        conclusion: null,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('build'), findsOneWidget);
    expect(find.text('test'), findsOneWidget);
    expect(find.text('security-scan'), findsOneWidget);
    expect(find.text('Queued'), findsOneWidget);
    expect(find.text('running'), findsOneWidget);
  });

  testWidgets('renders timed out check as failing', (tester) async {
    final checks = [
      CheckRun(
        name: 'deploy-staging',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.timedOut,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('deploy-staging'), findsOneWidget);
    expect(find.text('1 failing'), findsOneWidget);
  });

  testWidgets('renders neutral check', (tester) async {
    final checks = [
      CheckRun(
        name: 'coverage-report',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.neutral,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('coverage-report'), findsOneWidget);
    expect(find.text('Neutral'), findsOneWidget);
    expect(find.text('1 failing'), findsNothing);
  });

  testWidgets('renders cancelled check', (tester) async {
    final checks = [
      CheckRun(
        name: 'performance-bench',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.cancelled,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('performance-bench'), findsOneWidget);
  });

  testWidgets('renders action required check as failing', (tester) async {
    final checks = [
      CheckRun(
        name: 'manual-approval',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.actionRequired,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('manual-approval'), findsOneWidget);
    expect(find.text('1 failing'), findsOneWidget);
  });

  testWidgets('renders skipped check', (tester) async {
    final checks = [
      CheckRun(
        name: 'optional-lint',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.skipped,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('optional-lint'), findsOneWidget);
    expect(find.text('1 failing'), findsNothing);
  });

  testWidgets('renders stale check', (tester) async {
    final checks = [
      CheckRun(
        name: 'old-check',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.stale,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('old-check'), findsOneWidget);
  });

  testWidgets('renders check with output and no htmlUrl', (tester) async {
    final checks = [
      CheckRun(
        name: 'test-suite',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        htmlUrl: '',
        output: '2 tests failed:\n  - login_test\n  - signup_test',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('test-suite'), findsOneWidget);
    expect(find.text('1 failing'), findsOneWidget);
    expect(find.textContaining('login_test'), findsOneWidget);
    expect(find.text('View logs'), findsNothing);
  });

  testWidgets('renders successful check with completed time', (tester) async {
    final checks = [
      CheckRun(
        name: 'build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        htmlUrl: '',
        completedAt: DateTime(2024, 6, 15, 12, 30),
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('build'), findsOneWidget);
  });

  testWidgets('renders failing badge count with multiple fails', (
    tester,
  ) async {
    final checks = [
      CheckRun(
        name: 'lint',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        htmlUrl: '',
      ),
      CheckRun(
        name: 'test',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.failure,
        htmlUrl: '',
      ),
      CheckRun(
        name: 'build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        htmlUrl: '',
      ),
    ];

    await tester.pumpWidget(_wrap(PrChecksCard(checks: checks)));
    expect(find.text('2 failing'), findsOneWidget);
  });
}
