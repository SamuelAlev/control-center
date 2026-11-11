import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect/src/rate_limiter.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/fake_redis.dart';
import 'support/harness.dart';

final class _FlakyCipher implements SealCipher {
  _FlakyCipher(this._inner, this._fail);

  final SealCipher _inner;
  final bool Function() _fail;

  @override
  Future<SealCiphertext> encrypt(List<int> plaintext, List<int> aad) {
    if (_fail()) {
      throw StateError('kms down');
    }
    return _inner.encrypt(plaintext, aad);
  }

  @override
  Future<List<int>> decrypt(SealCiphertext ciphertext, List<int> aad) =>
      _inner.decrypt(ciphertext, aad);
}

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

    test('replace and deleteIf act only on the expected value', () async {
      await store.set('cas', 'one', const Duration(minutes: 1));
      expect(
        await store.replace('cas', 'other', 'two', const Duration(minutes: 1)),
        isFalse,
      );
      expect(await store.get('cas'), 'one');
      expect(
        await store.replace('cas', 'one', 'two', const Duration(minutes: 1)),
        isTrue,
      );
      expect(await store.get('cas'), 'two');
      expect(await store.deleteIf('cas', 'one'), isFalse);
      expect(await store.get('cas'), 'two');
      expect(await store.deleteIf('cas', 'two'), isTrue);
      expect(await store.get('cas'), isNull);
      expect(await store.deleteIf('cas', 'two'), isFalse);
    });

    test('a lease expires, renews while held and frees only itself', () async {
      final lease = await StateLease.acquire(
        store,
        'lock',
        const Duration(milliseconds: 300),
      );
      expect(lease, isNotNull);
      expect(
        await StateLease.acquire(store, 'lock', const Duration(seconds: 1)),
        isNull,
      );
      // Renewed every third of its TTL: still held well past it.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(
        await StateLease.acquire(store, 'lock', const Duration(seconds: 1)),
        isNull,
      );
      await lease!.release();
      expect(await store.get('lock'), isNull);

      // A holder whose lease lapsed never releases its successor's.
      final lapsed = await StateLease.acquire(
        store,
        'lock2',
        const Duration(minutes: 1),
      );
      await store.set('lock2', 'successor', const Duration(minutes: 1));
      await lapsed!.release();
      expect(await store.get('lock2'), 'successor');
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
    test('never evicts live state: a full store refuses the write', () async {
      var now = DateTime.utc(2026, 11, 8);
      var full = 0;
      final store = MemoryStateStore(
        clock: () => now,
        maxEntries: 2,
        maxNonces: 1,
        onFull: () => full++,
      );
      addTearDown(store.close);
      await store.set('a', '1', const Duration(seconds: 10));
      await store.set('b', '2', const Duration(minutes: 10));
      await expectLater(
        store.set('c', '3', const Duration(minutes: 10)),
        throwsA(isA<StateStoreUnavailable>()),
      );
      expect(full, 1);
      expect(await store.get('a'), '1', reason: 'live state is kept');
      expect(await store.get('b'), '2');
      // Overwriting an existing key is not a new entry.
      await store.set('b', '2b', const Duration(minutes: 10));

      // Nonces have their own room: the full store still takes one.
      expect(
        await store.putIfAbsent('nonce:i:n1', '1', const Duration(minutes: 5)),
        isTrue,
      );
      await expectLater(
        store.putIfAbsent('nonce:i:n2', '1', const Duration(minutes: 5)),
        throwsA(isA<StateStoreUnavailable>()),
      );

      // Expired entries are dropped to make room.
      now = now.add(const Duration(seconds: 11));
      await store.set('c', '3', const Duration(minutes: 10));
      expect(await store.get('a'), isNull);
      expect(await store.get('c'), '3');
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

    test('the probe needs GETDEL (Redis 6.2+) and AUTH', () async {
      final store = RedisStateStore(
        Uri.parse('redis://127.0.0.1:${redis.port}'),
      );
      addTearDown(store.close);
      await store.probe();
      redis.oldServer = true;
      await expectLater(store.probe(), throwsA(isA<StateStoreUnavailable>()));
      await expectLater(store.take('t'), throwsA(isA<StateStoreUnavailable>()));
    });

    test('an old Redis fails the boot with exit-78 config error', () async {
      redis.oldServer = true;
      final identity = await ConnectInstallIdentity.derive(
        masterSeed: seed(1),
        connectUrl: testPublicUrl,
      );
      await expectLater(
        Harness.start(
          allowed: [identity],
          env: {
            'CONNECT_STATE': 'redis',
            'CONNECT_REDIS_URL': 'redis://127.0.0.1:${redis.port}',
          },
        ),
        throwsA(
          isA<ConnectConfigException>().having(
            (e) => e.message,
            'message',
            contains('Redis 6.2'),
          ),
        ),
      );
    });

    test('a Redis that may evict keys fails the boot', () async {
      final identity = await ConnectInstallIdentity.derive(
        masterSeed: seed(1),
        connectUrl: testPublicUrl,
      );
      for (final policy in ['allkeys-lru', 'volatile-ttl', 'allkeys-random']) {
        redis.evictionPolicy = policy;
        await expectLater(
          Harness.start(
            allowed: [identity],
            env: {
              'CONNECT_STATE': 'redis',
              'CONNECT_REDIS_URL': 'redis://127.0.0.1:${redis.port}',
            },
          ),
          throwsA(
            isA<ConnectConfigException>().having(
              (e) => e.message,
              'message',
              allOf(contains(policy), contains('noeviction')),
            ),
          ),
        );
      }
      redis.evictionPolicy = 'noeviction';
      final harness = await Harness.start(
        allowed: [identity],
        env: {
          'CONNECT_STATE': 'redis',
          'CONNECT_REDIS_URL': 'redis://127.0.0.1:${redis.port}',
        },
      );
      await harness.close();
      expect(redis.commands, contains(equals(['INFO', 'memory'])));
    });

    test(
      '/readyz rechecks the eviction policy and logs each change once',
      () async {
        final identity = await ConnectInstallIdentity.derive(
          masterSeed: seed(1),
          connectUrl: testPublicUrl,
        );
        var now = DateTime.utc(2026, 11, 10);
        final harness = await Harness.start(
          allowed: [identity],
          env: {
            'CONNECT_STATE': 'redis',
            'CONNECT_REDIS_URL': 'redis://127.0.0.1:${redis.port}',
          },
          clock: () => now,
        );
        addTearDown(harness.close);
        Future<int> ready() async {
          now = now.add(const Duration(seconds: 6));
          return (await harness.raw('GET', '/readyz')).status;
        }

        List<Map<String, Object?>> changes() => [
          for (final line in harness.logs)
            if (jsonDecode(line) case final Map<String, Object?> json
                when json['event'] == 'readyz.eviction_policy')
              json,
        ];
        expect(await ready(), 200);
        redis.evictionPolicy = 'allkeys-lru';
        expect(await ready(), 503);
        expect(await ready(), 503);
        redis.evictionPolicy = 'noeviction';
        expect(await ready(), 200);
        expect(await ready(), 200);
        expect(changes().map((l) => '${l['reason']}/${l['level']}'), [
          'allkeys_lru/error',
          'noeviction/info',
        ]);
      },
    );

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

    test('a reload that does not parse keeps the last good ring', () async {
      var ring = _keyring([('k1', 1)]);
      var now = DateTime.utc(2026, 11, 8);
      var failures = 0;
      final source = SecretSource.fromEnvironment(
        {'K_FILE': '/run/keys'},
        'K',
        readFile: (_) => ring,
        clock: () => now,
      )!;
      final cipher = LocalAeadSealCipher(
        source,
        onReloadFailed: () => failures++,
      );
      final sealed = await cipher.encrypt([1], [2]);
      ring = 'k2:not-a-key';
      now = now.add(const Duration(seconds: 31));
      expect((await cipher.encrypt([1], [2])).keyId, 'k1');
      expect(await cipher.decrypt(sealed, [2]), [1]);
      expect(failures, 1, reason: 'once per bad value');
    });
  });

  group('CredentialSealer', () {
    final cipher = LocalAeadSealCipher(
      SecretSource.value('K', _keyring([('k1', 1)])),
    );
    final sealer = CredentialSealer(
      connectOrigin: 'https://connect.test',
      cipher: cipher,
      log: ConnectLog(sink: (_) {}),
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
          log: ConnectLog(sink: (_) {}),
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

    test('a refused seal is logged by reason, never by value', () async {
      final sealerLogs = <String>[];
      final sealer = CredentialSealer(
        connectOrigin: 'https://connect.test',
        cipher: cipher,
        log: ConnectLog(sink: sealerLogs.add),
      );
      final seal = await sealOne();
      await denied(
        sealer.open(
          seal,
          provider: ConnectProvider.github,
          binding: const SealBinding(installId: 'x', workspaceId: 'ws9'),
        ),
      );
      await denied(
        sealer.open('v1.junk', provider: ConnectProvider.slack, binding: mine),
      );
      final lines = sealerLogs.map(jsonDecode).cast<Map<String, Object?>>();
      expect(
        lines.map((l) => '${l['event']} ${l['provider']} ${l['reason']}'),
        containsAll([
          'seal.refused github decrypt',
          'seal.refused slack malformed',
        ]),
      );
      expect(sealerLogs.join(), isNot(contains(seal)));
    });

    test('encryption is retried before it fails, and logged', () async {
      final logs = <String>[];
      var failuresLeft = 2;
      final flaky = _FlakyCipher(cipher, () => failuresLeft-- > 0);
      final retrying = CredentialSealer(
        connectOrigin: 'https://connect.test',
        cipher: flaky,
        log: ConnectLog(sink: logs.add),
        retryDelays: const [Duration.zero, Duration.zero],
      );
      Future<String> once() => retrying.seal(
        provider: ConnectProvider.github,
        accountId: '1001',
        appId: '4242',
        generation: 2,
        binding: mine,
        payload: {'refresh': 'ghr_x'},
      );
      expect(await once(), startsWith('v1.'));
      expect(logs, isEmpty);
      failuresLeft = 3;
      await expectLater(once(), throwsA(isA<StateError>()));
      final line = jsonDecode(logs.single) as Map<String, Object?>;
      expect(line['event'], 'seal.encrypt_failed');
      expect(line['level'], 'error');
      expect(line['exception'], 'StateError');
      expect(line['count'], 3);
    });

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
      botUserId: 'U0BOT',
      appId: 'A0TEST',
      boundAt: DateTime.utc(2026, 11, 8),
    );

    test('persists across reopen, privately', () async {
      final store = await FileBindingStore.open(dir.path);
      expect((await store.bindSlack(team('install-a'))).installId, 'install-a');
      await store.close();

      final reopened = await FileBindingStore.open(dir.path);
      expect((await reopened.slack('T0TEAM'))!.installId, 'install-a');
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

    test('keeps the bot user id', () async {
      final store = await FileBindingStore.open(dir.path);
      await store.bindSlack(
        SlackTeamBinding(
          teamId: 'T0TEAM',
          installId: 'install-a',
          botId: 'B0BOT',
          botUserId: 'U0BOT',
          appId: 'A0TEST',
          boundAt: DateTime.utc(2026, 11, 8),
        ),
      );
      await store.close();
      final reopened = await FileBindingStore.open(dir.path);
      expect((await reopened.slack('T0TEAM'))!.botUserId, 'U0BOT');
      await reopened.close();
    });

    test('a write that fails leaves the bindings as they were', () async {
      final store = await FileBindingStore.open(dir.path);
      // The directory goes read-only: the next write cannot land.
      await Process.run('chmod', ['500', dir.path]);
      addTearDown(() => Process.run('chmod', ['700', dir.path]));
      await expectLater(
        store.bindSlack(team('install-a')),
        throwsA(isA<BindingStoreUnavailable>()),
      );
      expect(await store.slack('T0TEAM'), isNull);
      await Process.run('chmod', ['700', dir.path]);
      await store.close();
    }, skip: Platform.isWindows ? 'POSIX modes only' : false);

    test('a file in an older shape refuses to open', () async {
      for (final file in [
        // A top-level key this version does not write.
        {'v': 1, 'slack': <String, Object?>{}, 'retired': <Object?>[]},
        // No retired set.
        {'slack': <String, Object?>{}},
        // A retired entry that is not an install id.
        {
          'slack': <String, Object?>{},
          'retired': [7],
        },
        // A Slack binding recorded without the bot's user id.
        {
          'slack': {
            'T0TEAM': {
              'install_id': 'install-a',
              'bot_id': 'B0BOT',
              'app_id': 'A0TEST',
              'bound_at': '2026-11-08T00:00:00Z',
            },
          },
          'retired': <Object?>[],
        },
      ]) {
        File('${dir.path}/bindings.json').writeAsStringSync(jsonEncode(file));
        await expectLater(
          FileBindingStore.open(dir.path),
          throwsA(
            isA<BindingStoreUnavailable>().having(
              (e) => e.reason,
              'reason',
              'bindings.json is corrupt',
            ),
          ),
        );
      }
    });

    test('writes only the slack section and the retired set', () async {
      final store = await FileBindingStore.open(dir.path);
      await store.bindSlack(team('install-a'));
      await store.close();
      final written =
          jsonDecode(File('${dir.path}/bindings.json').readAsStringSync())
              as Map<String, Object?>;
      expect(written.keys, ['slack', 'retired']);
    });

    test('a retired install stays retired across reopen', () async {
      final store = await FileBindingStore.open(dir.path);
      expect(await store.isRetired('install-a'), isFalse);
      expect(await store.retireInstall('install-a'), isTrue);
      expect(await store.retireInstall('install-a'), isTrue);
      expect(await store.isRetired('install-a'), isTrue);
      expect(await store.isRetired('install-b'), isFalse);
      await store.close();
      final reopened = await FileBindingStore.open(dir.path);
      expect(await reopened.isRetired('install-a'), isTrue);
      await reopened.close();
    });

    test('a full retired set refuses one more, and keeps the rest', () async {
      File('${dir.path}/bindings.json').writeAsStringSync(
        jsonEncode({
          'slack': <String, Object?>{},
          'retired': [for (var i = 0; i < maxRetiredInstalls; i++) 'i$i'],
        }),
      );
      final store = await FileBindingStore.open(dir.path);
      expect(await store.retireInstall('install-a'), isFalse);
      expect(await store.isRetired('install-a'), isFalse);
      expect(await store.isRetired('i0'), isTrue);
      expect(await store.retireInstall('i0'), isTrue, reason: 'already');
      await store.close();
    });

    test('a second Connect on the same directory refuses to start', () async {
      final first = await FileBindingStore.open(dir.path);
      await expectLater(
        FileBindingStore.open(dir.path),
        throwsA(isA<BindingStoreUnavailable>()),
      );
      await first.close();
      // Closing releases the directory.
      final again = await FileBindingStore.open(dir.path);
      await again.close();
    });

    test('the lock holds against another process', () async {
      final script = File('${dir.path}/hold_lock.dart')
        ..writeAsStringSync('''
import 'dart:io';

Future<void> main(List<String> args) async {
  final file = await File(args.first).open(mode: FileMode.append);
  await file.lock(FileLock.exclusive);
  stdout.writeln('locked');
  await stdin.first;
}
''');
      final holder = await Process.start(Platform.resolvedExecutable, [
        script.path,
        '${dir.path}${Platform.pathSeparator}bindings.lock',
      ]);
      addTearDown(holder.kill);
      final lines = holder.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      expect(await lines.first, 'locked');
      await expectLater(
        Harness.start(
          allowed: [
            await ConnectInstallIdentity.derive(
              masterSeed: seed(1),
              connectUrl: testPublicUrl,
            ),
          ],
          env: {'CONNECT_DATA_DIR': dir.path},
        ),
        throwsA(
          isA<ConnectConfigException>().having(
            (e) => e.message,
            'message',
            contains('another Connect holds this directory'),
          ),
        ),
      );
      holder.stdin.writeln();
      await holder.exitCode;
    });

    test('a corrupt file refuses to open', () async {
      File('${dir.path}/bindings.json').writeAsStringSync('{nope');
      await expectLater(
        FileBindingStore.open(dir.path),
        throwsA(isA<BindingStoreUnavailable>()),
      );
    });
  });

  group('writePrivateFile', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('cc_priv'));
    tearDown(() => dir.delete(recursive: true));

    test(
      'creates the file owner-only, replaces atomically and leaves no temp',
      () async {
        final path = '${dir.path}/secret';
        await writePrivateFile(path, utf8.encode('one'));
        await writePrivateFile(path, utf8.encode('two'));
        expect(File(path).readAsStringSync(), 'two');
        expect(File(path).statSync().mode & 0x1ff, 0x180, reason: '0600');
        expect(dir.listSync().map((e) => e.path), [path]);
        await expectLater(
          writePrivateFile(path, utf8.encode('three'), overwrite: false),
          throwsA(isA<FileSystemException>()),
        );
        expect(File(path).readAsStringSync(), 'two');
      },
      skip: Platform.isWindows ? 'POSIX modes only' : false,
    );
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
        botUserId: 'U0BOT',
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

  group('CachedBindingStore retired set', () {
    test('a retirement is remembered for good; a miss only briefly', () async {
      final dir = await Directory.systemTemp.createTemp('cc_bind');
      addTearDown(() => dir.delete(recursive: true));
      var now = DateTime.utc(2026, 11, 8);
      final inner = await FileBindingStore.open(dir.path);
      final cached = CachedBindingStore(inner, clock: () => now);
      expect(await cached.isRetired('install-a'), isFalse);
      // Retired through another instance.
      await inner.retireInstall('install-a');
      now = now.add(const Duration(seconds: 31));
      expect(await cached.isRetired('install-a'), isTrue);
      expect(await cached.retireInstall('install-b'), isTrue);
      expect(await cached.isRetired('install-b'), isTrue);
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

    test('reads with the metadata-server token', () async {
      final upstream = FakeUpstream()
        ..json('GET', '$docs/cc_connect_slack/T0TEAM', 404, {});
      final store = open(upstream);
      expect(await store.slack('T0TEAM'), isNull);
      expect(
        upstream.calls.single.request.headers['authorization'],
        'Bearer ya29.metadata',
      );
    });

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
            'bot_user_id': {'stringValue': 'U0BOT'},
            'app_id': {'stringValue': 'A0TEST'},
          },
        });
      final store = open(upstream);
      final winner = await store.bindSlack(
        SlackTeamBinding(
          teamId: 'T0TEAM',
          installId: 'install-b',
          botId: 'B0BOT',
          botUserId: 'U0BOT2',
          appId: 'A0TEST',
          boundAt: DateTime.utc(2026, 11, 8),
        ),
      );
      expect(winner.installId, 'install-a');
      final create = upstream.callsTo('POST', '$docs:commit').single.json;
      expect(jsonEncode(create), contains('"exists":false'));
    });

    test('a document without bot_user_id is refused as corrupt', () async {
      final upstream = FakeUpstream()
        ..json('GET', '$docs/cc_connect_slack/T0TEAM', 200, {
          'updateTime': '2026-11-08T00:00:00.000001Z',
          'fields': {
            'install_id': {'stringValue': 'install-a'},
            'bot_id': {'stringValue': 'B0BOT'},
            'app_id': {'stringValue': 'A0TEST'},
          },
        });
      await expectLater(
        open(upstream).slack('T0TEAM'),
        throwsA(isA<BindingStoreUnavailable>()),
      );
    });

    test('the probe reads a sentinel document', () async {
      final upstream = FakeUpstream()
        ..json('GET', '$docs/cc_connect_slack/_probe', 404, {});
      await open(upstream).probe();
      final denied = FakeUpstream()
        ..json('GET', '$docs/cc_connect_slack/_probe', 403, {});
      await expectLater(
        open(denied).probe(),
        throwsA(isA<BindingStoreUnavailable>()),
      );
    });

    test(
      'retire creates the document and counts it under preconditions',
      () async {
        final upstream = FakeUpstream()
          ..json('GET', '$docs/cc_connect_retired/install-a', 404, {})
          ..json('GET', '$docs/cc_connect_retired_count/count', 200, {
            'updateTime': '2026-11-08T00:00:00.000001Z',
            'fields': {
              'count': {'integerValue': '4'},
            },
          })
          ..json('POST', '$docs:commit', 200, {});
        expect(await open(upstream).retireInstall('install-a'), isTrue);
        final commit = jsonEncode(
          upstream.callsTo('POST', '$docs:commit').single.json,
        );
        expect(commit, contains('cc_connect_retired/install-a'));
        expect(commit, contains('"exists":false'));
        expect(commit, contains('"integerValue":"5"'));
        expect(commit, contains('"updateTime":"2026-11-08T00:00:00.000001Z"'));
      },
    );

    test(
      'retire of a retired install commits nothing; a full set refuses',
      () async {
        final retired = FakeUpstream()
          ..json('GET', '$docs/cc_connect_retired/install-a', 200, {
            'updateTime': '2026-11-08T00:00:00.000001Z',
            'fields': <String, Object?>{},
          });
        expect(await open(retired).isRetired('install-a'), isTrue);
        expect(await open(retired).retireInstall('install-a'), isTrue);
        expect(retired.callsTo('POST', '$docs:commit'), isEmpty);
        final full = FakeUpstream()
          ..json('GET', '$docs/cc_connect_retired/install-b', 404, {})
          ..json('GET', '$docs/cc_connect_retired_count/count', 200, {
            'updateTime': '2026-11-08T00:00:00.000001Z',
            'fields': {
              'count': {'integerValue': '$maxRetiredInstalls'},
            },
          });
        expect(await open(full).retireInstall('install-b'), isFalse);
        expect(full.callsTo('POST', '$docs:commit'), isEmpty);
      },
    );

    test('an install\'s teams come from one install_id query', () async {
      final upstream = FakeUpstream()
        ..json('POST', '$docs:runQuery', 200, [
          {
            'document': {'name': '$docs/cc_connect_slack/T0ONE'},
          },
          {
            'document': {'name': '$docs/cc_connect_slack/T0TWO'},
          },
          {'readTime': '2026-11-10T00:00:00Z'},
        ]);
      expect(await open(upstream).slackTeamsOf('install-a'), [
        'T0ONE',
        'T0TWO',
      ]);
      final query = jsonEncode(
        upstream.callsTo('POST', '$docs:runQuery').single.json,
      );
      expect(query, contains('"fieldPath":"install_id"'));
      expect(query, contains('"stringValue":"install-a"'));
      final broken = FakeUpstream()
        ..json('POST', '$docs:runQuery', 200, {'not': 'a list'});
      await expectLater(
        open(broken).slackTeamsOf('install-a'),
        throwsA(isA<BindingStoreUnavailable>()),
      );
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
    List<Map<String, Object?>> parsed(List<String> lines) => [
      for (final line in lines) jsonDecode(line) as Map<String, Object?>,
    ];

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
      final line = parsed(lines).first;
      expect(line['event'], 'test.event');
      expect(line['message'], 'test.event');
      expect(line['level'], 'info');
      expect(line['install'], tag);
      expect(line['status'], 200);
      expect(line['route'], '/v1/config');
      expect(line.containsKey('token'), isFalse);
      expect(lines.join(), isNot(contains('<html>')));
      expect(lines.join(), isNot(contains('ghu_secret')));
    });

    test('a value carrying a GitHub token prefix is dropped unwritten', () {
      final lines = <String>[];
      final log = ConnectLog(sink: lines.add);
      final values = [
        for (final prefix in ['ghp', 'gho', 'ghu', 'ghs', 'ghr'])
          '${prefix}_${'A' * 36}',
        'github_pat_${'B' * 30}',
        'x:ghu_${'C' * 36}',
      ];
      for (final value in values) {
        log.event('test.event', {'reason': value});
      }
      log.event('test.event', {'reason': 'github_app_write_scope'});
      final out = lines.join();
      for (final value in values) {
        expect(out, isNot(contains(value)));
      }
      final all = parsed(lines);
      expect(
        all
            .where((l) => l['event'] == 'log.field_dropped')
            .map((l) => l['field']),
        everyElement('reason'),
      );
      expect(
        all.where((l) => l['reason'] == 'github_app_write_scope'),
        hasLength(1),
      );
    });

    test('a dropped field or event is never silent', () {
      final lines = <String>[];
      final log = ConnectLog(sink: lines.add);
      log.event('test.event', {'token': 'x', 'reason': 'a b'});
      log.event('Bad Name!');
      final dropped = parsed(lines)
          .where((l) => l['event'] == 'log.field_dropped')
          .map((l) => '${l['source_event']}/${l['field']}/${l['level']}');
      expect(dropped, ['test.event/token/warn', 'test.event/reason/warn']);
      expect(parsed(lines).last['event'], 'log.event_dropped');
    });

    test('lines in a request scope carry its id, route and install', () {
      final lines = <String>[];
      final log = ConnectLog(sink: lines.add);
      final scope = ConnectRequestScope()..route = '/v1/config';
      expect(scope.requestId, matches(RegExp(r'^[A-Za-z0-9_-]{22}$')));
      scope.run(() {
        log.event('one');
        scope.install = 'abcdef0123456789';
        log.event('two', {'route': '/own'});
      });
      log.event('outside');
      final [one, two, outside] = parsed(lines);
      expect(one['request_id'], scope.requestId);
      expect(one['route'], '/v1/config');
      expect(one.containsKey('install'), isFalse);
      expect(two['install'], 'abcdef0123456789');
      expect(two['route'], '/own');
      expect(outside.containsKey('request_id'), isFalse);
    });

    test('sampled writes once per key per minute, then the count', () {
      final lines = <String>[];
      var now = DateTime.utc(2026, 11, 8);
      final log = ConnectLog(sink: lines.add, clock: () => now);
      for (var i = 0; i < 4; i++) {
        log.sampled('auth.refused', 'k1', {'reason': 'digest'});
      }
      log.sampled('auth.refused', 'k2', {'reason': 'digest'});
      expect(lines, hasLength(2));
      now = now.add(const Duration(minutes: 1));
      log.sampled('auth.refused', 'k1', {'reason': 'digest'});
      final last = parsed(lines).last;
      expect(last['suppressed'], 3);
      expect(last['level'], 'warn');
    });

    test('hashed_token is GitHub audit-log base64 and nothing else', () {
      // echo -n abc | openssl dgst -sha256 -binary | base64
      expect(
        githubHashedToken('abc'),
        'ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=',
      );
      final lines = <String>[];
      final log = ConnectLog(sink: lines.add);
      log.event('a', {'hashed_token': githubHashedToken('ghu_x')});
      log.event('b', {'hashed_token': 'ghu_rawtokenvalue'});
      log.event('c', {'reason': githubHashedToken('ghu_x')});
      final lines0 = parsed(lines);
      expect(lines0.first['hashed_token'], githubHashedToken('ghu_x'));
      expect(lines.join(), isNot(contains('ghu_rawtokenvalue')));
      expect(
        lines0
            .where((l) => l['event'] == 'log.field_dropped')
            .map((l) => l['field']),
        ['hashed_token', 'reason'],
      );
    });

    test('only error lines reach the reporter', () {
      final failures = <ConnectFailure>[];
      final log = ConnectLog(sink: (_) {})..reporter = failures.add;
      log.event('fine');
      log.event('meh', const {}, ConnectLogLevel.warn);
      log.event('bad', {'error': 'x'}, ConnectLogLevel.error);
      log.exception(
        'http.error',
        StateError('secret-looking'),
        StackTrace.current,
      );
      expect(failures.map((f) => f.type), ['bad', 'StateError']);
      expect(failures.first.error, 'x');
      expect(failures.last.stack, isNotNull);
    });

    test('truncateIp keeps a /24 or /48', () {
      expect(truncateIp('203.0.113.77'), '203.0.113.0/24');
      expect(truncateIp('2001:db8:1234:5678::1'), '2001:db8:1234::/48');
      expect(truncateIp('2001:db8::1'), '2001:db8:0::/48');
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
