import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, ValidationException;
import 'package:cc_server_core/src/connect/github_manifest_service.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:test/test.dart';

/// A 2048-bit key generated for tests and used nowhere else: saving an app
/// validates that the PEM parses.
const _pem = '''
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

void main() {
  late Directory dir;
  late ProviderAppSettings apps;
  late HttpServer github;
  late Map<String, Object?> answer;
  late int status;
  final hits = <String>[];

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_manifest_');
    apps = ProviderAppSettings(secrets: FileSecretsStore(dataDir: dir.path));
    status = 201;
    hits.clear();
    github = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    github.listen((request) async {
      hits.add('${request.method} ${request.uri.path}');
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(answer));
      await request.response.close();
    });
  });

  tearDown(() async {
    await github.close(force: true);
    dir.deleteSync(recursive: true);
  });

  GitHubManifestService service() => GitHubManifestService(
    apps: apps,
    apiBase: Uri.parse('http://127.0.0.1:${github.port}'),
  );

  /// Runs begin → page and returns the state, nonce and browser key the
  /// page carries.
  ({String state, String nonce, String browser}) startFlow(
    GitHubManifestService svc, {
    String organization = '',
    int? ownerAccountId,
  }) {
    final url = svc.begin(
      origin: 'https://cc.example',
      organization: organization,
      ownerAccountId: ownerAccountId,
    );
    final page = svc.startPage(url.queryParameters['ticket']!)!;
    final state = RegExp(
      r'state=([A-Za-z0-9_-]+)',
    ).firstMatch(page.html)!.group(1)!;
    final nonce = RegExp(
      r'Control Center ([0-9a-f]{16})',
    ).firstMatch(const HtmlUnescape().convert(page.html))!.group(1)!;
    return (state: state, nonce: nonce, browser: page.browserKey);
  }

  Map<String, Object?> app(String nonce, {Map<String, Object?>? owner}) => {
    'id': 4242,
    'slug': 'control-center-$nonce',
    'name': 'Control Center $nonce',
    'client_id': 'Iv1.client',
    'client_secret': 'secret',
    'pem': _pem,
    'owner': owner ?? {'login': 'octocat', 'id': 583231, 'type': 'User'},
    'permissions': GitHubManifestService.permissions,
  };

  test('begin needs a reachable origin and a valid organization', () {
    final svc = service();
    expect(() => svc.begin(origin: ''), throwsA(isA<ValidationException>()));
    expect(
      () => svc.begin(origin: 'https://cc.example', organization: 'no/such'),
      throwsA(isA<ValidationException>()),
    );
  });

  test('the start page is served once and posts an inactive-webhook '
      'manifest', () {
    final svc = service();
    final url = svc.begin(origin: 'https://cc.example');
    expect(url.toString(), startsWith('https://cc.example/oauth/github/'));
    final ticket = url.queryParameters['ticket']!;
    final page = svc.startPage(ticket)!;
    expect(page.secure, isTrue);
    final manifest = const HtmlUnescape().convert(page.html);
    expect(manifest, contains('https://github.com/settings/apps/new?state='));
    expect(manifest, contains('"active":false'));
    expect(manifest, contains('"public":false'));
    expect(
      manifest,
      contains('https://cc.example${GitHubManifestService.callbackPath}'),
    );
    expect(svc.startPage(ticket), isNull, reason: 'single serve');
  });

  test('an organization app posts to that organization', () {
    final svc = service();
    final url = svc.begin(origin: 'https://cc.example', organization: 'acme');
    final page = svc.startPage(url.queryParameters['ticket']!)!;
    expect(
      const HtmlUnescape().convert(page.html),
      contains('https://github.com/organizations/acme/settings'),
    );
  });

  test('complete converts the code and stores the app', () async {
    final svc = service();
    final flow = startFlow(svc);
    answer = app(flow.nonce);

    final result = await svc.complete(
      Uri.parse(
        'https://cc.example${GitHubManifestService.callbackPath}'
        '?code=abc123&state=${flow.state}',
      ),
      browserKey: flow.browser,
    );
    expect(hits, ['POST /app-manifests/abc123/conversions']);
    expect(result.slug, 'control-center-${flow.nonce}');
    expect(
      result.installUrl.toString(),
      'https://github.com/apps/control-center-${flow.nonce}/installations/new',
    );
    final saved = await apps.status(ProviderApp.github);
    expect(saved.state, OwnAppState.complete);
    expect(saved.appId, '4242');
  });

  test('a state is single use', () async {
    final svc = service();
    final flow = startFlow(svc);
    answer = app(flow.nonce);
    final callback = Uri.parse(
      'https://cc.example/cb?code=abc&state=${flow.state}',
    );
    await svc.complete(callback, browserKey: flow.browser);
    await expectLater(
      svc.complete(callback, browserKey: flow.browser),
      throwsA(isA<AuthException>()),
    );
  });

  test('an unknown state converts nothing', () async {
    final svc = service();
    final flow = startFlow(svc);
    await expectLater(
      svc.complete(
        Uri.parse('https://cc.example/cb?code=abc&state=forged'),
        browserKey: flow.browser,
      ),
      throwsA(isA<AuthException>()),
    );
    expect(hits, isEmpty);
  });

  test(
    'a state carried to another browser converts nothing and is spent',
    () async {
      final svc = service();
      final flow = startFlow(svc);
      answer = app(flow.nonce);
      final callback = Uri.parse(
        'https://cc.example/cb?code=abc&state=${flow.state}',
      );
      await expectLater(
        svc.complete(callback, browserKey: 'not-the-cookie'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        svc.complete(callback, browserKey: flow.browser),
        throwsA(isA<AuthException>()),
        reason: 'the attempt was spent by the wrong browser',
      );
      expect(hits, isEmpty);
      expect((await apps.status(ProviderApp.github)).state, OwnAppState.none);
    },
  );

  test("an app without this attempt's nonce is refused", () async {
    final svc = service();
    final flow = startFlow(svc);
    answer = app('f' * 16 == flow.nonce ? '0' * 16 : 'f' * 16);
    await expectLater(
      svc.complete(
        Uri.parse('https://cc.example/cb?code=abc&state=${flow.state}'),
        browserKey: flow.browser,
      ),
      throwsA(isA<AuthException>()),
    );
    expect((await apps.status(ProviderApp.github)).state, OwnAppState.none);
  });

  group('an app that is not exactly what this attempt posted is refused', () {
    for (final (label, edit)
        in <(String, void Function(Map<String, Object?>, String))>[
          (
            'a name that only contains the nonce',
            (a, nonce) => a['name'] = 'Not Control Center $nonce',
          ),
          (
            'a permission the manifest never asked for',
            (a, _) => a['permissions'] = {
              'metadata': 'read',
              'administration': 'write',
            },
          ),
          (
            'a higher level than asked',
            (a, _) => a['permissions'] = {'checks': 'write'},
          ),
          (
            'an answer that does not say what it holds',
            (a, _) => a.remove('permissions'),
          ),
        ]) {
      test(label, () async {
        final svc = service();
        final flow = startFlow(svc);
        answer = app(flow.nonce);
        edit(answer, flow.nonce);
        await expectLater(
          svc.complete(
            Uri.parse('https://cc.example/cb?code=abc&state=${flow.state}'),
            browserKey: flow.browser,
          ),
          throwsA(isA<AuthException>()),
        );
        expect((await apps.status(ProviderApp.github)).state, OwnAppState.none);
      });
    }

    test('an app holding less than asked is fine', () async {
      final svc = service();
      final flow = startFlow(svc);
      answer = app(flow.nonce)..['permissions'] = {'metadata': 'read'};
      await svc.complete(
        Uri.parse('https://cc.example/cb?code=abc&state=${flow.state}'),
        browserKey: flow.browser,
      );
      expect(
        (await apps.status(ProviderApp.github)).state,
        OwnAppState.complete,
      );
    });
  });

  test(
    'a personal app under someone other than the signed-in owner is refused',
    () async {
      final svc = service();
      final flow = startFlow(svc, ownerAccountId: 583231);
      answer = app(
        flow.nonce,
        owner: {'login': 'attacker', 'id': 999, 'type': 'User'},
      );
      await expectLater(
        svc.complete(
          Uri.parse('https://cc.example/cb?code=abc&state=${flow.state}'),
          browserKey: flow.browser,
        ),
        throwsA(isA<AuthException>()),
      );
      expect((await apps.status(ProviderApp.github)).state, OwnAppState.none);
    },
  );

  test('an app under another account than requested is refused', () async {
    final svc = service();
    final flow = startFlow(svc, organization: 'acme');
    answer = app(
      flow.nonce,
      owner: {'login': 'someone-else', 'type': 'Organization'},
    );
    await expectLater(
      svc.complete(
        Uri.parse('https://cc.example/cb?code=abc&state=${flow.state}'),
        browserKey: flow.browser,
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('a failed conversion stores nothing', () async {
    final svc = service();
    final flow = startFlow(svc);
    status = 422;
    answer = {'message': 'Validation Failed'};
    await expectLater(
      svc.complete(
        Uri.parse('https://cc.example/cb?code=abc&state=${flow.state}'),
        browserKey: flow.browser,
      ),
      throwsA(isA<AuthException>()),
    );
    expect((await apps.status(ProviderApp.github)).state, OwnAppState.none);
  });
}

/// Undoes [HtmlEscape] for the handful of entities it produces.
class HtmlUnescape {
  const HtmlUnescape();

  String convert(String input) => input
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#47;', '/')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}
