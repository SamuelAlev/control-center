import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:rhttp/rhttp.dart';

/// Wire code when GitHub refuses to mint because the App installation is
/// suspended. Distinct from a generic `auth_error`: retrying cannot help
/// until a human resumes the installation or the caller uses a token.
const String kGitHubInstallationSuspendedCode = 'installation_suspended';

/// Whether [statusCode] + [data] is GitHub saying this App installation has
/// been suspended (`403` + that phrasing). Used by the App client so it can
/// stop minting without going through [mapHttpException].
///
/// [data] is the decoded error body (see [httpErrorBody]) or the raw body text.
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
  if (error is RhttpException) {
    return isGitHubInstallationSuspendedResponse(
      _statusOf(error),
      httpErrorBody(error),
    );
  }
  return false;
}

/// Maps a transport failure from the shared rhttp clients to the app's typed
/// [NetworkException].
///
/// Every GitHub/GitLab/Bitbucket/Slack/… client funnels its `catch` through
/// this one function, so the mapping is stable across adapters: each branch
/// carries a distinct `code` that callers switch on.
///
/// `RhttpCancelException` is deliberately NOT special-cased here: cancellation
/// is a subscriber standing down, and every stream-shaped caller checks for it
/// by type *before* mapping. It falls through to `network_error` like any
/// other unclassified failure.
NetworkException mapHttpException(RhttpException e) {
  final statusCode = _statusOf(e);
  final headers = e is RhttpStatusCodeException ? e.headers : null;
  final body = _responseString(e);

  if (statusCode == 400) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Bad request',
      statusCode: 400,
      responseBody: body,
      code: 'bad_request',
    );
  }

  // GitHub's PRIMARY rate limit is a 403 (NOT a 429) carrying
  // `x-ratelimit-remaining: 0`; its SECONDARY (abuse) limit is a 403 with a
  // `retry-after`. Classify both — and every 429, which is a rate limit by
  // definition — as `rate_limited` BEFORE the generic auth branch below:
  // mislabelling a rate limit as `auth_error` would trigger a pointless token
  // re-auth and, worse, invite an immediate retry that never recovers until
  // the window resets (and deepens the limit).
  if ((statusCode == 403 || statusCode == 429) &&
      _isRateLimited(headers, statusCode, e)) {
    final resetIn = _rateLimitResetSeconds(headers);
    final message = resetIn != null
        ? 'GitHub rate limit exceeded — resets in ${resetIn}s'
        : (httpExceptionReason(e) ?? 'Rate limited');
    return NetworkException(
      message,
      statusCode: statusCode,
      responseBody: body,
      code: 'rate_limited',
    );
  }

  if (isGitHubInstallationSuspendedResponse(statusCode, httpErrorBody(e))) {
    return NetworkException(
      httpExceptionReason(e) ??
          'This GitHub App installation has been suspended',
      statusCode: statusCode,
      responseBody: body,
      code: kGitHubInstallationSuspendedCode,
    );
  }

  if (statusCode == 401 || statusCode == 403) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Authentication failed',
      statusCode: statusCode,
      responseBody: body,
      code: 'auth_error',
    );
  }

  if (statusCode == 404) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Resource not found',
      statusCode: 404,
      responseBody: body,
      code: 'not_found',
    );
  }

  if (statusCode == 409) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Conflict',
      statusCode: 409,
      responseBody: body,
      code: 'conflict',
    );
  }

  if (statusCode == 406) {
    final tooLarge =
        body != null &&
        (body.contains('too_large') ||
            body.contains('exceeded the maximum number of lines'));
    return NetworkException(
      tooLarge
          ? 'Pull request diff exceeded the forge size limit'
          : (httpExceptionReason(e) ?? 'Not acceptable'),
      statusCode: 406,
      responseBody: body,
      code: tooLarge ? 'diff_too_large' : 'not_acceptable',
    );
  }

  if (statusCode == 422) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Unprocessable entity',
      statusCode: 422,
      responseBody: body,
      code: 'unprocessable_entity',
    );
  }

  if (statusCode != null && statusCode >= 500) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Server error',
      statusCode: statusCode,
      responseBody: body,
      code: 'server_error',
    );
  }

  if (e is RhttpTimeoutException) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Network timeout',
      statusCode: statusCode,
      code: 'timeout',
    );
  }

  if (e is RhttpConnectionException) {
    return NetworkException(
      httpExceptionReason(e) ?? 'Connection error',
      statusCode: statusCode,
      code: 'connection_error',
    );
  }

  return NetworkException(
    httpExceptionReason(e) ?? 'Network error',
    statusCode: statusCode,
    responseBody: body,
    code: 'network_error',
  );
}

/// The decoded body of a failed request: JSON when the body IS JSON, the raw
/// text when it is not, `null` when there is no body.
Object? httpErrorBody(RhttpException e) =>
    e is RhttpStatusCodeException ? _decodeBody(e.body) : null;

/// The decoded body of a successful response, with [httpErrorBody]'s rules
/// (empty body → `null`, JSON → the decoded value, plain text → the text,
/// bytes → decoded UTF-8 when valid, else the raw bytes as [Uint8List]).
///
/// Callers that expect an object can `as Map<String, dynamic>?`-check the
/// result; unlike `HttpTextResponse.bodyToJson` this never throws on an empty
/// body — an endpoint answering `204 No Content` yields `null`, not a
/// `FormatException`.
Object? httpJsonBody(HttpResponse response) => switch (response) {
  HttpTextResponse(:final body) => _decodeBody(body),
  HttpBytesResponse(:final body) => _decodeBody(body),
  HttpStreamResponse() => null,
};

