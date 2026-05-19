import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_commit.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_commits_tab.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_commits_card.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PrCommit _c(String sha, String message) => PrCommit(
  sha: sha,
  message: message,
  author: const PrUser(login: 'author', avatarUrl: ''),
  date: DateTime(2024),
);

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('JetBrainsMono'),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
    ],
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('CommitsTab', () {
    testWidgets('renders loading state', (tester) async {
      await tester.pumpWidget(
        _wrap(const CommitsTab(commits: [], isLoading: true, error: null)),
      );
      await tester.pump();

      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets('renders error state when no commits and error', (tester) async {
      await tester.pumpWidget(
        _wrap(const CommitsTab(commits: [], isLoading: false, error: 'Failed')),
      );
      await tester.pump();

      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('renders commits card with data', (tester) async {
      final commits = [
        _c('aaa11111111111111111111111111111111111111', 'First commit'),
        _c('bbb22222222222222222222222222222222222222', 'Second commit'),
      ];

      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: CommitsTab(commits: commits, isLoading: false, error: null),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PrCommitsCard), findsOneWidget);
    });

    testWidgets('renders loading when isLoading even with error', (tester) async {
      await tester.pumpWidget(
        _wrap(const CommitsTab(commits: [], isLoading: true, error: 'ignored')),
      );
      await tester.pump();

      expect(find.byType(CcSpinner), findsOneWidget);
    });
  });
}
