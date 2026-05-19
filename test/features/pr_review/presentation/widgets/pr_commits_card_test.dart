import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_commits_card.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PrUser _user(String login) => PrUser(login: login, avatarUrl: '');

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
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('renders empty state when no commits', (tester) async {
    await tester.pumpWidget(_wrap(const PrCommitsCard(commits: [])));
    expect(find.text('Commits'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('No commits in this PR yet.'), findsOneWidget);
  });

  testWidgets('renders single commit', (tester) async {
    final author = _user('dev1');
    final commits = [
      PrCommit(
        sha: 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0',
        message: 'Fix authentication bug',
        author: author,
        date: DateTime(2024, 6, 15, 10, 0),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('Fix authentication bug'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('a1b2c3d'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.data != null && w.data!.contains('dev1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders multiple commits', (tester) async {
    final commits = [
      PrCommit(
        sha: 'aaa111',
        message: 'First',
        author: _user('dev1'),
        date: DateTime(2024, 6, 15, 10, 0),
      ),
      PrCommit(
        sha: 'bbb222',
        message: 'Second',
        author: _user('dev2'),
        date: DateTime(2024, 6, 15, 11, 0),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('aaa111'), findsOneWidget);
    expect(find.text('bbb222'), findsOneWidget);
  });

  testWidgets('renders commit with truncated SHA', (tester) async {
    final commits = [
      PrCommit(
        sha: 'abcdef1234567890abcdef1234567890abcdef12',
        message: 'Long sha commit',
        author: _user('dev1'),
        date: DateTime(2024, 6, 15),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('abcdef1'), findsOneWidget);
    expect(find.text('Long sha commit'), findsOneWidget);
  });

  testWidgets('renders emoji commit message', (tester) async {
    final commits = [
      PrCommit(
        sha: 'sha',
        message: 'Add rocket',
        author: _user('astronaut'),
        date: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('Add rocket'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.data != null && w.data!.contains('astronaut'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders commit without author', (tester) async {
    final commits = [
      PrCommit(
        sha: 'deadbeef1234567890abcdef1234567890abcde',
        message: 'Anonymous commit',
        author: null,
        date: DateTime(2024, 6, 15),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('Anonymous commit'), findsOneWidget);
    expect(find.text('deadbee'), findsOneWidget);
  });

  testWidgets('renders commit without date', (tester) async {
    final commits = [
      PrCommit(
        sha: 'feed1234567890abcdef1234567890abcdef1234',
        message: 'Undated commit',
        author: _user('timeless'),
        date: null,
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('Undated commit'), findsOneWidget);
    expect(find.text('timeless'), findsOneWidget);
  });

  testWidgets('renders commit with multi-line message as title only', (
    tester,
  ) async {
    final commits = [
      PrCommit(
        sha: 'feedfeedfeedfeedfeedfeedfeedfeedfeedfeed',
        message: 'feat: add login\n\nThis adds the login feature with OAuth.',
        author: _user('dev1'),
        date: DateTime(2024, 1, 1),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('feat: add login'), findsOneWidget);
  });

  testWidgets('renders commit with empty message', (tester) async {
    final commits = [
      PrCommit(
        sha: 'aaa111122223333444455556666777788889999',
        message: '',
        author: _user('silent'),
        date: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('(no commit message)'), findsOneWidget);
  });

  testWidgets('renders commit with empty author login', (tester) async {
    final commits = [
      PrCommit(
        sha: 'abc111122223333444455556666777788889999',
        message: 'Ghost commit',
        author: const PrUser(login: '', avatarUrl: ''),
        date: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('Ghost commit'), findsOneWidget);
  });

  testWidgets('renders count badge for multiple commits', (tester) async {
    final commits = List.generate(
      5,
      (i) => PrCommit(
        sha: 'sh$i'.padRight(40, '0'),
        message: 'Commit $i',
        author: _user('dev'),
        date: DateTime(2024),
      ),
    );

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Commit 0'), findsOneWidget);
    expect(find.text('Commit 4'), findsOneWidget);
  });

  testWidgets('renders commit with short sha less than 7 chars', (
    tester,
  ) async {
    final commits = [
      PrCommit(
        sha: 'abc',
        message: 'Short sha',
        author: _user('dev'),
        date: DateTime(2024),
      ),
    ];

    await tester.pumpWidget(_wrap(PrCommitsCard(commits: commits)));
    expect(find.text('abc'), findsOneWidget);
  });
}
