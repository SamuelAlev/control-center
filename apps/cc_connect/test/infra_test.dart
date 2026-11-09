import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect/src/rate_limiter.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/fake_redis.dart';
import 'support/harness.dart';

final class _FixedTokens implements GcpTokenSource {
  @override
  Future<String> token() async => 'ya29.metadata';
}

String _keyring(List<(String, int)> entries) => [
  for (final (kid, fill) in entries)
    '$kid:${base64.encode(List.filled(32, fill))}',
].join(',');

/// Exercises the `StateStore` contract on the store [open] returns.
void _stateStoreContract(String name, Future<StateStore> Function() open) {
  group('$name contract', () {
    late StateStore store;
    setUp(() async => store = await open());
    tearDown(() => store.close());

    test('set, get, delete and expiry', () async {
      await store.set('k', 'v', const Duration(minutes: 1));
      expect(await store.get('k'), 'v');
      await store.delete('k');
      expect(await store.get('k'), isNull);
      await store.set('short', 'v', const Duration(milliseconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(await store.get('short'), isNull);
    });

    test('putIfAbsent is first-writer-wins', () async {
      expect(
        await store.putIfAbsent('n', 'a', const Duration(minutes: 1)),
        isTrue,
      );
      expect(
        await store.putIfAbsent('n', 'b', const Duration(minutes: 1)),
        isFalse,
      );
      expect(await store.get('n'), 'a');
    });

    test('take is single use, even concurrently', () async {
      await store.set('t', 'once', const Duration(minutes: 1));
      final results = await Future.wait([store.take('t'), store.take('t')]);
      expect(results.where((r) => r == 'once'), hasLength(1));
      expect(await store.take('t'), isNull);
    });

    test('increment counts within the window', () async {
      expect(await store.increment('c', const Duration(minutes: 1)), 1);
      expect(await store.increment('c', const Duration(minutes: 1)), 2);
      expect(await store.increment('c', const Duration(minutes: 1)), 3);
    });

    test('push keeps the newest maxLength; drain pops at most max', () async {
      for (var i = 0; i < 5; i++) {
        await store.push(
          'q',
          'item$i',
          const Duration(minutes: 1),
          maxLength: 3,
        );
      }
      expect(await store.drain('q', max: 2), ['item2', 'item3']);
      expect(await store.drain('q', max: 10), ['item4']);
      expect(await store.drain('q'), isEmpty);
    });
  });
}

void main() {
  _stateStoreContract('MemoryStateStore', () async => MemoryStateStore());

  group('MemoryStateStore', () {
    test('uses its clock and evicts the soonest expiry when full', () async {
      var now = DateTime.utc(2026, 11, 8);
      final store = MemoryStateStore(clock: () => now, maxEntries: 2);
      await store.set('a', '1', const Duration(seconds: 10));
      await store.set('b', '2', const Duration(minutes: 10));
      await store.set('c', '3', const Duration(minutes: 10));
      expect(await store.get('a'), isNull);
      expect(await store.get('b'), '2');
      now = now.add(const Duration(minutes: 11));
      expect(await store.get('b'), isNull);
    });
  });

  late FakeRedis redis;
  group('RedisStateStore', () {
    setUp(() async => redis = await FakeRedis.start());
    tearDown(() => redis.close());

    _stateStoreContract(
      'RedisStateStore',
      () async => RedisStateStore(Uri.parse('redis://127.0.0.1:${redis.port}')),
    );

    test('authenticates, selects the db and prefixes every key', () async {
      redis.password = 's3cret';
      final store = RedisStateStore(
        Uri.parse('redis://connect:s3cret@127.0.0.1:${redis.port}/2'),
      );
      addTearDown(store.close);
      await store.set('login:x', 'v', const Duration(minutes: 1));
      expect(redis.commands.first, ['AUTH', 'connect', 's3cret']);
      expect(redis.commands[1], ['SELECT', '2']);
      expect(redis.commands.last.take(2), ['SET', 'cc_connect:login:x']);
    });

    test('a wrong password is unavailable', () async {
      redis.password = 's3cret';
      final store = RedisStateStore(
        Uri.parse('redis://:nope@127.0.0.1:${redis.port}'),
      );
      addTearDown(store.close);
      await expectLater(store.get('k'), throwsA(isA<StateStoreUnavailable>()));
    });

    test('falls back to MULTI GET DEL without GETDEL', () async {
      redis.oldServer = true;
      final store = RedisStateStore(
        Uri.parse('redis://127.0.0.1:${redis.port}'),
      );
      addTearDown(store.close);
      await store.set('t', 'v', const Duration(minutes: 1));
      expect(await store.take('t'), 'v');
      expect(await store.take('t'), isNull);
    });

    test('reconnects after the connection drops', () async {
      final store = RedisStateStore(
        Uri.parse('redis://127.0.0.1:${redis.port}'),
      );
      addTearDown(store.close);
      await store.set('k', 'v', const Duration(minutes: 1));
      redis.dropClients();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await store.get('k'), 'v');
    });

    test('an unreachable server is StateStoreUnavailable', () async {
      final port = redis.port;
      await redis.close();
      final store = RedisStateStore(
        Uri.parse('redis://127.0.0.1:$port'),
        commandTimeout: const Duration(seconds: 1),
      );
      await expectLater(store.get('k'), throwsA(isA<StateStoreUnavailable>()));
      redis = await FakeRedis.start();
    });
  });

  group('seal keyring', () {
    test('parses, rejects malformed rings and mints fresh entries', () {
      final ring = parseSealKeyring(_keyring([('k2', 2), ('k1', 1)]));
      expect(ring.map((e) => e.kid), ['k2', 'k1']);
      expect(() => parseSealKeyring(''), throwsFormatException);
      expect(
        () => parseSealKeyring('k1:${base64.encode([1, 2])}'),
        throwsFormatException,
      );
      expect(
        () => parseSealKeyring(
          '${_keyring([('k1', 1)])},${_keyring([('k1', 2)])}',
        ),
        throwsFormatException,
      );
      expect(() => parseSealKeyring('nokid'), throwsFormatException);
      final entry = newSealKeyEntry(now: DateTime.utc(2026, 11, 8));
      expect(entry, startsWith('k20261108'));
      expect(parseSealKeyring(entry).single.key, hasLength(32));
      expect(newSealKeyEntry(), isNot(newSealKeyEntry()));
    });
  });

  group('LocalAeadSealCipher', () {
    test('round-trips, binds the AAD and survives key rotation', () async {
      final old = LocalAeadSealCipher(
        SecretSource.value('K', _keyring([('k1', 1)])),
      );
      final sealed = await old.encrypt(
        utf8.encode('payload'),
        utf8.encode('aad'),
      );
      expect(sealed.keyId, 'k1');
      expect(
        utf8.decode(await old.decrypt(sealed, utf8.encode('aad'))),
        'payload',
      );
      await expectLater(
        old.decrypt(sealed, utf8.encode('other')),
        throwsA(isA<SealDecryptFailed>()),
      );
      final tampered = SealCiphertext('k1', [...sealed.bytes]..last ^= 1);
      await expectLater(
        old.decrypt(tampered, utf8.encode('aad')),
        throwsA(isA<SealDecryptFailed>()),
      );

      final rotated = LocalAeadSealCipher(
        SecretSource.value('K', _keyring([('k2', 2), ('k1', 1)])),
      );
      final fresh = await rotated.encrypt(
        utf8.encode('new'),
        utf8.encode('aad'),
      );
      expect(fresh.keyId, 'k2');
      expect(
        utf8.decode(await rotated.decrypt(sealed, utf8.encode('aad'))),
        'payload',
      );

      final retired = LocalAeadSealCipher(
        SecretSource.value('K', _keyring([('k2', 2)])),
      );
      await expectLater(
        retired.decrypt(sealed, utf8.encode('aad')),
        throwsA(isA<SealDecryptFailed>()),
      );
    });

    test('a file-backed ring picks up a rotation without a restart', () async {
      var ring = _keyring([('k1', 1)]);
      var now = DateTime.utc(2026, 11, 8);
      final source = SecretSource.fromEnvironment(
        {'K_FILE': '/run/keys'},
        'K',
        readFile: (_) => ring,
        clock: () => now,
      )!;
      final cipher = LocalAeadSealCipher(source);
      expect((await cipher.encrypt([1], [2])).keyId, 'k1');
      ring = _keyring([('k2', 2), ('k1', 1)]);
      now = now.add(const Duration(seconds: 31));
      expect((await cipher.encrypt([1], [2])).keyId, 'k2');
    });
  });

  group('CredentialSealer', () {
    final cipher = LocalAeadSealCipher(
      SecretSource.value('K', _keyring([('k1', 1)])),
    );
    final sealer = CredentialSealer(
      connectOrigin: 'https://connect.test',
      cipher: cipher,
    );
    const mine = SealBinding(installId: 'install-a', workspaceId: 'ws1');

    Future<String> sealOne() => sealer.seal(
      provider: ConnectProvider.github,
      accountId: '1001',
      appId: '4242',
      generation: 2,
      binding: mine,
      payload: {'refresh': 'ghr_x'},
    );

    Future<void> denied(Future<Object?> future) => expectLater(
      future,
      throwsA(
        isA<ConnectException>().having(
          (e) => e.code,
          'code',
          ConnectErrorCode.accessDenied,
        ),
      ),
    );

    test(
      'opens only for the same install, workspace, provider and origin',
      () async {
        final seal = await sealOne();
        expect(seal, isNot(contains('ghr_x')));
        final opened = await sealer.open(
          seal,
          provider: ConnectProvider.github,
          binding: mine,
        );
        expect(opened.text('refresh'), 'ghr_x');
        expect(opened.header.generation, 2);
        await denied(
          sealer.open(
            seal,
            provider: ConnectProvider.github,
            binding: const SealBinding(
              installId: 'install-b',
              workspaceId: 'ws1',
            ),
          ),
        );
        await denied(
          sealer.open(
            seal,
            provider: ConnectProvider.github,
            binding: const SealBinding(
              installId: 'install-a',
              workspaceId: 'ws2',
            ),
          ),
        );
        await denied(
          sealer.open(seal, provider: ConnectProvider.google, binding: mine),
        );
        final otherConnect = CredentialSealer(
          connectOrigin: 'https://other.test',
          cipher: cipher,
        );
        await denied(
          otherConnect.open(
            seal,
            provider: ConnectProvider.github,
            binding: mine,
          ),
        );
      },
    );

    test('malformed, oversized or edited seals are access_denied', () async {
      final seal = await sealOne();
      final parts = seal.split('.');
      for (final bad in [
        '',
        'v2.${parts[1]}.${parts[2]}',
        '${parts[0]}.${parts[1]}',
        '$seal.extra',
        'v1.!!!.${parts[2]}',
        'v1.${b64url(utf8.encode('{"p":"github"}'))}.${parts[2]}',
        'v1.${parts[1]}.${b64url([...unb64url(parts[2])]..[5] ^= 1)}',
        'v1.${parts[1]}.${'A' * 9000}',
      ]) {
        await denied(
          sealer.open(bad, provider: ConnectProvider.github, binding: mine),
        );
      }
      final header =
          jsonDecode(utf8.decode(unb64url(parts[1]))) as Map<String, Object?>;
      for (final edit in [
        {'g': 3},
        {'a': '1002'},
        {'app': '4343'},
        {'k': 'k9'},
        {'extra': 1},
      ]) {
        final forged =
            'v1.${b64url(utf8.encode(jsonEncode({...header, ...edit})))}.${parts[2]}';
        await denied(
          sealer.open(forged, provider: ConnectProvider.github, binding: mine),
        );
      }
    });

    test('sealDigest is the SHA-256 of the exact string', () async {
      final seal = await sealOne();
      expect(sealDigest(seal), hasLength(64));
      expect(sealDigest(seal), isNot(sealDigest('$seal ')));
    });
  });

  group('GcpKmsSealCipher', () {
    const key = 'projects/p/locations/global/keyRings/cc/cryptoKeys/seals';
    const kms = 'https://cloudkms.googleapis.com/v1/$key';

    test('encrypts and decrypts with the AAD, bearer-authenticated', () async {
      final upstream = FakeUpstream()
        ..on('POST', '$kms:encrypt', (call) {
          final body = call.json;
          return UpstreamResponse.json(200, {
            'ciphertext': base64.encode(
              utf8.encode(
                jsonEncode([
                  body['plaintext'],
                  body['additionalAuthenticatedData'],
                ]),
              ),
            ),
          });
        })
        ..on('POST', '$kms:decrypt', (call) {
          final body = call.json;
          final stored =
              jsonDecode(
                    utf8.decode(base64.decode(body['ciphertext']! as String)),
                  )
                  as List<Object?>;
          if (stored[1] != body['additionalAuthenticatedData']) {
            return UpstreamResponse.json(400, {
              'error': {'status': 'INVALID_ARGUMENT'},
            });
          }
          return UpstreamResponse.json(200, {'plaintext': stored[0]});
        });
      final cipher = GcpKmsSealCipher(
        keyName: key,
        http: upstream,
        tokens: _FixedTokens(),
      );
      final sealed = await cipher.encrypt(
        utf8.encode('payload'),
        utf8.encode('aad'),
      );
      expect(sealed.keyId, 'kms');
      expect(
        utf8.decode(await cipher.decrypt(sealed, utf8.encode('aad'))),
        'payload',
      );
      expect(
        upstream.calls.first.request.headers['authorization'],
        'Bearer ya29.metadata',
      );
      await expectLater(
        cipher.decrypt(sealed, utf8.encode('other')),
        throwsA(isA<SealDecryptFailed>()),
      );
      await expectLater(
        cipher.decrypt(SealCiphertext('k1', sealed.bytes), utf8.encode('aad')),
        throwsA(isA<SealDecryptFailed>()),
      );
    });

    test('a KMS outage is unavailable, never a verdict on the seal', () async {
      final upstream = FakeUpstream()
        ..json('POST', '$kms:decrypt', 503, {'error': 'down'});
      final cipher = GcpKmsSealCipher(
        keyName: key,
        http: upstream,
        tokens: _FixedTokens(),
      );
      await expectLater(
        cipher.decrypt(const SealCiphertext('kms', [1, 2, 3]), [4]),
        throwsA(isA<UpstreamUnavailable>()),
      );
      await expectLater(
        cipher.encrypt([1], [2]),
        throwsA(isA<UpstreamUnavailable>()),
      );
    });
  });

  group('GcpMetadataTokenSource', () {
    test('caches until shortly before expiry and single-flights', () async {
      var now = DateTime.utc(2026, 11, 8);
      final upstream = FakeUpstream()
        ..on(
          'GET',
          'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
          (call) {
            expect(call.request.headers['metadata-flavor'], 'Google');
            return UpstreamResponse.json(200, {
              'access_token': 'ya29.t',
              'expires_in': 3600,
              'token_type': 'Bearer',
            });
          },
        );
      final source = GcpMetadataTokenSource(upstream, clock: () => now);
      final tokens = await Future.wait([source.token(), source.token()]);
      expect(tokens, ['ya29.t', 'ya29.t']);
      expect(upstream.calls, hasLength(1));
      now = now.add(const Duration(minutes: 58));
      await source.token();
      expect(upstream.calls, hasLength(1));
      now = now.add(const Duration(minutes: 2));
      await source.token();
      expect(upstream.calls, hasLength(2));
    });
  });

  group('FileBindingStore', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('cc_bind'));
    tearDown(() => dir.delete(recursive: true));

    SlackTeamBinding team(String install) => SlackTeamBinding(
      teamId: 'T0TEAM',
      installId: install,
      botId: 'B0BOT',
      appId: 'A0TEST',
      boundAt: DateTime.utc(2026, 11, 8),
    );

    test('persists across reopen, privately', () async {
      final store = await FileBindingStore.open(dir.path);
      await store.addGitHub(77, 'install-a');
      await store.addGitHub(77, 'install-b');
      await store.addGitHub(77, 'install-a');
      expect((await store.bindSlack(team('install-a'))).installId, 'install-a');
      await store.close();

      final reopened = await FileBindingStore.open(dir.path);
      expect((await reopened.github(77))!.installIds, {
        'install-a',
        'install-b',
      });
      expect((await reopened.slack('T0TEAM'))!.installId, 'install-a');
      expect(await reopened.github(78), isNull);
      if (!Platform.isWindows) {
        final mode = File('${dir.path}/bindings.json').statSync().mode;
        expect(mode & 0x3f, 0, reason: 'no group/other access');
      }
      await reopened.close();
    });

    test('a bound team stays bound; release needs the owner', () async {
      final store = await FileBindingStore.open(dir.path);
      await store.bindSlack(team('install-a'));
      expect((await store.bindSlack(team('install-b'))).installId, 'install-a');
      expect(
        await store.releaseSlack('T0TEAM', installId: 'install-b'),
        isFalse,
      );
      expect((await store.slack('T0TEAM'))!.installId, 'install-a');
      expect(
        await store.releaseSlack('T0TEAM', installId: 'install-a'),
        isTrue,
      );
      expect(await store.slack('T0TEAM'), isNull);
      expect((await store.bindSlack(team('install-b'))).installId, 'install-b');
      expect(await store.releaseSlack('T0TEAM'), isTrue);
      await store.close();
    });

    test('a corrupt file refuses to open', () async {
      File('${dir.path}/bindings.json').writeAsStringSync('{nope');
      await expectLater(
        FileBindingStore.open(dir.path),
        throwsA(isA<BindingStoreUnavailable>()),
      );
    });
  });

  group('CachedBindingStore', () {
    test('caches hits for 30s; fresh reads and writes bypass it', () async {
      final dir = await Directory.systemTemp.createTemp('cc_bind');
      addTearDown(() => dir.delete(recursive: true));
      var now = DateTime.utc(2026, 11, 8);
      final inner = await FileBindingStore.open(dir.path);
      final cached = CachedBindingStore(inner, clock: () => now);
      final binding = SlackTeamBinding(
        teamId: 'T0TEAM',
        installId: 'install-a',
        botId: 'B0BOT',
        appId: 'A0TEST',
        boundAt: now,
      );
      await cached.bindSlack(binding);
      expect((await cached.slack('T0TEAM'))!.installId, 'install-a');
      // Changed behind the cache (another instance).
      await inner.releaseSlack('T0TEAM');
      expect(await cached.slack('T0TEAM'), isNotNull, reason: 'cached');
      expect(await cached.slack('T0TEAM', fresh: true), isNull);
      await inner.bindSlack(binding);
      await cached.slack('T0TEAM');
      await inner.releaseSlack('T0TEAM');
      now = now.add(const Duration(seconds: 31));
      expect(await cached.slack('T0TEAM'), isNull, reason: 'expired');
      await cached.close();
    });
  });

  group('FirestoreBindingStore', () {
    const docs =
        'https://firestore.googleapis.com/v1/projects/cc-prod/databases/(default)/documents';

    FirestoreBindingStore open(FakeUpstream upstream) => FirestoreBindingStore(
      project: 'cc-prod',
      database: '(default)',
      http: upstream,
      tokens: _FixedTokens(),
    );

    test(
      'reads, appends GitHub binds atomically and creates Slack binds once',
      () async {
        final upstream = FakeUpstream()
          ..json('GET', '$docs/cc_connect_github/77', 404, {})
          ..json('POST', '$docs:commit', 200, {'writeResults': <Object?>[]})
          ..json('GET', '$docs/cc_connect_github/78', 200, {
            'fields': {
              'install_ids': {
                'arrayValue': {
                  'values': [
                    {'stringValue': 'install-a'},
                  ],
                },
              },
              'bound_at': {'timestampValue': '2026-11-08T00:00:00Z'},
            },
          });
        final store = open(upstream);
        expect(await store.github(77), isNull);
        expect((await store.github(78))!.installIds, {'install-a'});
        await store.addGitHub(77, 'install-b');
        final commit = upstream.callsTo('POST', '$docs:commit').single.json;
        final write =
            (commit['writes']! as List).single as Map<String, Object?>;
        expect(jsonEncode(write), contains('appendMissingElements'));
        expect(jsonEncode(write), contains('install-b'));
        expect(
          upstream.calls.first.request.headers['authorization'],
          'Bearer ya29.metadata',
        );
      },
    );

    test('a Slack bind that loses the race returns the winner', () async {
      final upstream = FakeUpstream()
        ..json('POST', '$docs:commit', 409, {
          'error': {'status': 'ALREADY_EXISTS'},
        })
        ..json('GET', '$docs/cc_connect_slack/T0TEAM', 200, {
          'updateTime': '2026-11-08T00:00:00.000001Z',
          'fields': {
            'install_id': {'stringValue': 'install-a'},
            'bot_id': {'stringValue': 'B0BOT'},
            'app_id': {'stringValue': 'A0TEST'},
          },
        });
      final store = open(upstream);
      final winner = await store.bindSlack(
        SlackTeamBinding(
          teamId: 'T0TEAM',
          installId: 'install-b',
          botId: 'B0BOT',
          appId: 'A0TEST',
          boundAt: DateTime.utc(2026, 11, 8),
        ),
      );
      expect(winner.installId, 'install-a');
      final create = upstream.callsTo('POST', '$docs:commit').single.json;
      expect(jsonEncode(create), contains('"exists":false'));
    });

    test('an outage is BindingStoreUnavailable', () async {
      final upstream = FakeUpstream()
        ..json('GET', '$docs/cc_connect_slack/T0TEAM', 503, {});
      await expectLater(
        open(upstream).slack('T0TEAM'),
        throwsA(isA<BindingStoreUnavailable>()),
      );
    });
  });

  group('rate limiting', () {
    test('TokenBucketLimiter refills over time and bounds its keys', () {
      var now = DateTime.utc(2026, 11, 8);
      final limiter = TokenBucketLimiter(
        capacity: 2,
        per: const Duration(minutes: 1),
        clock: () => now,
      );
      expect(limiter.tryTake('a'), isTrue);
      expect(limiter.tryTake('a'), isTrue);
      expect(limiter.tryTake('a'), isFalse);
      expect(limiter.tryTake('b'), isTrue);
      now = now.add(const Duration(seconds: 30));
      expect(limiter.tryTake('a'), isTrue);
      expect(limiter.tryTake('a'), isFalse);
      final bounded = TokenBucketLimiter(
        capacity: 1,
        per: const Duration(minutes: 1),
        maxKeys: 2,
        clock: () => now,
      );
      expect(bounded.tryTake('x'), isTrue);
      expect(bounded.tryTake('y'), isTrue);
      expect(bounded.tryTake('z'), isTrue);
      expect(
        bounded.tryTake('x'),
        isTrue,
        reason: 'the oldest key was evicted',
      );
    });

    test('BoundedPool caps concurrency and refuses past its queue', () async {
      final pool = BoundedPool(concurrency: 1, maxQueued: 1);
      final gate = Completer<void>();
      final first = pool.run(() async {
        await gate.future;
        return 1;
      });
      final second = pool.run(() async => 2);
      expect(await pool.run(() async => 3), isNull);
      gate.complete();
      expect(await first, 1);
      expect(await second, 2);
    });
  });

  group('ConnectLog', () {
    test('keeps allowlisted, safe fields only and tags ids', () {
      final lines = <String>[];
      final log = ConnectLog(
        sink: lines.add,
        hmacKey: utf8.encode('k'),
        clock: () => DateTime.utc(2026, 11, 8),
      );
      final tag = log.tag('install-a');
      expect(tag, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(log.tag('install-a'), tag);
      expect(log.tag('install-b'), isNot(tag));
      log.event('test.event', {
        'install': tag,
        'status': 200,
        'token': 'ghu_secret',
        'reason': 'has spaces and <html>',
        'route': '/v1/config',
      });
      final line = jsonDecode(lines.single) as Map<String, Object?>;
      expect(line['event'], 'test.event');
      expect(line['install'], tag);
      expect(line['status'], 200);
      expect(line['route'], '/v1/config');
      expect(line.containsKey('token'), isFalse);
      expect(lines.single, isNot(contains('<html>')));
      log.event('Bad Name!');
      expect(lines, hasLength(1));
    });

    test('truncateIp keeps a /24 or /48', () {
      expect(truncateIp('203.0.113.77'), '203.0.113.0/24');
      expect(truncateIp('2001:db8:1234:5678::1'), '2001:db8:1234::/48');
      expect(truncateIp('garbage'), isEmpty);
    });
  });

  test('connectUpstreamHosts is a closed allowlist', () {
    expect(
      connectUpstreamHosts.keys,
      containsAll(['api.github.com', 'slack.com']),
    );
    expect(connectUpstreamHosts.keys, isNot(contains('linear.app')));
    expect(connectUpstreamHosts['metadata.google.internal'], 'http');
    expect(
      connectUpstreamHosts.entries
          .where((e) => e.value != 'https')
          .map((e) => e.key),
      ['metadata.google.internal'],
    );
  });
}
