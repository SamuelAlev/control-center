import 'dart:io';

import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// Regression coverage for `HttpException: More than one value for header
/// cache-control` — observed in production against news.ycombinator.com,
/// which sends `Cache-Control` as TWO separate header lines (`private` +
/// `max-age=0`). dart:io's `HttpHeaders.value()` throws on a multi-valued
/// header, which made the media proxy answer 502 for the whole fetch; the
/// proxy's header reads must tolerate repeated lines instead.
void main() {
  late ServerSocket socket;
  late Uri origin;

  // A hand-rolled HTTP origin. dart:io's own HttpServer may fold repeated
  // response headers into a single comma-joined line on write, so emit raw
  // bytes to guarantee the client parser sees TWO `Cache-Control` /
  // `ETag` lines, exactly as HN serves them.
  setUp(() async {
    socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    origin = Uri.parse('http://127.0.0.1:${socket.port}/favicon.ico');
    socket.listen((conn) {
      conn.listen((_) {
        const body = 'png-bytes';
        conn.write(
          'HTTP/1.1 200 OK\r\n'
          'Content-Type: image/png\r\n'
          'Content-Length: ${body.length}\r\n'
          'Cache-Control: private\r\n'
          'Cache-Control: max-age=0\r\n'
          'ETag: "first"\r\n'
          'ETag: "second"\r\n'
          'Connection: close\r\n'
          '\r\n'
          '$body',
        );
        conn.close();
      });
    });
  });

  tearDown(() => socket.close());

  Future<HttpClientResponse> fetch() async {
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    return (await client.getUrl(origin)).close();
  }

  test('the upstream really sends repeated header lines (root cause)', () async {
    final resp = await fetch();
    expect(resp.headers[HttpHeaders.cacheControlHeader], [
      'private',
      'max-age=0',
    ]);
    expect(resp.headers[HttpHeaders.etagHeader], ['"first"', '"second"']);
    // This is the call that took the fetch down before the fix.
    expect(
      () => resp.headers.value(HttpHeaders.cacheControlHeader),
      throwsA(isA<HttpException>()),
    );
    await resp.drain<void>();
  });

  test('upstreamCacheControlValue comma-joins repeated lines', () async {
    final resp = await fetch();
    expect(upstreamCacheControlValue(resp.headers), 'private, max-age=0');
    await resp.drain<void>();
  });

  test(
    'firstUpstreamHeaderValue takes the first of a repeated singleton header',
    () async {
      final resp = await fetch();
      expect(
        firstUpstreamHeaderValue(resp.headers, HttpHeaders.etagHeader),
        '"first"',
      );
      await resp.drain<void>();
    },
  );

  test('absent headers read as null, not an exception', () async {
    final resp = await fetch();
    expect(
      firstUpstreamHeaderValue(resp.headers, HttpHeaders.lastModifiedHeader),
      isNull,
    );
    await resp.drain<void>();
  });
}
