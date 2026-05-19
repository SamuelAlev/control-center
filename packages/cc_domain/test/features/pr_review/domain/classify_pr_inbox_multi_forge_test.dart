import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_pr_inbox_use_case.dart';
import 'package:test/test.dart';

/// The inbox is the surface where mixing forges is most visible: one operator,
/// one list, several accounts. These tests pin the rule that makes it work —
/// "is this mine?" is asked of the forge the repo lives on, never of one global
/// login.
void main() {
  Repo repo(String id, ForgeHost forge) => Repo(
    id: id,
    name: 'acme/$id',
    path: '/tmp/$id',
    forge: forge,
    remoteOwner: 'acme',
    remoteName: id,
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2025),
  );

  PullRequest pr(
    int number,
    String repoFullName, {
    required String authorLogin,
    List<String> requestedReviewers = const [],
    PrState state = PrState.open,
    DateTime? mergedAt,
  }) => PullRequest(
    id: number,
    number: number,
    title: 'PR $number',
    body: '',
    state: state,
    isDraft: false,
    author: PrUser(login: authorLogin, avatarUrl: ''),
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2025),
    repoFullName: repoFullName,
    htmlUrl: '',
    requestedReviewers: [
      for (final r in requestedReviewers) PrUser(login: r, avatarUrl: ''),
    ],
    mergedAt: mergedAt,
  );

  const classifier = ClassifyPrInboxUseCase();

  test('classifies each forge’s PRs under that forge’s identity', () {
    // The same human: `octocat` on GitHub, `o.cat` on GitLab. A PR requesting
    // review from each must land in Needs your review — a single-login
    // comparison would drop one of them entirely.
    final data = classifier.execute(
      viewerLoginByForge: const {
        ForgeHost.github: 'octocat',
        ForgeHost.gitlab: 'o.cat',
      },
      openByRepo: [
        RepoPullRequests(
          repo: repo('web', ForgeHost.github),
          prs: [
            pr(
              1,
              'acme/web',
              authorLogin: 'someone',
              requestedReviewers: ['octocat'],
            ),
          ],
        ),
        RepoPullRequests(
          repo: repo('api', ForgeHost.gitlab),
          prs: [
            pr(
              2,
              'acme/api',
              authorLogin: 'someone',
              requestedReviewers: ['o.cat'],
            ),
          ],
        ),
      ],
    );

    expect(
      data.sections[PrInboxSection.needsYourReview]!
          .map((i) => i.pr.number)
          .toSet(),
      {1, 2},
    );
  });

  test('a login that matches on the wrong forge is not me', () {
    // `octocat` on GitLab is a different person. Attributing their PR to the
    // operator would put a stranger's work in "your PRs".
    final data = classifier.execute(
      viewerLoginByForge: const {ForgeHost.github: 'octocat'},
      openByRepo: [
        RepoPullRequests(
          repo: repo('api', ForgeHost.gitlab),
          prs: [pr(2, 'acme/api', authorLogin: 'octocat')],
        ),
      ],
    );

    for (final section in PrInboxSection.values) {
      expect(data.sections[section], isEmpty, reason: section.name);
    }
  });

  test('a forge with no connected identity contributes nothing', () {
    final data = classifier.execute(
      viewerLoginByForge: const {ForgeHost.github: 'octocat'},
      openByRepo: [
        RepoPullRequests(
          repo: repo('web', ForgeHost.github),
          prs: [pr(1, 'acme/web', authorLogin: 'octocat')],
        ),
        // Bitbucket is unconnected: no login, so its PRs cannot be classified.
        RepoPullRequests(
          repo: repo('docs', ForgeHost.bitbucket),
          prs: [pr(3, 'acme/docs', authorLogin: 'octocat')],
        ),
      ],
    );

    final all = data.sections.values.expand((i) => i).map((i) => i.pr.number);
    expect(all, [1]);
  });

  test(
    'an empty identity map yields an empty inbox rather than everything',
    () {
      final data = classifier.execute(
        viewerLoginByForge: const {},
        openByRepo: [
          RepoPullRequests(
            repo: repo('web', ForgeHost.github),
            prs: [pr(1, 'acme/web', authorLogin: 'octocat')],
          ),
        ],
      );
      for (final section in PrInboxSection.values) {
        expect(data.sections[section], isEmpty, reason: section.name);
      }
    },
  );

  test('merged history is attributed per forge too', () {
    final now = DateTime.utc(2025, 6, 10);
    final data = classifier.execute(
      now: now,
      viewerLoginByForge: const {
        ForgeHost.github: 'octocat',
        ForgeHost.bitbucket: 'o_cat',
      },
      openByRepo: const [],
      mergedByRepo: [
        RepoPullRequests(
          repo: repo('web', ForgeHost.github),
          prs: [
            pr(
              1,
              'acme/web',
              authorLogin: 'octocat',
              state: PrState.merged,
              mergedAt: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
        RepoPullRequests(
          repo: repo('docs', ForgeHost.bitbucket),
          prs: [
            pr(
              2,
              'acme/docs',
              authorLogin: 'o_cat',
              state: PrState.merged,
              mergedAt: now.subtract(const Duration(days: 2)),
            ),
            // Someone else's merged PR on the same forge stays out.
            pr(
              3,
              'acme/docs',
              authorLogin: 'stranger',
              state: PrState.merged,
              mergedAt: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
      ],
    );

    expect(
      data.sections[PrInboxSection.mergingAndMerged]!
          .map((i) => i.pr.number)
          .toSet(),
      {1, 2},
    );
  });

  test('interleaves forges in one section, newest merge first', () {
    final now = DateTime.utc(2025, 6, 10);
    final data = classifier.execute(
      now: now,
      viewerLoginByForge: const {
        ForgeHost.github: 'me',
        ForgeHost.gitlab: 'me',
      },
      openByRepo: const [],
      mergedByRepo: [
        RepoPullRequests(
          repo: repo('web', ForgeHost.github),
          prs: [
            pr(
              1,
              'acme/web',
              authorLogin: 'me',
              state: PrState.merged,
              mergedAt: now.subtract(const Duration(days: 3)),
            ),
          ],
        ),
        RepoPullRequests(
          repo: repo('api', ForgeHost.gitlab),
          prs: [
            pr(
              2,
              'acme/api',
              authorLogin: 'me',
              state: PrState.merged,
              mergedAt: now.subtract(const Duration(days: 1)),
            ),
          ],
        ),
      ],
    );

    // One stream, ordered by merge time — not grouped by forge.
    expect(
      data.sections[PrInboxSection.mergingAndMerged]!.map((i) => i.pr.number),
      [2, 1],
    );
  });
}
