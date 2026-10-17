import 'dart:async';
import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/secure_resource_host.dart';
import 'package:test/test.dart';

Future<RemoteResourceClient> _connect(
  SecureResourceHost host,
  String deviceId,
  String userId,
) async {
  final (serverWire, clientWire) = InProcessRpcChannel.pair();
  final psk = RemoteControlCrypto.generatePsk();
  final seed = await ServerIdentityCrypto.generateSeed();
  final accepting = acceptSecureChannel(
    channel: serverWire,
    readPsk: (id) async => id == deviceId ? psk : null,
    serverPublicKey: await ServerIdentityCrypto.publicKeyFromSeed(seed),
    signIdentity: (nonce) =>
        ServerIdentityCrypto.signChallenge(seedB64: seed, nonce: nonce),
  );
  final connection = await connectSecureChannel(
    channel: clientWire,
    deviceId: deviceId,
    psk: psk,
  );
  final server = await accepting;
  host.attach(
    server.channel,
    deviceId: deviceId,
    userId: userId,
    expiresAt: null,
  );
  final client = RemoteResourceClient(connection.channel);
  addTearDown(() async {
    await client.close();
    await connection.channel.close();
  });
  return client;
}

void main() {
  test(
    'canceled tunnel IDs cannot bypass actual handler capacity across devices',
    () async {
      final release = Completer<void>();
      final unwound = Completer<void>();
      var held = 0;
      var finished = 0;
      final host = await SecureResourceHost.start(
        handleRequest: (request, principal, transfer) async {
          final response = request.response;
          // Deliberately emulate work that cannot be interrupted mid-transaction.
          // The network response may be canceled, but its admission stays held.
          unawaited(response.done.then<void>((_) {}, onError: (Object _) {}));
          response.bufferOutput = false;
          response.write('accepted');
          if (principal.userId == 'bounded-user' && !release.isCompleted) {
            held++;
            await release.future;
            finished++;
            if (finished == 32) {
              unwound.complete();
            }
          }
          try {
            await response.close();
          } on HttpException {
            // The consumer intentionally disconnected while work was held.
          }
        },
        handleEditorBridge: (_, _, _) => throw StateError('Unexpected bridge'),
      );
      addTearDown(() async {
        if (!release.isCompleted) {
          release.complete();
        }
        await host.close();
      });
      final first = await _connect(host, 'device-one', 'bounded-user');
      final second = await _connect(host, 'device-two', 'bounded-user');
      final otherUser = await _connect(host, 'other-device', 'other-user');
      for (var i = 0; i < 32; i++) {
        final client = i.isEven ? first : second;
        final response = await client.request('GET', Uri.parse('/proxy/media'));
        expect(response.statusCode, HttpStatus.ok);
        await response.close();
      }
      expect(held, 32);
      await expectLater(
        second.request('GET', Uri.parse('/proxy/media')),
        throwsStateError,
      );
      expect(held, 32);
      final independent = await otherUser.request(
        'GET',
        Uri.parse('/proxy/media'),
      );
      expect(
        await independent.body.expand((bytes) => bytes).toList(),
        'accepted'.codeUnits,
      );
      release.complete();
      await unwound.future.timeout(const Duration(seconds: 5));
      // Closing responses and releasing the host's finally blocks is asynchronous.
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final recovered = await first.request('GET', Uri.parse('/proxy/media'));
      expect(
        await recovered.body.expand((bytes) => bytes).toList(),
        'accepted'.codeUnits,
      );
    },
  );
}
