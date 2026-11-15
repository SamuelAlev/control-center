import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect/src/connect_service.dart' show ObservedUpstream;
import 'package:cc_connect/src/provider_github.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

const String _dsn = 'https://pubkey123@sentry.example/42';
const String _envelopeUrl = 'https://sentry.example/api/42/envelope/';

List<Map<String, Object?>> _lines(List<String> logs) => [
  for (final line in logs) jsonDecode(line) as Map<String, Object?>,
];

Future<void> _eventually(bool Function() check) async {
  for (var i = 0; i < 100 && !check(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

/// The three lines of a Sentry envelope: header, item header, event.
List<Map<String, Object?>> _envelope(RecordedCall call) => [
  for (final line in const LineSplitter().convert(
    utf8.decode(call.request.body!),
  ))
    jsonDecode(line) as Map<String, Object?>,
];

void main() {
  late ConnectInstallIdentity a;
  late ConnectInstallIdentity stranger;

  setUpAll(() async {
    a = await ConnectInstallIdentity.derive(
      masterSeed: seed(1),
      connectUrl: testPublicUrl,
    );
    stranger = await ConnectInstallIdentity.derive(
      masterSeed: seed(3),
      connectUrl: testPublicUrl,
    );
  });

  test('every logged field is allowlisted and every allowlisted field is '
      'used', () {
    // Added by the logger itself, not at a call site.
    const internal = {
      'request_id',
      'route',
      'install',
      'exception',
      'field',
      'source_event',
      'suppressed',
    };
    final used = <String>{};
    final names = <String>{};
    final call = RegExp(r'\.(event|sampled|exception)\(');
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final match in call.allMatches(text)) {
        var depth = 0;
        var end = match.end - 1;
        for (; end < text.length; end++) {
          if (text[end] == '(') {
            depth++;
          } else if (text[end] == ')' && --depth == 0) {
            break;
          }
        }
        final args = text.substring(match.end, end);
        final name = RegExp(r"^\s*'([^']*)'").firstMatch(args)?.group(1);
        if (name != null) {
          names.add(name);
        }
        for (final key in RegExp(r"'([a-z][a-z0-9_]*)':").allMatches(args)) {
          used.add(key.group(1)!);
        }
      }
    }
    expect(names, contains('github.mint'));
    for (final name in names) {
      expect(name, matches(RegExp(r'^[a-z][a-z0-9_.]{0,63}$')));
    }
    expect(used.difference(connectLogFields), isEmpty);
    expect(connectLogFields.difference({...used, ...internal}), isEmpty);
  });

  group('request ids and headers', () {
    late Harness harness;
    setUp(() async => harness = await Harness.start(allowed: [a]));
    tearDown(() => harness.close());

    test(
      'every response carries a fresh x-request-id, and so do its lines',
      () async {
        final health = await harness.raw('GET', '/healthz');
        final missing = await harness.raw('GET', '/v1/nope');
        final signed = await harness.call(a, 'GET', '/v1/config');
        final ids = [
          for (final response in [health, missing, signed])
            response.header('x-request-id'),
        ];
        for (final id in ids) {
          expect(id, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
        }
        expect(ids.toSet(), hasLength(3));
        // The line is written once the response is sent, so the client can
        // read the response before it exists.
        bool logged(Map<String, Object?> l) =>
            l['event'] == 'http.request' && l['request_id'] == ids.last;
        await _eventually(() => _lines(harness.logs).any(logged));
        final line = _lines(harness.logs).singleWhere(logged);
        expect(line['route'], '/v1/config');
        expect(line['install'], matches(RegExp(r'^[0-9a-f]{16}$')));
        expect(line['level'], 'info');
        expect(line['message'], 'http.request');
      },
    );

    test('HSTS only for an https public URL', () async {
      expect(
        (await harness.raw(
          'GET',
          '/healthz',
        )).header('strict-transport-security'),
        'max-age=31536000',
      );
      final loopback = await Harness.start(
        allowed: [a],
        env: {'CONNECT_PUBLIC_URL': 'http://127.0.0.1:8790'},
      );
      addTearDown(loopback.close);
      expect(
        (await loopback.raw(
          'GET',
          '/healthz',
        )).header('strict-transport-security'),
        isNull,
      );
    });

    test('a refusal is one warn line with its code and reason', () async {
      final nonce = b64url(randomBytes(16));
      await harness.call(a, 'GET', '/v1/config', nonce: nonce);
      final replay = await harness.call(a, 'GET', '/v1/config', nonce: nonce);
      expect(replay.json, {'error': 'stale_request'});
      final refused = _lines(
        harness.logs,
      ).where((l) => l['event'] == 'auth.refused').single;
      expect(refused['reason'], 'replay');
      expect(refused['level'], 'warn');
      expect(refused['request_id'], replay.header('x-request-id'));
    });
  });

  group('unexpected errors and Sentry', () {
    FlakyStateStore crashing() => FlakyStateStore()
      ..failPuts.add('nonce:')
      ..putError = StateError('secret-looking text');

    test('http.error names the type, never the message', () async {
      final harness = await Harness.start(allowed: [a], state: crashing());
      addTearDown(harness.close);
      final response = await harness.call(a, 'GET', '/v1/config');
      expect(response.status, 503);
      expect(response.json, {'error': 'provider_unavailable'});
      final line = _lines(
        harness.logs,
      ).singleWhere((l) => l['event'] == 'http.error');
      expect(line['level'], 'error');
      expect(line['exception'], 'StateError');
      expect(line['route'], '/v1/config');
      expect(harness.logs.join(), isNot(contains('secret-looking')));
      expect(harness.upstream.calls, isEmpty, reason: 'no DSN, no report');
    });

    test('with a DSN, the envelope holds the type and frames only', () async {
      final harness = await Harness.start(
        allowed: [a],
        state: crashing(),
        env: {'CONNECT_SENTRY_DSN': _dsn, 'CONNECT_VERSION': '1.2.3'},
      );
      addTearDown(harness.close);
      final response = await harness.call(a, 'GET', '/v1/config');
      expect(response.status, 503);
      await _eventually(
        () => harness.upstream.callsTo('POST', _envelopeUrl).isNotEmpty,
      );
      final sent = harness.upstream.callsTo('POST', _envelopeUrl).single;
      expect(
        sent.request.headers['x-sentry-auth'],
        allOf(contains('sentry_key=pubkey123'), contains('sentry_version=7')),
      );
      final body = utf8.decode(sent.request.body!);
      expect(body, isNot(contains('secret-looking')));
      expect(body, isNot(contains(a.installId)));
      final [header, item, event] = _envelope(sent);
      expect(item, {'type': 'event'});
      expect(header['event_id'], event['event_id']);
      expect(event.keys.toSet(), {
        'event_id',
        'timestamp',
        'level',
        'logger',
        'release',
        'environment',
        'tags',
        'exception',
      });
      expect(event['logger'], 'cc_connect');
      expect(event['release'], '1.2.3');
      expect(event['environment'], 'self-hosted');
      expect(event['tags'], {
        'route': '/v1/config',
        'request_id': response.header('x-request-id'),
        'error': 'provider_unavailable',
      });
      final exception =
          ((event['exception']! as Map)['values']! as List).single as Map;
      expect(exception['type'], 'StateError');
      final frames = (exception['stacktrace']! as Map)['frames']! as List;
      expect(frames, isNotEmpty);
      expect((frames.last as Map).keys.toSet(), {
        'function',
        'filename',
        'lineno',
      });

      // The same type on the same route is reported once a minute.
      await harness.call(a, 'GET', '/v1/config');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(harness.upstream.callsTo('POST', _envelopeUrl), hasLength(1));
    });

    test('a Sentry outage changes nothing for the request', () async {
      final down = FakeUpstream()
        ..on('POST', _envelopeUrl, (_) => throw const UpstreamUnavailable('x'));
      final harness = await Harness.start(
        allowed: [a],
        state: crashing(),
        upstream: down,
        env: {'CONNECT_SENTRY_DSN': _dsn},
      );
      addTearDown(harness.close);
      final response = await harness.call(a, 'GET', '/v1/config');
      expect(response.status, 503);
      expect(response.json, {'error': 'provider_unavailable'});
      await _eventually(
        () => harness.logs.any((l) => l.contains('sentry.report_failed')),
      );
      final failed = _lines(
        harness.logs,
      ).singleWhere((l) => l['event'] == 'sentry.report_failed');
      expect(failed['level'], 'warn');
      expect(failed['reason'], 'unavailable');
    });

    test('a ConnectException is never reported', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {'CONNECT_SENTRY_DSN': _dsn},
      );
      addTearDown(harness.close);
      final refused = await harness.call(
        a,
        'POST',
        '/v1/github/refresh',
        body: {'unexpected': true},
      );
      expect(refused.json, {'error': 'invalid_request'});
      final line = _lines(
        harness.logs,
      ).singleWhere((l) => l['event'] == 'http.refused');
      expect(line['level'], 'warn');
      expect(line['error'], 'invalid_request');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(harness.upstream.callsTo('POST', _envelopeUrl), isEmpty);
    });

    test('the reporter, alone: a thrown StateError', () async {
      final upstream = FakeUpstream()
        ..json('POST', _envelopeUrl, 200, {'id': 'x'});
      final log = ConnectLog(sink: (_) {});
      log.reporter = SentryReporter(
        dsn: SentryDsn.tryParse(_dsn)!,
        http: upstream,
        log: log,
        release: '0.0.1',
        environment: 'hosted',
      ).report;
      try {
        throw StateError('secret-looking text');
      } on StateError catch (error, stack) {
        log.exception('http.error', error, stack);
      }
      await _eventually(() => upstream.calls.isNotEmpty);
      final body = utf8.decode(upstream.calls.single.request.body!);
      expect(body, contains('"type":"StateError"'));
      expect(body, contains('observability_test.dart'));
      expect(body, isNot(contains('secret-looking')));
    });

    test('a malformed DSN refuses to start without printing it', () {
      expect(
        () => ConnectServiceConfig.fromEnvironment({
          ...Harness.defaultEnv([a], 'data'),
          'CONNECT_SENTRY_DSN': 'not a dsn pubkey123',
        }),
        throwsA(
          isA<ConnectConfigException>().having(
            (e) => e.message,
            'message',
            allOf(contains('CONNECT_SENTRY_DSN'), isNot(contains('pubkey'))),
          ),
        ),
      );
      expect(SentryDsn.tryParse(_dsn)!.envelopeUrl.toString(), _envelopeUrl);
      expect(SentryDsn.tryParse('http://k@h/1'), isNull);
    });
  });

  group('upstream observation', () {
    test('a failed GitHub call is logged with its request id', () async {
      final logs = <String>[];
      final fake = FakeUpstream()
        ..on(
          'GET',
          'https://api.github.com/user',
          (_) => const UpstreamResponse(
            502,
            [],
            headers: {'x-github-request-id': 'C4E2:3A4B:1F2E3D:6543ABCD'},
          ),
        );
      final observed = ObservedUpstream(fake, ConnectLog(sink: logs.add));
      await observed.send(
        UpstreamRequest('GET', Uri.parse('https://api.github.com/user')),
      );
      await observed.send(
        UpstreamRequest('GET', Uri.parse('https://slack.com/api/x')),
      );
      final lines = _lines(logs);
      expect(lines.first, containsPair('event', 'upstream.failed'));
      expect(lines.first['upstream'], 'github_api');
      expect(lines.first['upstream_status'], 502);
      expect(lines.first['github_request_id'], 'C4E2:3A4B:1F2E3D:6543ABCD');
      expect(lines.first['level'], 'warn');
      expect(lines.last['upstream'], 'slack');
      expect(lines.last['upstream_status'], 599);
    });

    test(
      'the shared App token budget is watched over a rolling hour',
      () async {
        final logs = <String>[];
        var now = DateTime.utc(2026, 11, 10);
        final fake = FakeUpstream()
          ..json(
            'POST',
            'https://github.com/login/oauth/access_token',
            200,
            {},
          );
        final observed = ObservedUpstream(
          fake,
          ConnectLog(sink: logs.add, clock: () => now),
          clock: () => now,
        );
        Future<void> tokenCalls(int count) async {
          for (var i = 0; i < count; i++) {
            await observed.send(
              UpstreamRequest(
                'POST',
                Uri.parse('https://github.com/login/oauth/access_token'),
              ),
            );
          }
        }

        await tokenCalls(ObservedUpstream.budgetWarn);
        expect(logs, isEmpty);
        await tokenCalls(1);
        final first = _lines(logs).single;
        expect(first['event'], 'github.token_budget');
        expect(first['count'], ObservedUpstream.budgetWarn + 1);
        expect(first['level'], 'warn');
        await tokenCalls(ObservedUpstream.budgetError);
        expect(logs, hasLength(1), reason: 'once per 10 minutes');
        now = now.add(const Duration(minutes: 10));
        await tokenCalls(1);
        expect(_lines(logs).last['level'], 'error');
        // An hour later the window has emptied.
        now = now.add(const Duration(hours: 1));
        logs.clear();
        await tokenCalls(1);
        expect(logs, isEmpty);
      },
    );
  });

  group('rate limits', () {
    test('the per-IP bucket runs before the global one', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_TRUST_PROXY': '1',
          'CONNECT_RATE_IP_PER_MINUTE': '1',
          'CONNECT_RATE_GLOBAL_PER_SECOND': '3',
        },
      );
      addTearDown(harness.close);
      Future<int> from(String ip) async => (await harness.raw(
        'GET',
        '/v1/version',
        headers: {'x-forwarded-for': ip},
      )).status;
      expect(await from('203.0.113.1'), 200);
      for (var i = 0; i < 5; i++) {
        expect(await from('203.0.113.1'), 429);
      }
      expect(await from('203.0.113.2'), 200, reason: 'global not drained');
      final hit = _lines(
        harness.logs,
      ).firstWhere((l) => l['event'] == 'ratelimit.hit');
      expect(hit['bucket'], 'ip');
      expect(hit['ip'], '203.0.113.0/24');
    });

    test('IPv6 clients share a bucket per /64', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {'CONNECT_TRUST_PROXY': '1', 'CONNECT_RATE_IP_PER_MINUTE': '1'},
      );
      addTearDown(harness.close);
      Future<int> from(String ip) async => (await harness.raw(
        'GET',
        '/v1/version',
        headers: {'x-forwarded-for': ip},
      )).status;
      expect(await from('2001:db8:1:2::1'), 200);
      expect(await from('2001:db8:1:2:ffff::9'), 429);
      expect(await from('2001:db8:1:3::1'), 200);
      expect(ConnectService.ipBucketKey('2001:db8:1:2::1'), '2001:db8:1:2');
      expect(ConnectService.ipBucketKey('203.0.113.5'), '203.0.113.5');
    });

    test('Slack hooks have their own buckets and drain no other', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_RATE_SLACK_HOOK_IP_PER_MINUTE': '2',
          'CONNECT_RATE_GLOBAL_PER_SECOND': '2',
          'CONNECT_RATE_IP_PER_MINUTE': '2',
        },
      );
      addTearDown(harness.close);
      final statuses = [
        for (var i = 0; i < 4; i++)
          (await harness.raw(
            'POST',
            '/v1/hooks/slack/events',
            body: utf8.encode('{}'),
          )).status,
      ];
      expect(statuses, [403, 403, 429, 429]);
      expect((await harness.call(a, 'GET', '/v1/config')).status, 200);
    });

    test('a global hook bucket caps hooks from every address', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_TRUST_PROXY': '1',
          'CONNECT_RATE_SLACK_HOOK_GLOBAL_PER_SECOND': '1',
        },
      );
      addTearDown(harness.close);
      final statuses = [
        for (final ip in ['203.0.113.1', '198.51.100.1'])
          (await harness.raw(
            'POST',
            '/v1/hooks/slack/commands',
            headers: {'x-forwarded-for': ip},
            body: utf8.encode('x'),
          )).status,
      ];
      expect(statuses, [403, 429]);
    });

    test('/healthz and /readyz spend no token', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_RATE_IP_PER_MINUTE': '1',
          'CONNECT_RATE_GLOBAL_PER_SECOND': '1',
        },
      );
      addTearDown(harness.close);
      for (var i = 0; i < 5; i++) {
        expect((await harness.raw('GET', '/healthz')).status, 200);
        expect((await harness.raw('GET', '/readyz')).status, 200);
      }
      expect((await harness.call(a, 'GET', '/v1/config')).status, 200);
    });

    test('a non-listed install is refused before verification', () async {
      final harness = await Harness.start(allowed: [a]);
      addTearDown(harness.close);
      // A broken signature from a non-listed key: the allow list answers
      // first (verification would have said access_denied).
      final response = await harness.call(
        stranger,
        'GET',
        '/v1/config',
        signedUrl: 'https://evil.example/v1/config',
      );
      expect(response.json, {'error': 'install_blocked'});
      final listed = await harness.call(
        a,
        'GET',
        '/v1/config',
        signedUrl: 'https://evil.example/v1/config',
      );
      expect(listed.json, {'error': 'access_denied'});
      final reasons = [
        for (final l in _lines(harness.logs))
          if (l['event'] == 'auth.refused') l['reason'],
      ];
      expect(reasons, ['blocked', 'signature']);
    });
  });

  group('/readyz', () {
    test(
      'answers 503 when the state store fails its probe, cached 5 s',
      () async {
        final store = FlakyStateStore();
        final harness = await Harness.start(allowed: [a], state: store);
        addTearDown(harness.close);
        store.failProbe = true;
        final failing = await harness.raw('GET', '/readyz');
        expect(failing.status, 503);
        expect(failing.json, {'ok': false});
        store.failProbe = false;
        expect(
          (await harness.raw('GET', '/readyz')).status,
          503,
          reason: 'cached',
        );
        expect((await harness.raw('GET', '/healthz')).status, 200);
      },
    );

    test('a failing probe at boot refuses to start', () async {
      final store = FlakyStateStore()..failProbe = true;
      await expectLater(
        Harness.start(allowed: [a], state: store),
        throwsA(isA<ConnectConfigException>()),
      );
    });
  });

  group('GitHub App JWT', () {
    test('is reused for 8 of its 9 minutes', () async {
      var now = DateTime.utc(2026, 11, 10);
      final fake = FakeUpstream()
        ..json(
          'GET',
          'https://api.github.com/users/acme/installation',
          404,
          {},
        );
      final api = GitHubApi(
        fake,
        GitHubCredentials(
          appId: 4242,
          appSlug: 'cc-test',
          clientId: 'Iv23test',
          clientSecret: DualSecret(
            current: SecretSource.value('S', 'gh-secret-2'),
          ),
          privateKey: SecretSource.value('K', testGitHubAppKey),
        ),
        clock: () => now,
      );
      String? lastJwt() => fake.calls.last.request.headers['authorization'];
      await api.accountInstallation('acme');
      final first = lastJwt();
      now = now.add(const Duration(minutes: 7, seconds: 59));
      await api.accountInstallation('acme');
      expect(lastJwt(), first);
      now = now.add(const Duration(seconds: 1));
      await api.accountInstallation('acme');
      expect(lastJwt(), isNot(first));
    });
  });
}
