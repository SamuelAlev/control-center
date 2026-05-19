import 'dart:io';

import 'package:cc_server_core/src/builtin_credentials.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:test/test.dart';

/// What an OFFICIAL build offers before anyone configures anything.
///
/// The built-in tier is empty in this repository (the release job writes it),
/// so these assert against the constant rather than a literal — that keeps them
/// honest in a release checkout, where the value is real.
void main() {
  late Directory dir;
  late ProviderAppSettings apps;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_provider_apps_');
    apps = ProviderAppSettings(secrets: FileSecretsStore(dataDir: dir.path));
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('GitHub falls back to the built-in device-flow client id', () async {
    // This is what makes "Sign in with GitHub" work out of the box: a device
    // flow authenticates with the client id alone, so the id can ship.
    final status = await apps.status(ProviderApp.github);
    expect(status.clientId, builtinGitHubClientId);
    expect(status.canSignIn, builtinGitHubClientId.isNotEmpty);
  });

  test('no client secret ships — the sign-in never sends one', () async {
    // A device flow authenticates with the id alone. The only thing a secret
    // would buy is refreshing an expiring token, and the shipped app leaves
    // token expiry off so nothing needs refreshing.
    final credentials = await apps.oauthCredentials(ProviderApp.github);
    if (builtinGitHubClientId.isEmpty) {
      expect(credentials, isNull);
      return;
    }
    expect(credentials!.clientId, builtinGitHubClientId);
    expect(credentials.clientSecret, isEmpty);
  });

  test('an operator id wins over the built-in one', () async {
    await apps.save(ProviderApp.github, clientId: 'their-own-id');
    final status = await apps.status(ProviderApp.github);
    expect(status.clientId, 'their-own-id');
    expect(status.canSignIn, isTrue);
    final credentials = await apps.oauthCredentials(ProviderApp.github);
    expect(credentials!.clientId, 'their-own-id');
    expect(credentials.clientSecret, isEmpty);
  });

  test('GITHUB_CLIENT_SECRET seeds from the environment, once', () async {
    // The secret never ships in a build, but an operator whose own app has
    // token expiry on can supply it via the environment; without it an
    // expiring user token cannot be refreshed. The seed writes only an unset
    // field — a stored value survives later boots with a different env.
    await apps.loadAndApply(
      env: {'GITHUB_CLIENT_ID': 'their-own-id', 'GITHUB_CLIENT_SECRET': 'one'},
    );
    var credentials = await apps.oauthCredentials(ProviderApp.github);
    expect(credentials!.clientSecret, 'one');
    await apps.loadAndApply(env: {'GITHUB_CLIENT_SECRET': 'two'});
    credentials = await apps.oauthCredentials(ProviderApp.github);
    expect(credentials!.clientSecret, 'one');
  });

  test('the server identity is NOT built in', () async {
    // The app's private key mints installation tokens for every repository the
    // app can see; an extracted copy would read all of them. The server binary
    // is the distributed artifact, so only the client id ships — a stock build
    // still has no identity of its own.
    final status = await apps.status(ProviderApp.github);
    expect(status.hasPrivateKey, isFalse);
    expect(status.canActAsServer, isFalse);
  });

  test('Linear ships no app — its flow would need a secret', () async {
    final status = await apps.status(ProviderApp.linear);
    expect(status.clientId, isEmpty);
    expect(status.canSignIn, isFalse);
  });
}
