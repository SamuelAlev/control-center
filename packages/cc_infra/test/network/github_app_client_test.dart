import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/network/github/github_app_client.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// A 2048-bit key generated for this test and used nowhere else.
const _testKeyPem = '''
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1oBppJyKMeYgcjUYMYgsuycTm9rDmhmwxlAWPSvKkU7dudpa
B7lcgz4shv5qmOZ69MS3E2wlh7ztPUpE2/gmPGGprEvERAwEnOxC2eVzoVX023Va
yQNdisqWVmsoW/30lVKPCxynVG78cxWE6KzYqbg+ru5plAof7gHt9gKsv55ybJWw
YptP42DrbFh69A2HRtLaoTrk1yPjBNzT/0xxQO1tf2lZbNbd1Z5LOSt7YSmzaUL/
R+JnEF3DLhQxOv4DNdwds//CvfuMvgnjMXqdfWxzQlQAWYYEE55QpJfPpCSMKmIn
7vI16xGoAoyF3yqmp1MNMeulz5ieTe3z/wcGtQIDAQABAoIBAGYJCbfjOx3HcXHC
bfLJ6zVPvlUqOFeqltuPJzUMCr0afgC1rJP2CdrojXfduElpgd3DYa8ch7HNHjFE
jgLxRQb+Eh9Cn2cbLGqVPKu4KUv6vpJSfdAXCL1H50HOkZFI+bq6Xg8UH0jbzrzT
5Lhl2F7LpQ3DnXdtZYjrZA3dcd1oG0BaojY+JnI6HNz/QbPNQQprYkrwykuRcqUF
Y51fCsdktdmB8vYma3yUfMfMpyrvZ6l7xIGJwjulspIuKQWAnraqRV1fB+V6ZHSt
PaZr/p91NXn6GnAYmupCdC1/oqVJVjcMmxBp940lra8vW64TJf6z43zsObD9mqz0
t1Q2rkECgYEA/PCqRj1HOh0YzNbjV1Cv1Y0rtHqT6n2FNM+mXZvNqm0qFR/g2f+G
wOvfAev2a749NxKr2ljl5xPMTwtA/FvH0JR3RLGXqwSoUR7Ag8m3yozWg4EVdKyK
ByQrmTQ1RUvmlF5uELnwsA+A3rgTSa6/hpK7X15Q+RcaStsRmI1ww/ECgYEA2Ri0
6Kw+bNT7+tIoVFERkJXe+5hiPFxuLBTPHwBqYsF4uTIVQk5zQPqZDLaXv+mOYgEU
D5Shd4I/ROMJ5y8ITxkc0HjfqUF/XPgqF3LqWtLLhLrqoo1JaoeoRQzggb9n6MQe
+KSWHTC4FsLjxEc5SbLXXhFbzQHhCqnoqgndYwUCgYEAsZ09tDzrez9bXtu2oGWk
U0ziV8WLgKnLlB4MMMdrUDV/y32rIulv8qCu5GaRj27zBW0zCAxMxEr+uLKqW4sH
cMwQREiAvDJ1DyGNBf3r9WuYZpeKPXe7JPCdPOOQVKzLqXv1xgELplX8pGiWArOX
AiSfNoTAT2mNqOrUHE+V08ECgYBFCZdWOpgrcduj2rsafSFR0mczqTTsLxSWDhQD
rtUmDJKAik26ZUo/irGrGlHNpM8zmVYw0jo6z/+gv3aBvzIsPTctkJLHt11ySjTQ
einOsiQoVGyTPszvBK7dLogimqTHn76doXFfXQPdsSJPY7rzFd1pO6nu2r8e7gNg
N3zgpQKBgQCm/sXLID74u9VtVlhL0nhv6zaKm3UqcMtdu+ivl/intWZTGbXUxJqq
L+pzaH8qXpUpjZynoVk8RE8aCqN9h34//JD4u7TOtcHoZmbA+AMdPmc1vknVbvn5
SVgaUK2148/jd/aKIcXn3k4Hc17BYRgsoeMdfe3jrjOw4SknWBjC5g==
-----END RSA PRIVATE KEY-----
''';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.responses);

  final Map<String, Object> responses;
  final List<String> paths = [];
  final List<String> authorizations = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    authorizations.add('${options.headers[HttpHeaders.authorizationHeader]}');
    final body = responses[options.path];
    if (body == null) {
      return ResponseBody.fromString('{}', 404);
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        HttpHeaders.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Map<String, Object> responsesWith({
    String token = 'ghs_token',
    Duration expiresIn = const Duration(hours: 1),
    DateTime? now,
  }) => {
    '/app/installations': [
      {
        'id': 42,
        'account': {'login': 'acme'},
        'repository_selection': 'all',
      },
      {
        'id': 43,
        'account': {'login': 'other-org'},
        'repository_selection': 'selected',
      },
    ],
    '/app/installations/42/access_tokens': {
      'token': token,
      'expires_at': (now ?? DateTime.now().toUtc())
          .add(expiresIn)
          .toIso8601String(),
    },
    '/app/installations/43/access_tokens': {
      'token': '$token-other',
      'expires_at': (now ?? DateTime.now().toUtc())
          .add(expiresIn)
          .toIso8601String(),
    },
  };

  ({GitHubAppClient client, _RecordingAdapter adapter}) build({
    Map<String, Object>? responses,
    DateTime Function()? now,
  }) {
    final adapter = _RecordingAdapter(responses ?? responsesWith());
    final dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'))
      ..httpClientAdapter = adapter;
    return (
      client: GitHubAppClient(
        appId: '12345',
        privateKeyPem: _testKeyPem,
        dio: dio,
        now: now,
      ),
      adapter: adapter,
    );
  }

  group('the app JWT', () {
    test('is RS256 and carries the app id as the issuer', () {
      final jwt = build().client.buildAppJwt();
      final parts = jwt.split('.');
      expect(parts, hasLength(3));

      Map<String, dynamic> decode(String segment) =>
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(segment))))
              as Map<String, dynamic>;

      expect(decode(parts[0])['alg'], 'RS256');
      expect(decode(parts[1])['iss'], '12345');
    });

    test('expires inside GitHub\'s ten-minute ceiling', () {
      final jwt = build().client.buildAppJwt();
      final claims =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(base64Url.normalize(jwt.split('.')[1])),
                ),
              )
              as Map<String, dynamic>;
      final iat = claims['iat'] as int;
      final exp = claims['exp'] as int;
      expect(exp - iat, lessThanOrEqualTo(600));
    });

    test('is presented as the bearer on app requests', () async {
      final built = build();
      await built.client.installations();
      expect(built.adapter.authorizations.first, startsWith('Bearer eyJ'));
    });
  });

  group('tryCreate', () {
    test('refuses a key that does not parse, rather than failing later', () {
      // A bad key must be rejected while the operator is still looking at the
      // settings screen, not on a background request hours later.
      expect(
        GitHubAppClient.tryCreate(appId: '1', privateKeyPem: 'not a key'),
        isNull,
      );
    });

    test('is null when the app is simply not configured', () {
      expect(GitHubAppClient.tryCreate(appId: '', privateKeyPem: ''), isNull);
    });
  });

  group('installations', () {
    test('are read once and cached', () async {
      final built = build();
      await built.client.installations();
      await built.client.installations();
      expect(
        built.adapter.paths.where((p) => p == '/app/installations'),
        hasLength(1),
      );
    });

    test('a failure is not cached', () async {
      // A network blip must not leave the app permanently "installed
      // nowhere" until the next restart.
      final built = build(responses: const {});
      expect(await built.client.installations(), isEmpty);
      expect(await built.client.installations(), isEmpty);
      expect(
        built.adapter.paths.where((p) => p == '/app/installations').length,
        greaterThan(1),
      );
    });
  });

  group('installation tokens', () {
    test('resolve by owner', () async {
      final built = build();
      expect(await built.client.tokenForOwner('acme'), 'ghs_token');
      expect(await built.client.tokenForOwner('other-org'), 'ghs_token-other');
    });

    test('owner matching is case-insensitive', () async {
      expect(await build().client.tokenForOwner('ACME'), 'ghs_token');
    });

    test('an owner with no installation has no token', () async {
      expect(await build().client.tokenForOwner('stranger'), isNull);
    });

    test('are cached until they are nearly expired', () async {
      final built = build();
      await built.client.tokenForOwner('acme');
      await built.client.tokenForOwner('acme');
      expect(
        built.adapter.paths.where(
          (p) => p == '/app/installations/42/access_tokens',
        ),
        hasLength(1),
      );
    });

    test('are re-minted once inside the five-minute margin', () async {
      var now = DateTime.utc(2026, 1, 1, 12);
      final built = build(
        responses: responsesWith(
          expiresIn: const Duration(minutes: 6),
          now: now,
        ),
        now: () => now,
      );
      await built.client.tokenForInstallation(42);
      now = now.add(const Duration(minutes: 2));
      await built.client.tokenForInstallation(42);

      expect(
        built.adapter.paths.where(
          (p) => p == '/app/installations/42/access_tokens',
        ),
        hasLength(2),
      );
    });

    test('invalidate drops every cached token', () async {
      final built = build();
      await built.client.tokenForInstallation(42);
      built.client.invalidate();
      await built.client.tokenForInstallation(42);

      expect(
        built.adapter.paths.where(
          (p) => p == '/app/installations/42/access_tokens',
        ),
        hasLength(2),
      );
    });

    test('a mint failure resolves to null rather than throwing', () async {
      // The caller has other credential lanes; a broken app must not take
      // the server's forge access down with it.
      final built = build(
        responses: {
          '/app/installations': [
            {
              'id': 42,
              'account': {'login': 'acme'},
            },
          ],
        },
      );
      expect(await built.client.tokenForOwner('acme'), isNull);
    });
  });
}
