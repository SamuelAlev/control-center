import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_rpc/src/crypto/noise_session.dart';
import 'package:test/test.dart';

final _psk = base64Url.encode(List<int>.generate(32, (i) => i + 1));
final _otherPsk = base64Url.encode(List<int>.generate(32, (i) => i + 80));
const _deviceId = 'device-1';
const _timeout = Duration(seconds: 3);

typedef _Peer = ({InProcessRpcChannel raw, Future<SecureChannelConnection> session});

Future<_Peer> _peer({
  String? psk,
  String? publicKey,
  String? signingSeed,
  Future<String> Function(String)? signIdentity,
  Future<void> Function(SecureChannelConnection)? afterHandshake,
}) async {
  final seed = signingSeed ?? await ServerIdentityCrypto.generateSeed();
  final pub = publicKey ?? await ServerIdentityCrypto.publicKeyFromSeed(seed);
  final (server, client) = InProcessRpcChannel.pair();
  final session = acceptSecureChannel(
    channel: server,
    readPsk: (id) async => id == _deviceId ? (psk ?? _psk) : null,
    serverPublicKey: pub,
    signIdentity: signIdentity ?? (challenge) =>
        ServerIdentityCrypto.signChallenge(seedB64: seed, nonce: challenge),
    timeout: _timeout,
  ).then((connection) async {
    await afterHandshake?.call(connection);
    return connection;
  });
  // Attach an error observer immediately: client failures also terminate the
  // server's handshake, sometimes before the test awaits its future.
  unawaited(session.then<void>((_) {}, onError: (Object _) {}));
  return (raw: client, session: session);
}

