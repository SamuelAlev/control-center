import 'dart:async';
import 'dart:typed_data';

import 'package:cc_server_core/src/demo/demo_repo_stats.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// Serves one canned JSON body, counts fetches, and can be flipped to fail —
/// enough behaviour to exercise the whole cache policy without a network.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.body);

  final String body;
  int fetches = 0;
  bool fail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetches++;
    if (fail) {
      throw StateError('network down');
    }
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DemoRepoStats _stats(
  _ScriptedAdapter adapter, {
  Duration ttl = const Duration(minutes: 30),
  Duration failureCooldown = const Duration(minutes: 5),
}) => DemoRepoStats(
  dio: Dio()..httpClientAdapter = adapter,
  ttl: ttl,
  failureCooldown: failureCooldown,
);

void main() {
  test('parses stargazers_count', () async {
    final adapter = _ScriptedAdapter('{"stargazers_count": 1287}');
    final stats = _stats(adapter);

    expect(await stats.current(), 1287);
    expect(adapter.fetches, 1);
  });

  test('a fresh cache serves without a second fetch', () async {
    final adapter = _ScriptedAdapter('{"stargazers_count": 1287}');
    final stats = _stats(adapter);

    await stats.current();
    expect(await stats.current(), 1287);
    expect(adapter.fetches, 1);
  });

  test('an expired cache refetches', () async {
    final adapter = _ScriptedAdapter('{"stargazers_count": 1287}');
    final stats = _stats(adapter, ttl: const Duration(milliseconds: 1));

    expect(await stats.current(), 1287);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(await stats.current(), 1287);
    expect(adapter.fetches, 2);
  });

  test('a failed refresh keeps the last known count', () async {
    final adapter = _ScriptedAdapter('{"stargazers_count": 1287}');
    final stats = _stats(adapter, ttl: const Duration(milliseconds: 1));

    expect(await stats.current(), 1287);
    adapter.fail = true;
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // The count does not flash away just because GitHub hiccuped.
    expect(await stats.current(), 1287);
  });

  test('a failed fetch starts a cooldown, not a retry storm', () async {
    final adapter = _ScriptedAdapter('{"stargazers_count": 1287}')..fail = true;
    final stats = _stats(adapter, ttl: const Duration(milliseconds: 1));

    expect(await stats.current(), isNull);
    expect(await stats.current(), isNull);
    // Failed requests count against GitHub's unauthenticated rate limit
    // exactly like successful ones — one attempt per cooldown, not per caller.
    expect(adapter.fetches, 1);
  });

  test('a malformed body is a failure, not a bogus count', () async {
    final adapter = _ScriptedAdapter('{"message": "rate limited"}');
    final stats = _stats(adapter);

    expect(await stats.current(), isNull);
  });
}
