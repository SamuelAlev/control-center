import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/relay/relay_remote_transport.dart';
import 'package:cc_signaling_server/cc_signaling_server.dart';
import 'package:test/test.dart';

/// Exercises the full N-way relay mechanism through the REAL broker, running
/// in-process: server owner channel + [RelayRemoteTransport] ⇄ signaling
/// broker ⇄ a real [RelayClientChannel] (the client class every platform
/// uses). This proves the invite-gated room protocol, the hello→PSK binding,
/// the E2E seal/open and the chunked data plane all interoperate — no app
/// or UI required.
void main() {
  late SignalingServerHandle broker;
  late String url;

  const psk = 'relay-test-psk-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const room = 'server-room-code-abc';
  const deviceId = 'device-1';
  const ownerToken = 'owner-secret';

  String admissionHash() => RemoteControlCrypto.relayAdmissionHash(
    RemoteControlCrypto.relayAdmissionToken(psk: psk, room: room),
  );

  setUp(() async {
    broker = await serveSignaling(host: 'localhost', port: 0);
    url = 'ws://localhost:${broker.port}/signal';
  });

  tearDown(() async {
    await broker.close();
  });

  /// Joins the room as the server, waits for one client hello and returns
  /// the peer-scoped transport for it.
  Future<
    ({RelaySignalingChannel signaling, Future<RelayRemoteTransport> transport})
  >
  serverSide() async {
    final signaling = await RelaySignalingChannel.joinAsOwner(
      signalingUrl: url,
      room: room,
      ownerToken: ownerToken,
      admit: [admissionHash()],
    );
    final transport = signaling.incoming
        .firstWhere((f) => f['type'] == 'signal' && f['kind'] == 'hello')
        .then(
          (hello) => RelayRemoteTransport(
            signaling: signaling,
            peer: hello['from'] as String,
            psk: psk,
          ),
        );
    return (signaling: signaling, transport: transport);
  }

  test('client frames round-trip E2E-encrypted and chunked through the '
      'broker', () async {
    final server = await serverSide();
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    final transport = await server.transport;

    // Client → server.
    final serverGot = transport.incoming.first;
    await client.send({'jsonrpc': '2.0', 'id': 7, 'method': 'ping'});
    expect(await serverGot, {'jsonrpc': '2.0', 'id': 7, 'method': 'ping'});

    // Server → client.
    final clientGot = client.incoming.first;
    await transport.send({'jsonrpc': '2.0', 'id': 7, 'result': 'pong'});
    expect(await clientGot, {'jsonrpc': '2.0', 'id': 7, 'result': 'pong'});

    // A frame far larger than one broker frame cap must arrive intact
    // (chunked + credited both ways).
    final bigGot = transport.incoming.first;
    final blob = 'x' * (300 * 1024);
    await client.send({'id': 8, 'blob': blob});
    expect(((await bigGot)['blob'] as String).length, blob.length);

    await client.close();
    await transport.close();
    await server.signaling.close();
  });

  test('the broker never sees plaintext — only ciphertext payloads', () async {
    // Tap every frame the broker relays by joining a second admitted
    // observer? No — the room protocol prevents that. Instead assert at the
    // client's own signaling layer: outbound payloads are sealed.
    final server = await serverSide();
    final observed = <String>[];
    final signaling = await RelaySignalingChannel.joinAsClient(
      signalingUrl: url,
      room: room,
      token: RemoteControlCrypto.relayAdmissionToken(psk: psk, room: room),
    );
    signaling.incoming.listen((f) {
      if (f['type'] == 'signal') {
        observed.add(jsonEncode(f['payload']));
      }
    });
    signaling.sendSignal(
      to: server.signaling.peerId,
      kind: 'hello',
      payload: {'d': deviceId},
    );
    final transport = await server.transport;
    await transport.send({'secret': 'top-secret-ticket-title'});
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(observed, isNotEmpty);
    for (final payload in observed) {
      expect(payload, isNot(contains('top-secret-ticket-title')));
    }
    await transport.close();
    await signaling.close();
    await server.signaling.close();
  });

  test('a wrong-PSK frame is dropped, not surfaced to the session', () async {
    final server = await serverSide();
    final signaling = await RelaySignalingChannel.joinAsClient(
      signalingUrl: url,
      room: room,
      token: RemoteControlCrypto.relayAdmissionToken(psk: psk, room: room),
    );
    signaling.sendSignal(
      to: server.signaling.peerId,
      kind: 'hello',
      payload: {'d': deviceId},
    );
    final transport = await server.transport;

    var surfaced = 0;
    final sub = transport.incoming.listen((_) => surfaced++);

    // A frame sealed with the WRONG psk must fail the MAC and be dropped.
    signaling.sendSignal(
      to: server.signaling.peerId,
      payload: {'e': RelayFrameCrypto.seal('{"x":1}', 'the-wrong-psk')},
    );
    // Then a valid one, to have a deterministic point to assert after.
    final good = transport.incoming.first;
    signaling.sendSignal(
      to: server.signaling.peerId,
      payload: {'e': RelayFrameCrypto.seal('{"x":2}', psk)},
    );
    expect(await good, {'x': 2});
    expect(surfaced, 1, reason: 'only the valid frame surfaced');

    await sub.cancel();
    await transport.close();
    await signaling.close();
    await server.signaling.close();
  });

  test('an unadmitted client cannot join; a revoked admission evicts the '
      'live client', () async {
    final server = await serverSide();

    // No token → refused before any relaying.
    await expectLater(
      RelayClientChannel.connect(
        signalingUrl: url,
        room: room,
        deviceId: deviceId,
        psk: 'some-other-psk',
      ),
      throwsA(isA<RelaySignalingException>()),
    );

    // Admitted client connects, then the server revokes its hash — the
    // broker evicts it and the client's channel closes.
    final client = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    final closed = client.state.firstWhere(
      (s) => s == RemoteChannelState.closed,
    );
    server.signaling.admit(remove: [admissionHash()]);
    await closed;

    await client.close();
    await server.signaling.close();
  });

  test('two clients get independent peer-scoped transports (N-way)', () async {
    const psk2 = 'second-device-psk';
    const device2 = 'device-2';
    final hash2 = RemoteControlCrypto.relayAdmissionHash(
      RemoteControlCrypto.relayAdmissionToken(psk: psk2, room: room),
    );
    final signaling = await RelaySignalingChannel.joinAsOwner(
      signalingUrl: url,
      room: room,
      ownerToken: ownerToken,
      admit: [admissionHash(), hash2],
    );
    final transports = <String, RelayRemoteTransport>{};
    signaling.incoming.listen((f) {
      if (f['type'] == 'signal' && f['kind'] == 'hello') {
        final peer = f['from'] as String;
        final device = (f['payload'] as Map)['d'] as String;
        transports[device] = RelayRemoteTransport(
          signaling: signaling,
          peer: peer,
          psk: device == deviceId ? psk : psk2,
        );
      }
    });

    final c1 = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: deviceId,
      psk: psk,
    );
    final c2 = await RelayClientChannel.connect(
      signalingUrl: url,
      room: room,
      deviceId: device2,
      psk: psk2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(transports.keys, containsAll([deviceId, device2]));

    // Server → each client individually; the other never sees it.
    final got1 = c1.incoming.first;
    await transports[deviceId]!.send({'to': 1});
    expect(await got1, {'to': 1});

    final got2 = c2.incoming.first;
    await transports[device2]!.send({'to': 2});
    expect(await got2, {'to': 2});

    // Client → server lands on the right transport.
    final fromC2 = transports[device2]!.incoming.first;
    await c2.send({'from': 2});
    expect(await fromC2, {'from': 2});

    await c1.close();
    await c2.close();
    for (final t in transports.values) {
      await t.close();
    }
    await signaling.close();
  });
}