/// Rebuilds [exception] against [request].
///
/// Used where an error must be re-attributed to a DIFFERENT request object
/// than the one it was raised on: a coalesced GET waiter that inherited the
/// original request's failure (`DedupInterceptor`), and a retry that exhausted
/// its attempts on a re-issued request (`RetryInterceptor`). Both cases must
/// hand the caller a failure that names the caller's own request — every
/// interceptor downstream keys its behaviour off `exception.request`.
RhttpException httpExceptionFor(RhttpException exception, HttpRequest request) {
  return switch (exception) {
    RhttpCancelException() => RhttpCancelException(request),
    RhttpTimeoutException() => RhttpTimeoutException(request),
    RhttpRedirectException() => RhttpRedirectException(request),
    RhttpStatusCodeException(:final statusCode, :final headers, :final body) =>
      RhttpStatusCodeException(
        request: request,
        statusCode: statusCode,
        headers: headers,
        body: body,
      ),
    RhttpInvalidCertificateException(:final message) =>
      RhttpInvalidCertificateException(request: request, message: message),
    RhttpConnectionException(:final message) => RhttpConnectionException(
      request,
      message,
    ),
    RhttpClientDisposedException() => RhttpClientDisposedException(request),
    RhttpInterceptorException(:final error) => RhttpInterceptorException(
      request,
      error,
    ),
    RhttpUnknownException(:final message) => RhttpUnknownException(
      request,
      message,
    ),
    _ => exception,
  };
}

/// The status code of [e], or `null` when the failure never got that far
/// (timeout, connection refused, cancellation).
int? _statusOf(RhttpException e) =>
    e is RhttpStatusCodeException ? e.statusCode : null;

/// The part of an [RhttpException] worth showing a person, or `null` when the
/// caller has a better description of its own (see the branches of
/// [mapHttpException]).
///
/// Shared deliberately between the `NetworkException` message and the failure
/// line `HttpLogInterceptor` writes, so what the log says and what the UI says
/// cannot drift apart.
///
/// A status failure carries nothing but its code, headers and body — the
/// server's own words live in the body, and each branch already has a precise
/// default ("Rate limited", "Resource not found", …), so its message is empty.
/// The types whose text IS specific — connection refused, an invalid
/// certificate, an unknown native error, an interceptor's own failure — keep
/// theirs, whitespace-collapsed onto one line.
String? httpExceptionReason(RhttpException e) {
  final message = switch (e) {
    RhttpConnectionException(:final message) => message,
    RhttpInvalidCertificateException(:final message) => message,
    RhttpUnknownException(:final message) => message,
    RhttpInterceptorException(:final error) => '$error',
    _ => null,
  };
  if (message == null) {
    return null;
  }
  final collapsed = message.replaceAll(RegExp(r'\s+'), ' ').trim();
  return collapsed.isEmpty ? null : collapsed;
}

/// The failed response's body as text: the wire text for a text response, the
/// UTF-8 decoding of a byte body (malformed sequences replaced, never thrown),
/// `null` when the body is empty or absent.
String? _responseString(RhttpException e) {
  if (e is! RhttpStatusCodeException) {
    return null;
  }
  return switch (e.body) {
    String body => body,
    Uint8List bytes when bytes.isEmpty => null,
    Uint8List bytes => utf8.decode(bytes, allowMalformed: true),
    _ => null,
  };
}

/// JSON-decodes [body] when it is JSON, and hands back what was actually there
/// otherwise — see [httpErrorBody].
Object? _decodeBody(Object? body) {
  final text = switch (body) {
    String text => text,
    Uint8List bytes =>
      bytes.isEmpty ? '' : utf8.decode(bytes, allowMalformed: true),
    _ => null,
  };
  if (text == null) {
    // An unexpected body shape (a streamed body is never captured, so this is
    // defensive): hand it back rather than pretend there was nothing.
    return body;
  }
  if (text.trim().isEmpty) {
    return null;
  }
  try {
    return jsonDecode(text);
  } on FormatException {
    return text;
  }
}

/// The first value of [name] on [headers] (case-insensitive), or `null`.
String? _headerValue(List<(String, String)>? headers, String name) {
  if (headers == null) {
    return null;
  }
  final lower = name.toLowerCase();
  for (final (key, value) in headers) {
    if (key.toLowerCase() == lower) {
      return value;
    }
  }
  return null;
}

/// Whether a 403/429 is a rate limit (vs a plain auth failure). Detected from
/// `x-ratelimit-remaining: 0`, a `retry-after`, or GitHub's "rate limit
/// exceeded" body phrasing — any one is sufficient. A 429 is always one.
bool _isRateLimited(
  List<(String, String)>? headers,
  int? statusCode,
  RhttpException e,
) {
  if (statusCode == 429) {
    return true;
  }
  final remaining = _headerValue(headers, 'x-ratelimit-remaining');
  if (remaining != null && (int.tryParse(remaining) ?? 1) <= 0) {
    return true;
  }
  if (_headerValue(headers, 'retry-after') != null) {
    return true;
  }
  final text = _responseString(e)?.toLowerCase();
  return text != null &&
      (text.contains('rate limit') || text.contains('secondary rate'));
}

/// Seconds until the rate-limit window resets, from `x-ratelimit-reset` (epoch
/// seconds) or `retry-after` (delta seconds). `null` when neither is present.
int? _rateLimitResetSeconds(List<(String, String)>? headers) {
  final reset = _headerValue(headers, 'x-ratelimit-reset');
  if (reset != null) {
    final epoch = int.tryParse(reset);
    if (epoch != null) {
      final secs = epoch - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return secs > 0 ? secs : 0;
    }
  }
  final retryAfter = _headerValue(headers, 'retry-after');
  return retryAfter == null ? null : int.tryParse(retryAfter);
}
