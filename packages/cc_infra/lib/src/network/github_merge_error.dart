import 'package:cc_domain/cc_domain.dart' show PrNotMergeableException;
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/network/github/github_http.dart' show isHttpStatus;
import 'package:rhttp/rhttp.dart';

/// Maps a pull-request merge `PUT` failure.
///
/// A cancel is rethrown. A `405` is GitHub declining this merge, with the
/// reason in the body ("Pull Request has merge conflicts", "Required status
/// check … is expected"). Left to [mapHttpException] that became a reasonless
/// `network_error`, so the operator never learned why.
Never mapPullRequestMergeError(RhttpException e) {
  if (e is RhttpCancelException) {
    throw e;
  }
  if (isHttpStatus(e, 405)) {
    final data = httpErrorBody(e);
    final reason = data is Map ? data['message'] as String? : null;
    final message = (reason == null || reason.trim().isEmpty)
        ? 'GitHub refused to merge this pull request'
        : reason.trim();
    throw PrNotMergeableException(
      message,
      hasConflicts: message.toLowerCase().contains('conflict'),
      code: 'not_mergeable',
    );
  }
  throw mapHttpException(e);
}
