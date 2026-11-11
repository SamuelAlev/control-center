import 'dart:io';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/connect/linear_sign_in_lane.dart'
    show LinearAppGrants;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
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
    WorkspaceConnectMode mode = WorkspaceConnectMode.inherit,
    String appId = '',
  }) {
    final now = DateTime.utc(2024);
    return Workspace(
      id: id,
      name: id,
      createdAt: now,
      updatedAt: now,
      connectMode: mode,
      githubAppId: appId,
    );
  }

  test('own mode with no key does not inherit the install App', () async {
    final ws = workspace(
      id: 'ws-app',
      mode: WorkspaceConnectMode.own,
      appId: '9',
    );
    expect(await apps.githubApp(ws), isNull);
  });

  test('a workspace on its own Connect uses no App here at all', () async {
    for (final mode in [
      WorkspaceConnectMode.hosted,
      WorkspaceConnectMode.custom,
    ]) {
      final ws = workspace(id: 'ws-c', mode: mode, appId: '9');
      expect(await apps.githubApp(ws), isNull, reason: mode.wireName);
      expect(await apps.oauthCredentials(ws), isNull, reason: mode.wireName);
    }
  });

  test('a half-set-up App is a setup error only in own mode', () async {
    await apps.save(
      workspace(id: 'ws-p', appId: '9'),
      clientId: 'Iv1.ws',
    );
    for (final mode in WorkspaceConnectMode.values) {
      final status = await apps.status(
        workspace(id: 'ws-p', mode: mode, appId: '9'),
      );
      expect(status.state, OwnAppState.partial, reason: mode.wireName);
      expect(
        status.error,
        mode == WorkspaceConnectMode.own ? isNotEmpty : isEmpty,
        reason: mode.wireName,
      );
    }
  });

  test('deletion listeners run after the workspace data is gone', () async {
    final heard = <String>[];
    apps.addDeletionListener((workspaceId) async => heard.add(workspaceId));
    await apps.deleteForWorkspace('ws-1');
    expect(heard, ['ws-1']);
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

  test(
    'deleteForWorkspace drops every forge sign-in and lapse marker in its '
    'own slot, and nothing of another workspace',
    () async {
      final users = UserCredentialsStore(secrets);
      for (final forge in ForgeHost.values) {
        for (final ws in ['ws-1', 'ws-10']) {
          await users.setForgeToken(
            'alice',
            forge,
            const ProviderToken(accessToken: 'access'),
            workspaceId: ws,
          );
          await users.markForgeLapsed('bob', forge, 'bob', workspaceId: ws);
        }
      }
      await apps.deleteForWorkspace('ws-1');
      for (final forge in ForgeHost.values) {
        expect(
          await users.forgeToken('alice', forge, workspaceId: 'ws-1'),
          isNull,
        );
        expect(await users.forgeLapse('bob', forge, workspaceId: 'ws-1'), isNull);
        expect(
          await users.forgeToken('alice', forge, workspaceId: 'ws-10'),
          isNotNull,
        );
        expect(
          await users.forgeLapse('bob', forge, workspaceId: 'ws-10'),
          'bob',
        );
      }
    },
  );

  test(
    'a workspace named like a person never reaches their global sign-in',
    () async {
      // A workspace id is chosen by its creator: one equal to another
      // user's id must not delete that user's own credentials with it.
      const victim = '5b0c8a52-1e7f-4a7e-9d33-2f1c3a9e8b41';
      final users = UserCredentialsStore(secrets);
      for (final forge in ForgeHost.values) {
        await users.setForgeToken(
          victim,
          forge,
          const ProviderToken(accessToken: 'access'),
        );
        await users.markForgeLapsed(victim, forge, 'victim');
      }
      await apps.deleteForWorkspace(victim);
      for (final forge in ForgeHost.values) {
        expect(await users.forgeToken(victim, forge), isNotNull);
        expect(await users.forgeLapse(victim, forge), 'victim');
      }
    },
  );
}
