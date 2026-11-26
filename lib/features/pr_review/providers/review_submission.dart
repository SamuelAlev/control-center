import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Submits a review verdict for [prRef] and records `review_submitted`.
///
/// A plain top-level `COMMENT` with no queued inline diff comments goes out as
/// an issue/conversation comment (`postIssueComment`), so GitHub attaches
/// `performed_via_github_app` and renders the App logo badge on the author's
/// avatar. Formal verdicts (`APPROVE`, `REQUEST_CHANGES`) and batched reviews
/// with queued inline comments use `submitReview`.
///
/// Goes through the inline-comments controller when it can post (so queued
/// diff comments ride along as ONE review), otherwise straight through
/// [repo]. Returns false, sending nothing, when neither is available.
/// [analytics] is passed in, read before the caller's overlay closes, because
/// the submit lands after the widget that started it is gone.
Future<bool> submitPrReview({
  required PrRef prRef,
  required PrInlineCommentsController comments,
  required PrReviewRepository? repo,
  required Analytics analytics,
  required String event,
  required String? body,
}) async {
  final queued = comments.pendingReviewThreads.length;
  final trimmedBody = body?.trim() ?? '';
  if (event == 'COMMENT' && queued == 0) {
    if (trimmedBody.isEmpty) {
      return false;
    }
    if (repo != null) {
      await repo.postIssueComment(prNumber: prRef.number, body: trimmedBody);
    } else if (comments.canPost) {
      await comments.submitPendingReview(event: event, body: trimmedBody);
    } else {
      return false;
    }
  } else if (comments.canPost) {
    await comments.submitPendingReview(event: event, body: body);
  } else if (repo != null) {
    await repo.submitReview(prNumber: prRef.number, event: event, body: body);
  } else {
    return false;
  }
  analytics.track(
    AnalyticsEvents.reviewSubmitted(
      verdict: event.toLowerCase(),
      commentCount: queued,
      workspaceId: prRef.workspaceId,
    ),
  );
  return true;
}

/// Re-subscribes the PR providers affected by a review or conversation comment
/// submission.
///
/// The server already busts its own cache and signals every open watch
/// stream, so this is not what fetches the new data — it is what guarantees
/// the new data is *emitted*. A live stream dedupes on the payload
/// fingerprint it last sent, so a re-validation that races the forge's
/// read-after-write lag and comes back with the pre-review payload emits
/// nothing at all, leaving the reviewer rail on its old state until the
/// operator presses refresh. Invalidating re-subscribes with a clean
/// fingerprint, which is the same thing that makes the refresh button work.
/// Mirrors `PrEditNotifier._refreshReviewers`.
void refreshPrAfterReviewSubmit(
  WidgetRef ref,
  PrRef pr, {
  required bool postedComments,
}) {
  ref
    ..invalidate(prReviewersProvider(pr))
    ..invalidate(prDetailProvider(pr))
    ..invalidate(prReviewsProvider(pr))
    ..invalidate(prIssueCommentsProvider(pr))
    ..invalidate(prTimelineEventsProvider(pr));
  if (postedComments) {
    ref.invalidate(prReviewCommentsProvider(pr));
  }
}
