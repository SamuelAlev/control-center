import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_route_scope_sync_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the active workspace to a fixed id, bypassing prefs/bootstrap.
class _FixedWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'w1';
}

/// Active workspace id a test can flip, standing in for the workspace switch
/// (which is really a `go(inboxRoute(otherId))` navigation).
class _SwitchableWorkspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'w1';

  void switchTo(String id) => state = id;
}

Repo _repo(String owner, String name) => Repo(
  id: '$owner/$name',
  name: '$owner/$name',
  path: '/tmp/$name',
  githubOwner: owner,
  githubRepoName: name,
  createdAt: DateTime(2020),
  updatedAt: DateTime(2020),
);

Workspace _workspace(String id) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime(2020),
  updatedAt: DateTime(2020),
);

/// Records every `owner/repo#number` a PR-keyed read is issued against, so a
/// test can assert a read never reached the wrong repo.
class _RecordingFactory implements VcsProviderFactory {
  final List<String> calls = [];

  @override
  VcsHost get host => VcsHost.github;

  @override
  PrReviewRepository create(VcsProviderContext ctx) => _RecordingRepository(
    '${ctx.repo.githubOwner}/${ctx.repo.githubRepoName}',
    calls,
  );
}

class _RecordingRepository extends EmptyPrReviewRepository {
  _RecordingRepository(this._repoFullName, this._calls);

