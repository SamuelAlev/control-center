import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_diff_scope_notifier.dart';
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

Widget _wrap(
  Widget child, {
  List<PrFile> files = const [],
  List<PrCommit> commits = const [],
  Map<String, List<PrFile>> commitFiles = const {},
  Set<String> selectedShas = const {},
}) {
  return ProviderScope(
    overrides: [
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      prReviewRepositoryProvider.overrideWith(
        (ref) => const EmptyPrReviewRepository(),
      ),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      prFileIndexProvider(_prRef).overrideWith((ref) => Stream.value(files)),
      prCommitsProvider(_prRef).overrideWith((ref) => Stream.value(commits)),
      if (selectedShas.isNotEmpty)
        prDiffScopeProvider.overrideWith(() => _FixedScope(selectedShas)),
      if (commitFiles.isNotEmpty)
        prCommitFilesProvider.overrideWith((ref, key) {
          return Stream.value(commitFiles[key.sha] ?? const <PrFile>[]);
        }),
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

/// The PR identity TreeOverlay is keyed by in this suite.
const _prRef = (workspaceId: 'ws', repoFullName: 'owner/repo', number: 42);

void main() {
  group('TreeOverlay', () {
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

    testWidgets('lists every pull-request file when no commit is selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_tree(), files: [_file(_inCommit), _file(_onlyInPr)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Context.php'), findsOneWidget);
      expect(find.text('InstanceEndpointTest.php'), findsOneWidget);
    });

    testWidgets('lists only the selected commit\'s files', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _tree(),
          files: [_file(_inCommit), _file(_onlyInPr)],
          commits: [_commit(_commitSha)],
          selectedShas: {_commitSha},
          commitFiles: {
            _commitSha: [_file(_inCommit)],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Context.php'), findsOneWidget);
      expect(find.text('InstanceEndpointTest.php'), findsNothing);
    });
  });
}

const _commitSha = 'abc1234567';
const _inCommit = 'application/server/Legacy/Context.php';
const _onlyInPr = 'tests/Frontend/Endpoint/InstanceEndpointTest.php';

PrFile _file(String filename) {
  return PrFile(
    filename: filename,
    status: PrFileStatus.modified,
    additions: 4,
    deletions: 0,
    patch: '',
  );
}

PrCommit _commit(String sha) {
  return PrCommit(
    sha: sha,
    message: 'feat: add saml logout links',
    author: const PrUser(login: 'author', avatarUrl: ''),
    date: DateTime(2024, 1, 2),
  );
}

Widget _tree() {
  return TreeOverlay(
    pr: _pr(),
    prRef: _prRef,
    diffKey: GlobalKey(),
    mode: PrDiffSidebarMode.tree,
    searchFocusToken: 0,
    onOpenSearch: () {},
    onShowFileTree: () {},
    onOpenFileInEditor: (_, {int? line}) {},
  );
}

class _FixedScope extends PrDiffScopeNotifier {
  _FixedScope(this._shas);

  final Set<String> _shas;

  @override
  PrDiffScopeState build() => PrDiffScopeState(selectedShas: _shas);
}
