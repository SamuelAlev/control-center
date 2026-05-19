import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_server_core/src/pr_review/multi_forge_open_pr_fetch.dart';
import 'package:cc_server_core/src/pr_review/open_pr_polling_service.dart';
import 'package:test/test.dart';

Repo _repo(String id, ForgeHost forge, {String owner = 'acme'}) => Repo(
  id: id,
  name: '$owner/$id',
  path: '/tmp/$id',
  forge: forge,
  remoteOwner: owner,
  remoteName: id,
  createdAt: DateTime.utc(2025),
  updatedAt: DateTime.utc(2025),
);

PullRequest _pr(int number, String repoFullName) => PullRequest(
  id: number,
  number: number,
  title: 'PR $number',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: const PrUser(login: 'me', avatarUrl: ''),
  createdAt: DateTime.utc(2025),
  updatedAt: DateTime.utc(2025),
  repoFullName: repoFullName,
  htmlUrl: '',
);

/// A per-forge delegate that answers for the repos it is given, or blows up.
class _FakePort implements OpenPrFetchPort {
  _FakePort({this.fail = false, this.prNumbersByRepoId = const {}});

  final bool fail;
  final Map<String, List<int>> prNumbersByRepoId;
  int fetchCalls = 0;

  @override
  Future<({bool changed, String? etag})> probeRepo(Repo repo, String? etag) =>
      Future.value((changed: true, etag: null));

  @override
  Future<OpenPrFetchResult> fetchGroups(List<Repo> repos) async {
    fetchCalls++;
    if (fail) {
      throw StateError('forge is down');
    }
    final groups = <OpenPrGroup>[];
    final resolved = <String>{};
    for (final repo in repos) {
      resolved.add(repo.id);
      final numbers = prNumbersByRepoId[repo.id] ?? const <int>[];
      if (numbers.isNotEmpty) {
        groups.add((
          repo: repo,
          prs: [for (final n in numbers) _pr(n, repo.fullName)],
          hasMore: false,
        ));
      }
    }
    return (groups: groups, resolvedRepoIds: resolved);
  }

  @override
  Future<Map<String, Map<int, PrStatusOverlay>>> fetchChecks(
    List<Repo> repos,
  ) async {
    if (fail) {
      throw StateError('forge is down');
    }
    return {
      for (final r in repos)
        r.id: {1: (checksRollup: 'SUCCESS', reviewDecision: null)},
    };
  }

  @override
  Future<bool?> wasMerged(Repo repo, int prNumber) async =>
      fail ? null : true;

  @override
  Future<PrMergeableState> mergeState(Repo repo, int prNumber) async =>
      PrMergeableState.clean;

  @override
  Future<String?> latestApprover(Repo repo, int prNumber) async => 'octocat';

  @override
  Future<({String name, String? url})?> firstFailingCheck(
    Repo repo,
    int prNumber,
  ) async => (name: 'build', url: 'https://ci.example/1');
}

