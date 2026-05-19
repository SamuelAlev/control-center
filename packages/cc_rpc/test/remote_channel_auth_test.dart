import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Unit tests for `authenticateRemoteChannel` / `authenticateRemoteClient` —
/// the client half of the mutual PSK handshake. A hand-driven peer (the server
/// side of an [InProcessRpcChannel] pair) reproduces each protocol branch so
/// the success path, the auth-denied / bad-proof failures, the TOFU pinning
/// happy path, and the identity-mismatch hard stops are all exercised without a
/// real socket.
void main() {
  const psk = 'shared-pre-shared-key';

  /// Drives the server side of the handshake, parameterised so every protocol
  /// branch can be staged. Reads the client's `auth` frame (to capture its
  /// fresh nonce), then answers per the toggles. Each toggled-off step simply
  /// never sends the corresponding frame, exercising the client's timeouts.
  Future<void> runServer(
    InProcessRpcChannel server, {
    required String serverSeed,
    bool deny = false,
    // When non-null, the server's mutual proof is wrong (bad PSK on the server).
    String? proofOverride,
    bool omitIdentity = false,
    bool corruptSignature = false,
    bool omitApproved = false,
    bool neverRespond = false,
  }) async {
    try {
      final auth = await server.incoming
          .firstWhere((f) => f['type'] == 'auth')
          .timeout(const Duration(seconds: 5));
      final nonce = auth['nonce'] as String;

      if (neverRespond) {
        return;
      }
      if (deny) {
        await server.send({'type': 'auth_denied'});
        return;
      }

      final response =
          proofOverride ??
          RemoteControlCrypto.respondToChallenge(
            nonce: nonce,
            psk: psk,
            localFingerprint: '',
            remoteFingerprint: '',
          );
      final pub = await ServerIdentityCrypto.publicKeyFromSeed(serverSeed);
      final sig = corruptSignature
          ? 'not-a-valid-signature'
          : await ServerIdentityCrypto.signChallenge(
              seedB64: serverSeed,
              nonce: nonce,
            );
      await server.send({
        'type': 'auth_response',
        'response': response,
        if (!omitIdentity) 'sid_pub': pub,
        if (!omitIdentity) 'sid_sig': sig,
      });
      if (!omitApproved) {
        await server.send({'type': 'approved'});
      }
    } catch (_) {
      // The client may close the channel mid-handshake on a failure path; that
      // is expected and the matching assertion lives in the calling test.
    }
  }

  group('authenticateRemoteChannel success', () {
    test(
      'verifies the mutual PSK proof and returns the open channel',
      () async {
        final seed = await ServerIdentityCrypto.generateSeed();
        final expectedFp = ServerIdentityCrypto.fingerprintOf(
          await ServerIdentityCrypto.publicKeyFromSeed(seed),
        );
        final (server, client) = InProcessRpcChannel.pair();

        final handshake = runServer(server, serverSeed: seed);
        final authed = await authenticateRemoteChannel(
          channel: client,
          deviceId: 'dev-1',
          psk: psk,
          timeout: const Duration(seconds: 5),
        );

        expect(authed.channel.isOpen, isTrue);
        expect(authed.serverFingerprint, expectedFp);

        await handshake;
        await client.close();
      },
    );

    test(
      'pins the server fingerprint on first connect (TOFU, no pin passed)',
      () async {
        final seed = await ServerIdentityCrypto.generateSeed();
        final expectedFp = ServerIdentityCrypto.fingerprintOf(
          await ServerIdentityCrypto.publicKeyFromSeed(seed),
        );
        final (server, client) = InProcessRpcChannel.pair();

        final handshake = runServer(server, serverSeed: seed);
        // No pinnedFingerprint → TOFU: the verified fingerprint is returned for
        // the caller to pin.
        final authed = await authenticateRemoteChannel(
          channel: client,
          deviceId: 'dev-1',
          psk: psk,
          timeout: const Duration(seconds: 5),
        );
        expect(authed.serverFingerprint, expectedFp);

        await handshake;
        await client.close();
      },
    );

    test('accepts a matching pinned fingerprint', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final pin = ServerIdentityCrypto.fingerprintOf(
        await ServerIdentityCrypto.publicKeyFromSeed(seed),
      );
      final (server, client) = InProcessRpcChannel.pair();

      final handshake = runServer(server, serverSeed: seed);
      final authed = await authenticateRemoteChannel(
        channel: client,
        deviceId: 'dev-1',
        psk: psk,
        pinnedFingerprint: pin,
        timeout: const Duration(seconds: 5),
      );
      expect(authed.serverFingerprint, pin);

      await handshake;
      await client.close();
    });
  });

  group('authenticateRemoteChannel hard failures', () {
    test(
      'auth_denied is an AuthRejectedException (wrong device credential)',
      () async {
        final seed = await ServerIdentityCrypto.generateSeed();
        final (server, client) = InProcessRpcChannel.pair();

        final handshake = runServer(server, serverSeed: seed, deny: true);
        await expectLater(
          authenticateRemoteChannel(
            channel: client,
            deviceId: 'dev-1',
            psk: psk,
            timeout: const Duration(seconds: 5),
          ),
          throwsA(isA<AuthRejectedException>()),
        );

        await handshake;
        await client.close();
      },
    );

    test(
      'a wrong mutual proof is an AuthRejectedException (proof mismatch)',
      () async {
        final seed = await ServerIdentityCrypto.generateSeed();
        final (server, client) = InProcessRpcChannel.pair();

        final handshake = runServer(
          server,
          serverSeed: seed,
          proofOverride: 'definitely-not-the-right-proof',
        );
        await expectLater(
          authenticateRemoteChannel(
            channel: client,
            deviceId: 'dev-1',
            psk: psk,
            timeout: const Duration(seconds: 5),
          ),
          throwsA(isA<AuthRejectedException>()),
        );

        await handshake;
        await client.close();
      },
    );

    test('a pinned fingerprint that does not match throws '
        'ServerIdentityMismatchException (no "continue anyway")', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final (server, client) = InProcessRpcChannel.pair();

      final handshake = runServer(server, serverSeed: seed);
      await expectLater(
        authenticateRemoteChannel(
          channel: client,
          deviceId: 'dev-1',
          psk: psk,
          pinnedFingerprint: 'a-completely-different-fingerprint',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<ServerIdentityMismatchException>()),
      );

      await handshake;
      await client.close();
    });

    test('a pinned client that gets no server identity throws '
        'ServerIdentityMismatchException', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final (server, client) = InProcessRpcChannel.pair();

      final handshake = runServer(server, serverSeed: seed, omitIdentity: true);
      await expectLater(
        authenticateRemoteChannel(
          channel: client,
          deviceId: 'dev-1',
          psk: psk,
          pinnedFingerprint: 'some-pin',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<ServerIdentityMismatchException>()),
      );

      await handshake;
      await client.close();
    });

    test(
      'an invalid identity signature yields an empty fingerprint (TOFU)',
      () async {
        // No pin: an unverifiable signature means no identity is pinned, but the
        // handshake still succeeds (the proof verified) with an empty fingerprint.
        final seed = await ServerIdentityCrypto.generateSeed();
        final (server, client) = InProcessRpcChannel.pair();

        final handshake = runServer(
          server,
          serverSeed: seed,
          corruptSignature: true,
        );
        final authed = await authenticateRemoteChannel(
          channel: client,
          deviceId: 'dev-1',
          psk: psk,
          timeout: const Duration(seconds: 5),
        );
        expect(authed.serverFingerprint, isEmpty);

        await handshake;
        await client.close();
      },
    );

    test('timing out waiting for auth_response is a StateError', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final (server, client) = InProcessRpcChannel.pair();

      final handshake = runServer(server, serverSeed: seed, neverRespond: true);
      await expectLater(
        authenticateRemoteChannel(
          channel: client,
          deviceId: 'dev-1',
          psk: psk,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<StateError>()),
      );

      await handshake;
      await client.close();
    });

    test('timing out waiting for `approved` is a StateError', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final (server, client) = InProcessRpcChannel.pair();

      final handshake = runServer(server, serverSeed: seed, omitApproved: true);
      await expectLater(
        authenticateRemoteChannel(
          channel: client,
          deviceId: 'dev-1',
          psk: psk,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<StateError>()),
      );

      await handshake;
      await client.close();
    });
  });

  group('authenticateRemoteClient', () {
    test('authenticates, then initializes the RPC client', () async {
      final seed = await ServerIdentityCrypto.generateSeed();
      final expectedFp = ServerIdentityCrypto.fingerprintOf(
        await ServerIdentityCrypto.publicKeyFromSeed(seed),
      );
      final (server, client) = InProcessRpcChannel.pair();

      // One long-lived subscription routes every inbound frame, so the
      // `initialize` request (sent right after `approved`) is never dropped by
      // the broadcast stream.
      final sub = server.incoming.listen((frame) async {
        if (frame['type'] == 'auth') {
          final nonce = frame['nonce'] as String;
          final pub = await ServerIdentityCrypto.publicKeyFromSeed(seed);
          final sig = await ServerIdentityCrypto.signChallenge(
            seedB64: seed,
            nonce: nonce,
          );
          await server.send({
            'type': 'auth_response',
            'response': RemoteControlCrypto.respondToChallenge(
              nonce: nonce,
              psk: psk,
              localFingerprint: '',
              remoteFingerprint: '',
            ),
            'sid_pub': pub,
            'sid_sig': sig,
          });
          await server.send({'type': 'approved'});
          return;
        }
        if (frame['method'] == 'initialize') {
          await server.send({
            'jsonrpc': '2.0',
            'id': frame['id'],
            'result': {
              'capabilities': {'subscriptions': true},
            },
          });
        }
      });

      final result = await authenticateRemoteClient(
        channel: client,
        deviceId: 'dev-1',
        psk: psk,
        timeout: const Duration(seconds: 5),
      );
      expect(result.serverFingerprint, expectedFp);
      expect(result.client.isOpen, isTrue);

      await result.client.close();
      await sub.cancel();
      await client.close();
    });
  });
}
