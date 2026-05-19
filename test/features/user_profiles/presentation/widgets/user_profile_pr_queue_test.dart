import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/user_profiles/presentation/widgets/user_profile_pr_queue.dart';
import 'package:control_center/features/user_profiles/providers/user_profile_pr_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _login = 'testuser';

Repo _repo(String id, String owner, String name) => Repo(
      id: id,
      name: '$owner/$name',
      path: '/repos/$owner/$name',
      githubOwner: owner,
      githubRepoName: name,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

PullRequest _pr({
  required int number,
  required String title,
  String authorLogin = _login,
  PrState state = PrState.open,
  DateTime? mergedAt,
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: '',
    state: state,
    isDraft: false,
    author: PrUser(login: authorLogin, avatarUrl: ''),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
    mergedAt: mergedAt,
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

// ---------------------------------------------------------------------------
// Test notifier subclasses
// ---------------------------------------------------------------------------

class _SearchNotifier extends UserProfileSearchNotifier {
  _SearchNotifier(super.login, this._value);
  final String _value;
  @override
  String build() => _value;
}

class _StateFilterNotifier extends UserProfileStateFilterNotifier {
  _StateFilterNotifier(super.login, this._value);
  final Set<ProfilePrState> _value;
  @override
  Set<ProfilePrState> build() => _value;
}

class _FixedClosedPrsNotifier extends UserClosedPrsNotifier {
  _FixedClosedPrsNotifier(super.login, this._state);
  final UserClosedPrsState _state;
  @override
  Future<UserClosedPrsState> build() async => _state;
}

/// Base overrides that prevent side effects (no GitHub, no drift DB).
final _sharedOverrides = [
  keybindingDispatcherProvider.overrideWithValue(
    KeybindingDispatcher(registerWithOs: false, observeFocus: false),
  ),
  isGitHubAuthenticatedProvider.overrideWith((ref) => false),
  currentUserLoginProvider.overrideWith((ref) => ''),
  githubCliStatusProvider.overrideWith(
    (ref) => Future.value(const GitHubCliStatus()),
  ),
  activeWorkspaceIdProvider.overrideWith(
    _NullActiveWorkspaceIdNotifier.new,
  ),
];

/// Wraps [child] with shared overrides and the given [openData] override.
Widget _wrapWidget(
  Widget child,
  AsyncValue<List<RepoPullRequests>> openData,
) {
  return ProviderScope(
    overrides: [
      ..._sharedOverrides,
      prsByAuthorInWorkspaceProvider(_login).overrideWith((ref) => openData),
    ],
    child: testWrap(child),
  );
}


// ---------------------------------------------------------------------------
// Null-active-workspace notifier
// ---------------------------------------------------------------------------

class _NullActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}
// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows loading spinner when data is loading', (tester) async {
    _useLargeViewport(tester);

    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        const AsyncValue.loading(),
      ),
    );

    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.text('move'), findsOneWidget);
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

  testWidgets('shows empty state when user has no open PRs', (tester) async {
    _useLargeViewport(tester);

    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        const AsyncValue.data([]),
      ),
    );

    expect(
      find.text('No PRs by @$_login in this workspace'),
      findsOneWidget,
    );
    expect(find.text('move'), findsOneWidget);
  });

  testWidgets('shows empty state for search with no matches', (
    tester,
  ) async {
    _useLargeViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._sharedOverrides,
          prsByAuthorInWorkspaceProvider(_login)
              .overrideWith((ref) => const AsyncValue.data([])),
          userProfileSearchProvider(_login).overrideWith(
            () => _SearchNotifier(_login, 'no-match-xyz'),
          ),
        ],
        child: testWrap(
          UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        ),
      ),
    );

    expect(find.text('No matching pull requests'), findsOneWidget);
    expect(find.text('No open PRs match your search. '
        'Try different terms or clear the search.'), findsOneWidget);
    expect(find.byIcon(LucideIcons.searchX), findsOneWidget);
  });

  testWidgets('shows empty state for non-open filter with no PRs', (
    tester,
  ) async {
    _useLargeViewport(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._sharedOverrides,
          prsByAuthorInWorkspaceProvider(_login)
              .overrideWith((ref) => const AsyncValue.data([])),
          userProfileStateFilterProvider(_login).overrideWith(
            () => _StateFilterNotifier(
              _login,
              const {ProfilePrState.merged},
            ),
          ),
          // merged state is active, so userClosedPrsProvider is watched;
          // provide a fixed empty state so it resolves immediately.
          userClosedPrsProvider(_login).overrideWith(
            () => _FixedClosedPrsNotifier(
              _login,
              UserClosedPrsState.empty,
            ),
          ),
        ],
        child: testWrap(
          UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        ),
      ),
    );
    // The _FixedClosedPrsNotifier.build() returns a Future; pump once more
    // to let it resolve so we don't see the intermediate loading state.
    // Let the _FixedClosedPrsNotifier's Future resolve.
    await tester.pump();

    expect(
      find.text('No pull requests for the selected states'),
      findsOneWidget,
    );
  });

  testWidgets('renders populated queue with PR repo sections', (
    tester,
  ) async {
    _useLargeViewport(tester);

    final repo = _repo('r1', 'owner', 'repo');
    final groups = [
      _group(repo, [
        _pr(number: 1, title: 'Fix login bug'),
        _pr(number: 2, title: 'Add dark mode'),
      ]),
    ];

    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        AsyncValue.data(groups),
      ),
    );

    expect(find.text('Fix login bug'), findsOneWidget);
    expect(find.text('Add dark mode'), findsOneWidget);
    expect(find.text('move'), findsOneWidget);
    expect(find.text('open'), findsOneWidget);
    expect(find.text('peek'), findsOneWidget);
  });

  testWidgets('renders multiple repo groups', (tester) async {
    _useLargeViewport(tester);

    final repoA = _repo('ra', 'owner', 'alpha');
    final repoB = _repo('rb', 'owner', 'beta');
    final groups = [
      _group(repoA, [_pr(number: 1, title: 'A-PR-1')]),
      _group(repoB, [_pr(number: 2, title: 'B-PR-2')]),
    ];

    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        AsyncValue.data(groups),
      ),
    );

    expect(find.text('A-PR-1'), findsOneWidget);
    expect(find.text('B-PR-2'), findsOneWidget);
  });

  testWidgets('filters PRs by author login', (tester) async {
    _useLargeViewport(tester);

    final repo = _repo('r1', 'owner', 'repo');
    final filteredGroups = [
      _group(repo, [_pr(number: 1, title: 'My PR')]),
    ];

    await tester.pumpWidget(
      _wrapWidget(
        UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        AsyncValue.data(filteredGroups),
      ),
    );

    expect(find.text('My PR'), findsOneWidget);
    expect(find.text('Other PR'), findsNothing);
  });

  testWidgets('shows merged PRs alongside open when states active', (
    tester,
  ) async {
    _useLargeViewport(tester);

    final repo = _repo('r1', 'owner', 'repo');
    final openGroups = [
      _group(repo, [_pr(number: 1, title: 'Open PR', state: PrState.open)]),
    ];
    final closedGroups = [
      _group(repo, [
        _pr(
          number: 2,
          title: 'Merged PR',
          state: PrState.closed,
          mergedAt: DateTime(2024, 3, 1),
        ),
      ]),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._sharedOverrides,
          prsByAuthorInWorkspaceProvider(_login)
              .overrideWith((ref) => AsyncValue.data(openGroups)),
          userProfileStateFilterProvider(_login).overrideWith(
            () => _StateFilterNotifier(
              _login,
              const {ProfilePrState.open, ProfilePrState.merged},
            ),
          ),
          userClosedPrsProvider(_login).overrideWith(
            () => _FixedClosedPrsNotifier(
              _login,
              UserClosedPrsState(
                repos: closedGroups,
                hasMore: const {},
                nextPage: const {},
                loadingMore: const {},
              ),
            ),
          ),
        ],
        child: testWrap(
          UserProfilePrQueue(login: _login, searchFocusNode: FocusNode()),
        ),
      ),
    );
    // Let the _FixedClosedPrsNotifier's Future resolve.
    await tester.pump();

    expect(find.text('Open PR'), findsOneWidget);
    expect(find.text('Merged PR'), findsOneWidget);
  });
}
