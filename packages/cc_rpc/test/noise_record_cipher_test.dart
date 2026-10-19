import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_rpc/src/crypto/noise_record_cipher.dart';
import 'package:cc_rpc/src/crypto/noise_session.dart';
import 'package:test/test.dart';

/// A completed NNpsk0 handshake: (client, server) sessions.
Future<(NoiseSession, NoiseSession)> _sessions() async {
  final psk = Uint8List.fromList(List<int>.generate(32, (i) => i));
  final a = NoisePskHandshake(initiator: true, psk: psk);
  final b = NoisePskHandshake(initiator: false, psk: psk);
  await b.readMessage(await a.writeMessage(const []));
  await a.readMessage(await b.writeMessage(const []));
  return (a.takeSession(), b.takeSession());
}

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  test('handOff destroys the local direction and keeps its nonce', () async {
    final (client, server) = await _sessions();
    addTearDown(client.destroy);
    addTearDown(server.destroy);
    // Two records on the original state, then move it.
    for (final text in ['one', 'two']) {
      final record = await client.outgoing.encrypt(_bytes(text));
      expect(utf8.decode(await server.incoming.decrypt(record)), text);
    }
    final moved = client.outgoing.handOff();
    await expectLater(
      client.outgoing.encrypt(_bytes('after')),
      throwsA(isA<NoiseProtocolException>()),
      reason: 'a handed-off direction can no longer seal',
    );
    expect(moved.nonce, 2);
    final resumed = NoiseCipherState.resume(moved);
    addTearDown(resumed.destroy);
    final record = await resumed.encrypt(_bytes('three'));
    expect(
      utf8.decode(await server.incoming.decrypt(record)),
      'three',
      reason: 'the resumed state continues the same nonce sequence',
    );
  });

  test(
    'records round-trip through the worker after local keys are gone',
    () async {
      final (clientSession, serverSession) = await _sessions();
      final client = NoiseRecordCipher(clientSession);
      final server = NoiseRecordCipher(serverSession);
      addTearDown(client.destroy);
      addTearDown(server.destroy);
      // The sessions handed both directions over: nothing here can seal.
      await expectLater(
        clientSession.outgoing.encrypt(_bytes('local')),
        throwsA(isA<NoiseProtocolException>()),
      );

      final sealed = await client.seal(_bytes('hello'));
      expect(sealed, isNot(contains('hello')));
      expect(utf8.decode(await server.open(sealed)), 'hello');
      final reply = await server.seal(_bytes('world'));
      expect(utf8.decode(await client.open(reply)), 'world');
    },
  );

  test('a burst of opens dispatched at once resolves in order', () async {
    final (clientSession, serverSession) = await _sessions();
    final client = NoiseRecordCipher(clientSession);
    final server = NoiseRecordCipher(serverSession);
    addTearDown(client.destroy);
    addTearDown(server.destroy);
    final sealed = <String>[];
    for (var i = 0; i < 200; i++) {
      sealed.add(await client.seal(_bytes('record-$i')));
    }
    // Every open is in flight before the first resolves, as the channel
    // dispatches them on arrival.
    final opened = await Future.wait([for (final s in sealed) server.open(s)]);
    expect(opened.map(utf8.decode), [
      for (var i = 0; i < 200; i++) 'record-$i',
    ]);
  });

  test('a reordered or tampered record is rejected without detail', () async {
    final (clientSession, serverSession) = await _sessions();
    final client = NoiseRecordCipher(clientSession);
    final server = NoiseRecordCipher(serverSession);
    addTearDown(client.destroy);
    addTearDown(server.destroy);
    final first = await client.seal(_bytes('secret-first'));
    final second = await client.seal(_bytes('secret-second'));

    await expectLater(
      server.open(second),
      throwsA(
        isA<NoiseProtocolException>().having(
          (e) => e.toString(),
          'message',
          allOf(isNot(contains('secret')), isNot(contains(second))),
        ),
      ),
      reason: 'the second record cannot open at the first nonce',
    );
    final tampered = base64Url.decode(first)..[0] ^= 1;
    await expectLater(
      server.open(base64Url.encode(tampered)),
      throwsA(isA<NoiseProtocolException>()),
    );
    await expectLater(
      server.open('not base64url!'),
      throwsA(isA<NoiseProtocolException>()),
    );
  });

  test(
    'destroy refuses later requests; records sealed before still open',
    () async {
      final (clientSession, serverSession) = await _sessions();
      final client = NoiseRecordCipher(clientSession);
      final server = NoiseRecordCipher(serverSession);
      addTearDown(server.destroy);
      final sealed = await client.seal(_bytes('before'));
      client.destroy();
      await expectLater(
        client.seal(_bytes('after')),
        throwsA(isA<NoiseProtocolException>()),
      );
      expect(utf8.decode(await server.open(sealed)), 'before');
    },
  );
}
