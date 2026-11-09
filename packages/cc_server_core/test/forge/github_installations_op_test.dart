import 'dart:io';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/catalog/github_app_ops.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:test/test.dart';

import 'github_clients_test.dart' as harness show testPem;

const _ws = 'ws';

final class _Members implements WorkspaceMembershipRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [repos] are the workspace's linked repositories.
final class _Repos implements RepoRepository {
  _Repos(this.repos);

  final List<Repo> repos;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Repo>> getAll(String workspaceId) async =>
      workspaceId == _ws ? repos : const [];
}

Repo _repo(String owner, {ForgeHost forge = ForgeHost.github}) => Repo(
  id: 'r-$owner',
  name: '$owner/api',
  path: '/src/$owner/api',
  remoteOwner: owner,
  remoteName: 'api',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  forge: forge,
);

/// `github.installations` shows only the accounts this workspace's linked
/// repositories live under, never the rest of what the App is installed on.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('cc_gh_installs_'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// The op on the server's own App, which GitHub says is installed on Acme,
  /// globex and someone's personal account.
  Future<RepoOp> op(List<Repo> repos) async {
    final secrets = FileSecretsStore(dataDir: dir.path);
    final apps = ProviderAppSettings(
      secrets: secrets,
      githubAppFactory: ({required appId, required pem}) => GitHubAppClient(
        appId: appId,
        privateKeyPem: pem,
        httpClient: TestHttpClient(
          handler: (request) => httpTextResponse(request, [
            for (final (id, login) in [
              (1, 'Acme'),
              (2, 'globex'),
              (3, 'someone'),
            ])
              {
                'id': id,
                'account': {'login': login, 'id': id * 10},
                'target_type': id == 3 ? 'User' : 'Organization',
              },
          ]),
        ),
      ),
    );
    await apps.save(
      ProviderApp.github,
      appId: '4242',
      clientId: 'Iv1.client',
      clientSecret: 'secret',
      privateKeyPem: harness.testPem,
    );
    final workspace = Workspace(
      id: _ws,
      name: _ws,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      ownerUserId: 'alice',
    );
    final clients = GitHubClients(
      credentials: ForgeCredentials(
        env: (_) => null,
        users: UserCredentialsStore(secrets),
      ),
      apps: apps,
      workspaceApps: WorkspaceGitHubAppSettings(
        secrets: secrets,
        install: apps,
      ),
      workspaceLookup: (id) async => id == _ws ? workspace : null,
      members: _Members(),
      connect: ConnectClient(settings: ConnectSettings(secrets: secrets)),
      isLinkedRepo: (_, _, _) async => true,
    );
    return buildGitHubAppOps(
      clients: clients,
      manifest: null,
      pairingServerUrl: 'https://cc.example.com',
      repos: _Repos(repos),
    ).firstWhere((o) => o.name == 'github.installations');
  }

  Future<List<String>> listed(RepoOp op) async {
    final result = await op.handler(
      const RepoOpContext(
        args: {},
        workspaceId: _ws,
        deviceId: 'd',
        userId: 'alice',
      ),
    );
    return [
      for (final i in result['installations']! as List)
        (i as Map)['account_login'] as String,
    ];
  }

  test('lists only accounts that own a linked repository', () async {
    expect(await listed(await op([_repo('acme')])), ['Acme']);
  });

  test('a workspace with no GitHub repository lists nothing', () async {
    expect(
      await listed(await op([_repo('globex', forge: ForgeHost.gitlab)])),
      isEmpty,
    );
  });
}
