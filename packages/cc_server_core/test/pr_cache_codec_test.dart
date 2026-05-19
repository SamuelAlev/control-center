import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/commit_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_server_core/src/pr_review/pr_cache_codec.dart';
import 'package:test/test.dart';

/// The SWR cache dedupes emissions by comparing `encode(decode(cached))` with
/// `encode(fresh)`. That comparison is only meaningful if the codec is a true
/// round trip: any field that decodes to something which re-encodes
/// differently makes every cached read emit twice — the cached value, then an
/// identical "fresh" one — doubling client rebuilds for no new information.
///
/// So these tests assert **encode ∘ decode ∘ encode == encode**, not just that
/// the values survive.
void main() {
  String enc(Map<String, dynamic> m) => jsonEncode(m);

  group('PrCacheCodec round-trips', () {
    test('a fully populated pull request', () {
      final pr = PullRequest(
        id: 12,
        number: 42,
        title: 'Title',
        body: 'Body',
        state: PrState.open,
        isDraft: true,
        author: const PrUser(login: 'me', avatarUrl: 'a', name: 'Me'),
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025, 2),
        repoFullName: 'o/r',
        htmlUrl: 'https://example.test/pr/42',
        externalId: 'n1',
        headSha: 'aaa',
        baseRef: 'main',
        baseSha: 'bbb',
        headRef: 'feature',
        requestedReviewers: const [PrUser(login: 'rev', avatarUrl: '')],
        requestedTeamSlugs: const ['team'],
        assignees: const [PrUser(login: 'asg', avatarUrl: '')],
        mergedAt: DateTime.utc(2025, 3),
        reviewedByMe: true,
        reactions: const [
          ReactionGroup(
            content: '+1',
            emoji: '👍',
            count: 2,
            userReacted: true,
            usernames: ['me', 'you'],
          ),
        ],
        bodyHtml: '<p>Body</p>',
        changedFiles: 3,
        commitsCount: 4,
        additions: 10,
        deletions: 5,
        commentsCount: 6,
        checksStatus: PrChecksStatus.passing,
        mergeableState: PrMergeableState.clean,
        reviewDecision: PrReviewDecision.approved,
      );

      final once = PrCacheCodec.pullRequestToCache(pr);
      final twice = PrCacheCodec.pullRequestToCache(
        PrCacheCodec.pullRequestFromCache(once)!,
      );
      expect(enc(twice), enc(once));
    });

    test('a minimal pull request with an empty author', () {
      // The asymmetry that bites: an author with no login and no avatar decodes
      // to null, so a naive encode would drop the key on the second pass and
      // make the two encodings differ.
      final pr = PullRequest(
        id: 0,
        number: 1,
        title: 't',
        body: '',
        state: PrState.open,
        isDraft: false,
        author: const PrUser(login: '', avatarUrl: ''),
        createdAt: null,
        updatedAt: null,
        repoFullName: 'o/r',
        htmlUrl: '',
      );

      final once = PrCacheCodec.pullRequestToCache(pr);
      final twice = PrCacheCodec.pullRequestToCache(
        PrCacheCodec.pullRequestFromCache(once)!,
      );
      expect(enc(twice), enc(once));
    });

    test('a changed file', () {
      final f = PrFile(
        filename: 'lib/a.dart',
        status: PrFileStatus.renamed,
        additions: 1,
        deletions: 2,
        patch: '@@ -1 +1 @@',
        previousFilename: 'lib/b.dart',
        viewerViewedState: PrFileViewedState.viewed,
      );
      final once = PrCacheCodec.fileToCache(f);
      expect(
        enc(PrCacheCodec.fileToCache(PrCacheCodec.fileFromCache(once))),
        enc(once),
      );
    });

    test('a commit with no author', () {
      const c = PrCommit(sha: 's', message: 'm', author: null, date: null);
      final once = PrCacheCodec.commitToCache(c);
      expect(
        enc(PrCacheCodec.commitToCache(PrCacheCodec.commitFromCache(once))),
        enc(once),
      );
    });

    test('a review submission', () {
      final r = PrReviewSubmission(
        id: 3,
        state: PrReviewSubmissionState.changesRequested,
        author: const PrUser(login: 'rev', avatarUrl: ''),
        body: 'no',
        submittedAt: DateTime.utc(2025),
      );
      final once = PrCacheCodec.reviewToCache(r);
      expect(
        enc(PrCacheCodec.reviewToCache(PrCacheCodec.reviewFromCache(once))),
        enc(once),
      );
    });

    test('an inline review comment', () {
      final c = PrCodeReviewComment(
        id: 7,
        body: 'b',
        user: const PrUser(login: 'u', avatarUrl: ''),
        path: 'lib/a.dart',
        position: 3,
        createdAt: DateTime.utc(2025),
        side: 'LEFT',
        inReplyToId: 6,
        startLine: 1,
        diffHunk: '@@',
        line: 4,
        originalLine: 5,
        reviewId: 9,
      );
      final once = PrCacheCodec.reviewCommentToCache(c);
      expect(
        enc(
          PrCacheCodec.reviewCommentToCache(
            PrCacheCodec.reviewCommentFromCache(once),
          ),
        ),
        enc(once),
      );
    });

    test('a conversation comment', () {
      final c = IssueComment(
        id: 1,
        body: 'b',
        user: const PrUser(login: 'u', avatarUrl: ''),
        createdAt: DateTime.utc(2025),
      );
      final once = PrCacheCodec.issueCommentToCache(c);
      expect(
        enc(
          PrCacheCodec.issueCommentToCache(
            PrCacheCodec.issueCommentFromCache(once),
          ),
        ),
        enc(once),
      );
    });

    test('a timeline event', () {
      final e = PrTimelineEvent(
        kind: PrTimelineEventKind.reviewRequested,
        actor: const PrUser(login: 'a', avatarUrl: ''),
        reviewerName: 'team',
        reviewerIsTeam: true,
        reviewerAvatarUrl: 'x',
        createdAt: DateTime.utc(2025),
      );
      final once = PrCacheCodec.timelineEventToCache(e);
      expect(
        enc(
          PrCacheCodec.timelineEventToCache(
            PrCacheCodec.timelineEventFromCache(once),
          ),
        ),
        enc(once),
      );
    });

    test('a check run', () {
      final c = CheckRun(
        name: 'build',
        status: CheckRunStatus.completed,
        conclusion: CheckRunConclusion.success,
        htmlUrl: 'u',
        startedAt: DateTime.utc(2025),
        completedAt: DateTime.utc(2025, 2),
        output: 'ok',
        workflowName: 'CI',
        checkSuiteId: 1,
        jobId: 2,
        workflowRunId: 3,
      );
      final once = PrCacheCodec.checkRunToCache(c);
      expect(
        enc(PrCacheCodec.checkRunToCache(PrCacheCodec.checkRunFromCache(once))),
        enc(once),
      );
    });

    test('a check run with no conclusion', () {
      final c = CheckRun(
        name: 'build',
        status: CheckRunStatus.queued,
        conclusion: null,
      );
      final once = PrCacheCodec.checkRunToCache(c);
      expect(
        enc(PrCacheCodec.checkRunToCache(PrCacheCodec.checkRunFromCache(once))),
        enc(once),
      );
    });

    test('a commit status', () {
      final s = CommitStatus(
        context: 'ci',
        state: CommitStatusState.success,
        targetUrl: 'u',
        description: 'd',
        updatedAt: DateTime.utc(2025),
      );
      final once = PrCacheCodec.commitStatusToCache(s);
      expect(
        enc(
          PrCacheCodec.commitStatusToCache(
            PrCacheCodec.commitStatusFromCache(once),
          ),
        ),
        enc(once),
      );
    });

    test('a user reviewer', () {
      const r = PrUserReviewer(
        user: PrUser(login: 'u', avatarUrl: 'a'),
        isCodeOwner: true,
        state: PrReviewSubmissionState.approved,
      );
      final once = PrCacheCodec.reviewerToCache(r);
      expect(
        enc(PrCacheCodec.reviewerToCache(PrCacheCodec.reviewerFromCache(once))),
        enc(once),
      );
    });

    test('a team reviewer satisfied by a member', () {
      const r = PrTeamReviewer(
        name: 'Platform',
        slug: 'platform',
        isCodeOwner: false,
        state: PrReviewSubmissionState.approved,
        avatarUrl: 'a',
        reviewedBy: PrUser(login: 'member', avatarUrl: ''),
      );
      final once = PrCacheCodec.reviewerToCache(r);
      expect(
        enc(PrCacheCodec.reviewerToCache(PrCacheCodec.reviewerFromCache(once))),
        enc(once),
      );
    });
  });

  group('PrCacheCodec tolerates stale rows', () {
    test('an enum name from a newer release falls back instead of throwing', () {
      // A cache row outlives the release that wrote it, so a value this build
      // has never heard of must degrade to a sane default rather than take the
      // stream down.
      final pr = PrCacheCodec.pullRequestFromCache({
        'number': 1,
        'title': 't',
        'repo_full_name': 'o/r',
        'state': 'from-a-future-release',
        'mergeable_state': 'nonsense',
        'checks_status': 'nonsense',
      });
      expect(pr!.state, PrState.open);
      expect(pr.mergeableState, PrMergeableState.unknown);
      expect(pr.checksStatus, PrChecksStatus.none);
    });

    test('missing and wrongly typed scalars read as defaults', () {
      final f = PrCacheCodec.fileFromCache({
        'filename': 'lib/a.dart',
        'additions': 'lots',
        'status': null,
      });
      expect(f.additions, 0);
      expect(f.deletions, 0);
      expect(f.status, PrFileStatus.modified);
      expect(f.viewerViewedState, PrFileViewedState.unviewed);
    });

    test('a row missing its required fields throws, for the caller to catch', () {
      // Deliberate: the entities assert their invariants, and the SWR pass
      // wraps `decode` in a try/catch that treats a throwing row as a cache
      // miss. Swallowing it here instead would hand the UI a PR with an empty
      // title and no way to tell it apart from a real one.
      expect(
        () => PrCacheCodec.pullRequestFromCache({'number': 1}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
