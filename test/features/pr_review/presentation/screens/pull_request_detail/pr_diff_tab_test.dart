import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_diff_tab.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_chip.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_file_tree.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

PullRequest _pr() => PullRequest(
  id: 1,
  number: 42,
  title: 'Test PR',
  body: '',
  state: PrState.open,
  isDraft: false,
  headSha: '',
  author: const PrUser(login: 'author', avatarUrl: ''),
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  repoFullName: 'owner/repo',
  htmlUrl: 'https://github.com/owner/repo/pull/42',
);

PrCommit _commit({required String sha, required String message}) {
  return PrCommit(
    sha: sha,
    message: message,
    author: const PrUser(login: 'Author', avatarUrl: ''),
    date: DateTime(2024, 1, 1),
  );
}

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

Widget _wrap(
  Widget child, {
  required AppPreferences prefs,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWithValue(prefs),
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider.overrideWith(
        (ref) => const EmptyPrReviewRepository(),
      ),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      ...overrides,
    ],
    child: MaterialApp(
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
    ),
  );
}

Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(Container());
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('PrDiffTab merged toolbar', () {
    testWidgets('renders tree toggle, stats and settings trigger', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(PrDiffTab(pr: _pr()), prefs: AppPreferences.inMemory()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tree'), findsOneWidget);
      expect(find.byIcon(AppIcons.slidersHorizontal), findsOneWidget);
      expect(find.text('0 files'), findsOneWidget);
      // No commits loaded: the commit-range dropdown stays hidden.
      expect(find.text('All commits'), findsNothing);

      await _teardown(tester);
    });

    testWidgets('tree toggle flips and persists the preference', (
      tester,
    ) async {
      final prefs = AppPreferences.inMemory();
      await tester.pumpWidget(_wrap(PrDiffTab(pr: _pr()), prefs: prefs));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Tree'));
      await tester.pump();

      expect(prefs.getBool(prTreeVisibleKey), isFalse);

      await tester.tap(find.text('Tree'));
      await tester.pump();

      expect(prefs.getBool(prTreeVisibleKey), isTrue);

      await _teardown(tester);
    });

    testWidgets('settings dropdown switches split view and persists', (
      tester,
    ) async {
      final prefs = AppPreferences.inMemory();
      await tester.pumpWidget(_wrap(PrDiffTab(pr: _pr()), prefs: prefs));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(AppIcons.slidersHorizontal));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Split'), findsOneWidget);
      expect(find.text('Unified'), findsOneWidget);

      await tester.tap(find.text('Split'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(prefs.getBool(prDiffSplitViewKey), isTrue);

      await _teardown(tester);
    });

    testWidgets('commit dropdown lists commits with checkboxes', (
      tester,
    ) async {
      final commits = [
        _commit(
          sha: 'aaa11111111111111111111111111111111111111',
          message: 'First',
        ),
        _commit(
          sha: 'bbb22222222222222222222222222222222222222',
          message: 'Second',
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          PrDiffTab(pr: _pr()),
          prefs: AppPreferences.inMemory(),
          overrides: [
            prCommitsProvider(42).overrideWith((ref) => Stream.value(commits)),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All commits'), findsOneWidget);

      await tester.tap(find.text('All commits'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(CcCheckbox), findsWidgets);

      await _teardown(tester);
    });

    testWidgets('tree chip left-aligns with the file filter field', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final files = [
        PrFile(
          filename: 'lib/main.dart',
          status: PrFileStatus.modified,
          additions: 1,
          deletions: 0,
          patch: '',
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          PrDiffTab(pr: _pr()),
          prefs: AppPreferences.inMemory(),
          overrides: [
            prFilesProvider(42).overrideWith((ref) => Stream.value(files)),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PrTabChip), findsOneWidget);
      expect(find.byType(CcTextField), findsOneWidget);

      final chipLeft = tester.getTopLeft(find.byType(PrTabChip)).dx;
      final fieldLeft = tester.getTopLeft(find.byType(CcTextField)).dx;
      expect(chipLeft, moreOrLessEquals(fieldLeft, epsilon: 0.5));
      expect(chipLeft, moreOrLessEquals(kPrDiffTreeFilterInset, epsilon: 0.5));

      await _teardown(tester);
    });
  });
}
