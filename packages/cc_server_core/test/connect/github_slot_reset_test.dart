import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/github_sign_in_lane.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:test/test.dart';

import '../forge/github_clients_test.dart' show testPem;

/// A Connect that records the grants revoked through it.
final class _RecordingConnect extends ConnectClient {
  _RecordingConnect(ConnectSettings settings)
    : super(settings: settings, trustedRootKeys: const []);

  final List<({ConnectTarget target, GitHubRevokeRequest request})> revoked =
      [];

  @override
  Future<void> githubRevoke(
    ConnectTarget target,
    GitHubRevokeRequest request,
  ) async => revoked.add((target: target, request: request));
}

/// A workspace's GitHub slot grants are revoked and deleted when its
/// sign-in target changes, as Linear's and Google's already are.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late UserCredentialsStore users;
  late Map<String, Workspace> registry;
  late _RecordingConnect connect;
  late ForgeCredentials credentials;
  late GitHubSignInLane lane;
  late ProviderAppSettings apps;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_github_slot_reset_');
    secrets = FileSecretsStore(dataDir: dir.path);
    users = UserCredentialsStore(secrets);
    registry = {
      'ws': Workspace(
        id: 'ws',
        name: 'ws',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        connectMode: WorkspaceConnectMode.hosted,
      ),
    };
    final settings = ConnectSettings(secrets: secrets)
      ..workspaceLookup = (id) async => registry[id];
    connect = _RecordingConnect(settings);
    apps = ProviderAppSettings(secrets: secrets);
    credentials = ForgeCredentials(users: users)
      ..workspaceOwnsSlot = (id) async =>
          (await settings.routeFor(id)).workspaceSlot;
    lane = GitHubSignInLane(
      apps: apps,
      workspaceApps: WorkspaceGitHubAppSettings(
        secrets: secrets,
        install: apps,
      ),
      workspaceLookup: (id) async => registry[id],
      credentials: credentials,
      users: users,
      connect: connect,
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  ProviderToken seal(String blob) => ProviderToken(
    seal: blob,
    sealInstallId: 'inst-1',
    connectOrigin: canonicalConnectBaseUrl(hostedConnectOrigin),
    source: ForgeCredentialSource.connect,
    accountLogin: 'octo',
    accountId: '583231',
  );

  ProviderToken ownApp(String access, String clientId) => ProviderToken(
    accessToken: access,
    refreshToken: 'ghr',
    expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
    source: ForgeCredentialSource.oauth,
    appId: clientId,
  );

  test('every slot grant is revoked at the Connect that sealed it and '
      'deleted; global grants stay', () async {
    await users.setForgeToken(
      'alice',
      ForgeHost.github,
      seal('alice-seal'),
      workspaceId: 'ws',
    );
    await users.setForgeToken(
      'bob',
      ForgeHost.github,
      ownApp('ghu_bob', 'Iv1.old'),
      workspaceId: 'ws',
    );
    await users.setForgeToken('alice', ForgeHost.github, seal('global-seal'));

    expect(await lane.resetWorkspaceSlot('ws'), 2);

    expect(
      await users.forgeToken('alice', ForgeHost.github, workspaceId: 'ws'),
      isNull,
    );
    expect(
      await users.forgeToken('bob', ForgeHost.github, workspaceId: 'ws'),
      isNull,
    );
    expect(await users.forgeToken('alice', ForgeHost.github), isNotNull);
    expect(connect.revoked, hasLength(1));
    expect(connect.revoked.single.request.seal, 'alice-seal');
    expect(connect.revoked.single.request.workspaceId, 'ws');
    expect(connect.revoked.single.target.mode, ConnectMode.hosted);
  });

  test('an own-App save keeps the grants its client still issues', () async {
    await users.setForgeToken(
      'alice',
      ForgeHost.github,
      ownApp('ghu_alice', 'Iv1.same'),
      workspaceId: 'ws',
    );
    await users.setForgeToken(
      'bob',
      ForgeHost.github,
      ownApp('ghu_bob', 'Iv1.old'),
      workspaceId: 'ws',
    );

    expect(
      await lane.resetWorkspaceSlot(
        'ws',
        where: (token) => token.isSealed || token.appId != 'Iv1.same',
      ),
      1,
    );
    expect(
      await users.forgeToken('alice', ForgeHost.github, workspaceId: 'ws'),
      isNotNull,
    );
    expect(
      await users.forgeToken('bob', ForgeHost.github, workspaceId: 'ws'),
      isNull,
    );
  });

  test('a hosted workspace on a hosted server reads the global grant, '
      'never its old slot', () async {
    await connect.settings.setChoice(ConnectMode.hosted);
    await users.setForgeToken(
      'alice',
      ForgeHost.github,
      seal('slot-seal'),
      workspaceId: 'ws',
    );
    await users.setForgeToken('alice', ForgeHost.github, seal('global-seal'));

    final stored = await credentials.storedCredential(
      ForgeHost.github,
      'alice',
      workspaceId: 'ws',
    );
    expect(stored?.workspaceId, isNull);
    expect(stored?.token.seal, 'global-seal');
    expect(await lane.slotFor('ws'), isNull);

    await connect.settings.setChoice(ConnectMode.off);
    final owned = await credentials.storedCredential(
      ForgeHost.github,
      'alice',
      workspaceId: 'ws',
    );
    expect(owned?.workspaceId, 'ws');
    expect(owned?.token.seal, 'slot-seal');
    expect(await lane.slotFor('ws'), 'ws');
  });

  test('the lane reports the connection status and scope', () async {
    await connect.settings.setChoice(ConnectMode.off);
    credentials.currentSealInstallId = (origin, {workspaceId}) async => null;
    await users.setForgeToken(
      'alice',
      ForgeHost.github,
      seal('slot-seal'),
      workspaceId: 'ws',
    );

    final connection = await lane.connection('alice', 'ws');
    expect(connection?.status, ForgeConnectionStatus.paused);
    expect(connection?.workspaceSlot, isTrue);
    expect(connection?.account, 'octo');
    expect(connection?.toJson()['status'], 'paused');
  });

  test(
    'an own-App grant is revoked only with the App that issued it',
    () async {
      final lines = <String>[];
      final previous = CcHostLog.sink;
      CcHostLog.sink = (level, message, [error, stack]) => lines.add(message);
      addTearDown(() => CcHostLog.sink = previous);
      await connect.settings.setChoice(ConnectMode.off);
      await apps.save(
        ProviderApp.github,
        appId: '4242',
        clientId: 'Iv1.new',
        clientSecret: 'secret',
        privateKeyPem: testPem,
      );

      await lane.revokeOwnGrant(ownApp('ghu_bob', 'Iv1.old'), null);

      final skipped = lines.where(
        (l) => l.contains('"event":"grant.revoke_skipped"'),
      );
      expect(skipped.single, contains('"reason":"app_changed"'));
      expect(skipped.single, isNot(contains('ghu_bob')));
    },
  );
}
