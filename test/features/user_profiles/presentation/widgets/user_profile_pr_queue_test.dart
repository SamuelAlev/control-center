import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_pr_queue.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../../helpers/test_wrap.dart';

const _login = 'testuser';

Repo _repo(String id, String owner, String name) => Repo(
  id: id,
  name: '$owner/$name',
  path: '/repos/$owner/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

PullRequest _pr({required int number, required String title}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: '',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: _login, avatarUrl: ''),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
  );
}

RepoPullRequests _group(Repo repo, List<PullRequest> prs) =>
    RepoPullRequests(repo: repo, prs: prs);

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

class _NullActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

/// Base overrides that prevent side effects (no GitHub, no drift DB).
final _sharedOverrides = [
  keybindingDispatcherProvider.overrideWithValue(
    KeybindingDispatcher(observeFocus: false, listenToHardwareKeyboard: false),
  ),
  currentUserLoginProvider.overrideWith((ref) => ''),
  activeWorkspaceIdProvider.overrideWith(_NullActiveWorkspaceIdNotifier.new),
];

Widget _wrapWidget(
  Widget child,
  AsyncValue<List<RepoPullRequests>> openData, {
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [
      ..._sharedOverrides,
      prsByAuthorInWorkspaceProvider(_login).overrideWith((ref) => openData),
      ...extra,
    ],
    child: testWrap(child),
  );
}

void main() {
  testWidgets('shows loading spinner when data is loading', (tester) async {
    _useLargeViewport(tester);
    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        const AsyncValue.loading(),
      ),
    );
    expect(find.byType(CcSpinner), findsOneWidget);
  });

  testWidgets('shows error state when data fails to load', (tester) async {
    _useLargeViewport(tester);
    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        AsyncValue.error(Exception('Network error'), StackTrace.empty),
      ),
    );
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Exception: Network error'), findsOneWidget);
    expect(find.byType(CcAlert), findsOneWidget);
  });

  testWidgets('shows empty state when the user has no open PRs', (
    tester,
  ) async {
    _useLargeViewport(tester);
    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        const AsyncValue.data([]),
      ),
    );
    expect(find.text('No PRs by @$_login in this workspace'), findsOneWidget);
  });

  testWidgets('shows the search empty state when nothing matches', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repo = _repo('r1', 'owner', 'repo');
    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        AsyncValue.data([
          _group(repo, [_pr(number: 1, title: 'Fix login bug')]),
        ]),
        extra: [
          userProfileSearchProvider(
            _login,
          ).overrideWith(() => _SearchNotifier(_login, 'zzz-no-match')),
        ],
      ),
    );
    expect(find.text('No matching pull requests'), findsOneWidget);
  });

  testWidgets('renders the selected repo\'s PRs', (tester) async {
    _useLargeViewport(tester);
    final repo = _repo('r1', 'owner', 'repo');
    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        AsyncValue.data([
          _group(repo, [
            _pr(number: 1, title: 'Fix login bug'),
            _pr(number: 2, title: 'Add dark mode'),
          ]),
        ]),
      ),
    );
    expect(find.text('owner/repo'), findsOneWidget); // rail entry
    expect(find.text('Fix login bug'), findsOneWidget);
    expect(find.text('Add dark mode'), findsOneWidget);
  });

  testWidgets('lists every repo in the rail but details only the first', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repoA = _repo('ra', 'owner', 'alpha');
    final repoB = _repo('rb', 'owner', 'beta');
    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        AsyncValue.data([
          _group(repoA, [_pr(number: 1, title: 'A-PR-1')]),
          _group(repoB, [_pr(number: 2, title: 'B-PR-2')]),
        ]),
      ),
    );
    // Both repos in the rail…
    expect(find.text('owner/alpha'), findsOneWidget);
    expect(find.text('owner/beta'), findsOneWidget);
    // …but only the preselected first repo's PR is rendered in the detail.
    expect(find.text('A-PR-1'), findsOneWidget);
    expect(find.text('B-PR-2'), findsNothing);
  });
}
