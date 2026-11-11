import 'dart:io';

import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:test/test.dart';

/// Own-app credentials: nothing ships in a build, a half-configured app is a
/// setup error (never a Connect fallback), and the environment seeds once.
void main() {
  late Directory dir;
  late ProviderAppSettings apps;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_provider_apps_');
    apps = ProviderAppSettings(secrets: FileSecretsStore(dataDir: dir.path));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('a stock server has no own app for any provider', () async {
    for (final provider in ProviderApp.values) {
      final status = await apps.status(provider);
      expect(status.state, OwnAppState.none, reason: provider.wire);
      expect(status.canSignIn, isFalse, reason: provider.wire);
      expect(await apps.oauthCredentials(provider), isNull);
    }
    expect((await apps.status(ProviderApp.github)).canActAsServer, isFalse);
  });

  test('a Google client id without its secret is partial', () async {
    await apps.save(ProviderApp.google, clientId: 'id.apps.googleusercontent');
    expect((await apps.status(ProviderApp.google)).state, OwnAppState.partial);
    expect(
      () => apps.oauthCredentials(ProviderApp.google),
      throwsA(isA<OwnAppIncomplete>()),
    );
  });

  test('a complete Google client resolves to its pair', () async {
    await apps.save(
      ProviderApp.google,
      clientId: 'id.apps.googleusercontent',
      clientSecret: 'shh',
    );
    final credentials = await apps.oauthCredentials(ProviderApp.google);
    expect(credentials!.clientId, 'id.apps.googleusercontent');
    expect(credentials.clientSecret, 'shh');
    // The secret is reported as present, never echoed.
    final wire = (await apps.status(ProviderApp.google)).toJson();
    expect(wire['has_client_secret'], isTrue);
    expect(wire.values, isNot(contains('shh')));
  });

  test('the environment seeds unset fields once', () async {
    await apps.loadAndApply(
      env: {
        'GOOGLE_OAUTH_CLIENT_ID': 'one.apps.googleusercontent',
        'GOOGLE_OAUTH_CLIENT_SECRET': 'one',
      },
    );
    var credentials = await apps.oauthCredentials(ProviderApp.google);
    expect(credentials!.clientSecret, 'one');
    await apps.loadAndApply(env: {'GOOGLE_OAUTH_CLIENT_SECRET': 'two'});
    credentials = await apps.oauthCredentials(ProviderApp.google);
    expect(credentials!.clientSecret, 'one');
  });

  test('a field cleared in Settings stays cleared while the environment still '
      'has it', () async {
    const env = {
      'GOOGLE_OAUTH_CLIENT_ID': 'one.apps.googleusercontent',
      'GOOGLE_OAUTH_CLIENT_SECRET': 'one',
    };
    await apps.loadAndApply(env: env);
    await apps.save(ProviderApp.google, clientId: '', clientSecret: '');
    await apps.loadAndApply(env: env);
    expect(await apps.oauthCredentials(ProviderApp.google), isNull);
    expect((await apps.status(ProviderApp.google)).state, OwnAppState.none);
  });

  test('clearing both Google fields returns the lane to none', () async {
    await apps.save(ProviderApp.google, clientId: 'id', clientSecret: 'shh');
    await apps.save(ProviderApp.google, clientId: '', clientSecret: '');
    expect(await apps.oauthCredentials(ProviderApp.google), isNull);
  });
}
