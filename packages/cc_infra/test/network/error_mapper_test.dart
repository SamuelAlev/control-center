import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

/// Pins the RhttpException → NetworkException status and type mapping. Each
/// branch of [mapHttpException] carries a distinct `code`, so a mis-routed
/// error would surface as the wrong code in the UI.

HttpRequest _request([String url = 'https://example.com']) =>
    HttpRequest(method: HttpMethod.get, url: url);

RhttpStatusCodeException _status(
  int status, {
  Object? body,
  Map<String, String> headers = const {},
}) => RhttpStatusCodeException(
  request: _request(),
  statusCode: status,
  headers: [for (final entry in headers.entries) (entry.key, entry.value)],
  body: body,
);

NetworkException _map(
  int status, {
  Object? body,
  Map<String, String> headers = const {},
}) => mapHttpException(_status(status, body: body, headers: headers));

void main() {
  test('400 → bad_request, body preserved', () {
    final e = _map(400, body: 'bad');
    expect(e.statusCode, 400);
    expect(e.code, 'bad_request');
    expect(e.responseBody, 'bad');
  });

  test('401 and a plain 403 → auth_error', () {
    expect(_map(401).code, 'auth_error');
    // A bare 403 with no rate-limit signal (e.g. a missing OAuth scope) stays
    // an auth error.
    expect(_map(403).code, 'auth_error');
    expect(
      _map(403, body: 'Resource not accessible by integration').code,
      'auth_error',
    );
  });

  test('403 with no body at all → auth_error (no null crash on the body)', () {
    final e = _map(403);
    expect(e.code, 'auth_error');
    expect(e.responseBody, isNull);
  });

  test('403 installation suspended → installation_suspended', () {
    final e = _map(
      403,
      body: jsonEncode({
        'message': 'This installation has been suspended',
        'status': 403,
      }),
    );
    expect(e.code, 'installation_suspended');
    expect(e.statusCode, 403);
    expect(isGitHubInstallationSuspendedError(e), isTrue);
  });

  group('403 primary/secondary rate limit', () {
    test(
      '403 with x-ratelimit-remaining: 0 → rate_limited (not auth_error)',
      () {
        final reset =
            DateTime.now()
                .add(const Duration(seconds: 42))
                .millisecondsSinceEpoch ~/
            1000;
        final e = _map(
          403,
          headers: {
            'x-ratelimit-remaining': '0',
            'x-ratelimit-reset': '$reset',
          },
        );
        expect(e.code, 'rate_limited');
        expect(e.statusCode, 403);
        expect(e.message, contains('resets in'));
      },
    );

    test('403 secondary limit with retry-after → rate_limited', () {
      final e = _map(403, headers: {'retry-after': '60'});
      expect(e.code, 'rate_limited');
      expect(e.message, contains('60'));
    });

    test('403 with a rate-limit body phrase → rate_limited', () {
      final e = _map(403, body: 'API rate limit exceeded for user ID 123.');
      expect(e.code, 'rate_limited');
    });

    test('a non-numeric x-ratelimit-remaining is not a rate limit', () {
      expect(
        _map(403, headers: {'x-ratelimit-remaining': 'plenty'}).code,
        'auth_error',
      );
    });
  });

  test('404 → not_found, body preserved', () {
    final e = _map(404, body: jsonEncode({'x': 1}));
    expect(e.code, 'not_found');
    expect(e.responseBody, contains('"x"'));
  });

  test('409 → conflict', () {
    expect(_map(409).code, 'conflict');
  });

  test('406 with GitHub too_large body → diff_too_large', () {
    final e = _map(
      406,
      body: jsonEncode({
        'message':
            'Sorry, the diff exceeded the maximum number of lines (20000)',
        'errors': [
          {'resource': 'PullRequest', 'field': 'diff', 'code': 'too_large'},
        ],
      }),
    );
    expect(e.statusCode, 406);
    expect(e.code, 'diff_too_large');
    expect(e.message, contains('size limit'));
  });

  test('406 without a too-large body → not_acceptable', () {
    expect(_map(406).code, 'not_acceptable');
  });

  test('422 → unprocessable_entity', () {
    expect(_map(422).code, 'unprocessable_entity');
  });

  group('429 rate limit', () {
    test('uses the retry-after header when present', () {
      final e = _map(429, headers: {'retry-after': '30'});
      expect(e.code, 'rate_limited');
      expect(e.message, contains('30'));
    });

    test('a bare 429 falls back to the default message', () {
      // A 429 IS a rate limit whatever the headers say, and an rhttp status
      // failure carries no message of its own — so the default is what a
      // person sees.
      final e = _map(429);
      expect(e.code, 'rate_limited');
      expect(e.message, 'Rate limited');
    });
  });

  test('5xx → server_error', () {
    expect(_map(500).code, 'server_error');
    expect(_map(503).code, 'server_error');
  });

  test('timeout → timeout, with no response body', () {
    final e = mapHttpException(RhttpTimeoutException(_request()));
    expect(e.code, 'timeout');
    expect(e.message, 'Network timeout');
    expect(e.responseBody, isNull);
  });

  test('connection failure → connection_error, with the native reason', () {
    final e = mapHttpException(
      RhttpConnectionException(_request(), 'Connection refused (os error 61)'),
    );
    expect(e.code, 'connection_error');
    expect(e.message, 'Connection refused (os error 61)');
  });

  test('invalid certificate → network_error, with the native reason', () {
    final e = mapHttpException(
      RhttpInvalidCertificateException(
        request: _request(),
        message: 'certificate has expired',
      ),
    );
    expect(e.code, 'network_error');
    expect(e.message, 'certificate has expired');
  });

  test('an unknown native error → network_error', () {
    expect(
      mapHttpException(RhttpUnknownException(_request(), 'boom')).code,
      'network_error',
    );
  });

  test('a status with no branch of its own → network_error', () {
    final e = _map(418);
    expect(e.code, 'network_error');
    expect(e.responseBody, isNull);
  });

  _bodyDecodingTests();
}

