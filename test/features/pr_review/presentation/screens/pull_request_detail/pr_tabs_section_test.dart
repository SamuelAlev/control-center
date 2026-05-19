import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tabs_section.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scaffold(Widget child) {
  return MaterialApp(
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      prDetailProvider(42).overrideWith((ref) => Stream.value(null)),
      prFilesProvider(42).overrideWith((ref) => Stream.value(const <PrFile>[])),
      prCommitsProvider(42).overrideWith((ref) => Stream.value(const <PrCommit>[])),
      prCheckRunsProvider(42).overrideWith((ref) => Stream.value(const [])),
    ],
    child: _scaffold(child),
  );
}

PullRequest _pr({int changedFiles = 0, int commitsCount = 0}) {
  return PullRequest(
    id: 1,
    number: 42,
    title: 'Test PR',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: null,
    createdAt: null,
    updatedAt: null,
    repoFullName: 'owner/repo',
    htmlUrl: 'https://example.com',
    changedFiles: changedFiles,
    commitsCount: commitsCount,
  );
}

/// Reports a PR detail with `changedFiles` set while serving an empty file list
/// — mimics a large PR whose local clone is still running.
class _LargePrRepo extends EmptyPrReviewRepository {
  const _LargePrRepo();

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) =>
      Stream.value(_pr(changedFiles: 4029));
}

void main() {
  group('TabStripContent', () {
    testWidgets('renders all tabs', (tester) async {
      final controller = TabController(length: 4, vsync: const TestVSync());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(TabStripContent(controller: controller, prNumber: 42)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Files changed'), findsOneWidget);
      expect(find.text('Commits'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('AI review'), findsOneWidget);
    });

    testWidgets('renders count badges', (tester) async {
      final controller = TabController(length: 4, vsync: const TestVSync());
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrap(TabStripContent(controller: controller, prNumber: 42)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Files, Commits and Actions each carry a badge; AI review does not.
      expect(find.byType(CountBadge), findsNWidgets(3));
    });

    testWidgets(
      'files badge falls back to changedFiles while the file list is empty',
      (tester) async {
        final controller = TabController(length: 4, vsync: const TestVSync());
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              codeFontFamilyProvider.overrideWithValue('Fira Code'),
              prReviewRepositoryProvider.overrideWithValue(const _LargePrRepo()),
              workspacesProvider.overrideWith(
                (ref) => const Stream<List<Workspace>>.empty(),
              ),
            ],
            child: _scaffold(
              TabStripContent(controller: controller, prNumber: 42),
            ),
          ),
        );
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Loaded file list is empty, but the badge shows the GitHub total.
        expect(find.text('4029'), findsOneWidget);
      },
    );
  });

  group('CountBadge', () {
    testWidgets('renders count text', (tester) async {
      await tester.pumpWidget(
        _wrap(const CountBadge(count: 42)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('renders zero count', (tester) async {
      await tester.pumpWidget(
        _wrap(const CountBadge(count: 0)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders large count', (tester) async {
      await tester.pumpWidget(
        _wrap(const CountBadge(count: 9999)),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('9999'), findsOneWidget);
    });
  });
}
