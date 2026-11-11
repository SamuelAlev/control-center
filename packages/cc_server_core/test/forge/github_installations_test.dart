import 'dart:io';

import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/github_installations.dart';
import 'package:cc_server_core/src/forge/github_lane_resolver.dart';
import 'package:cc_server_core/src/forge/github_minter.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:test/test.dart';

/// `GET /user/installations` pages: 250 installations, ours spread over all
/// three pages.
final class _PagedGitHub extends GitHubRest {
  final pages = <String>[];

  @override
  Future<GitHubRestResponse> send(
    String method,
    String path, {
    Map<String, String>? query,
    String? bearer,
    ({String clientId, String clientSecret})? basic,
    Object? body,
  }) async {
    final page = int.parse(query!['page']!);
    pages.add('$page');
    final first = (page - 1) * 100;
    final count = page < 3 ? 100 : 50;
    return GitHubRestResponse(200, {
      'total_count': 250,
      'installations': [
        for (var i = first; i < first + count; i++)
          {
            'app_id': i % 50 == 0 ? 4242 : 1,
            'account': {'login': 'org$i'},
            'suspended_at': i == 200 ? '2026-01-01T00:00:00Z' : null,
          },
      ],
    });
  }
}

void main() {
  test('every page of a person’s installations is read', () async {
    final dir = Directory.systemTemp.createTempSync('cc_installations_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final secrets = FileSecretsStore(dataDir: dir.path);
    final apps = ProviderAppSettings(secrets: secrets);
    final connect = ConnectClient(settings: ConnectSettings(secrets: secrets));
    final rest = _PagedGitHub();
    final installations = GitHubInstallations(
      lanes: GitHubLaneResolver(
        apps: apps,
        workspaceApps: WorkspaceGitHubAppSettings(
          secrets: secrets,
          install: apps,
        ),
        workspaceLookup: (_) async => null,
        connect: connect,
      ),
      connect: connect,
      seals: GitHubSeals(
        ForgeCredentials(users: UserCredentialsStore(secrets)),
      ),
      rest: rest,
      humanToken: (_) async => null,
      now: DateTime.now,
    );

    final found = await installations.userInstallations('ghu_token', 4242);

    expect(rest.pages, ['1', '2', '3']);
    expect(
      [for (final i in found) i.account],
      ['org0', 'org50', 'org100', 'org150', 'org200'],
    );
    expect(
      [
        for (final i in found)
          if (i.suspended) i.account,
      ],
      ['org200'],
    );
  });
}
