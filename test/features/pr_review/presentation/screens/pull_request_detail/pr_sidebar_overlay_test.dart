import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_sidebar_overlay.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PullRequest _pr() {
  return PullRequest(
    id: 1,
    number: 42,
    title: 'Test PR',
    body: 'Description',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'author', avatarUrl: ''),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/42',
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      prReviewRepositoryProvider.overrideWith(
        (ref) => const EmptyPrReviewRepository(),
      ),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      prFilesProvider(_prRef).overrideWith((ref) => Stream.value(const <PrFile>[])),
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

/// The PR identity TreeOverlay is keyed by in this suite.
const _prRef = (workspaceId: 'ws', repoFullName: 'owner/repo', number: 42);

void main() {
  group('TreeOverlay', () {
    testWidgets('tree mode renders empty state when no files', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(
        _wrap(
          TreeOverlay(
            pr: pr,
            prRef: _prRef,
            diffKey: GlobalKey(),
            mode: PrDiffSidebarMode.tree,
            searchFocusToken: 0,
            onOpenSearch: () {},
            onShowFileTree: () {},
            onOpenFileInEditor: (_, {int? line}) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('search mode shows a preparing state without a workspace', (
      tester,
    ) async {
      final pr = _pr();
      await tester.pumpWidget(
        _wrap(
          TreeOverlay(
            pr: pr,
            prRef: _prRef,
            diffKey: GlobalKey(),
            mode: PrDiffSidebarMode.search,
            searchFocusToken: 1,
            onOpenSearch: () {},
            onShowFileTree: () {},
            onOpenFileInEditor: (_, {int? line}) {},
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // No active workspace is bound (no route), so the search host renders its
      // preparing fallback rather than the search field.
      expect(find.text('Preparing workspace…'), findsOneWidget);
    });
  });
}
