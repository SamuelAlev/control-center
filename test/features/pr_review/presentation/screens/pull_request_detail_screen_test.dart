import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail_screen.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_database.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp.router(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (_, _) => child)],
      ),
    ),
  );
}

PullRequest _makePr({
  required int number,
  required String title,
  PrState state = PrState.open,
  bool isDraft = false,
  String authorLogin = 'dev',
  String body = '',
  String repoFullName = 'owner/repo',
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? mergedAt,
  List<PrUser> requestedReviewers = const [],
  List<PrUser> assignees = const [],
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: body,
    state: state,
    isDraft: isDraft,
    author: PrUser(login: authorLogin, avatarUrl: ''),
    createdAt: createdAt ?? DateTime(2024),
    updatedAt: updatedAt ?? DateTime(2024),
    repoFullName: repoFullName,
    htmlUrl: 'https://github.com/$repoFullName/pull/$number',
    requestedReviewers: requestedReviewers,
    assignees: assignees,
    mergedAt: mergedAt,
  );
}

void main() {
  late AppDatabase testDb;
  late AppPreferences prefs;

  setUp(() async {
    testDb = createTestDatabase();
    prefs = AppPreferences.inMemory();
  });

  tearDown(() async {
    await testDb.close();
  });

  List baseOverrides({int prNumber = 42}) {
    return [
      databaseProvider.overrideWithValue(testDb),
      appPreferencesProvider.overrideWithValue(prefs),
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      activeRepoProvider.overrideWith((ref) => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
    ];
  }

  group('PullRequestDetailScreen', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(42).overrideWith((ref) => const Stream.empty()),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PrDetailSkeleton), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders not found state when PR is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 99),
            prDetailProvider(99).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 99,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pull request not found'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders error state without crashing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(42).overrideWithValue(
              AsyncValue.error(Exception('Network error'), StackTrace.empty),
            ),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('not found state shows helpful message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 999),
            prDetailProvider(999).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 999,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('It may have been merged, closed, or moved.'),
        findsOneWidget,
      );
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state shows error message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(42).overrideWithValue(
              AsyncValue.error(Exception('Failed'), StackTrace.empty),
            ),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Couldn\'t load this pull request'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state shows exception text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(42).overrideWithValue(
              AsyncValue.error(
                Exception('rate limit exceeded'),
                StackTrace.empty,
              ),
            ),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Raw exception text is tucked behind a "Show details" disclosure so it
      // never greets the user by default.
      expect(find.textContaining('rate limit exceeded'), findsNothing);
      await tester.tap(find.text('Show details'));
      await tester.pump();
      expect(find.textContaining('rate limit exceeded'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders PR detail without crashing', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final pr = _makePr(number: 42, title: 'Fix login bug');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 42),
            prDetailProvider(42).overrideWith((ref) => Stream.value(pr)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PullRequestDetailScreen), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders draft PR without crashing', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final pr = _makePr(number: 55, title: 'Draft PR', isDraft: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 55),
            prDetailProvider(55).overrideWith((ref) => Stream.value(pr)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 55,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PullRequestDetailScreen), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders merged PR without crashing', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final pr = _makePr(
        number: 77,
        title: 'Merged PR',
        state: PrState.merged,
        mergedAt: DateTime(2024, 5, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 77),
            prDetailProvider(77).overrideWith((ref) => Stream.value(pr)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 77,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PullRequestDetailScreen), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders closed PR without crashing', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final pr = _makePr(number: 88, title: 'Closed PR', state: PrState.closed);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 88),
            prDetailProvider(88).overrideWith((ref) => Stream.value(pr)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 88,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PullRequestDetailScreen), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('not found state shows icon and page wrapper', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 555),
            prDetailProvider(555).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 555,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pull request not found'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state shows couldn\'t-load title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(42).overrideWithValue(
              AsyncValue.error(Exception('timeout'), StackTrace.empty),
            ),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Couldn\'t load this pull request'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('loading state renders skeleton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(42).overrideWith((ref) => const Stream.empty()),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The product register calls for a skeleton, not a centered spinner.
      expect(find.byType(PrDetailSkeleton), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('not found state renders not found text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 404),
            prDetailProvider(404).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 404,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pull request not found'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders with different PR numbers', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 7),
            prDetailProvider(7).overrideWith((ref) => const Stream.empty()),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                owner: 'owner',
                repo: 'repo',
                prNumber: 7,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PrDetailSkeleton), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
