import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileSecretsStore secrets;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_forge_creds_');
    secrets = FileSecretsStore(dataDir: dir.path);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  ForgeCredentials build({
    Map<String, String> env = const {},
    ({String token, String username})? ghCli,
    Future<String?> Function(ForgeHost, String)? viewerProbe,
  }) => ForgeCredentials(
    secrets: secrets,
    env: (name) => env[name],
    ghCliProbe: ghCli == null ? null : () async => ghCli,
    viewerProbe: viewerProbe,
  );

  group('precedence', () {
    test('a Settings token wins over the environment and the CLI', () async {
      final creds = build(
        env: {'GITHUB_TOKEN': 'from-env'},
        ghCli: (token: 'from-cli', username: 'cliuser'),
      );
      await creds.setToken(ForgeHost.github, 'from-settings');

      expect(await creds.tokenFor(ForgeHost.github), 'from-settings');
      final connection = (await creds.connections()).firstWhere(
        (c) => c.forge == ForgeHost.github,
      );
      expect(connection.source, ForgeCredentialSource.settings);
    });

    test('the environment wins over the CLI', () async {
      final creds = build(
        env: {'GITHUB_TOKEN': 'from-env'},
        ghCli: (token: 'from-cli', username: 'cliuser'),
      );
      expect(await creds.tokenFor(ForgeHost.github), 'from-env');
    });

    test('the CLI is the last resort', () async {
      final creds = build(ghCli: (token: 'from-cli', username: 'cliuser'));
      expect(await creds.tokenFor(ForgeHost.github), 'from-cli');
    });

    test('the CLI fallback is GitHub-only', () async {
      // A host with `gh` installed must not make GitLab look connected.
      final creds = build(ghCli: (token: 'from-cli', username: 'cliuser'));
      expect(await creds.tokenFor(ForgeHost.gitlab), isNull);
      expect(await creds.tokenFor(ForgeHost.bitbucket), isNull);
    });

    test('each forge reads its own environment variables', () async {
      final creds = build(
        env: {
          'GH_TOKEN': 'gh',
          'GITLAB_TOKEN': 'gl',
          'BITBUCKET_API_TOKEN': 'bb',
        },
      );
      expect(await creds.tokenFor(ForgeHost.github), 'gh');
      expect(await creds.tokenFor(ForgeHost.gitlab), 'gl');
      expect(await creds.tokenFor(ForgeHost.bitbucket), 'bb');
    });

    test('a forge with nothing configured has no token', () async {
      final creds = build();
      for (final forge in ForgeHost.supported) {
        expect(await creds.tokenFor(forge), isNull, reason: forge.name);
      }
    });

    test('the local pseudo-forge never resolves a credential', () async {
      final creds = build(env: {'GITHUB_TOKEN': 'x'});
      expect(await creds.tokenFor(ForgeHost.local), isNull);
    });
  });

  group('connections', () {
    test('reports every supported forge, in order', () async {
      final connections = await build().connections();
      expect(
        connections.map((c) => c.forge).toList(),
        ForgeHost.supported,
      );
      expect(connections.every((c) => !c.authenticated), isTrue);
    });

    test('never carries a token', () async {
      final creds = build();
      await creds.setToken(ForgeHost.github, 'super-secret');
      final json = (await creds.connections())
          .firstWhere((c) => c.forge == ForgeHost.github)
          .toJson()
          .toString();
      expect(json, isNot(contains('super-secret')));
    });

    test('one forge connecting leaves the others disconnected', () async {
      final creds = build();
      await creds.setToken(ForgeHost.gitlab, 'gl');
      final byForge = {for (final c in await creds.connections()) c.forge: c};

      expect(byForge[ForgeHost.gitlab]!.authenticated, isTrue);
      expect(byForge[ForgeHost.github]!.authenticated, isFalse);
      expect(byForge[ForgeHost.bitbucket]!.authenticated, isFalse);
    });

    test('the CLI supplies its username without a probe', () async {
      final creds = build(ghCli: (token: 't', username: 'octocat'));
      final gh = (await creds.connections()).firstWhere(
        (c) => c.forge == ForgeHost.github,
      );
      expect(gh.authenticated, isTrue);
      expect(gh.username, 'octocat');
      expect(gh.source, ForgeCredentialSource.cli);
    });
  });

  group('testConnection', () {
    test('resolves the viewer and caches it', () async {
      var probes = 0;
      final creds = build(
        viewerProbe: (forge, token) async {
          probes++;
          return 'resolved-user';
        },
      );
      await creds.setToken(ForgeHost.gitlab, 'gl');

      final result = await creds.testConnection(ForgeHost.gitlab);
      expect(result.authenticated, isTrue);
      expect(result.username, 'resolved-user');

      // The cached identity serves later reads rather than re-probing.
      expect(await creds.viewerLogin(ForgeHost.gitlab), 'resolved-user');
      expect(probes, 1);
    });

    test('a rejected credential reports unauthenticated with a reason',
        () async {
      final creds = build(viewerProbe: (forge, token) async => null);
      await creds.setToken(ForgeHost.gitlab, 'bad');

      final result = await creds.testConnection(ForgeHost.gitlab);
      expect(result.authenticated, isFalse);
      expect(result.error, contains('GitLab'));
    });

    test('changing a token invalidates the cached identity', () async {
      var next = 'first';
      final creds = build(viewerProbe: (forge, token) async => next);
      await creds.setToken(ForgeHost.gitlab, 'a');
      expect(await creds.viewerLogin(ForgeHost.gitlab), 'first');

      next = 'second';
      await creds.setToken(ForgeHost.gitlab, 'b');
      expect(await creds.viewerLogin(ForgeHost.gitlab), 'second');
    });
  });

  group('clearing', () {
    test('falls back to the next source rather than staying connected',
        () async {
      final creds = build(env: {'GITHUB_TOKEN': 'from-env'});
      await creds.setToken(ForgeHost.github, 'from-settings');
      expect(await creds.tokenFor(ForgeHost.github), 'from-settings');

      await creds.clearToken(ForgeHost.github);
      expect(await creds.tokenFor(ForgeHost.github), 'from-env');
    });

    test('an empty token clears rather than storing an empty credential',
        () async {
      final creds = build();
      await creds.setToken(ForgeHost.github, 'x');
      await creds.setToken(ForgeHost.github, '');
      expect(await creds.tokenFor(ForgeHost.github), isNull);
    });

    test('the revision bumps on every credential change', () async {
      final creds = build();
      final before = creds.revision;
      await creds.setToken(ForgeHost.github, 'x');
      expect(creds.revision, greaterThan(before));
    });
  });
}
