import 'dart:convert';
import 'dart:io';

import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/jwt_claims.dart';
import 'package:cc_harness_runtime/src/oauth/kimi_oauth.dart';
import 'package:cc_harness_runtime/src/oauth/oauth_provider.dart';
import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:test/test.dart';

/// A [ProviderHttp] that answers form posts from a script instead of the wire.
class _FakeHttp implements ProviderHttp {
  _FakeHttp(this.responses);

  /// Queued responses; a `ProviderHttpException` is thrown instead of returned.
  final List<Object> responses;
  final List<Map<String, String>> sentFields = [];
  final List<Map<String, String>> sentHeaders = [];

  @override
  Future<Map<String, dynamic>> postForm(
    Uri uri, {
    Map<String, String> headers = const {},
    required Map<String, String> fields,
  }) async {
    sentFields.add(fields);
    sentHeaders.add(headers);
    final next = responses.removeAt(0);
    if (next is ProviderHttpException) {
      throw next;
    }
    return next as Map<String, dynamic>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Builds an unsigned JWT carrying [claims] (only the payload is ever read).
String _jwt(Map<String, dynamic> claims) {
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg({'alg': 'none'})}.${seg(claims)}.sig';
}

void main() {
  group('decodeJwtClaims', () {
    test('reads the payload of a well-formed token', () {
      expect(decodeJwtClaims(_jwt({'email': 'a@b.c'}))['email'], 'a@b.c');
    });

    test('anything unparseable is an empty map, never a throw', () {
      expect(decodeJwtClaims(null), isEmpty);
      expect(decodeJwtClaims('not-a-jwt'), isEmpty);
      expect(decodeJwtClaims('a.!!!!.c'), isEmpty);
      expect(decodeJwtClaims(_jwt({}).replaceFirst('.', '')), isEmpty);
    });

    test('firstClaim takes the first non-empty spelling', () {
      const claims = {'email': '  ', 'user_email': 'real@example.com'};
      expect(firstClaim(claims, ['email', 'user_email']), 'real@example.com');
      expect(firstClaim(claims, ['nope']), isNull);
    });
  });

  group('KimiOAuth', () {
    test(
      'authorize returns what the user is shown and what we poll with',
      () async {
        final http = _FakeHttp([
          {
            'device_code': 'dev',
            'user_code': 'AB12-CD34',
            'verification_uri': 'https://www.kimi.com/code/authorize_device',
            'verification_uri_complete':
                'https://www.kimi.com/code/authorize_device?user_code=AB12-CD34',
            'expires_in': 1800,
            'interval': 5,
          },
        ]);
        final auth = await KimiOAuth(http: http).authorize();
        expect(auth.deviceCode, 'dev');
        expect(auth.userCode, 'AB12-CD34');
        // The pre-filled URL wins, so the user does not retype the code.
        expect(auth.verificationUri, contains('user_code=AB12-CD34'));
        expect(auth.interval, const Duration(seconds: 5));
        expect(auth.expiresIn, const Duration(minutes: 30));
        expect(http.sentFields.single['client_id'], KimiOAuth.clientId);
        expect(http.sentHeaders.single['X-Msh-Platform'], 'kimi_cli');
      },
    );

    test(
      'a missing field in the authorize response is a clear failure',
      () async {
        final http = _FakeHttp([
          {'user_code': 'AB12'},
        ]);
        expect(
          () => KimiOAuth(http: http).authorize(),
          throwsA(isA<HarnessDeviceAuthException>()),
        );
      },
    );

    test('pending polls return null so the broker keeps waiting', () async {
      final http = _FakeHttp([
        {'error': 'authorization_pending'},
        ProviderHttpException(400, '{"error":"authorization_pending"}'),
      ]);
      final kimi = KimiOAuth(http: http);
      expect(await kimi.poll('dev'), isNull);
      expect(await kimi.poll('dev'), isNull);
    });

    test('slow_down asks the broker to back off, not to give up', () async {
      final http = _FakeHttp([
        ProviderHttpException(400, '{"error":"slow_down"}'),
      ]);
      expect(
        () => KimiOAuth(http: http).poll('dev'),
        throwsA(isA<HarnessDeviceSlowDown>()),
      );
    });

    test(
      'denial and expiry are terminal, with messages a user can act on',
      () async {
        for (final (code, fragment) in [
          ('access_denied', 'denied'),
          ('expired_token', 'expired'),
        ]) {
          final http = _FakeHttp([
            ProviderHttpException(400, '{"error":"$code"}'),
          ]);
          await expectLater(
            () => KimiOAuth(http: http).poll('dev'),
            throwsA(
              isA<HarnessDeviceAuthException>().having(
                (e) => e.message.toLowerCase(),
                'message',
                contains(fragment),
              ),
            ),
          );
        }
      },
    );

    test(
      'a granted token becomes an OAuth credential on the plan host',
      () async {
        final http = _FakeHttp([
          {
            'access_token': _jwt({'email': 'dev@example.com'}),
            'refresh_token': 'r1',
            'expires_in': 3600,
          },
        ]);
        final cred = await KimiOAuth(http: http).poll('dev');
        expect(cred!.method, HarnessAuthMethod.oauth);
        expect(cred.refreshToken, 'r1');
        expect(cred.baseUrl, KimiOAuth.apiBaseUrl);
        // The token said who it is, so the tile can name the account.
        expect(cred.email, 'dev@example.com');
        expect(cred.accountLabel, 'dev@example.com');
        // Renewed early, so a run starting near expiry does not die mid-stream.
        expect(
          cred.expiresAt!.isBefore(
            DateTime.now().add(const Duration(hours: 1)),
          ),
          isTrue,
        );
      },
    );

    test('an opaque token still connects, named by the plan', () async {
      final http = _FakeHttp([
        {'access_token': 'opaque', 'refresh_token': 'r1', 'expires_in': 3600},
      ]);
      final cred = await KimiOAuth(http: http).poll('dev');
      expect(cred!.email, isNull);
      expect(cred.accountLabel, 'Kimi Code plan');
    });

    test(
      'refresh keeps the prior refresh token when the response omits it',
      () async {
        // Dropping it would silently end the session at the next expiry.
        final http = _FakeHttp([
          {'access_token': 'fresh', 'expires_in': 3600},
        ]);
        final refreshed = await KimiOAuth(http: http).refresh(
          const ProviderCredential(
            providerId: 'kimi-code',
            method: HarnessAuthMethod.oauth,
            accessToken: 'stale',
            refreshToken: 'r1',
            accountId: 'device-abc',
          ),
        );
        expect(refreshed.accessToken, 'fresh');
        expect(refreshed.refreshToken, 'r1');
        // The device identity must survive a refresh — the API headers key off it.
        expect(refreshed.accountId, 'device-abc');
        expect(http.sentFields.single['grant_type'], 'refresh_token');
      },
    );

    test(
      'the device id is stable across instances sharing a data dir',
      () async {
        final dir = Directory.systemTemp.createTempSync('kimi-device').path;
        final first = KimiOAuth(dataDir: dir).deviceId();
        final second = KimiOAuth(dataDir: dir).deviceId();
        expect(first, isNotEmpty);
        expect(second, first);
        Directory(dir).deleteSync(recursive: true);
      },
    );

    test('an unwritable data dir still yields a usable id', () {
      // Header construction must never be what takes authentication down.
      final id = KimiOAuth(dataDir: '/proc/nonexistent/nope').deviceId();
      expect(id, isNotEmpty);
    });
  });
}
