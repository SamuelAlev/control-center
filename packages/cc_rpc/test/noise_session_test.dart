import 'dart:typed_data';

import 'package:cc_rpc/src/crypto/noise_session.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

Uint8List _hex(String text) => Uint8List.fromList([
  for (var i = 0; i < text.length; i += 2)
    int.parse(text.substring(i, i + 2), radix: 16),
]);

String _toHex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // Cacophony's independent NNpsk0 test vector, from
  // https://github.com/blckngm/noise-rust/blob/master/vectors/tests/vectors/cacophony.txt
  // (protocol Noise_NNpsk0_25519_ChaChaPoly_SHA256, prologue "John Galt",
  // PSK "This is my Austrian perspective!"). Both handshake messages,
  // handshake hash, and alternating directional transport records are pinned.
  test('Noise revision 34 matches Cacophony NNpsk0 byte for byte', () async {
    final psk = _hex(
      '54686973206973206d7920417573747269616e20706572737065637469766521',
    );
    final prologue = _hex('4a6f686e2047616c74');
    final initiator = NoisePskHandshake(
      initiator: true,
      psk: psk,
      prologue: prologue,
      ephemeralKeyPair: await X25519().newKeyPairFromSeed(
        _hex(
          '893e28b9dc6ca8d611ab664754b8ceb7bac5117349a4439a6b0569da977c464a',
        ),
      ),
    );
    final responder = NoisePskHandshake(
      initiator: false,
      psk: psk,
      prologue: prologue,
      ephemeralKeyPair: await X25519().newKeyPairFromSeed(
        _hex(
          'bbdb4cdbd309f1a1f2e1456967fe288cadd6f712d65dc7b7793d5e63da6b375b',
        ),
      ),
    );
    const payloads = [
      '4c756477696720766f6e204d69736573',
      '4d757272617920526f746862617264',
      '462e20412e20486179656b',
      '4361726c204d656e676572',
      '4a65616e2d426170746973746520536179',
      '457567656e2042f6686d20766f6e2042617765726b',
    ];
    const records = [
      'ca35def5ae56cec33dc2036731ab14896bc4c75dbb07a61f879f8e3afa4c794479b962b8aff8485742ac32f905ba45369e2465fb59e138a93d67a0d1266b6a54',
      '95ebc60d2b1fa672c1f46a8aa265ef51bfe38e7ccb39ec5be34069f144808843d6062704d5a9c422a8e834423f8c1feada7e8d0d910a1a2cd030fb584221e3',
      'e632c3763d7669067383433197a3baddf146e9e70ad4b4e9e59e0f',
      '64c6bee32ea91c8474bb4c21d7a700109ad45af77b29764ba5eb1e',
      'e2fa0bed0603b62d3ccac2ecabbf3fe33f3e86514909b323361626266cb2471cc8',
      '0c01dc9cec1fe4ddd692e8dd32188aa351088dc91183639a53b57aa4692b5ebdef8b8ca111',
    ];
    final first = await initiator.writeMessage(_hex(payloads[0]));
    expect(_toHex(first), records[0]);
    expect(_toHex(await responder.readMessage(first)), payloads[0]);
    final second = await responder.writeMessage(_hex(payloads[1]));
    expect(_toHex(second), records[1]);
    expect(_toHex(await initiator.readMessage(second)), payloads[1]);
    final a = initiator.takeSession();
    final b = responder.takeSession();
    addTearDown(a.destroy);
    addTearDown(b.destroy);
    expect(
      _toHex(a.handshakeHash),
      'f4d03dc34495c95729ea6de9e1b59004b59733102488b3e24bc441e0be208eaf',
    );
    expect(_toHex(b.handshakeHash), _toHex(a.handshakeHash));
    for (var i = 2; i < payloads.length; i++) {
      final sender = i.isEven ? a : b;
      final receiver = i.isEven ? b : a;
      final encrypted = await sender.outgoing.encrypt(_hex(payloads[i]));
      expect(_toHex(encrypted), records[i], reason: 'vector record $i');
      expect(_toHex(await receiver.incoming.decrypt(encrypted)), payloads[i]);
    }
  });

  test(
    'direction swap, replay, and ciphertext tamper cannot decrypt',
    () async {
      final psk = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final a = NoisePskHandshake(initiator: true, psk: psk);
      final b = NoisePskHandshake(initiator: false, psk: psk);
      final first = await a.writeMessage(const []);
      expect(await b.readMessage(first), isEmpty);
      final reply = await b.writeMessage(const []);
      expect(await a.readMessage(reply), isEmpty);
      final client = a.takeSession();
      final server = b.takeSession();
      addTearDown(client.destroy);
      addTearDown(server.destroy);
      final ciphertext = await client.outgoing.encrypt([1, 2, 3]);
      await expectLater(client.incoming.decrypt(ciphertext), throwsA(anything));
      expect(await server.incoming.decrypt(ciphertext), [1, 2, 3]);
      await expectLater(server.incoming.decrypt(ciphertext), throwsA(anything));
      final next = await client.outgoing.encrypt([4, 5, 6]);
      final tampered = Uint8List.fromList(next)..[0] ^= 1;
      await expectLater(server.incoming.decrypt(tampered), throwsA(anything));
      expect(await server.incoming.decrypt(next), [4, 5, 6]);
    },
  );
}
