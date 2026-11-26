import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_domain/features/pr_review/domain/entities/github_profile_activity.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:control_center/core/notifications/live_notification_lane.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart'
    show currentUserIdProvider;
import 'package:control_center/features/inbox/providers/inbox_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeOpenPrListRepository implements OpenPrListRepository {
  List<RepoOpenPrs> mergedResponse = const [];
  int closedByAuthorCalls = 0;

  @override
  Future<List<RepoOpenPrs>> closedByAuthorForWorkspace(
    String workspaceId,
  ) async {
    closedByAuthorCalls++;
    return mergedResponse;
  }

  @override
  Future<WorkspaceOpenPrs> listOpenForWorkspace(String workspaceId) =>
      throw UnimplementedError();

  @override
  Stream<WorkspaceOpenPrs> watchOpenForWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<void> refreshOpenForWorkspace(String workspaceId) async {}

  @override
  Stream<NeedsMyReviewCount> watchNeedsMyReviewCount(String workspaceId) =>
      const Stream.empty();

  @override
  Stream<List<RepoAccessIssue>> watchRepoAccessForWorkspace(
    String workspaceId,
  ) => const Stream.empty();

  @override
  Future<List<({String repoId, PullRequest pr})>> reviewRequestedForWorkspace(
    String workspaceId,
  ) async => const [];

  @override
  Future<Set<String>> reviewedByKeysForWorkspace(String workspaceId) async =>
      const {};

  @override
  Future<GitHubProfileActivity> profileActivityForUser(
    String workspaceId,
    String login, {
    bool force = false,
  }) => throw UnimplementedError();

  @override
  Future<GitHubProfileActivity> profileActivityForTeam(
    String workspaceId,
    String organization,
    String slug, {
    bool force = false,
  }) => throw UnimplementedError();
}

class _FixedActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws1';
}

void main() {
  test('recentlyMergedPrsProvider refreshes when prMerged notification arrives', () async {
    final repo = Repo(
      id: 'r1',
      name: 'o/r1',
      path: '/tmp/r1',
      forge: ForgeHost.github,
      remoteOwner: 'o',
      remoteName: 'r1',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final fakeRepo = _FakeOpenPrListRepository();
    final container = ProviderContainer(
      overrides: [
        activeWorkspaceIdProvider.overrideWith(_FixedActiveWorkspaceId.new),
        currentUserIdProvider.overrideWithValue('u1'),
        hasAnyForgeConnectedProvider.overrideWithValue(true),
        reposForWorkspaceProvider('ws1').overrideWith((_) => Stream.value([repo])),
        openPrListRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(recentlyMergedPrsProvider, (_, _) {});
    addTearDown(sub.close);

    final initial = await container.read(recentlyMergedPrsProvider.future);
    expect(initial, isEmpty);
    // Let the repos StreamProvider emit and settle the initial rebuild before
    // firing the live merge notification.
    await Future<void>.delayed(Duration.zero);
    await container.read(recentlyMergedPrsProvider.future);
    final callsBefore = fakeRepo.closedByAuthorCalls;

    // A PR merges and its live notification arrives: recentlyMergedPrsProvider
    // should immediately refetch without requiring a manual refresh.
    fakeRepo.mergedResponse = [
      RepoOpenPrs(
        repoId: 'r1',
        hasMore: false,
        prs: [
          PullRequest(
            id: 42,
            number: 42,
            title: 'Merged PR',
            body: '',
            state: PrState.merged,
            isDraft: false,
            author: const PrUser(login: 'me', avatarUrl: ''),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            mergedAt: DateTime.utc(2026, 11, 25),
            repoFullName: 'o/r1',
            htmlUrl: '',
          ),
        ],
      ),
    ];

    container.read(liveNotificationLaneProvider).add(
      const AppNotification(
        category: NotificationCategory.prMerged,
        title: 'PR merged',
        body: 'Merged PR',
        route: '/ws/ws1/inbox',
        workspaceId: 'ws1',
      ),
    );

    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(fakeRepo.closedByAuthorCalls, callsBefore + 1);
    final updated = container.read(recentlyMergedPrsProvider).value;
    expect(updated, hasLength(1));
    expect(updated!.single.prs.single.number, 42);
  });
}
