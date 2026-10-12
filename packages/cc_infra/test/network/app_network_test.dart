import 'dart:typed_data';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/retry_interceptor.dart';
// rhttp ships an interceptor of its own with the same name as the cc_infra
// one this file uses; hide it so the local class is unambiguous.
import 'package:rhttp/rhttp.dart' hide RetryInterceptor;
import 'package:test/test.dart';

HttpRequest _request({
  String url = 'https://example.com/x',
  String? baseUrl,
  Map<String, String> headers = const {},
  HttpMethod method = HttpMethod.get,
  Map<String, String>? query,
  HttpBody? body,
}) => HttpRequest(
  method: method,
  url: url,
  headers: headers.isEmpty ? null : HttpHeaders.rawMap(headers),
  settings: baseUrl == null ? null : ClientSettings(baseUrl: baseUrl),
  query: query,
  body: body,
);

RhttpStatusCodeException _status(
  int statusCode, {
  Object? body,
  Map<String, String> headers = const {},
  HttpRequest? request,
}) {
  return RhttpStatusCodeException(
    request: request ?? _request(),
    statusCode: statusCode,
    headers: [for (final entry in headers.entries) (entry.key, entry.value)],
    body: body,
  );
}

void main() {
  final records = <(CcInfraLogLevel, String, Object?)>[];

  setUp(() {
    records.clear();
    CcInfraLog.sink = (level, message, [error, stackTrace]) =>
        records.add((level, message, error));
  });

  tearDown(() {
    CcInfraLog.sink = null;
    CcInfraLog.level = CcInfraLogLevel.info;
  });

  Iterable<(CcInfraLogLevel, String, Object?)> at(CcInfraLogLevel level) =>
      records.where((record) => record.$1 == level);

  group('HttpLogInterceptor levels', () {
    test('a cancelled request is never logged as an error', () async {
      CcInfraLog.level = CcInfraLogLevel.debug;
      final log = HttpLogInterceptor();

      await log.onError(RhttpCancelException(_request()));

      // Cancellation is a subscriber standing down, not a failure: nothing at
      // warning/error, only the debug-tier line keeping the "→" request log
      // symmetric.
      expect(at(CcInfraLogLevel.warning), isEmpty);
      expect(at(CcInfraLogLevel.error), isEmpty);
      final cancelled = at(CcInfraLogLevel.debug).toList();
      expect(cancelled, hasLength(1));
      expect(cancelled.single.$2, contains('cancelled'));
    });

    test('a cancellation is silent at the default (info) level', () async {
      await HttpLogInterceptor().onError(RhttpCancelException(_request()));

      expect(records, isEmpty);
    });

    test(
      'a status the caller declared expected is not logged as an error',
      () async {
        CcInfraLog.level = CcInfraLogLevel.debug;
        final request = _request()
          ..additionalData.addAll(expectStatuses(const [429]));

        await HttpLogInterceptor().onError(
          _status(429, body: '{"code":"resource_exhausted"}', request: request),
        );

        // Kimi answers a spent plan with a 429 the caller reads as state, so the
        // lane where real failures land stays clean — the exchange is still
        // visible at debug.
        expect(at(CcInfraLogLevel.warning), isEmpty);
        expect(at(CcInfraLogLevel.error), isEmpty);
        expect(
          at(CcInfraLogLevel.debug).where((r) => r.$2.contains('HTTP 429')),
          isNotEmpty,
        );
      },
    );

    test('an UNdeclared status is still logged as an error', () async {
      // 429 declared, 500 not: the marker is a per-status opt-out, not a
      // blanket "never log this request".
      final request = _request()
        ..additionalData.addAll(expectStatuses(const [429]));

      await HttpLogInterceptor().onError(
        _status(500, body: 'boom', request: request),
      );

      expect(at(CcInfraLogLevel.error), hasLength(1));
    });

    test(
      '401 and 403 are warnings, not errors (the auth layer owns them)',
      () async {
        final log = HttpLogInterceptor();
        await log.onError(_status(401));
        await log.onError(_status(403, body: '{"message":"secondary rate"}'));

        expect(at(CcInfraLogLevel.warning), hasLength(2));
        expect(at(CcInfraLogLevel.error), isEmpty);
      },
    );

    test(
      'a 410 on a syncToken request is an info line without the body',
      () async {
        final request = _request(
          url: 'https://www.googleapis.com/calendar/v3/calendars/c/events',
          query: {'syncToken': 'abc'},
        );

        await HttpLogInterceptor().onError(
          _status(410, body: '{"error":"fullSyncRequired"}', request: request),
        );

        final info = at(CcInfraLogLevel.info).toList();
        expect(info, hasLength(1));
        expect(info.single.$2, contains('sync token expired'));
        expect(info.single.$2, contains('/events'));
        expect(info.single.$2, isNot(contains('fullSyncRequired')));
        expect(at(CcInfraLogLevel.error), isEmpty);
      },
    );

    test(
      'an intermediate retry attempt is not logged as the outcome',
      () async {
        final request = _request()
          ..additionalData[RetryInterceptor.retryCountKey] = 2;

        await HttpLogInterceptor().onError(
          _status(503, body: 'upstream', request: request),
        );

        expect(records, isEmpty);
      },
    );

    test(
      'a transport failure is logged once, with its cause and reason',
      () async {
        await HttpLogInterceptor().onError(
          RhttpInterceptorException(
            _request(),
            StateError('token lookup blew up'),
          ),
        );

        final errors = at(CcInfraLogLevel.error).toList();
        expect(errors, hasLength(1));
        expect(errors.single.$2, contains('interceptor_error'));
        expect(errors.single.$2, contains('token lookup blew up'));
        expect(errors.single.$3, isA<StateError>());
      },
    );

    test(
      'a failure line carries the request and response bodies on one line',
      () async {
        final request = _request(
          method: HttpMethod.post,
          url: 'https://api.github.com/graphql',
          body: const HttpBody.text('query {\n  viewer {\n    login\n  }\n}'),
        );

        await HttpLogInterceptor().onError(
          _status(
            502,
            body: '<html>\n  <body>bad gateway</body>\n</html>',
            request: request,
          ),
        );

        final line = at(CcInfraLogLevel.error).single.$2;
        expect(line, contains('HTTP 502 https://api.github.com/graphql'));
        expect(
          line,
          contains('request: query { viewer { login } }'),
          reason: 'the query is collapsed onto one line',
        );
        expect(
          line,
          contains('response: <html> <body>bad gateway</body> </html>'),
        );
        expect(line.split('\n'), hasLength(1));
      },
    );

    test('a body past the cap is truncated with a count', () async {
      await HttpLogInterceptor().onError(_status(500, body: 'x' * 5000));

      final line = at(CcInfraLogLevel.error).single.$2;
      expect(line, contains('… [+3000 chars]'));
    });

    test(
      'request and response traces are debug-only, and never read a stream',
      () async {
        final log = HttpLogInterceptor();
        final request = _request(
          body: HttpBody.bytes(Uint8List.fromList(List<int>.filled(12, 7))),
        );

        await log.beforeRequest(request);
        expect(records, isEmpty, reason: 'silent at info level');

        CcInfraLog.level = CcInfraLogLevel.debug;
        await log.beforeRequest(request);
        await log.afterResponse(
          HttpTextResponse(
            remoteIp: null,
            request: request,
            version: HttpVersion.http1_1,
            statusCode: 200,
            headers: const [],
            body: '{"ok":true}',
          ),
        );

        final debug = at(CcInfraLogLevel.debug).map((r) => r.$2).toList();
        expect(debug.first, contains('HTTP → GET https://example.com/x'));
        expect(debug.first, contains('request: <12 bytes>'));
        expect(debug.last, contains('HTTP ← 200 https://example.com/x'));
        expect(debug.last, contains('response: {"ok":true}'));
      },
    );

    test('expectStatuses is request metadata, not a header', () {
      expect(expectStatuses(const [429, 404]), {
        expectedStatusesExtra: [429, 404],
      });
    });
  });

  group('HttpRequestNormalizer', () {
    test('an absolute URL ignores the client base URL', () async {
      // Pagination can follow absolute next links on another host.
      final result = await HttpRequestNormalizer().beforeRequest(
        _request(url: 'https://other.test/raw', baseUrl: 'https://api.test'),
      );

      expect(result.value!.url, 'https://other.test/raw');
      expect(result.value!.settings?.baseUrl, isNull);
    });

    test(
      'relative URLs collapse duplicate slashes and resolve dot segments',
      () async {
        final normalizer = HttpRequestNormalizer();

        final joined = await normalizer.beforeRequest(
          _request(url: '/usage', baseUrl: 'https://api.test'),
        );
        expect(joined.value!.url, 'https://api.test/usage');
        expect(joined.value!.settings?.baseUrl, isNull);

        final slashed = await normalizer.beforeRequest(
          _request(url: '/user', baseUrl: 'https://api.test/v4/'),
        );
        expect(slashed.value!.url, 'https://api.test/v4/user');

        final dotted = await normalizer.beforeRequest(
          _request(url: '/a/../b', baseUrl: 'https://api.test'),
        );
        expect(dotted.value!.url, 'https://api.test/b');
      },
    );

    test(
      'Accept defaults to JSON, and the caller wins when it sets one',
      () async {
        final normalizer = HttpRequestNormalizer();

        final defaulted = await normalizer.beforeRequest(
          _request(url: '/usage', baseUrl: 'https://api.test'),
        );
        expect(
          defaulted.value!.headers![HttpHeaderName.accept],
          'application/json',
        );

        final request = _request(headers: {'Accept': 'text/html'});
        final explicit = await normalizer.beforeRequest(request);
        expect(
          (explicit.value ?? request).headers![HttpHeaderName.accept],
          'text/html',
        );
      },
    );

    test('an unencodable request body still logs instead of throwing', () async {
      CcInfraLog.level = CcInfraLogLevel.debug;
      // A payload jsonEncode cannot represent must not be the reason a request
      // fails: the log line falls back to `toString()`.
      await HttpLogInterceptor().beforeRequest(
        _request(body: const HttpBody.json(Object())),
      );

      expect(at(CcInfraLogLevel.debug), hasLength(1));
    });
  });
}
