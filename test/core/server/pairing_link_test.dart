import 'dart:convert';

import 'package:control_center/core/server/pairing_link.dart';
import 'package:flutter_test/flutter_test.dart';

String _fragment(Map<String, Object?> fields) =>
    base64Url.encode(utf8.encode(jsonEncode(fields))).replaceAll('=', '');

void main() {
  group('PairingLink.parse', () {
    test('reads the link a pairing panel builds', () {
      final link = PairingLink.parse(
        buildPairingLink(
          origin: 'https://cc.example.com:9030',
          server: 'wss://cc.example.com:9030/rpc',
          deviceId: 'device-1',
          psk: 'secret',
        ),
      );

      expect(link?.server, 'wss://cc.example.com:9030/rpc');
      expect(link?.displayServer, 'wss://cc.example.com:9030/rpc');
      expect(link?.deviceId, 'device-1');
      expect(link?.psk, 'secret');
      expect(link?.inviteCode, isEmpty);
    });

    test('reads an invite link, whose server is an http origin', () {
      final link = PairingLink.parse(
        'https://cc.example.com/#${_fragment({
          's': 'https://cc.example.com',
          'inv': 'code',
          'd': {'paths': <Object?>[]},
        })}',
      );

      expect(link?.inviteCode, 'code');
      expect(link?.displayServer, 'wss://cc.example.com/rpc');
      expect(link?.psk, isEmpty);
    });

    test('reads a bare fragment and the query-string form', () {
      final payload = _fragment({
        's': 'ws://host:9030/rpc',
        'i': 'd',
        'k': 'k',
      });
      expect(PairingLink.parse('  $payload\n')?.deviceId, 'd');
      expect(
        PairingLink.parse('https://h/#server=ws://h/rpc&device=d&psk=k')?.psk,
        'k',
      );
    });

    test('refuses what it cannot safely connect', () {
      final refused = {
        'empty': '',
        'plain text': 'not a link',
        'a url without a fragment': 'https://cc.example.com/',
        'no credential': _fragment({'s': 'wss://h/rpc'}),
        'a key without a device': _fragment({'s': 'wss://h/rpc', 'k': 'k'}),
        'no server': _fragment({'i': 'd', 'k': 'k'}),
        'a non-websocket server': _fragment({
          's': 'file:///etc/passwd',
          'i': 'd',
          'k': 'k',
        }),
        'a phone relay payload': _fragment({
          'v': 2,
          'd': <String, Object?>{},
          'i': 'd',
          'k': 'k',
          'x': 0,
        }),
        'a sealed SSO completion': _fragment({
          'box': {'c': 'x'},
        }),
      };
      for (final MapEntry(key: name, value: input) in refused.entries) {
        expect(PairingLink.parse(input), isNull, reason: name);
      }
    });
  });

  test('the credential rides in the fragment, never the query', () {
    final link = buildPairingLink(
      origin: 'https://h',
      server: 'wss://h/rpc',
      deviceId: 'd',
      psk: 'secret',
    );
    final uri = Uri.parse(link);
    expect(uri.query, isEmpty);
    expect(uri.path, '/');
    expect(decodePairingFragment(uri.fragment)?['k'], 'secret');
  });
}
