import 'dart:io';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart'
    show LinearAppGrants;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late ProviderAppSettings install;
  late WorkspaceGitHubAppSettings apps;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_ws_gh_');
    secrets = FileSecretsStore(dataDir: dir.path);
    install = ProviderAppSettings(secrets: secrets);
    apps = WorkspaceGitHubAppSettings(secrets: secrets, install: install);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Workspace workspace({
    required String id,
    GithubAuthMode mode = GithubAuthMode.inherit,
    String appId = '',
  }) {
    final now = DateTime.utc(2024);
    return Workspace(
      id: id,
      name: id,
      createdAt: now,
      updatedAt: now,
      githubAuthMode: mode,
      githubAppId: appId,
    );
  }

  test('app mode with no key does not inherit the install App', () async {
    final ws = workspace(id: 'ws-app', mode: GithubAuthMode.app, appId: '9');
    expect(await apps.githubApp(ws), isNull);
  });

  test(
    'deleteForWorkspace removes the App key and the Linear app grant',
    () async {
      await secrets.writePsk(
        WorkspaceGitHubAppSettings.privateKeySecret('ws-1'),
        'pem',
      );
      await secrets.writePsk(LinearAppGrants.keyFor('ws-1'), '{"access":"x"}');
      await secrets.writePsk(LinearAppGrants.keyFor('ws-2'), '{"access":"y"}');
      await secrets.writePsk('unrelated', 'keep-me');
      await apps.deleteForWorkspace('ws-1');
      expect(
        await secrets.readPsk(
          WorkspaceGitHubAppSettings.privateKeySecret('ws-1'),
        ),
        isNull,
      );
      expect(await secrets.readPsk(LinearAppGrants.keyFor('ws-1')), isNull);
      expect(await secrets.readPsk(LinearAppGrants.keyFor('ws-2')), isNotNull);
      expect(await secrets.readPsk('unrelated'), 'keep-me');
    },
  );

  test('purgeLegacyTokens deletes stored workspace PATs only', () async {
    await secrets.writePsk('workspace_forge_github_ws-1', 'gho_pat');
    await secrets.writePsk('unrelated', 'keep-me');
    expect(await apps.purgeLegacyTokens(), 1);
    expect(await secrets.readPsk('workspace_forge_github_ws-1'), isNull);
    expect(await secrets.readPsk('unrelated'), 'keep-me');
  });

  test('deleteForWorkspace also drops per-user GitHub overlays', () async {
    await secrets.writePsk('user_forge_github_alice_ws-1', 'gho_alice');
    await secrets.writePsk('user_forge_github_alice_ws-2', 'gho_other');
    await apps.deleteForWorkspace('ws-1');
    expect(await secrets.readPsk('user_forge_github_alice_ws-1'), isNull);
    expect(await secrets.readPsk('user_forge_github_alice_ws-2'), 'gho_other');
  });
}
