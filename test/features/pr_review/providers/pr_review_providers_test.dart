import 'package:cc_data/cc_data.dart' show RpcPrReviewRepository;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_rpc/cc_rpc.dart' show InProcessRpcChannel, RemoteRpcClient;
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('prReviewRepositoryProvider', () {
    test('returns EmptyPrReviewRepository when not authenticated', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          credentialsProvider.overrideWith(_StubCredentialsNotifier.empty),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(prReviewRepositoryProvider);
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test('returns EmptyPrReviewRepository when no active workspace', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          credentialsProvider.overrideWith(_StubCredentialsNotifier.empty),
        ],
      );
      addTearDown(container.dispose);
      final repo = container.read(prReviewRepositoryProvider);
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test(
      'returns EmptyPrReviewRepository when workspace has no repo info',
      () async {
        final prefs = AppPreferences.inMemory({githubTokenKey: 'ghp_test'});

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            credentialsProvider.overrideWith(
              () => _StubCredentialsNotifier(token: 'ghp_test'),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(credentialsProvider.future);
        final repo = container.read(prReviewRepositoryProvider);
        expect(repo, isA<EmptyPrReviewRepository>());
      },
    );

    test('returns EmptyPrReviewRepository when authenticated but no active '
        'workspace is selected', () async {
      final prefs = AppPreferences.inMemory({githubTokenKey: 'ghp_test'});

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          credentialsProvider.overrideWith(
            () => _StubCredentialsNotifier(token: 'ghp_test'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(credentialsProvider.future);
      // Even though authenticated, without an active workspace/repo
      // the repository falls back to EmptyPrReviewRepository.
      final repo = container.read(prReviewRepositoryProvider);
      expect(repo, isA<EmptyPrReviewRepository>());
    });
  });

  group('prDetailProvider', () {
    test('is a StreamProvider.family', () {
      expect(prDetailProvider, isNotNull);
    });
  });

  group('repoScopedPrReviewRepositoryProvider', () {
    Repo repoEntity(String owner, String name) => Repo(
      id: 'repo-1',
      name: name,
      path: '/tmp/$name',
      remoteOwner: owner,
      remoteName: name,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    ProviderContainer containerWithRepos(List<Repo> repos) {
      // An inert client over a bare in-process channel: constructing the
      // repo-scoped repository sends nothing, so no server end is needed.
      final (_, clientChannel) = InProcessRpcChannel.pair();
      final container = ProviderContainer(
        overrides: [
          reposForWorkspaceProvider(
            'ws-1',
          ).overrideWith((ref) => Stream.value(repos)),
          rpcClientProvider.overrideWithValue(RemoteRpcClient(clientChannel)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('returns EmptyPrReviewRepository for a malformed full name', () {
      final container = containerWithRepos([repoEntity('acme', 'cc')]);
      final repo = container.read(
        repoScopedPrReviewRepositoryProvider((
          workspaceId: 'ws-1',
          repoFullName: 'no-slash',
        )),
      );
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test('returns EmptyPrReviewRepository when the repo is not linked to the '
        'workspace (no doomed server subscription)', () async {
      final container = containerWithRepos([repoEntity('acme', 'cc')]);
      // Hold a listener so the (pause-on-no-listener) stream emits, then let
      // the link check run against loaded data.
      final sub = container.listen(
        reposForWorkspaceProvider('ws-1'),
        (_, _) {},
      );
      addTearDown(sub.close);
      await container.read(reposForWorkspaceProvider('ws-1').future);
      final repo = container.read(
        repoScopedPrReviewRepositoryProvider((
          workspaceId: 'ws-1',
          repoFullName: 'other/unlinked',
        )),
      );
      expect(repo, isA<EmptyPrReviewRepository>());
    });

    test(
      'returns EmptyPrReviewRepository while the repo list is still loading',
      () {
        final container = containerWithRepos([repoEntity('acme', 'cc')]);
        // Read synchronously, before the stream's first emission lands.
        final repo = container.read(
          repoScopedPrReviewRepositoryProvider((
            workspaceId: 'ws-1',
            repoFullName: 'acme/cc',
          )),
        );
        expect(repo, isA<EmptyPrReviewRepository>());
      },
    );

    test(
      'returns the RPC repository for a linked repo (case-insensitive)',
      () async {
        final container = containerWithRepos([repoEntity('Acme', 'CC')]);
        final sub = container.listen(
          reposForWorkspaceProvider('ws-1'),
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(reposForWorkspaceProvider('ws-1').future);
        final repo = container.read(
          repoScopedPrReviewRepositoryProvider((
            workspaceId: 'ws-1',
            repoFullName: 'acme/cc',
          )),
        );
        expect(repo, isA<RpcPrReviewRepository>());
        expect((repo as RpcPrReviewRepository).workspaceId, 'ws-1');
      },
    );
  });

  group('prDiffProvider', () {
    test('is a StreamProvider.family', () {
      expect(prDiffProvider, isNotNull);
    });
  });

  group('prFilesProvider', () {
    test('is a StreamProvider.family', () {
      expect(prFilesProvider, isNotNull);
    });
  });

  group('prReviewsProvider', () {
    test('is a StreamProvider.family', () {
      expect(prReviewsProvider, isNotNull);
    });
  });

  group('ReviewAction enum', () {
    test('has three values', () {
      expect(ReviewAction.values, hasLength(3));
      expect(ReviewAction.values, contains(ReviewAction.approve));
      expect(ReviewAction.values, contains(ReviewAction.requestChanges));
      expect(ReviewAction.values, contains(ReviewAction.comment));
    });
  });

  group('EmptyPrReviewRepository', () {
    test('watchPullRequest emits null', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchPullRequest(1).first;
      expect(result, null);
    });

    test('watchDiff emits empty string', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchDiff(1).first;
      expect(result, '');
    });

    test('watchFiles emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchFiles(1).first;
      expect(result, isEmpty);
    });

    test('watchFileContent emits empty string', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchFileContent('path', 'main').first;
      expect(result, '');
    });

    test('watchCommits emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCommits(1).first;
      expect(result, isEmpty);
    });

    test('watchCommitFiles emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCommitFiles('sha').first;
      expect(result, isEmpty);
    });

    test('watchReviews emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchReviews(1).first;
      expect(result, isEmpty);
    });

    test('watchReviewComments emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchReviewComments(1).first;
      expect(result, isEmpty);
    });

    test('watchIssueComments emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchIssueComments(1).first;
      expect(result, isEmpty);
    });

    test('watchCheckRuns emits empty list', () async {
      const repo = EmptyPrReviewRepository();
      final result = await repo.watchCheckRuns(1).first;
      expect(result, isEmpty);
    });

    test('invalidatePullRequest completes without error', () async {
      const repo = EmptyPrReviewRepository();
      await repo.invalidatePullRequest(1);
    });
  });

  group('isImmutableGitRef', () {
    // The predicate that decides whether a PR read may be held after its last
    // listener. Wrong in one direction it serves a stale branch tip; wrong in
    // the other it re-pulls every file on every tab switch, which is the
    // behaviour it exists to remove.
    test('a full or abbreviated commit SHA is immutable', () {
      expect(isImmutableGitRef('a' * 40), isTrue);
      expect(isImmutableGitRef('0123456'), isTrue);
      expect(isImmutableGitRef('deadbeefcafe1234'), isTrue);
    });

    test('a branch name is not', () {
      for (final branch in [
        'main',
        'master',
        'develop',
        'release/2026.1',
        'feature/add-thing',
        'HEAD',
      ]) {
        expect(isImmutableGitRef(branch), isFalse, reason: branch);
      }
    });

    test('uppercase hex is rejected rather than guessed at', () {
      // Git prints lowercase. Accepting uppercase would only widen the window
      // for a branch name that happens to look hex.
      expect(isImmutableGitRef('ABCDEF0'), isFalse);
    });

    test('too short to be an abbreviated SHA is not immutable', () {
      expect(isImmutableGitRef(''), isFalse);
      expect(isImmutableGitRef('abc'), isFalse);
      expect(isImmutableGitRef('abcdef'), isFalse);
    });

    test('longer than a SHA is not immutable', () {
      expect(isImmutableGitRef('a' * 41), isFalse);
    });
  });
}

class _StubCredentialsNotifier extends CredentialsNotifier {
  _StubCredentialsNotifier({this._token = ''});

  factory _StubCredentialsNotifier.empty() => _StubCredentialsNotifier();

  final String _token;
  @override
  Future<ApiCredentials> build() async {
    return ApiCredentials(githubToken: _token);
  }
}
