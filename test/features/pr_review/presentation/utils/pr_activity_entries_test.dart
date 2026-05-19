import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/pr_activity_entries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 7, 1, 12);

  PullRequest pr({DateTime? createdAt, int commits = 2}) => PullRequest(
    id: 1,
    number: 1,
    title: 'Title',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'alice', avatarUrl: ''),
    createdAt: createdAt ?? t0,
    updatedAt: null,
    repoFullName: 'o/r',
    htmlUrl: '',
    commitsCount: commits,
  );

  PrReviewSubmission review({
    PrReviewSubmissionState state = PrReviewSubmissionState.approved,
    String body = '',
    DateTime? at,
  }) => PrReviewSubmission(
    id: 1,
    state: state,
    author: const PrUser(login: 'bob', avatarUrl: ''),
    body: body,
    submittedAt: at,
  );

  PrTimelineEvent request(
    String reviewer,
    DateTime at, {
    String actor = 'alice',
    PrTimelineEventKind kind = PrTimelineEventKind.reviewRequested,
  }) => PrTimelineEvent(
    kind: kind,
    actor: PrUser(login: actor, avatarUrl: ''),
    reviewerName: reviewer,
    createdAt: at,
  );

  group('buildPrActivityEntries', () {
    test('starts with the opened entry and sorts ascending by time', () {
      final entries = buildPrActivityEntries(
        pr: pr(),
        reviews: [review(at: t0.add(const Duration(hours: 3)))],
        comments: [
          IssueComment(
            id: 9,
            body: 'hello',
            user: const PrUser(login: 'carol', avatarUrl: ''),
            createdAt: t0.add(const Duration(hours: 1)),
          ),
        ],
        commits: [
          PrCommit(
            sha: 'abc1234567',
            message: 'fix: thing',
            author: const PrUser(login: 'alice', avatarUrl: ''),
            date: t0.add(const Duration(hours: 2)),
          ),
        ],
        events: [request('bob', t0.add(const Duration(minutes: 5)))],
      );

      expect(entries, hasLength(5));
      expect(entries[0], isA<PrOpenedEntry>());
      expect(entries[1], isA<PrReviewRequestEntry>());
      expect(entries[2], isA<PrCommentEntry>());
      expect(entries[3], isA<PrCommitEntry>());
      expect(entries[4], isA<PrReviewEntry>());
    });

    test(
      'groups burst review-request events by the same actor into one row',
      () {
        final entries = buildPrActivityEntries(
          pr: pr(),
          reviews: const [],
          comments: const [],
          commits: const [],
          events: [
            request('bob', t0.add(const Duration(minutes: 1))),
            request('carol', t0.add(const Duration(minutes: 1, seconds: 20))),
            request('team-x', t0.add(const Duration(minutes: 1, seconds: 40))),
            // A different actor breaks the group.
            request('dave', t0.add(const Duration(minutes: 2)), actor: 'zed'),
          ],
        );

        final requests = entries.whereType<PrReviewRequestEntry>().toList();
        expect(requests, hasLength(2));
        expect(requests[0].requestedNames, ['bob', 'carol', 'team-x']);
        expect(requests[0].removedNames, isEmpty);
        expect(requests[0].actor?.login, 'alice');
        expect(requests[1].requestedNames, ['dave']);
        expect(requests[1].actor?.login, 'zed');
      },
    );

    test(
      'groups mixed request and removal events by the same actor into one row',
      () {
        final entries = buildPrActivityEntries(
          pr: pr(),
          reviews: const [],
          comments: const [],
          commits: const [],
          events: [
            request('bob', t0.add(const Duration(minutes: 1))),
            request('carol', t0.add(const Duration(minutes: 1, seconds: 5))),
            request(
              'bob',
              t0.add(const Duration(minutes: 1, seconds: 10)),
              kind: PrTimelineEventKind.reviewRequestRemoved,
            ),
            request('dave', t0.add(const Duration(minutes: 1, seconds: 20))),
            request(
              'carol',
              t0.add(const Duration(minutes: 1, seconds: 30)),
              kind: PrTimelineEventKind.reviewRequestRemoved,
            ),
            request('erin', t0.add(const Duration(minutes: 1, seconds: 40))),
          ],
        );

        final requests = entries.whereType<PrReviewRequestEntry>().toList();
        expect(requests, hasLength(1));
        expect(requests.single.actor?.login, 'alice');
        // bob and carol were requested then dropped in the same burst.
        expect(requests.single.requestedNames, ['dave', 'erin']);
        expect(requests.single.removedNames, ['bob', 'carol']);
      },
    );

    test('does not group mixed events across a long gap or other actor', () {
      final entries = buildPrActivityEntries(
        pr: pr(),
        reviews: const [],
        comments: const [],
        commits: const [],
        events: [
          request('bob', t0.add(const Duration(minutes: 1))),
          request(
            'bob',
            t0.add(const Duration(hours: 2)),
            kind: PrTimelineEventKind.reviewRequestRemoved,
          ),
          request(
            'carol',
            t0.add(const Duration(hours: 2, minutes: 1)),
            actor: 'zed',
          ),
        ],
      );

      final requests = entries.whereType<PrReviewRequestEntry>().toList();
      expect(requests, hasLength(3));
      expect(requests[0].requestedNames, ['bob']);
      expect(requests[0].removedNames, isEmpty);
      expect(requests[1].requestedNames, isEmpty);
      expect(requests[1].removedNames, ['bob']);
      expect(requests[2].actor?.login, 'zed');
    });

    test('groups a chain when each hop is inside the window', () {
      final entries = buildPrActivityEntries(
        pr: pr(),
        reviews: const [],
        comments: const [],
        commits: const [],
        events: [
          request('bob', t0.add(const Duration(minutes: 1))),
          request(
            'carol',
            t0.add(const Duration(minutes: 50)),
            kind: PrTimelineEventKind.reviewRequestRemoved,
          ),
          request('dave', t0.add(const Duration(minutes: 99))),
        ],
      );

      final requests = entries.whereType<PrReviewRequestEntry>().toList();
      expect(requests, hasLength(1));
      expect(requests.single.requestedNames, ['bob', 'dave']);
      expect(requests.single.removedNames, ['carol']);
    });

    test('skips pending (unsubmitted) reviews', () {
      final entries = buildPrActivityEntries(
        pr: pr(),
        reviews: [
          review(state: PrReviewSubmissionState.pending, at: t0),
          review(at: t0.add(const Duration(hours: 1))),
        ],
        comments: const [],
        commits: const [],
        events: const [],
      );

      final reviews = entries.whereType<PrReviewEntry>().toList();
      expect(reviews, hasLength(1));
      expect(reviews.single.review.state, PrReviewSubmissionState.approved);
    });

    test('compacts contiguous same-author commit runs into a group', () {
      PrCommit commit(String sha, String login, int minutes) => PrCommit(
        sha: sha,
        message: 'upd',
        author: PrUser(login: login, avatarUrl: ''),
        date: t0.add(Duration(minutes: minutes)),
      );

      final entries = buildPrActivityEntries(
        pr: pr(),
        reviews: const [],
        comments: const [],
        commits: [
          commit('a111111111', 'bot', 1),
          commit('b222222222', 'sam', 2),
          commit('c333333333', 'sam', 3),
          commit('d444444444', 'sam', 20),
          commit('e555555555', 'zoe', 30),
        ],
        events: [
          // Lands between sam's runs, breaking them apart.
          request('bob', t0.add(const Duration(minutes: 10))),
        ],
      );

      final tail = entries.skip(1).toList();
      expect(tail[0], isA<PrCommitEntry>()); // bot: run of 1 stays plain
      expect(tail[1], isA<PrCommitGroupEntry>());
      final group = tail[1] as PrCommitGroupEntry;
      expect(group.commits.map((c) => c.shortSha), ['b222222', 'c333333']);
      expect(group.author?.login, 'sam');
      expect(tail[2], isA<PrReviewRequestEntry>());
      expect(tail[3], isA<PrCommitEntry>()); // sam again, but run broken
      expect(tail[4], isA<PrCommitEntry>()); // zoe: different author
    });

    test('sorts null timestamps first, keeping insertion order', () {
      final entries = buildPrActivityEntries(
        pr: pr(createdAt: t0),
        reviews: [
          review(),
          review(at: t0.add(const Duration(hours: 1))),
        ],
        comments: const [],
        commits: const [],
        events: const [],
      );

      // The timestamp-less review floats above the opened entry; the dated
      // one lands after it.
      expect(entries[0], isA<PrReviewEntry>());
      expect((entries[0] as PrReviewEntry).timestamp, isNull);
      expect(entries[1], isA<PrOpenedEntry>());
      expect(entries[2], isA<PrReviewEntry>());
    });
  });
}
