import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/relay/relay_remote_transport.dart';
import 'package:cc_signaling_server/cc_signaling_server.dart';
import 'package:test/test.dart';

/// Captures the exact records handed to the broker without modifying routing.
/// A raw relay adapter is deliberately not encrypted; only the secure wrapper is.
final class _WireTap implements RemoteRpcChannelPort {
  _WireTap(this.raw);

  final RemoteRpcChannelPort raw;
  final sent = <Map<String, dynamic>>[];
  final received = <Map<String, dynamic>>[];

  @override
  Stream<Map<String, dynamic>> get incoming => raw.incoming.map((frame) {
    received.add(frame);
    return frame;
  });

  @override
  Stream<RemoteChannelState> get state => raw.state;

  @override
  bool get isOpen => raw.isOpen;

  @override
  Future<void> send(Map<String, dynamic> frame) {
    sent.add(frame);
    return raw.send(frame);
  }

  @override
  Future<void> close() => raw.close();
}

/// Real N-way signaling broker, real client/server relay adapters and the
/// production Noise handshake when a test expects confidentiality.
void main() {
  late SignalingServerHandle broker;
  late String url;
  late String seed;
  late String publicKey;

  final psk = base64Url.encode(List<int>.generate(32, (i) => i + 1));
  final psk2 = base64Url.encode(List<int>.generate(32, (i) => 255 - i));
  const room = 'server-room-code-abc';
  const deviceId = 'device-1';
  const ownerToken = 'owner-secret';

  String admissionHash(String credential) =>
      RemoteControlCrypto.relayAdmissionHash(
        RemoteControlCrypto.relayAdmissionToken(psk: credential, room: room),
      );

  setUp(() async {
    broker = await serveSignaling(host: 'localhost', port: 0);
    url = 'ws://localhost:${broker.port}/signal';
    seed = await ServerIdentityCrypto.generateSeed();
    publicKey = await ServerIdentityCrypto.publicKeyFromSeed(seed);
  });

  tearDown(() async => broker.close());

  Future<
    ({RelaySignalingChannel signaling, Future<RelayRemoteTransport> transport})
  > serverSide({List<String>? admit}) async {
    final signaling = await RelaySignalingChannel.joinAsOwner(
      signalingUrl: url,
      room: room,
      ownerToken: ownerToken,
      admit: admit ?? [admissionHash(psk)],
    );
    addTearDown(signaling.close);
    final transport = signaling.incoming
        .firstWhere((f) => f['type'] == 'signal' && f['kind'] == 'hello')
        .timeout(const Duration(seconds: 5))
        .then((hello) {
          final raw = RelayRemoteTransport(
            signaling: signaling,
            peer: hello['from'] as String,
          );
          addTearDown(raw.close);
          return raw;
        });
    return (signaling: signaling, transport: transport);
  }

  Future<
    ({
      RelayClientChannel client,
      RelayRemoteTransport transport,
      _WireTap clientWire,
      _WireTap serverWire,
      SecureChannelConnection clientSecure,
      SecureChannelConnection serverSecure,
    })
  > securePair() async {
    final server = await serverSide();
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    final transport = await server.transport;
    final clientWire = _WireTap(client);
    final serverWire = _WireTap(transport);
    final accepted = acceptSecureChannel(
      channel: serverWire,
      readPsk: (device) async => device == deviceId ? psk : null,
      serverPublicKey: publicKey,
      signIdentity: (challenge) =>
          ServerIdentityCrypto.signChallenge(seedB64: seed, nonce: challenge),
    );
    final connected = await connectSecureChannel(
      channel: clientWire,
      deviceId: deviceId,
      psk: psk,
      pinnedFingerprint: ServerIdentityCrypto.fingerprintOf(publicKey),
    );
    final serverSecure = await accepted;
    addTearDown(serverSecure.channel.close);
    addTearDown(connected.channel.close);
    return (
      client: client,
      transport: transport,
      clientWire: clientWire,
      serverWire: serverWire,
      clientSecure: connected,
      serverSecure: serverSecure,
    );
  }

  test('raw broker routes both directions and a peer leaving closes its '
      'own transport', () async {
    final server = await serverSide();
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    final transport = await server.transport;
    final serverGot = transport.incoming.first.timeout(
      const Duration(seconds: 5),
    );
    const request = {'jsonrpc': '2.0', 'id': 7, 'method': 'ping'};
    await client.send(request);
    expect(await serverGot, request);

    final clientGot = client.incoming.first.timeout(const Duration(seconds: 5));
    const response = {'jsonrpc': '2.0', 'id': 7, 'result': 'pong'};
    await transport.send(response);
    expect(await clientGot, response);

    final closed = transport.state
        .firstWhere((state) => state == RemoteChannelState.closed)
        .timeout(const Duration(seconds: 5));
    await client.close();
    await closed;
    expect(transport.isOpen, isFalse);
    expect(server.signaling.isOpen, isTrue,
        reason: 'a peer departure must not close the shared owner room');
  });

  test('peer EOF preserves a bounded record buffered before listening', () async {
    final server = await serverSide();
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    final transport = await server.transport;
    final closed = transport.state
        .firstWhere((state) => state == RemoteChannelState.closed)
        .timeout(const Duration(seconds: 5));
    const record = {'type': 'secure', 'c': 'queued-record'};
    await client.send(record);
    await client.close();
    await closed;
    expect(await transport.incoming.first.timeout(const Duration(seconds: 5)),
        record);
  });

  test('relay delivers a final encrypted response before server close', () async {
    final pair = await securePair();
    final received = pair.clientSecure.channel.incoming.toList();
    const response = {'id': 8, 'result': 'final relay reply'};
    await pair.serverSecure.channel.send(response);
    await pair.serverSecure.channel.close();
    expect(await received.timeout(const Duration(seconds: 5)), [response]);
    expect(pair.clientSecure.channel.failure, isNull);
  });

  test('secure handshake seals both directions and fragments large frames '
      'without leaking application text onto the broker wire', () async {
    final pair = await securePair();
    const secret = 'top-secret-ticket-title';
    final serverGot = pair.serverSecure.channel.incoming.first.timeout(
      const Duration(seconds: 10),
    );
    await pair.clientSecure.channel.send({
      'jsonrpc': '2.0',
      'id': 7,
      'method': 'tickets/read',
      'params': {'title': secret},
    });
    expect((await serverGot)['params'], {'title': secret});

    final clientGot = pair.clientSecure.channel.incoming.first.timeout(
      const Duration(seconds: 10),
    );
    await pair.serverSecure.channel.send({
      'jsonrpc': '2.0',
      'id': 7,
      'result': secret,
    });
    expect((await clientGot)['result'], secret);

    // A relay signal is capped at 64 KiB. The secure channel must split the
    // JSON into credited, bounded records, in either direction.
    final blob = 'x' * (300 * 1024);
    final largeOnServer = pair.serverSecure.channel.incoming.first.timeout(
      const Duration(seconds: 20),
    );
    await pair.clientSecure.channel.send({'id': 8, 'blob': blob});
    expect((await largeOnServer)['blob'], blob);
    final largeOnClient = pair.clientSecure.channel.incoming.first.timeout(
      const Duration(seconds: 20),
    );
    await pair.serverSecure.channel.send({'id': 9, 'blob': blob});
    expect((await largeOnClient)['blob'], blob);

    final records = [...pair.clientWire.sent, ...pair.serverWire.sent];
    expect(records.where((frame) => frame['type'] == 'secure').length,
        greaterThan(2));
    for (final record in records) {
      expect(jsonEncode(record), isNot(contains(secret)));
      expect(jsonEncode(record), isNot(contains('"blob":"xxx')));
    }
  });

  test('plaintext sent through a raw relay after Noise is rejected', () async {
    final pair = await securePair();
    final surfaced = <Map<String, dynamic>>[];
    pair.serverSecure.channel.incoming.listen(surfaced.add);
    final closed = pair.serverSecure.channel.state
        .firstWhere((state) => state == RemoteChannelState.closed)
        .timeout(const Duration(seconds: 5));
    await pair.client.send({'jsonrpc': '2.0', 'method': 'plaintext/injection'});
    await closed;
    expect(surfaced, isEmpty);
    expect(pair.serverSecure.channel.failure, isA<NoiseProtocolException>());
  });

  test('an admitted peer with the wrong Noise PSK is denied, not promoted '
      'to an application session', () async {
    final server = await serverSide();
    // Broker admission uses the valid token; the subsequent Noise proof does
    // not. This isolates actual PSK authentication from admission enforcement.
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    final transport = await server.transport;
    final denied = expectLater(
      acceptSecureChannel(
        channel: transport,
        readPsk: (device) async => device == deviceId ? psk : null,
        serverPublicKey: publicKey,
        signIdentity: (challenge) =>
            ServerIdentityCrypto.signChallenge(seedB64: seed, nonce: challenge),
        timeout: const Duration(seconds: 5),
      ),
      throwsA(isA<SecureHandshakeException>()),
    );
    await expectLater(
      connectSecureChannel(
        channel: client,
        deviceId: deviceId,
        psk: psk2,
        timeout: const Duration(seconds: 5),
      ),
      throwsA(isA<SecureHandshakeException>()),
    );
    await denied;
    expect(transport.isOpen, isFalse);
  });

  test('broker refuses unadmitted peers and revocation evicts a live peer',
      () async {
    final server = await serverSide();
    await expectLater(
      RelayClientChannel.connect(
        signalingUrl: url,
        room: room,
        deviceId: deviceId,
        psk: psk2,
      ),
      throwsA(isA<RelaySignalingException>()),
    );
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    final transport = await server.transport;
    final closed = client.state
        .firstWhere((state) => state == RemoteChannelState.closed)
        .timeout(const Duration(seconds: 5));
    final serverClosed = transport.state
        .firstWhere((state) => state == RemoteChannelState.closed)
        .timeout(const Duration(seconds: 5));
    server.signaling.admit(remove: [admissionHash(psk)]);
    await Future.wait([closed, serverClosed]);
    expect(client.isOpen, isFalse);
    expect(transport.isOpen, isFalse);
  });

  test('two paired clients have independent authenticated peer-scoped '
      'transports and cannot read each other’s records', () async {
    const device2 = 'device-2';
    final signaling = await RelaySignalingChannel.joinAsOwner(
      signalingUrl: url,
      room: room,
      ownerToken: ownerToken,
      admit: [admissionHash(psk), admissionHash(psk2)],
    );
    addTearDown(signaling.close);
    final first = Completer<RelayRemoteTransport>();
    final second = Completer<RelayRemoteTransport>();
    signaling.incoming.listen((frame) {
      if (frame['type'] != 'signal' || frame['kind'] != 'hello') return;
      final device = (frame['payload'] as Map)['d'];
      final transport = RelayRemoteTransport(
        signaling: signaling,
        peer: frame['from'] as String,
      );
      addTearDown(transport.close);
      if (device == deviceId) {
        first.complete(transport);
      } else if (device == device2) {
        second.complete(transport);
      }
    });

    Future<({SecureChannelConnection client, SecureChannelConnection server,
             _WireTap clientWire, _WireTap serverWire})> join(
      String device, String credential, Future<RelayRemoteTransport> peer,
    ) async {
      final raw = await RelayClientChannel.connect(
        signalingUrl: url,
        room: room,
        deviceId: device,
        psk: credential,
      );
      addTearDown(raw.close);
      final transport = await peer.timeout(const Duration(seconds: 5));
      final clientWire = _WireTap(raw);
      final serverWire = _WireTap(transport);
      final accepted = acceptSecureChannel(
        channel: serverWire,
        readPsk: (id) async => id == device ? credential : null,
        serverPublicKey: publicKey,
        signIdentity: (challenge) =>
            ServerIdentityCrypto.signChallenge(seedB64: seed, nonce: challenge),
      );
      final connected = await connectSecureChannel(
        channel: clientWire,
        deviceId: device,
        psk: credential,
        pinnedFingerprint: ServerIdentityCrypto.fingerprintOf(publicKey),
      );
      final server = await accepted;
      addTearDown(connected.channel.close);
      addTearDown(server.channel.close);
      return (client: connected, server: server,
              clientWire: clientWire, serverWire: serverWire);
    }

    final one = await join(deviceId, psk, first.future);
    final two = await join(device2, psk2, second.future);
    final twoBeforeFirst = two.clientWire.received.length;
    final gotOne = one.client.channel.incoming.first.timeout(
      const Duration(seconds: 5),
    );
    await one.server.channel.send({'secret': 'only-for-device-one'});
    expect(await gotOne, {'secret': 'only-for-device-one'});
    expect(two.clientWire.received.length, twoBeforeFirst,
        reason: 'the broker must not forward device one’s record to device two');
    final oneBeforeSecond = one.clientWire.received.length;
    final gotTwo = two.client.channel.incoming.first.timeout(
      const Duration(seconds: 5),
    );
    await two.server.channel.send({'secret': 'only-for-device-two'});
    expect(await gotTwo, {'secret': 'only-for-device-two'});
    expect(one.clientWire.received.length, oneBeforeSecond,
        reason: 'the broker must not forward device two’s record to device one');

    final fromTwo = two.server.channel.incoming.first.timeout(
      const Duration(seconds: 5),
    );
    await two.client.channel.send({'from': device2});
    expect(await fromTwo, {'from': device2});
    final fromOne = one.server.channel.incoming.first.timeout(
      const Duration(seconds: 5),
    );
    await one.client.channel.send({'from': deviceId});
    expect(await fromOne, {'from': deviceId});
    expect(one.serverWire.received.length, greaterThan(1));
    expect(two.serverWire.received.length, greaterThan(1));
  });
}
