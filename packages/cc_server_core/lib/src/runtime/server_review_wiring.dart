part of '../cc_server_runtime.dart';

/// The `fetchPrPreview` / `fetchCommitPreview` closures behind PR and commit
/// link previews.
///
/// Read only with the caller's own GitHub sign-in: a preview is a person
/// reading a link, and a repository they cannot see must not render a title
/// fetched with somebody else's access. Not signed in, or no caller, is no
/// preview. A failed read is no preview, never an error.
({PrPreviewFetcher pr, CommitPreviewFetcher commit}) _linkPreviewFetchers({
  required GitHubApiClient Function(String userId, {String? workspaceId})
  forActor,
}) {
  GitHubApiClient? clientFor(String actingUserId, String? workspaceId) =>
      actingUserId.isEmpty
      ? null
      : forActor(actingUserId, workspaceId: workspaceId);

  return (
    pr: (owner, repo, number, {required actingUserId, workspaceId}) async {
      final client = clientFor(actingUserId, workspaceId);
      if (client == null) {
        return null;
      }
      try {
        final pr = await client.pr.getPullRequest(owner, repo, number);
        if (pr == null) {
          return null;
        }
        return {
          'title': pr.title,
          'state': pr.state,
          'is_draft': pr.isDraft,
          'is_merged': pr.mergedAt != null,
          'html_url': pr.htmlUrl,
        };
      } catch (_) {
        return null;
      }
    },
    commit: (owner, repo, sha, {required actingUserId, workspaceId}) async {
      final client = clientFor(actingUserId, workspaceId);
      if (client == null) {
        return null;
      }
      try {
        final commit = await client.pr.getCommit(owner, repo, sha);
        if (commit == null) {
          return null;
        }
        return {'title': commit.title, 'short_sha': commit.shortSha};
      } catch (_) {
        return null;
      }
    },
  );
}

/// The `reviewHubStats` closure: a workspace's aggregated review-effectiveness
/// counters (findings made vs. actually addressed).
Future<Map<String, dynamic>> Function({required String workspaceId})
_reviewHubStats(DaoReviewRunSnapshotRepository snapshots) =>
    ({required String workspaceId}) async {
      final stats = await snapshots.statsForWorkspace(workspaceId);
      return {
        'findings_total': stats.findingsTotal,
        'resolved': stats.resolved,
        'dismissed': stats.dismissed,
        'still_open': stats.stillOpen,
        'addressed': stats.addressed,
        // The two that actually say whether the review is worth running.
        // `action_rate` counts only findings a human FIXED — a dismissal is a
        // rejection, and folding it into "addressed" is how a reviewer
        // congratulates itself for being ignored. `dismissal_rate` is the
        // noise signal to tune against.
        'action_rate': stats.actionRate,
        'dismissal_rate': stats.dismissalRate,
      };
    };

/// The `publishReview` closure behind the client's "Publish to GitHub" button.
///
/// Published as the person who pressed it, on their own GitHub sign-in: the
/// release gate is theirs, so the review is too. Not signed in fails like any
/// unauthenticated call.
Future<Map<String, dynamic>> Function({
  required String workspaceId,
  required String spaceId,
  required String selection,
  required bool approveOnShip,
  required String userId,
})
_publishReviewAsCaller(ReviewPublisherService publisher) =>
    ({
      required String workspaceId,
      required String spaceId,
      required String selection,
      required bool approveOnShip,
      required String userId,
    }) async {
      final result = await publisher.publish(
        workspaceId: workspaceId,
        spaceId: spaceId,
        selection: selection == 'all_open'
            ? ReviewPublishSelection.allOpen
            : ReviewPublishSelection.consensus,
        approveOnShip: approveOnShip,
        actingUserId: userId,
      );
      return {
        'review_id': result.reviewId,
        'event': result.event,
        'finding_count': result.findingCount,
        'inline_count': result.inlineCount,
        'used_body_fallback': result.usedFallback,
        'status': 'published',
      };
    };