void main() {
  group('MultiForgeOpenPrFetchAdapter', () {
    test('merges groups from every forge into one snapshot', () async {
      final gh = _repo('web', ForgeHost.github);
      final gl = _repo('api', ForgeHost.gitlab);
      final bb = _repo('docs', ForgeHost.bitbucket);

      final adapter = MultiForgeOpenPrFetchAdapter({
        ForgeHost.github: _FakePort(prNumbersByRepoId: {'web': [1, 2]}),
        ForgeHost.gitlab: _FakePort(prNumbersByRepoId: {'api': [7]}),
        ForgeHost.bitbucket: _FakePort(prNumbersByRepoId: {'docs': [9]}),
      });

      final result = await adapter.fetchGroups([gh, gl, bb]);

      expect(result.resolvedRepoIds, {'web', 'api', 'docs'});
      expect(
        result.groups.map((g) => g.repo.id).toSet(),
        {'web', 'api', 'docs'},
      );
      expect(
        result.groups.expand((g) => g.prs).map((p) => p.number).toSet(),
        {1, 2, 7, 9},
      );
    });

    test('each forge is asked only about its own repos', () async {
      final github = _FakePort(prNumbersByRepoId: {'web': [1]});
      final gitlab = _FakePort(prNumbersByRepoId: {'api': [7]});
      final adapter = MultiForgeOpenPrFetchAdapter({
        ForgeHost.github: github,
        ForgeHost.gitlab: gitlab,
      });

      await adapter.fetchGroups([
        _repo('web', ForgeHost.github),
        _repo('api', ForgeHost.gitlab),
      ]);

      expect(github.fetchCalls, 1);
      expect(gitlab.fetchCalls, 1);
    });

    test('one forge failing leaves the others intact', () async {
      // The load-bearing guarantee: a Bitbucket outage must not empty the
      // GitHub half of the inbox. The failing forge contributes no resolved
      // repo ids either, which is what tells the poller to keep its previous
      // entries for those repos rather than publish "merged/closed" for each.
      final adapter = MultiForgeOpenPrFetchAdapter({
        ForgeHost.github: _FakePort(prNumbersByRepoId: {'web': [1]}),
        ForgeHost.bitbucket: _FakePort(fail: true),
      });

      final result = await adapter.fetchGroups([
        _repo('web', ForgeHost.github),
        _repo('docs', ForgeHost.bitbucket),
      ]);

      expect(result.resolvedRepoIds, {'web'});
      expect(result.groups.single.repo.id, 'web');
    });

    test('a repo on an unregistered forge is skipped, not guessed', () async {
      final adapter = MultiForgeOpenPrFetchAdapter({
        ForgeHost.github: _FakePort(prNumbersByRepoId: {'web': [1]}),
      });

      final result = await adapter.fetchGroups([
        _repo('web', ForgeHost.github),
        _repo('api', ForgeHost.gitlab),
      ]);

      // GitLab has no adapter (no credential), so its repo is absent from the
      // resolved set — never routed to GitHub's client by accident.
      expect(result.resolvedRepoIds, {'web'});
    });

    test('probe and wasMerged route to the repo’s own forge', () async {
      final adapter = MultiForgeOpenPrFetchAdapter({
        ForgeHost.github: _FakePort(),
        ForgeHost.bitbucket: _FakePort(fail: true),
      });

      expect(
        (await adapter.probeRepo(_repo('web', ForgeHost.github), null)).changed,
        isTrue,
      );
      expect(await adapter.wasMerged(_repo('web', ForgeHost.github), 1), isTrue);
      // An unregistered forge answers "unknown", never "closed".
      expect(await adapter.wasMerged(_repo('x', ForgeHost.gitlab), 1), isNull);
    });

    test('an unregistered forge reports no change rather than churning',
        () async {
      final adapter = MultiForgeOpenPrFetchAdapter({
        ForgeHost.github: _FakePort(),
      });
      final probe = await adapter.probeRepo(_repo('x', ForgeHost.gitlab), null);
      expect(probe.changed, isFalse);
    });

    test('checks overlays merge across forges and survive one failing',
        () async {
      final adapter = MultiForgeOpenPrFetchAdapter({
        ForgeHost.github: _FakePort(),
        ForgeHost.gitlab: _FakePort(fail: true),
      });

      final overlays = await adapter.fetchChecks([
        _repo('web', ForgeHost.github),
        _repo('api', ForgeHost.gitlab),
      ]);

      expect(overlays.keys, ['web']);
    });
  });

  group('compareByMergedAtDesc', () {
    PullRequest merged(int n, DateTime? at) => PullRequest(
      id: n,
      number: n,
      title: 'PR $n',
      body: '',
      state: PrState.merged,
      isDraft: false,
      author: null,
      createdAt: null,
      updatedAt: null,
      repoFullName: 'o/r',
      htmlUrl: '',
      mergedAt: at,
    );

    test('orders newest first across forges', () {
      final list = [
        merged(1, DateTime.utc(2025)),
        merged(2, DateTime.utc(2025, 6)),
        merged(3, DateTime.utc(2025, 3)),
      ]..sort(compareByMergedAtDesc);
      expect(list.map((p) => p.number), [2, 3, 1]);
    });

    test('a forge that omits the timestamp sorts last, never first', () {
      final list = [
        merged(1, null),
        merged(2, DateTime.utc(2025)),
      ]..sort(compareByMergedAtDesc);
      expect(list.map((p) => p.number), [2, 1]);
    });
  });
}
