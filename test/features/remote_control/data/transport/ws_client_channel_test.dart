import 'dart:convert';
import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal WebSocket server that mirrors `LocalRpcServer`'s WSS handshake +
/// a tiny repo-RPC echo — enough to prove [connectRemoteRpc] + the client
/// transport work over a real socket end to end.
Future<HttpServer> _startFakeServer(String psk) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.transform(WebSocketTransformer()).listen((ws) {
    ws.listen((dynamic data) {
      final frame = jsonDecode(data as String) as Map<String, dynamic>;
      if (frame['type'] == 'auth') {
        final nonce = frame['nonce'] as String;
        final proofOk = RemoteControlCrypto.verifyChallengeResponse(
          nonce: nonce,
          psk: psk,
          localFingerprint: '',
          remoteFingerprint: '',
          response: frame['proof'] as String? ?? '',
        );
        if (!proofOk) {
          ws.close();
          return;
        }
        ws
          ..add(
            jsonEncode({
              'type': 'auth_response',
              'nonce': nonce,
              'response': RemoteControlCrypto.respondToChallenge(
                nonce: nonce,
                psk: psk,
                localFingerprint: '',
                remoteFingerprint: '',
              ),
            }),
          )
          ..add(jsonEncode({'type': 'approved'}));
        return;
      }
      final id = frame['id'];
      final method = frame['method'];
      if (method == 'initialize') {
        ws.add(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'result': {'capabilities': <String, dynamic>{}},
          }),
        );
      } else if (method == 'repo/call') {
        final op = (frame['params'] as Map)['op'];
        ws.add(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': id,
            'result': {
              'op': op,
              'data': {'echoed': op},
            },
          }),
        );
      }
    });
  });
  return server;
}

void main() {
  test(
    'connectRemoteRpc authenticates and round-trips over a real WebSocket',
    () async {
      final psk = RemoteControlCrypto.generatePsk();
      final server = await _startFakeServer(psk);
      final uri = Uri.parse('ws://localhost:${server.port}/rpc');

      final client = await connectRemoteRpc(
        uri: uri,
        deviceId: 'dev-1',
        psk: psk,
      );

      final data = await client.call('tickets.list', const {});
      expect(data['echoed'], 'tickets.list');

      await client.close();
      await server.close(force: true);
    },
  );

  test('connectRemoteRpc fails closed against a wrong PSK', () async {
    final server = await _startFakeServer(RemoteControlCrypto.generatePsk());
    final uri = Uri.parse('ws://localhost:${server.port}/rpc');

    await expectLater(
      connectRemoteRpc(
        uri: uri,
        deviceId: 'dev-1',
        psk: RemoteControlCrypto.generatePsk(), // different PSK
        timeout: const Duration(seconds: 2),
      ),
      throwsA(isA<StateError>()),
    );

    await server.close(force: true);
  });
}
