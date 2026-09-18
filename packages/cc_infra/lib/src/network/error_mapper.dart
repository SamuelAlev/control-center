import 'package:cc_domain/cc_domain.dart';
import 'package:dio/dio.dart';

/// Wire code when GitHub refuses to mint because the App installation is
/// suspended. Distinct from a generic `auth_error`: retrying cannot help
/// until a human resumes the installation or the caller uses a token.
const String kGitHubInstallationSuspendedCode = 'installation_suspended';

/// Whether [statusCode] + [data] is GitHub saying this App installation has
/// been suspended (`403` + that phrasing). Used by the App client so it can
/// stop minting without going through [mapDioException].
bool isGitHubInstallationSuspendedResponse(int? statusCode, Object? data) {
  if (statusCode != 403) {
    return false;
  }
  final text = (data is Map ? data['message'] : data)?.toString().toLowerCase();
  return text != null && text.contains('installation has been suspended');
}

/// Whether [error] is GitHub refusing a suspended App installation.
bool isGitHubInstallationSuspendedError(Object error) {
  if (error is NetworkException) {
    return error.code == kGitHubInstallationSuspendedCode ||
        isGitHubInstallationSuspendedResponse(
          error.statusCode,
          error.responseBody,
        );
  }
  if (error is DioException) {
    return isGitHubInstallationSuspendedResponse(
      error.response?.statusCode,
      error.response?.data,
    );
  }
  return false;
}

/// Map dio exception.
NetworkException mapDioException(DioException e) {
  final statusCode = e.response?.statusCode;
  final headers = e.response?.headers;

  if (statusCode == 400) {
    return NetworkException(
      _reason(e) ?? 'Bad request',
      statusCode: 400,
      responseBody: _responseString(e.response?.data),
      code: 'bad_request',
    );
  }

  // GitHub's PRIMARY rate limit is a 403 (NOT a 429) carrying
  // `x-ratelimit-remaining: 0`; its SECONDARY (abuse) limit is a 403 with a
  // `retry-after`. Classify both as `rate_limited` BEFORE the generic auth
  // branch below — mislabelling a rate limit as `auth_error` would trigger a
  // pointless token re-auth and, worse, invite an immediate retry that never
  // recovers until the window resets (and deepens the limit). Handled here so
  // every GitHub caller (and the client, via the enriched sub/error code) can
  // back off instead of hammering.
  if ((statusCode == 403 || statusCode == 429) &&
      _isRateLimited(headers, statusCode, e.response?.data)) {
    final resetIn = _rateLimitResetSeconds(headers);
    final message = resetIn != null
        ? 'GitHub rate limit exceeded — resets in ${resetIn}s'
        : (_reason(e) ?? 'Rate limited');
    return NetworkException(
      message,
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'rate_limited',
    );
  }

  if (isGitHubInstallationSuspendedResponse(statusCode, e.response?.data)) {
    return NetworkException(
      _reason(e) ?? 'This GitHub App installation has been suspended',
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: kGitHubInstallationSuspendedCode,
    );
  }

  if (statusCode == 401 || statusCode == 403) {
    return NetworkException(
      _reason(e) ?? 'Authentication failed',
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'auth_error',
    );
  }

  if (statusCode == 404) {
    return NetworkException(
      _reason(e) ?? 'Resource not found',
      statusCode: 404,
      responseBody: _responseString(e.response?.data),
      code: 'not_found',
    );
  }

  if (statusCode == 409) {
    return NetworkException(
      _reason(e) ?? 'Conflict',
      statusCode: 409,
      responseBody: _responseString(e.response?.data),
      code: 'conflict',
    );
  }

  if (statusCode == 406) {
    final body = _responseString(e.response?.data);
    final tooLarge =
        body != null &&
        (body.contains('too_large') ||
            body.contains('exceeded the maximum number of lines'));
    return NetworkException(
      tooLarge
          ? 'Pull request diff exceeded the forge size limit'
          : (_reason(e) ?? 'Not acceptable'),
      statusCode: 406,
      responseBody: body,
      code: tooLarge ? 'diff_too_large' : 'not_acceptable',
    );
  }

  if (statusCode == 422) {
    return NetworkException(
      _reason(e) ?? 'Unprocessable entity',
      statusCode: 422,
      responseBody: _responseString(e.response?.data),
      code: 'unprocessable_entity',
    );
  }

  if (statusCode == 429) {
    final retryAfter = e.response?.headers.value('retry-after');
    final message = retryAfter != null
        ? 'Rate limited — retry after $retryAfter second(s)'
        : (_reason(e) ?? 'Rate limited');
    return NetworkException(
      message,
      statusCode: 429,
      responseBody: _responseString(e.response?.data),
      code: 'rate_limited',
    );
  }

  if (statusCode != null && statusCode >= 500) {
    return NetworkException(
      _reason(e) ?? 'Server error',
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'server_error',
    );
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return NetworkException(
      _reason(e) ?? 'Network timeout',
      statusCode: statusCode,
      code: 'timeout',
    );
  }

  if (e.type == DioExceptionType.connectionError) {
    return NetworkException(
      _reason(e) ?? 'Connection error',
      statusCode: statusCode,
      code: 'connection_error',
    );
  }

  return NetworkException(
    _reason(e) ?? 'Network error',
    statusCode: statusCode,
    responseBody: _responseString(e.response?.data),
    code: 'network_error',
  );
}

/// The part of [DioException.message] worth surfacing, or `null` when there is
/// none — in which case each branch below falls back to its own description.
///
/// Dio's message for a bad response is a fixed paragraph about `validateStatus`
/// and what an HTTP status class means: identical on every failed request, and
/// about nothing in particular. It read as the reason for the failure
/// everywhere a [NetworkException] is shown or logged. The types whose message
/// IS specific (timeouts, connection and certificate failures, an unknown
/// wrapped error) keep theirs.
String? _reason(DioException e) =>
    e.type == DioExceptionType.badResponse ? null : e.message;

String? _responseString(Object? data) {
  if (data == null) {
    return null;
  }

  return data is String ? data : data.toString();
}

/// Whether a 403/429 is a rate limit (vs a plain auth failure). Detected from
/// `x-ratelimit-remaining: 0`, a `retry-after`, or GitHub's "rate limit
/// exceeded" body phrasing — any one is sufficient.
bool _isRateLimited(Headers? headers, int? statusCode, Object? body) {
  if (statusCode == 429) {
    return true;
  }
  if (headers != null) {
    final remaining = headers.value('x-ratelimit-remaining');
    if (remaining != null && (int.tryParse(remaining) ?? 1) <= 0) {
      return true;
    }
    if (headers.value('retry-after') != null) {
      return true;
    }
  }
  final text = (body is String ? body : body?.toString())?.toLowerCase();
  return text != null &&
      (text.contains('rate limit') || text.contains('secondary rate'));
}

/// Seconds until the rate-limit window resets, from `x-ratelimit-reset` (epoch
/// seconds) or `retry-after` (delta seconds). `null` when neither is present.
int? _rateLimitResetSeconds(Headers? headers) {
  if (headers == null) {
    return null;
  }
  final reset = headers.value('x-ratelimit-reset');
  if (reset != null) {
    final epoch = int.tryParse(reset);
    if (epoch != null) {
      final secs = epoch - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return secs > 0 ? secs : 0;
    }
  }
  final retryAfter = headers.value('retry-after');
  if (retryAfter != null) {
    return int.tryParse(retryAfter);
  }
  return null;
}
