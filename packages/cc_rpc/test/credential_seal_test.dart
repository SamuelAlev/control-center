import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

void main() {
  test(
    'recipient alone opens a sealed PSK; the wire contains no PSK',
    () async {
      final recipient = await CredentialSeal.newRecipient();
      final envelope = await CredentialSeal.seal(
        recipientPublicKey: recipient.publicKey,
        credential: const {
          's': 'https://host',
          'i': 'device',
          'k': 'secret-psk',
        },
        context: 'https://host',
      );
      expect(CredentialSeal.isValidPublicKey(recipient.publicKey), isTrue);
      expect(jsonEncode(envelope), isNot(contains('secret-psk')));
      expect(
        await CredentialSeal.open(
          recipientPrivateKey: recipient.privateKey,
          envelope: envelope,
          context: 'https://host',
        ),
        {'s': 'https://host', 'i': 'device', 'k': 'secret-psk'},
      );
    },
  );

  test(
    'wrong recipient, context, and tampered ciphertext fail closed',
    () async {
      final recipient = await CredentialSeal.newRecipient();
      final other = await CredentialSeal.newRecipient();
      final envelope = await CredentialSeal.seal(
        recipientPublicKey: recipient.publicKey,
        credential: const {'k': 'secret-psk'},
        context: 'https://host',
      );
      expect(
        () => CredentialSeal.open(
          recipientPrivateKey: other.privateKey,
          envelope: envelope,
          context: 'https://host',
        ),
        throwsA(isA<Object>()),
      );
      expect(
        () => CredentialSeal.open(
          recipientPrivateKey: recipient.privateKey,
          envelope: envelope,
          context: 'https://impostor',
        ),
        throwsA(isA<Object>()),
      );
      final ciphertext = base64Url.decode(base64Url.normalize(envelope['c']!));
      ciphertext[ciphertext.length - 1] ^= 1;
      final tampered = Map<String, dynamic>.of(envelope)
        ..['c'] = base64Url.encode(ciphertext).replaceAll('=', '');
      expect(
        () => CredentialSeal.open(
          recipientPrivateKey: recipient.privateKey,
          envelope: tampered,
          context: 'https://host',
        ),
        throwsA(isA<Object>()),
      );
      expect(CredentialSeal.isValidPublicKey('password'), isFalse);
    },
  );
}
