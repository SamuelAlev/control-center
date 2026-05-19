import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/relay/relay_remote_transport.dart';
import 'package:cc_server_core/src/relay/signaling_relay_client.dart';
import 'package:cc_signaling_server/cc_signaling_server.dart';
import 'package:test/test.dart';

/// Exercises the full relay mechanism through the REAL broker, running it
/// in-process: server transport ⇄ signaling broker ⇄ a simulated phone peer.
/// The phone is simulated with `RelayFrameCrypto` directly (the phone mirrors it
/// byte-for-byte), so this proves the broker relay + E2E seal/open + the
/// transport's framing all interoperate — no phone app or UI required.
void main() {
  late SignalingServerHandle broker;
  late String url;

  setUp(() async {
    broker = await serveSignaling(host: 'localhost', port: 0);
    url = 'ws://localhost:${broker.port}/signal';
  });

  tearDown(() async {
    await broker.close();
  });

  const psk = 'relay-test-psk-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const room = 'device-abc';

  test('frames round-trip E2E-encrypted through the broker', () async {
    // Server side: join the room, then wrap a transport over it.
    final serverSignaling = SignalingRelayClient(url);
    await serverSignaling.connect(room: room, peerId: 'cc-server');
    final transport = RelayRemoteTransport(
      signaling: serverSignaling,
      room: room,
      peerId: 'cc-server',
      psk: psk,
    );

    // Phone side (simulated): a second peer in the same room.
    final phone = SignalingRelayClient(url);
    await phone.connect(room: room, peerId: 'phone-1');

    // Phone → server: a sealed frame must arrive decoded on transport.incoming.
    final serverGot = transport.incoming.first;
    phone.send({
      'type': 'signal',
      'room': room,
      'from': 'phone-1',
      'kind': 'rpc',
      'payload': {
        'e': RelayFrameCrypto.seal(
          jsonEncode({'jsonrpc': '2.0', 'id': 7, 'method': 'ping'}),
          psk,
        ),
      },
    });
    expect(await serverGot, {'jsonrpc': '2.0', 'id': 7, 'method': 'ping'});

    // Server → phone: transport.send must arrive at the phone as ciphertext that
    // opens to the original frame.
    final phoneGot = phone.incoming.firstWhere(
      (f) => f['type'] == 'signal' && f['kind'] == 'rpc',
    );
    await transport.send({'jsonrpc': '2.0', 'id': 7, 'result': 'pong'});
    final relayed = await phoneGot;
    final sealed = (relayed['payload'] as Map)['e'] as String;
    expect(
      jsonDecode(RelayFrameCrypto.open(sealed, psk)),
      {'jsonrpc': '2.0', 'id': 7, 'result': 'pong'},
    );

    await transport.close();
    await serverSignaling.close(room: room, peerId: 'cc-server');
    await phone.close(room: room, peerId: 'phone-1');
  });

  test('the broker never sees plaintext — only ciphertext payloads', () async {
    final serverSignaling = SignalingRelayClient(url);
    await serverSignaling.connect(room: room, peerId: 'cc-server');
    final transport = RelayRemoteTransport(
      signaling: serverSignaling,
      room: room,
      peerId: 'cc-server',
      psk: psk,
    );
    final phone = SignalingRelayClient(url);
    await phone.connect(room: room, peerId: 'phone-1');

    final phoneGot = phone.incoming.firstWhere(
      (f) => f['type'] == 'signal' && f['kind'] == 'rpc',
    );
    await transport.send({'secret': 'top-secret-ticket-title'});
    final relayed = await phoneGot;
    final sealed = (relayed['payload'] as Map)['e'] as String;
    expect(sealed, isNot(contains('top-secret-ticket-title')));

    await transport.close();
    await serverSignaling.close(room: room, peerId: 'cc-server');
    await phone.close(room: room, peerId: 'phone-1');
  });

  test('a wrong-PSK frame is dropped, not surfaced to the session', () async {
    final serverSignaling = SignalingRelayClient(url);
    await serverSignaling.connect(room: room, peerId: 'cc-server');
    final transport = RelayRemoteTransport(
      signaling: serverSignaling,
      room: room,
      peerId: 'cc-server',
      psk: psk,
    );
    final phone = SignalingRelayClient(url);
    await phone.connect(room: room, peerId: 'phone-1');

    var surfaced = 0;
    final sub = transport.incoming.listen((_) => surfaced++);

    // A frame sealed with the WRONG psk must fail the MAC and be dropped.
    phone.send({
      'type': 'signal',
      'room': room,
      'from': 'phone-1',
      'kind': 'rpc',
      'payload': {'e': RelayFrameCrypto.seal('{"x":1}', 'the-wrong-psk')},
    });
    // Then a valid one, to have a deterministic point to assert after.
    final good = transport.incoming.first;
    phone.send({
      'type': 'signal',
      'room': room,
      'from': 'phone-1',
      'kind': 'rpc',
      'payload': {'e': RelayFrameCrypto.seal('{"x":2}', psk)},
    });
    expect(await good, {'x': 2});
    expect(surfaced, 1, reason: 'only the valid frame surfaced');

    await sub.cancel();
    await transport.close();
    await serverSignaling.close(room: room, peerId: 'cc-server');
    await phone.close(room: room, peerId: 'phone-1');
  });
}
