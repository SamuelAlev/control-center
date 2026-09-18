import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/github_profile_pr_queue.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../../helpers/test_wrap.dart';

const _login = 'testuser';
const _profileKey = 'user:testuser';

Repo _repo(String id, String owner, String name) => Repo(
  id: id,
  name: '$owner/$name',
  path: '/repos/$owner/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

PullRequest _pr({
  required int number,
  required String title,
  PrState state = PrState.open,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: '',
    state: state,
    isDraft: false,
    author: const PrUser(login: _login, avatarUrl: ''),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
  );
}

GitHubProfileActivity _activity(
  List<({Repo repo, List<PullRequest> prs})> groups,
) {
  final prs = [for (final group in groups) ...group.prs];
  return GitHubProfileActivity(
    metrics: GitHubProfileMetrics(
      open: prs.where((pr) => pr.state == PrState.open).length,
      draft: 0,
      merged: prs.where((pr) => pr.state == PrState.merged).length,
      closed: prs.where((pr) => pr.state == PrState.closed).length,
      analyzedPullRequests: prs.length,
      resultsTruncated: false,
    ),
    repos: [
      for (final group in groups)
        GitHubProfileRepoPullRequests(repoId: group.repo.id, prs: group.prs),
    ],
  );
}

void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.resetPhysicalSize());
  addTearDown(() => tester.view.resetDevicePixelRatio());
}

class _SearchNotifier extends UserProfileSearchNotifier {
  _SearchNotifier(super.login, this._value);
  final String _value;

  @override
  String build() => _value;
}

class _ActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

final _sharedOverrides = [
  keybindingDispatcherProvider.overrideWithValue(
    KeybindingDispatcher(observeFocus: false, listenToHardwareKeyboard: false),
  ),
  activeWorkspaceIdProvider.overrideWith(_ActiveWorkspaceIdNotifier.new),
];

Widget _wrapWidget(
  Widget child,
  List<Repo> repos, {
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [
      ..._sharedOverrides,
      reposForWorkspaceProvider(
        'ws-1',
      ).overrideWith((ref) => Stream.value(repos)),
      ...extra,
    ],
    child: testWrap(child),
  );
}

Widget _queue(AsyncValue<GitHubProfileActivity> activity) =>
    GitHubProfilePrQueue(
      profileKey: _profileKey,
      activity: activity,
      emptyMessage: 'No PRs by @$_login in this workspace',
      searchFocusNode: FocusNode(),
    );

void main() {
  testWidgets('shows loading spinner when data is loading', (tester) async {
    _useLargeViewport(tester);
    await tester.pumpWidget(
      _wrapWidget(_queue(const AsyncValue.loading()), const []),
    );
    expect(find.byType(CcSpinner), findsOneWidget);
  });

  testWidgets('shows error state when data fails to load', (tester) async {
    _useLargeViewport(tester);
    await tester.pumpWidget(
      _wrapWidget(
        _queue(AsyncValue.error(Exception('Network error'), StackTrace.empty)),
        const [],
      ),
    );
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Exception: Network error'), findsOneWidget);
    expect(find.byType(CcAlert), findsOneWidget);
  });

  testWidgets('shows empty state when the profile has no PRs', (tester) async {
    _useLargeViewport(tester);
    await tester.pumpWidget(
      _wrapWidget(
        _queue(AsyncValue.data(GitHubProfileActivity.empty)),
        const [],
      ),
    );
    await tester.pump();
    expect(find.text('No PRs by @$_login in this workspace'), findsOneWidget);
  });

  testWidgets('shows the search empty state when nothing matches', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repo = _repo('r1', 'owner', 'repo');
    await tester.pumpWidget(
      _wrapWidget(
        _queue(
          AsyncValue.data(
            _activity([
              (repo: repo, prs: [_pr(number: 1, title: 'Fix login bug')]),
            ]),
          ),
        ),
        [repo],
        extra: [
          userProfileSearchProvider(
            _profileKey,
          ).overrideWith(() => _SearchNotifier(_profileKey, 'zzz-no-match')),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('No matching pull requests'), findsOneWidget);
    expect(
      find.text('Try another title or pull request number'),
      findsOneWidget,
    );
  });

  testWidgets('browses open, merged and closed pull requests by state', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repo = _repo('r1', 'owner', 'repo');
    await tester.pumpWidget(
      _wrapWidget(
        _queue(
          AsyncValue.data(
            _activity([
              (
                repo: repo,
                prs: [
                  _pr(number: 1, title: 'Open change'),
                  _pr(number: 2, title: 'Merged change', state: PrState.merged),
                  _pr(number: 3, title: 'Closed change', state: PrState.closed),
                ],
              ),
            ]),
          ),
        ),
        [repo],
      ),
    );
    await tester.pump();

    expect(find.text('Open change'), findsOneWidget);
    expect(find.text('Merged change'), findsOneWidget);
    expect(find.text('Closed change'), findsOneWidget);

    await tester.tap(find.text('Merged 1'));
    await tester.pumpAndSettle();
    expect(find.text('Open change'), findsNothing);
    expect(find.text('Merged change'), findsOneWidget);
    expect(find.text('Closed change'), findsNothing);
  });
}
