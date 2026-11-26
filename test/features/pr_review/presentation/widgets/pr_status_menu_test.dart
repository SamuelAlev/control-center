import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_status_menu.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _prRef = (
  workspaceId: 'ws-1',
  repoFullName: 'test/repo',
  number: 42,
  forge: null,
);

PullRequest _pr({bool isDraft = false, PrState state = PrState.open}) =>
    PullRequest(
      id: 1,
      number: 42,
      title: 'Test PR',
      body: '',
      state: state,
      isDraft: isDraft,
      author: const PrUser(login: 'tester', avatarUrl: ''),
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
      repoFullName: 'test/repo',
      htmlUrl: 'https://example.com',
    );

class _RecordingRepo extends EmptyPrReviewRepository {
  final List<String> calls = [];

  @override
  Future<void> setPullRequestDraft({
    required int prNumber,
    required bool draft,
  }) async => calls.add('draft:$draft');

  @override
  Future<void> closePullRequest({required int prNumber}) async =>
      calls.add('close');
}

Widget _app(PullRequest pr, _RecordingRepo repo, {required String login}) {
  return ProviderScope(
    overrides: [
      prRepoRowProvider(_prRef).overrideWith(
        (ref) => Repo(
          id: 'repo-1',
          name: 'repo',
          path: '/tmp/repo',
          remoteOwner: 'test',
          remoteName: 'repo',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ),
      forgeCapabilitiesProvider.overrideWith((ref) async => kForgeCapabilities),
      currentUserLoginForPrProvider(_prRef).overrideWithValue(login),
      repoPermissionProvider((
        owner: 'test',
        repo: 'repo',
      )).overrideWith((ref) async => 'read'),
      prRepositoryProvider(_prRef).overrideWith((ref) => repo),
      prReviewRepositoryProvider.overrideWith((ref) => repo),
    ],
    child: MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CcTheme(
        data: CcThemeData.light(),
        child: CcToastScope(
          child: Scaffold(
            body: Center(
              child: PrStatusMenu(pr: pr, prRef: _prRef),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a viewer who cannot change the state gets the plain tag', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_pr(), _RecordingRepo(), login: 'someone'));
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(CcMenu), findsNothing);
  });

  testWidgets('a merged or closed pull request has no menu', (tester) async {
    await tester.pumpWidget(
      _app(_pr(state: PrState.closed), _RecordingRepo(), login: 'tester'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Closed'), findsOneWidget);
    expect(find.byType(CcMenu), findsNothing);
  });

  testWidgets('the author moves an open pull request to draft', (tester) async {
    final repo = _RecordingRepo();
    await tester.pumpWidget(_app(_pr(), repo, login: 'tester'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Closed'), findsOneWidget);

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();
    // Nothing happens until the change is confirmed.
    expect(repo.calls, isEmpty);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['draft:true']);
  });

  testWidgets('choosing the current state does nothing', (tester) async {
    final repo = _RecordingRepo();
    await tester.pumpWidget(_app(_pr(), repo, login: 'tester'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open').last);
    await tester.pumpAndSettle();

    expect(find.text('Confirm'), findsNothing);
    expect(repo.calls, isEmpty);
  });

  testWidgets('a draft is marked ready, and can be closed', (tester) async {
    final repo = _RecordingRepo();
    await tester.pumpWidget(_app(_pr(isDraft: true), repo, login: 'tester'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['draft:false']);

    await tester.tap(find.text('Draft').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Closed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['draft:false', 'close']);
  });
}
