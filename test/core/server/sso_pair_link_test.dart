import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/server/sso_pair_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSsoPairLink', () {
    test('matches only the pair scheme+host', () {
      expect(isSsoPairLink('control-center://pair#abc'), isTrue);
      expect(isSsoPairLink('control-center://pr/owner/repo/1'), isFalse);
      expect(isSsoPairLink('https://example.com'), isFalse);
    });
  });

  group('decodeSsoPairLink', () {
    String linkFor(Map<String, dynamic> payload) {
      final fragment = base64Url
          .encode(utf8.encode(jsonEncode(payload)))
          .replaceAll('=', '');
      return 'control-center://pair#$fragment';
    }

    test('decrypts only the expected client-held recipient', () async {
      final recipient = await CredentialSeal.newRecipient();
      beginSealedSsoLogin(
        origin: 'https://cc.example.com',
        privateKey: recipient.privateKey,
      );
      final sealed = await CredentialSeal.seal(
        recipientPublicKey: recipient.publicKey,
        credential: const {
          's': 'https://cc.example.com',
          'i': 'device-1',
          'k': 'psk-1',
        },
        context: 'https://cc.example.com',
      );
      final link = linkFor({'s': 'https://cc.example.com', 'box': sealed});
      expect(link, isNot(contains('psk-1')));
      final payload = await decodeSsoPairLink(link);
      expect(payload?.server, 'https://cc.example.com');
      expect(payload?.deviceId, 'device-1');
      expect(payload?.psk, 'psk-1');
      expect(await decodeSsoPairLink(link), isNull); // Single use.
    });

    test('rejects plaintext, wrong recipients and changed origin', () async {
      final recipient = await CredentialSeal.newRecipient();
      final other = await CredentialSeal.newRecipient();
      beginSealedSsoLogin(
        origin: 'https://cc.example.com',
        privateKey: recipient.privateKey,
      );
      final legacy = linkFor({
        's': 'https://cc.example.com',
        'i': 'device-1',
        'k': 'psk-1',
      });
      expect(await decodeSsoPairLink(legacy), isNull);
      final sealed = await CredentialSeal.seal(
        recipientPublicKey: other.publicKey,
        credential: const {
          's': 'https://cc.example.com',
          'i': 'device-1',
          'k': 'psk-1',
        },
        context: 'https://cc.example.com',
      );
      expect(await decodeSsoPairLink(linkFor({
        's': 'https://cc.example.com',
        'box': sealed,
      })), isNull);
      expect(await decodeSsoPairLink(linkFor({
        's': 'https://impostor.example.com',
        'box': sealed,
      })), isNull);
      expect(await decodeSsoPairLink('control-center://pair#!!!'), isNull);
      clearSealedSsoLogin();
    });
    test('IdP-initiated sealed link requires explicit confirmation', () async {
      clearSealedSsoLogin();
      final recipient = await CredentialSeal.newRecipient();
      final sealed = await CredentialSeal.seal(
        recipientPublicKey: recipient.publicKey,
        credential: const {
          's': 'https://cc.example.com',
          'i': 'device-1',
          'k': 'psk-1',
        },
        context: 'https://cc.example.com',
      );
      final link = linkFor({
        's': 'https://cc.example.com',
        'box': sealed,
        'recipientPrivateKey': recipient.privateKey,
        'idpInitiated': true,
      });
      expect(isIdpInitiatedSsoPairLink(link), isTrue);
      expect(link, isNot(contains('psk-1')));
      final opened = await decodeSsoPairLink(link);
      expect(opened?.psk, 'psk-1');
      expect(opened?.unsolicited, isTrue);
      final other = await CredentialSeal.newRecipient();
      expect(
        await decodeSsoPairLink(linkFor({
          's': 'https://cc.example.com',
          'box': sealed,
          'recipientPrivateKey': other.privateKey,
          'idpInitiated': true,
        })),
        isNull,
      );
      expect(
        await decodeSsoPairLink(linkFor({
          's': 'https://impostor.example.com',
          'box': sealed,
          'recipientPrivateKey': recipient.privateKey,
          'idpInitiated': true,
        })),
        isNull,
      );
    });
  });

  group('httpOriginFor', () {
    test('scheme-swaps and strips ws urls', () {
      expect(
        httpOriginFor('wss://host:9030/rpc'),
        'https://host:9030',
      );
      expect(httpOriginFor('ws://192.168.1.5:9030/rpc'), 'http://192.168.1.5:9030');
      expect(httpOriginFor('https://cc.example.com/saml/acs'),
          'https://cc.example.com');
    });

    test('refuses non-http schemes and junk', () {
      expect(httpOriginFor('not a url'), isNull);
      expect(httpOriginFor('ftp://host'), isNull);
      expect(httpOriginFor(''), isNull);
    });
  });

  group('SSO login in-flight marker', () {
    // The marker gates pair-link adoption: a bounce inside the window is
    // the expected completion of a login this app started; outside it, the
    // link is unbidden (forged/forwarded) and must be refused or confirmed.
    test('is false with no marker and true within the window', () {
      ssoLoginStartedAt.value = null;
      expect(isSsoLoginInFlight(), isFalse);

      markSsoLoginStarted(DateTime.now().subtract(const Duration(minutes: 9)));
      expect(isSsoLoginInFlight(), isTrue);

      ssoLoginStartedAt.value = null;
    });

    test('expires after the window', () {
      markSsoLoginStarted(DateTime.now().subtract(const Duration(minutes: 11)));
      expect(isSsoLoginInFlight(), isFalse);
      // An explicit window override is honoured (tests / tight flows).
      expect(
        isSsoLoginInFlight(window: const Duration(minutes: 15)),
        isTrue,
      );

      ssoLoginStartedAt.value = null;
    });
  });
}
