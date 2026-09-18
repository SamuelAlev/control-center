import 'dart:convert';

import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/cursor_oauth.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:test/test.dart';

class _FakeHttp implements ProviderHttp {
  _FakeHttp(this.responses);

  final List<Object> responses;
  final List<Uri> gets = [];

  @override
  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    gets.add(uri);
    final next = responses.removeAt(0);
    if (next is ProviderHttpException) {
      throw next;
    }
    return next as Map<String, dynamic>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CursorOAuth', () {
    test('authorize packs uuid and PKCE verifier for the poll secret', () async {
      final oauth = CursorOAuth(http: _FakeHttp([]));
      final device = await oauth.authorize();
      expect(device.deviceCode.contains('|'), isTrue);
      expect(device.verificationUri, contains('loginDeepControl'));
      expect(device.verificationUri, contains('challenge='));
      expect(device.userCode, hasLength(8));
    });

    test('poll 404 stays pending', () async {
      final http = _FakeHttp([ProviderHttpException(404, 'not yet')]);
      final oauth = CursorOAuth(http: http, apiBase: 'https://api2.example');
      expect(await oauth.poll('uuid-1|verifier'), isNull);
    });

    test('poll returns a credential from accessToken', () async {
      final http = _FakeHttp([
        {
          'accessToken': _jwt({
            'sub': 'u1',
            'email': 'dev@cursor.com',
            'exp': 4102444800,
          }),
          'refreshToken': 'rt',
        },
      ]);
      final oauth = CursorOAuth(http: http);
      final cred = await oauth.poll('uuid-1|verifier');
      expect(cred, isNotNull);
      expect(cred!.providerId, 'cursor');
      expect(cred.method, HarnessAuthMethod.oauth);
      expect(cred.email, 'dev@cursor.com');
      expect(cred.accountId, 'u1');
      expect(http.gets.single.queryParameters['uuid'], 'uuid-1');
      expect(http.gets.single.queryParameters['verifier'], 'verifier');
    });

    test('a truncated poll secret fails closed', () async {
      final oauth = CursorOAuth(http: _FakeHttp([]));
      expect(
        () => oauth.poll('no-separator'),
        throwsA(isA<HarnessDeviceAuthException>()),
      );
    });
  });
}

String _jwt(Map<String, dynamic> claims) {
  String b64(List<int> bytes) => base64UrlEncode(bytes).replaceAll('=', '');
  final header = b64(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = b64(utf8.encode(jsonEncode(claims)));
  return '$header.$payload.';
}