void main() {
  test('first contact requires a valid signed identity and encrypted approval', () async {
    final seed = await ServerIdentityCrypto.generateSeed();
    final pub = await ServerIdentityCrypto.publicKeyFromSeed(seed);
    final peer = await _peer(signingSeed: seed, afterHandshake: (connection) =>
        connection.channel.send(const {'type': 'approved'}));
    final result = await authenticateRemoteChannel(
      channel: peer.raw,
      deviceId: _deviceId,
      psk: _psk,
      timeout: _timeout,
    );
    expect(result.serverFingerprint, ServerIdentityCrypto.fingerprintOf(pub));
    expect(result.channel.isOpen, isTrue);
    expect((await peer.session).channel.isOpen, isTrue);
    await result.channel.close();
  });

  test('matching pin succeeds; changing the server identity fails closed', () async {
    final seed = await ServerIdentityCrypto.generateSeed();
    final pin = ServerIdentityCrypto.fingerprintOf(
      await ServerIdentityCrypto.publicKeyFromSeed(seed),
    );
    final valid = await _peer(signingSeed: seed, afterHandshake: (connection) =>
        connection.channel.send(const {'type': 'approved'}));
    final result = await authenticateRemoteChannel(
      channel: valid.raw, deviceId: _deviceId, psk: _psk,
      pinnedFingerprint: pin, timeout: _timeout,
    );
    expect(result.serverFingerprint, pin);
    await result.channel.close();
    await valid.session;

    final impostor = await _peer(afterHandshake: (connection) =>
        connection.channel.send(const {'type': 'approved'}));
    await expectLater(
      authenticateRemoteChannel(
        channel: impostor.raw, deviceId: _deviceId, psk: _psk,
        pinnedFingerprint: pin, timeout: _timeout,
      ),
      throwsA(isA<ServerIdentityMismatchException>()),
    );
    expect(impostor.raw.isOpen, isFalse);
    await expectLater(impostor.session, throwsA(isA<SecureHandshakeException>()));
  });

  test('wrong PSK or unknown device cannot establish a session', () async {
    for (final (key, id) in [(_otherPsk, _deviceId), (_psk, 'not-paired')]) {
      final peer = await _peer();
      await expectLater(
        authenticateRemoteChannel(
          channel: peer.raw, deviceId: id, psk: key, timeout: _timeout,
        ),
        throwsA(isA<AuthRejectedException>()),
      );
      expect(peer.raw.isOpen, isFalse);
      await expectLater(peer.session, throwsA(isA<SecureHandshakeException>()));
    }
  });

  test('malformed pairing credentials fail without leaking their contents', () async {
    final (server, client) = InProcessRpcChannel.pair();
    final failure = authenticateRemoteChannel(
      channel: client, deviceId: _deviceId, psk: 'not-a-32-byte-key',
      timeout: _timeout,
    );
    await expectLater(failure, throwsA(isA<AuthRejectedException>().having(
      (error) => error.message, 'message', isNot(contains('not-a-32-byte-key')),
    )));
    expect(server.isOpen, isFalse);
  });

  test('missing or incorrect Ed25519 identity is rejected even with no pin', () async {
    final signer = await ServerIdentityCrypto.generateSeed();
    final unrelated = await ServerIdentityCrypto.generateSeed();
    for (final publicKey in [
      '',
      await ServerIdentityCrypto.publicKeyFromSeed(unrelated),
    ]) {
      final peer = await _peer(signingSeed: signer, publicKey: publicKey);
      await expectLater(
        authenticateRemoteChannel(
          channel: peer.raw, deviceId: _deviceId, psk: _psk,
          timeout: _timeout,
        ),
        throwsA(isA<AuthRejectedException>()),
      );
      expect(peer.raw.isOpen, isFalse);
      await expectLater(peer.session, throwsA(isA<SecureHandshakeException>()));
    }
  });

  test('a valid signature over the wrong transcript cannot be replayed', () async {
    final seed = await ServerIdentityCrypto.generateSeed();
    final wrongChallengeSignature = await ServerIdentityCrypto.signChallenge(
      seedB64: seed, nonce: 'cc-noise-identity-v1|stale-session',
    );
    final peer = await _peer(
      signingSeed: seed,
      signIdentity: (_) async => wrongChallengeSignature,
    );
    await expectLater(
      authenticateRemoteChannel(
        channel: peer.raw, deviceId: _deviceId, psk: _psk,
        timeout: _timeout,
      ),
      throwsA(isA<AuthRejectedException>()),
    );
    expect(peer.raw.isOpen, isFalse);
    await expectLater(peer.session, throwsA(isA<SecureHandshakeException>()));
  });

  test('plaintext legacy authentication and unsupported version cannot downgrade', () async {
    for (final input in [
      <String, dynamic>{'type': 'auth', 'nonce': 'legacy'},
      <String, dynamic>{'type': 'secure_hello', 'v': 0,
        'device_id': _deviceId, 'handshake': base64Url.encode(List<int>.filled(48, 1))},
    ]) {
      final seed = await ServerIdentityCrypto.generateSeed();
      final (server, client) = InProcessRpcChannel.pair();
      final accept = acceptSecureChannel(
        channel: server,
        readPsk: (_) async => _psk,
        serverPublicKey: await ServerIdentityCrypto.publicKeyFromSeed(seed),
        signIdentity: (challenge) => ServerIdentityCrypto.signChallenge(
          seedB64: seed, nonce: challenge,
        ),
        timeout: _timeout,
      );
      final denial = client.incoming.first;
      await client.send(input);
      expect((await denial)['type'], 'secure_denied');
      await expectLater(accept, throwsA(isA<SecureHandshakeException>()));
      expect(client.isOpen, isFalse);
    }
  });

  test('valid PSK cannot inject application data into the non-forward-secret first flight', () async {
    final seed = await ServerIdentityCrypto.generateSeed();
    final (server, client) = InProcessRpcChannel.pair();
    final accept = acceptSecureChannel(
      channel: server,
      readPsk: (_) async => _psk,
      serverPublicKey: await ServerIdentityCrypto.publicKeyFromSeed(seed),
      signIdentity: (challenge) => ServerIdentityCrypto.signChallenge(
        seedB64: seed, nonce: challenge,
      ),
      timeout: _timeout,
    );
    final handshake = NoisePskHandshake(
      initiator: true,
      psk: base64Url.decode(_psk),
      prologue: utf8.encode(jsonEncode([
        'control-center-secure-channel', SecureRpcChannel.version, _deviceId,
      ])),
    );
    final denial = client.incoming.first;
    await client.send({
      'type': 'secure_hello',
      'v': SecureRpcChannel.version,
      'device_id': _deviceId,
      'handshake': base64Url.encode(await handshake.writeMessage([1, 2, 3])),
    });
    expect((await denial)['type'], 'secure_denied');
    await expectLater(accept, throwsA(isA<SecureHandshakeException>()));
    handshake.destroy();
    expect(client.isOpen, isFalse);
  });

  test('missing encrypted approval rejects and closes the connection', () async {
    final peer = await _peer();
    final client = authenticateRemoteChannel(
      channel: peer.raw, deviceId: _deviceId, psk: _psk,
      timeout: const Duration(milliseconds: 150),
    );
    final server = await peer.session;
    await expectLater(client, throwsA(isA<TimeoutException>()));
    expect(server.channel.isOpen, isFalse);
  });

  test('authenticateRemoteClient initializes over the verified secure channel', () async {
    final peer = await _peer(afterHandshake: (connection) async {
      await connection.channel.send(const {'type': 'approved'});
      final request = await connection.channel.incoming.first;
      expect(request['method'], 'initialize');
      await connection.channel.send({
        'jsonrpc': '2.0', 'id': request['id'],
        'result': {'capabilities': {'subscriptions': true}},
      });
    });
    final result = await authenticateRemoteClient(
      channel: peer.raw, deviceId: _deviceId, psk: _psk,
      timeout: _timeout,
    );
    expect(result.client.isOpen, isTrue);
    expect(result.serverFingerprint, hasLength(64));
    await peer.session;
    await result.client.close();
  });
  test('initialize timeout closes the secure client and raw channel', () async {
    final initialized = Completer<void>();
    final peer = await _peer(afterHandshake: (connection) async {
      await connection.channel.send(const {'type': 'approved'});
      final request = await connection.channel.incoming.first;
      expect(request['method'], 'initialize');
      initialized.complete();
      // Deliberately withhold the response while leaving the server open.
    });
    final auth = authenticateRemoteClient(
      channel: peer.raw,
      deviceId: _deviceId,
      psk: _psk,
      timeout: _timeout,
      requestTimeout: const Duration(milliseconds: 100),
    );
    await initialized.future.timeout(_timeout);
    final server = await peer.session;
    await expectLater(auth, throwsA(isA<TimeoutException>()));
    expect(peer.raw.isOpen, isFalse);
    expect(server.channel.isOpen, isFalse);
  });
}
