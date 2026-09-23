import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_diff_tab.dart';
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
        GlobalMaterialLocalizations.delegate, // ignore: deprecated_member_use
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // ignore: deprecated_member_use
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

/// The PR identity PrDiffTab is keyed by in this suite.
const _prRef = (workspaceId: 'ws', repoFullName: 'test/repo', number: 42);

void main() {
  group('PrDiffTab merged toolbar', () {
    testWidgets('renders stats and settings trigger', (tester) async {
      await tester.pumpWidget(
        _wrap(PrDiffTab(pr: _pr(), prRef: _prRef), prefs: AppPreferences.inMemory()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tree'), findsNothing);
      expect(find.byIcon(AppIcons.slidersHorizontal), findsOneWidget);
      expect(find.text('0 files'), findsOneWidget);
      expect(
        tester.widget<CcIconButton>(find.byType(CcIconButton)).variant,
        CcButtonVariant.ghost,
      );
      // No commits loaded: the commit-range dropdown stays hidden.
      expect(find.text('All commits'), findsNothing);

      await _teardown(tester);
    });

    testWidgets('file-tree switch in settings flips and persists', (
      tester,
    ) async {
      final prefs = AppPreferences.inMemory();
      await tester.pumpWidget(_wrap(PrDiffTab(pr: _pr(), prRef: _prRef), prefs: prefs));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(AppIcons.slidersHorizontal));
      await tester.pump(const Duration(milliseconds: 100));

      final treeRow = find
          .ancestor(of: find.text('Tree'), matching: find.byType(Row))
          .first;
      final treeSwitch = find.descendant(
        of: treeRow,
        matching: find.byType(CcSwitch),
      );
      expect(treeSwitch, findsOneWidget);
      expect(tester.widget<CcSwitch>(treeSwitch).value, isTrue);

      await tester.tap(treeSwitch);
      await tester.pump();

      expect(prefs.getBool(prTreeVisibleKey), isFalse);

      await tester.tap(treeSwitch);
      await tester.pump();

      expect(prefs.getBool(prTreeVisibleKey), isTrue);

      await _teardown(tester);
    });

    testWidgets('settings dropdown switches split view and persists', (
      tester,
    ) async {
      final prefs = AppPreferences.inMemory();
      await tester.pumpWidget(_wrap(PrDiffTab(pr: _pr(), prRef: _prRef), prefs: prefs));
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
          PrDiffTab(pr: _pr(), prRef: _prRef),
          prefs: AppPreferences.inMemory(),
          overrides: [
            prCommitsProvider(_prRef).overrideWith((ref) => Stream.value(commits)),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All commits'), findsOneWidget);
      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'All commits'))
            .variant,
        CcButtonVariant.ghost,
      );

      await tester.tap(find.text('All commits'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.byType(CcCheckbox), findsWidgets);

      await _teardown(tester);
    });

  });
}