/// The decoders behind [httpErrorBody]/[httpJsonBody].
void _bodyDecodingTests() {
  group('httpErrorBody', () {
    test('JSON envelope → Map', () {
      final body = httpErrorBody(
        _status(429, body: jsonEncode({'code': 'resource_exhausted'})),
      );
      expect(body, isA<Map<String, dynamic>>());
      expect((body! as Map)['code'], 'resource_exhausted');
    });

    test('non-JSON text is preserved verbatim', () {
      expect(
        httpErrorBody(_status(504, body: 'gateway timeout')),
        'gateway timeout',
      );
    });

    test('an empty body is null', () {
      expect(httpErrorBody(_status(500, body: '')), isNull);
      expect(httpErrorBody(_status(500)), isNull);
    });

    test('a byte body is decoded', () {
      final body = httpErrorBody(
        _status(400, body: Uint8List.fromList(utf8.encode('{"a":1}'))),
      );
      expect((body! as Map)['a'], 1);
    });

    test('a non-status exception has no body', () {
      expect(httpErrorBody(RhttpTimeoutException(_request())), isNull);
    });
  });

  group('httpJsonBody', () {
    HttpTextResponse text(String body, [int status = 200]) => HttpTextResponse(
      remoteIp: null,
      request: _request(),
      version: HttpVersion.http1_1,
      statusCode: status,
      headers: const [],
      body: body,
    );

    test('parses a JSON object', () {
      expect(httpJsonBody(text('{"ok":true}')), {'ok': true});
    });

    test('an empty 204-style body is null rather than a FormatException', () {
      expect(httpJsonBody(text('')), isNull);
    });

    test('a plain-text body comes back as text', () {
      expect(httpJsonBody(text('<rss></rss>')), '<rss></rss>');
    });

    test('a stream response is not read', () {
      expect(
        httpJsonBody(
          HttpStreamResponse(
            remoteIp: null,
            request: _request(),
            version: HttpVersion.http1_1,
            statusCode: 200,
            headers: const [],
            body: const Stream<Uint8List>.empty(),
          ),
        ),
        isNull,
      );
    });
  });

  group('httpExceptionFor', () {
    test('re-attributes a status failure to another request', () {
      final other = _request('https://example.com/other');
      final rehosted = httpExceptionFor(
        _status(429, body: 'slow down', headers: {'retry-after': '3'}),
        other,
      );
      expect(rehosted, isA<RhttpStatusCodeException>());
      final status = rehosted as RhttpStatusCodeException;
      expect(status.request, same(other));
      expect(status.statusCode, 429);
      expect(status.body, 'slow down');
      expect(status.headerMap['retry-after'], '3');
    });

    test('re-attributes a cancellation', () {
      final other = _request();
      expect(
        httpExceptionFor(RhttpCancelException(_request()), other).request,
        same(other),
      );
    });
  });
}
