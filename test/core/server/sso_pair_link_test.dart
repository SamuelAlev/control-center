import 'dart:convert';

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
    String linkFor(Map<String, String> payload) {
      final fragment = base64Url
          .encode(utf8.encode(jsonEncode(payload)))
          .replaceAll('=', '');
      return 'control-center://pair#$fragment';
    }

    test('decodes the {s, i, k} fragment', () {
      final payload = decodeSsoPairLink(
        linkFor({
          's': 'https://cc.example.com',
          'i': 'device-1',
          'k': 'psk-1',
        }),
      );
      expect(payload, isNotNull);
      expect(payload!.server, 'https://cc.example.com');
      expect(payload.deviceId, 'device-1');
      expect(payload.psk, 'psk-1');
    });

    test('refuses malformed fragments', () {
      expect(decodeSsoPairLink('control-center://pair'), isNull);
      expect(decodeSsoPairLink('control-center://pair#!!!'), isNull);
      // Missing any of s/i/k.
      expect(
        decodeSsoPairLink(linkFor({'s': 'https://cc.example.com'})),
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
