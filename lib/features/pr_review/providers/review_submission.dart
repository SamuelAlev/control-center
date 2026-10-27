import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';

/// Submits a review verdict for [prRef] and records `review_submitted`.
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
  if (comments.canPost) {
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
