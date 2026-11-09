import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:test/test.dart';

/// A 2048-bit key generated for tests and used nowhere else.
const testPem = '''
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

/// Only [member] belongs to the workspace.
final class _Members implements WorkspaceMembershipRepository {
  _Members(this.member);

  final String? member;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      userId == member
      ? WorkspaceMember(
          id: 'm-$userId',
          workspaceId: workspaceId,
          userId: userId,
          role: WorkspaceRole.member,
          joinedAt: DateTime.utc(2026),
        )
      : null;
}

/// The refusals `GitHubClients` makes before it asks GitHub anything.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late ProviderAppSettings apps;
  late List<String> appRequests;

  const workspaceId = 'ws';

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_github_clients_');
    secrets = FileSecretsStore(dataDir: dir.path);
    appRequests = [];
    apps = ProviderAppSettings(
      secrets: secrets,
      githubAppFactory: ({required appId, required pem}) => GitHubAppClient(
        appId: appId,
        privateKeyPem: pem,
        httpClient: TestHttpClient(
          handler: (request) {
            appRequests.add(httpRequestUri(request).path);
            return httpTextResponse(request, const {
              'message': 'Not Found',
            }, statusCode: 404);
          },
        ),
      ),
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<GitHubClients> clients({
    bool ownApp = true,
    Set<String> linked = const {'acme/api'},
    String? member,
  }) async {
    if (ownApp) {
      await apps.save(
        ProviderApp.github,
        appId: '4242',
        clientId: 'Iv1.client',
        clientSecret: 'secret',
        privateKeyPem: testPem,
      );
    }
    final users = UserCredentialsStore(secrets);
    final workspace = Workspace(
      id: workspaceId,
      name: workspaceId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      ownerUserId: 'alice',
    );
    return GitHubClients(
      credentials: ForgeCredentials(env: (_) => null, users: users),
      apps: apps,
      workspaceApps: WorkspaceGitHubAppSettings(
        secrets: secrets,
        install: apps,
      ),
      workspaceLookup: (id) async => id == workspaceId ? workspace : null,
      members: _Members(member),
      connect: ConnectClient(settings: ConnectSettings(secrets: secrets)),
      isLinkedRepo: (ws, owner, repo) async =>
          ws == workspaceId &&
          linked.contains('${owner.toLowerCase()}/${repo.toLowerCase()}'),
    );
  }

  Future<String> refusal(Future<Object?> call) async {
    try {
      await call;
    } on GitHubScopeRefused catch (e) {
      return e.code;
    }
    fail('expected GitHubScopeRefused');
  }

  test('a chosen Connect leaves the stored own App inactive', () async {
    final choice = ConnectSettings(secrets: secrets);
    apps = ProviderAppSettings(
      secrets: secrets,
      ownAppsActive: choice.serverOwnAppsActive,
    );
    final github = await clients();
    expect(await github.laneFor(workspaceId), GitHubLane.ownApp);
    await choice.setChoice(ConnectMode.hosted);
    expect(await github.laneFor(workspaceId), isNot(GitHubLane.ownApp));
    expect(await apps.githubApp(), isNull);
    await choice.setChoice(ConnectMode.off);
    expect(await github.laneFor(workspaceId), GitHubLane.ownApp);
  });

  test('a repository not linked to the workspace gets no token', () async {
    final github = await clients(member: 'alice');
    expect(
      await refusal(
        github.mintScoped(
          workspaceId: workspaceId,
          owner: 'acme',
          repo: 'secrets',
          scope: GitHubTokenScope.read,
        ),
      ),
      'access_denied',
    );
    expect(appRequests, isEmpty, reason: 'the App was never asked');
  });

  test('an own-App read needs an accountable person; the App alone mints '
      'nothing', () async {
    // Nobody accountable: the workspace owner is not a member.
    final github = await clients(member: null);
    expect(
      await refusal(
        github.mintScoped(
          workspaceId: workspaceId,
          owner: 'acme',
          repo: 'api',
          scope: GitHubTokenScope.read,
        ),
      ),
      'needs_sign_in',
    );
    expect(appRequests.where((p) => p.endsWith('/access_tokens')), isEmpty);
  });

  test(
    'linking needs the linker signed in when a GitHub lane exists',
    () async {
      final github = await clients(member: 'alice');
      expect(
        await refusal(github.verifyLink(workspaceId, 'alice', 'acme', 'api')),
        'needs_sign_in',
      );
    },
  );

  test('with no GitHub lane, a link has nothing to check', () async {
    final github = await clients(ownApp: false, member: 'alice');
    await github.verifyLink(workspaceId, 'alice', 'acme', 'api');
  });
}
