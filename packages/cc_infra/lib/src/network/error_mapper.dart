import 'package:cc_domain/cc_domain.dart';
import 'package:dio/dio.dart';

/// Map dio exception.
NetworkException mapDioException(DioException e) {
  final statusCode = e.response?.statusCode;
  final headers = e.response?.headers;

  if (statusCode == 400) {
    return NetworkException(
      e.message ?? 'Bad request',
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
        : (e.message ?? 'Rate limited');
    return NetworkException(
      message,
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'rate_limited',
    );
  }

  if (statusCode == 401 || statusCode == 403) {
    return NetworkException(
      e.message ?? 'Authentication failed',
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'auth_error',
    );
  }

  if (statusCode == 404) {
    return NetworkException(
      e.message ?? 'Resource not found',
      statusCode: 404,
      responseBody: _responseString(e.response?.data),
      code: 'not_found',
    );
  }

  if (statusCode == 409) {
    return NetworkException(
      e.message ?? 'Conflict',
      statusCode: 409,
      responseBody: _responseString(e.response?.data),
      code: 'conflict',
    );
  }

  if (statusCode == 422) {
    return NetworkException(
      e.message ?? 'Unprocessable entity',
      statusCode: 422,
      responseBody: _responseString(e.response?.data),
      code: 'unprocessable_entity',
    );
  }

  if (statusCode == 429) {
    final retryAfter = e.response?.headers.value('retry-after');
    final message = retryAfter != null
        ? 'Rate limited — retry after $retryAfter second(s)'
        : (e.message ?? 'Rate limited');
    return NetworkException(
      message,
      statusCode: 429,
      responseBody: _responseString(e.response?.data),
      code: 'rate_limited',
    );
  }

  if (statusCode != null && statusCode >= 500) {
    return NetworkException(
      e.message ?? 'Server error',
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'server_error',
    );
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return NetworkException(
      e.message ?? 'Network timeout',
      statusCode: statusCode,
      code: 'timeout',
    );
  }

  if (e.type == DioExceptionType.connectionError) {
    return NetworkException(
      e.message ?? 'Connection error',
      statusCode: statusCode,
      code: 'connection_error',
    );
  }

  return NetworkException(
    e.message ?? 'Network error',
    statusCode: statusCode,
    responseBody: _responseString(e.response?.data),
    code: 'network_error',
  );
}

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
