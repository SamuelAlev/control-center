import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// The PR page used to wait on its detail stream before painting anything, so a
/// cold cache meant a forge round trip with a skeleton on screen — even though
/// the row the operator had just clicked was already in memory. Seeding the
/// chrome from that row removes the wait; matching the row correctly is the
/// whole risk, because a PR number is unique only inside its repo.
PullRequest _pr(int number, String repoFullName, {String title = 't'}) =>
    PullRequest(
      id: number,
      number: number,
      title: title,
      body: '',
      state: PrState.open,
      isDraft: false,
      author: null,
      createdAt: null,
      updatedAt: null,
      repoFullName: repoFullName,
      htmlUrl: '',
    );

Repo _repo(String owner, String name) => Repo(
  id: '$owner-$name',
  name: name,
  path: '/tmp/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  group('findSeedPullRequest', () {
    final groups = [
      RepoPullRequests(
        repo: _repo('acme', 'web'),
        prs: [_pr(42, 'acme/web', title: 'the right one'), _pr(7, 'acme/web')],
      ),
      RepoPullRequests(
        repo: _repo('acme', 'api'),
        prs: [_pr(42, 'acme/api', title: 'the sibling repo')],
      ),
    ];

    test('finds the row for the pinned repo', () {
      final found = findSeedPullRequest(
        groups,
        repoFullName: 'acme/web',
        prNumber: 42,
      );
      expect(found?.title, 'the right one');
    });

    test('never returns a same-numbered PR from another repo', () {
      // The failure this guards: a workspace routinely links several repos and
      // #42 exists in most of them. Matching on number alone would open the
      // page with another PR's title, author and branches, then swap the lot
      // when the real detail landed.
      final found = findSeedPullRequest(
        groups,
        repoFullName: 'acme/api',
        prNumber: 42,
      );
      expect(found?.title, 'the sibling repo');
    });

    test('a repo not in the snapshot seeds nothing', () {
      expect(
        findSeedPullRequest(
          groups,
          repoFullName: 'acme/mobile',
          prNumber: 42,
        ),
        isNull,
      );
    });

    test('a number not in the snapshot seeds nothing', () {
      // Deep-linked, or simply not an open PR — the page falls back to its
      // loading body rather than showing something adjacent.
      expect(
        findSeedPullRequest(groups, repoFullName: 'acme/web', prNumber: 999),
        isNull,
      );
    });

    test('the repo match is case-insensitive', () {
      // Route params and forge payloads disagree on case often enough that an
      // exact match would silently disable seeding for some repos.
      expect(
        findSeedPullRequest(
          groups,
          repoFullName: 'ACME/Web',
          prNumber: 42,
        )?.title,
        'the right one',
      );
    });
  });
}
