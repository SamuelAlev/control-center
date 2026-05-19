import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Pins the DioException → NetworkException status-code and type mapping. Each
/// branch of [mapDioException] carries a distinct `code`, so a mis-routed
/// error would surface as the wrong code in the UI.

RequestOptions _opts() => RequestOptions(path: 'https://example.com');

NetworkException _map(int? status, {DioExceptionType? type, Object? data}) {
  return mapDioException(
    DioException(
      requestOptions: _opts(),
      response: status == null
          ? null
          : Response(requestOptions: _opts(), statusCode: status, data: data),
      type: type ?? DioExceptionType.unknown,
      message: 'msg',
    ),
  );
}

void main() {
  test('400 → bad_request', () {
    final e = _map(400, data: 'bad');
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
      _map(403, data: 'Resource not accessible by integration').code,
      'auth_error',
    );
  });

  group('403 primary/secondary rate limit', () {
    NetworkException mapWithHeaders(
      int status,
      Map<String, List<String>> headers, {
      Object? data,
    }) => mapDioException(
      DioException(
        requestOptions: _opts(),
        response: Response(
          requestOptions: _opts(),
          statusCode: status,
          headers: Headers.fromMap(headers),
          data: data,
        ),
        type: DioExceptionType.badResponse,
        message: 'msg',
      ),
    );

    test(
      '403 with x-ratelimit-remaining: 0 → rate_limited (not auth_error)',
      () {
        final reset =
            DateTime.now()
                .add(const Duration(seconds: 42))
                .millisecondsSinceEpoch ~/
            1000;
        final e = mapWithHeaders(403, {
          'x-ratelimit-remaining': ['0'],
          'x-ratelimit-reset': ['$reset'],
        });
        expect(e.code, 'rate_limited');
        expect(e.statusCode, 403);
        expect(e.message, contains('resets in'));
      },
    );

    test('403 secondary limit with retry-after → rate_limited', () {
      final e = mapWithHeaders(403, {
        'retry-after': ['60'],
      });
      expect(e.code, 'rate_limited');
      expect(e.message, contains('60'));
    });

    test('403 with a rate-limit body phrase → rate_limited', () {
      final e = mapWithHeaders(
        403,
        const {},
        data: 'API rate limit exceeded for user ID 123.',
      );
      expect(e.code, 'rate_limited');
    });
  });

  test('404 → not_found', () {
    final e = _map(404, data: {'x': 1});
    expect(e.code, 'not_found');
    expect(e.responseBody, isNotNull);
  });

  test('409 → conflict', () {
    expect(_map(409).code, 'conflict');
  });

  test('422 → unprocessable_entity', () {
    expect(_map(422).code, 'unprocessable_entity');
  });

  group('429 rate limit', () {
    test('uses retry-after header when present', () {
      final e = mapDioException(
        DioException(
          requestOptions: _opts(),
          response: Response(
            requestOptions: _opts(),
            statusCode: 429,
            headers: Headers.fromMap({
              'retry-after': ['30'],
            }),
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(e.code, 'rate_limited');
      expect(e.message, contains('30'));
    });

    test('falls back to the raw message without retry-after', () {
      final e = _map(429);
      expect(e.code, 'rate_limited');
      expect(e.message, 'msg');
    });
  });

  test('5xx → server_error', () {
    expect(_map(500).code, 'server_error');
    expect(_map(503).code, 'server_error');
  });

  test('connection/send/receive timeouts → timeout', () {
    expect(
      _map(null, type: DioExceptionType.connectionTimeout).code,
      'timeout',
    );
    expect(_map(null, type: DioExceptionType.sendTimeout).code, 'timeout');
    expect(_map(null, type: DioExceptionType.receiveTimeout).code, 'timeout');
  });

  test('connectionError → connection_error', () {
    expect(
      _map(null, type: DioExceptionType.connectionError).code,
      'connection_error',
    );
  });

  test('other → network_error (with response body)', () {
    final e = _map(null, type: DioExceptionType.unknown);
    expect(e.code, 'network_error');
  });

  test('_responseString returns null for null data', () {
    final e = mapDioException(
      DioException(
        requestOptions: _opts(),
        response: Response(requestOptions: _opts(), statusCode: 418),
        type: DioExceptionType.badResponse,
      ),
    );
    expect(e.responseBody, isNull);
  });
}