  final String _repoFullName;
  final List<String> _calls;

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) {
    _calls.add('$_repoFullName#$prNumber');
    return Stream.value(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prDetailScopeFromRoute', () {
    const prDetailPattern =
        '/workspaces/:workspaceId/pull-requests/:owner/:repo/:prNumber';

    test('extracts owner/repo on the PR-detail route', () {
      final scope = prDetailScopeFromRoute(prDetailPattern, const {
        'workspaceId': 'w1',
        'owner': 'octocat',
        'repo': 'hello',
        'prNumber': '42',
      });
      expect(scope, (owner: 'octocat', repo: 'hello'));
    });

    test('returns null on the PR list route (no owner/repo)', () {
      final scope = prDetailScopeFromRoute(
        '/workspaces/:workspaceId/pull-requests',
        const {'workspaceId': 'w1'},
      );
      expect(scope, isNull);
    });

    test('returns null on the compose route', () {
      final scope = prDetailScopeFromRoute(
        '/workspaces/:workspaceId/pull-requests/compose',
        const {'workspaceId': 'w1'},
      );
      expect(scope, isNull);
    });

    test('returns null for a null fullPath', () {
      expect(prDetailScopeFromRoute(null, const {}), isNull);
    });

    test('returns null when the pattern matches but a param is empty', () {
      final scope = prDetailScopeFromRoute(prDetailPattern, const {
        'workspaceId': 'w1',
        'owner': '',
        'repo': 'hello',
        'prNumber': '42',
      });
      expect(scope, isNull);
    });
  });

  group('currentPrRepoProvider follows the scope (PR→PR staleness fix)', () {
    test('re-resolves to a different repo when the scope changes', () async {
      final repoA = _repo('octocat', 'alpha');
      final repoB = _repo('octocat', 'beta');
      final container = ProviderContainer(
        overrides: [
          activeWorkspaceIdProvider.overrideWith(_FixedWorkspace.new),
          activeRepoProvider.overrideWithValue(null),
          reposForWorkspaceProvider(
            'w1',
          ).overrideWith((ref) => Stream.value([repoA, repoB])),
        ],
      );
      addTearDown(container.dispose);

      // Keep the (autoDispose) repo-list stream alive, then prime it so `.value`
      // is populated for the synchronous reads below.
      final keepAlive = container.listen(
        reposForWorkspaceProvider('w1'),
        (_, _) {},
      );
      addTearDown(keepAlive.close);
      await container.read(reposForWorkspaceProvider('w1').future);

      // Scope points at repo A (as the URL sync would set on that PR's route).
      container.read(prDetailRepoScopeProvider.notifier).set((
        owner: 'octocat',
        repo: 'alpha',
      ));
      expect(container.read(currentPrRepoProvider), repoA);

      // A PR→PR hop into repo B flips the scope; the resolved repo follows —
      // the exact behaviour the old initState pin got wrong on a reused State.
      container.read(prDetailRepoScopeProvider.notifier).set((
        owner: 'octocat',
        repo: 'beta',
      ));
      expect(container.read(currentPrRepoProvider), repoB);

      // Leaving the PR detail (scope null) falls back to the active repo.
      container.read(prDetailRepoScopeProvider.notifier).set(null);
      expect(container.read(currentPrRepoProvider), isNull);
    });
  });

  group('PR-keyed reads never fall back to another repo', () {
    /// Reproduces the workspace-switch leak: open a PR,
    /// then switch to a workspace whose active repo is `SamuelAlev/control-center`.
    /// Switching navigates to the new workspace's inbox, which clears the
    /// PR-detail scope a microtask BEFORE the detail screen is torn down — so
    /// the still-mounted, number-keyed streams re-resolved their repository. An
    /// active-repo fallback made them re-subscribe on the new workspace's repo
    /// and fetch `SamuelAlev/control-center#15868` (a 404).
    test(
      'a workspace switch does not re-subscribe on the new active repo',
      () async {
        final usectrl = _repo('UseCtrl', 'test');
        final control = _repo('SamuelAlev', 'control-center');
        final factory = _RecordingFactory();
        final container = ProviderContainer(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(_SwitchableWorkspace.new),
            activeWorkspaceProvider.overrideWith(
              (ref) => _workspace(ref.watch(activeWorkspaceIdProvider)!),
            ),
            // The workspace switch also re-homes the active repo.
            activeRepoProvider.overrideWith(
              (ref) => ref.watch(activeWorkspaceIdProvider) == 'w2'
                  ? control
                  : usectrl,
            ),
            reposForWorkspaceProvider(
              'w1',
            ).overrideWith((ref) => Stream.value([usectrl])),
            reposForWorkspaceProvider(
              'w2',
            ).overrideWith((ref) => Stream.value([control])),
            vcsProviderRegistryProvider.overrideWithValue(
              VcsProviderRegistry([factory]),
            ),
          ],
        );
        addTearDown(container.dispose);

        for (final id in ['w1', 'w2']) {
          final keepAlive = container.listen(
            reposForWorkspaceProvider(id),
            (_, _) {},
          );
          addTearDown(keepAlive.close);
          await container.read(reposForWorkspaceProvider(id).future);
        }

        // On the PR's own route the pinned repo serves the read.
        container.read(prDetailRepoScopeProvider.notifier).set((
          owner: 'UseCtrl',
          repo: 'test',
        ));
        final prSub = container.listen(prDetailProvider(15868), (_, _) {});
        addTearDown(prSub.close);
        await container.read(prDetailProvider(15868).future);
        expect(factory.calls, ['UseCtrl/test#15868']);

        // The switch: active workspace + repo flip while the scope is still
        // pinned to a repo that isn't linked to the new workspace.
        (container.read(activeWorkspaceIdProvider.notifier)
                as _SwitchableWorkspace)
            .switchTo('w2');
        expect(container.read(prDetailRepoProvider), isNull);
        expect(container.read(prScopedReviewRepositoryProvider), isNull);

        // …and then the route-driven sync clears the scope. The repo-level
        // provider falls back to the new active repo (compose needs that), but
        // the PR-keyed stream must NOT: it stays pending and issues no read.
        container.read(prDetailRepoScopeProvider.notifier).set(null);
        expect(container.read(currentPrRepoProvider), control);
        expect(container.read(prScopedReviewRepositoryProvider), isNull);
        expect(container.read(prDetailProvider(15868)).isLoading, isTrue);
        expect(factory.calls, ['UseCtrl/test#15868']);
      },
    );
  });
}
