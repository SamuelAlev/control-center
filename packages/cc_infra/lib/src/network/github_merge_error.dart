import 'package:cc_domain/cc_domain.dart' show PrNotMergeableException;
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:dio/dio.dart';

/// Maps a pull-request merge `PUT` failure.
///
/// A cancel is rethrown. A `405` is GitHub declining this merge, with the
/// reason in the body ("Pull Request has merge conflicts", "Required status
/// check … is expected"). Left to [mapDioException] that became a reasonless
/// `network_error`, so the operator never learned why.
Never mapPullRequestMergeError(DioException e) {
  if (e.type == DioExceptionType.cancel) {
    throw e;
  }
  if (e.response?.statusCode == 405) {
    final data = e.response?.data;
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
  throw mapDioException(e);
}
