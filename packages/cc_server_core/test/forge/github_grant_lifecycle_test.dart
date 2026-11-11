import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeCredentialSource;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_automation_tokens.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_repo_unlink.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:rhttp/rhttp.dart' show HttpBodyJson;
import 'package:test/test.dart';

import '../helpers/test_database.dart';
import 'github_clients_test.dart' show testPem;

/// GitHub as `GitHubRest` reaches it: the accountable person's repository
/// read, the own-App downscope and every revocation.
final class _FakeGitHub extends GitHubRest {
  _FakeGitHub();

  /// Every call: method, path, bearer token, Basic client id, body.
  final calls =
      <
        ({
          String method,
          String path,
          String? bearer,
          String? clientId,
          Object? body,
        })
      >[];

  /// Held open until completed, for the repository read.
  Completer<void>? repoGate;

  /// What `/token/scoped` answers on top of the asked permissions.
  Map<String, String> extraScopedPermissions = const {};

  /// What a revoked installation token's probe answers.
  int probeAfterRevoke = 401;

  /// What the accountable person's repository read answers.
  int repoStatus = 200;

  var _child = 0;

  @override
  Future<GitHubRestResponse> send(
    String method,
    String path, {
    Map<String, String>? query,
    String? bearer,
    ({String clientId, String clientSecret})? basic,
    Object? body,
  }) async {
    calls.add((
      method: method,
      path: path,
      bearer: bearer,
      clientId: basic?.clientId,
      body: body,
    ));
    if (method == 'GET' && path == '/repos/acme/api') {
      await repoGate?.future;
      if (repoStatus != 200) {
        return GitHubRestResponse(repoStatus, const {'message': 'Not Found'});
      }
      return const GitHubRestResponse(200, {
        'id': 7,
        'name': 'api',
        'owner': {'id': 9, 'login': 'acme'},
        'private': true,
        'permissions': {'admin': false, 'push': true, 'pull': true},
      });
    }
    if (method == 'POST' && path.endsWith('/token/scoped')) {
      final asked = (body! as Map)['permissions'] as Map<String, String>;
      return GitHubRestResponse(200, {
        'token': 'ghu_child${_child++}',
        'repository_selection': 'selected',
        'permissions': {...asked, ...extraScopedPermissions},
      });
    }
    if (method == 'DELETE') {
      return const GitHubRestResponse(204, null);
    }
    if (method == 'GET' && path == '/installation/repositories') {
      return GitHubRestResponse(probeAfterRevoke, null);
    }
    return const GitHubRestResponse(404, null);
  }

  /// Tokens revoked with `DELETE /applications/{client}/token`, by client.
  List<(String?, String)> get userRevokes => [
    for (final c in calls)
      if (c.method == 'DELETE' && c.path.startsWith('/applications/'))
        (c.clientId, (c.body! as Map)['access_token'] as String),
  ];

  /// Tokens revoked with `DELETE /installation/token`.
  List<String> get installationRevokes => [
    for (final c in calls)
      if (c.method == 'DELETE' && c.path == '/installation/token') c.bearer!,
  ];

  int get downscopes =>
      calls.where((c) => c.path.endsWith('/token/scoped')).length;
}

final class _Members implements WorkspaceMembershipRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      WorkspaceMember(
        id: 'm-$userId',
        workspaceId: workspaceId,
        userId: userId,
        role: WorkspaceRole.member,
        joinedAt: DateTime.utc(2026),
      );
}

/// A stateless installation token as GitHub now mints them
/// (`ghs_<app id>_<JWT>`): about 520 characters, dots included.
String statelessInstallationToken(String salt) {
  String segment(int length) =>
      base64Url.encode(utf8.encode(salt * length)).replaceAll('=', '');
  final jwt = '${segment(14)}.${segment(300).substring(0, 380)}.${segment(90)}'
      .substring(0, 507);
  return 'ghs_4242_$jwt';
}

void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late ProviderAppSettings apps;
  late ForgeCredentials credentials;
  late _FakeGitHub github;
  late Set<String> linked;
  late List<String> mintedInstallationTokens;
  late List<String> logLines;
  late String Function(int n) nextInstallationToken;
  late List<int> mintedRepositoryIds;
  late int repoInstallationStatus;
  late List<Map<String, Object?>> installations;

  const workspaceId = 'ws';

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_grant_lifecycle_');
    addTearDown(() => dir.deleteSync(recursive: true));
    secrets = FileSecretsStore(dataDir: dir.path);
    github = _FakeGitHub();
    linked = {'acme/api'};
    mintedInstallationTokens = [];
    mintedRepositoryIds = [7];
    repoInstallationStatus = 200;
    installations = [
      {
        'id': 42,
        'account': {'login': 'acme'},
        'target_type': 'Organization',
      },
    ];
    nextInstallationToken = (n) => 'ghs_installation$n';
    logLines = [];
    final previousSink = CcHostLog.sink;
    CcHostLog.sink = (level, message, [error, stackTrace]) =>
        logLines.add(message);
    addTearDown(() => CcHostLog.sink = previousSink);
    apps = ProviderAppSettings(
      secrets: secrets,
      githubAppFactory: ({required appId, required pem}) => GitHubAppClient(
        appId: appId,
        privateKeyPem: pem,
        httpClient: TestHttpClient(
          handler: (request) {
            final path = httpRequestUri(request).path;
            if (path == '/app/installations') {
              return httpTextResponse(request, installations);
            }
            if (path == '/app') {
              return httpTextResponse(request, const {'slug': 'cc-test'});
            }
            if (path == '/repos/acme/api/installation') {
              return httpTextResponse(request, const {
                'id': 42,
              }, statusCode: repoInstallationStatus);
            }
            if (path == '/app/installations/42/access_tokens') {
              final body = (request.body! as HttpBodyJson).json as Map;
              final token = nextInstallationToken(
                mintedInstallationTokens.length,
              );
              mintedInstallationTokens.add(token);
              return httpTextResponse(request, {
                'token': token,
                'expires_at': DateTime.now()
                    .toUtc()
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
                'permissions': body['permissions'],
                'repository_selection': 'selected',
                'repositories': [
                  for (final id in mintedRepositoryIds)
                    {'id': id, 'name': 'api'},
                ],
              });
            }
            return httpTextResponse(request, const {}, statusCode: 404);
          },
        ),
      ),
    );
    await apps.save(
      ProviderApp.github,
      appId: '4242',
      clientId: 'Iv1.client',
      clientSecret: 'secret',
      privateKeyPem: testPem,
    );
    credentials = ForgeCredentials(users: UserCredentialsStore(secrets));
  });

  Future<void> signIn(String token) => credentials.storeSignIn(
    ForgeHost.github,
    'alice',
    ProviderToken(
      accessToken: token,
      refreshToken: 'ghr_refresh',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
      source: ForgeCredentialSource.oauth,
      accountLogin: 'alice',
      accountId: '1',
      appId: 'Iv1.client',
    ),
  );

  setUp(() => signIn('ghu_alice_first'));

  var linkedAsked = 0;
  GitHubClients clients({
    int maxCachedGrants = 2048,
    DateTime Function()? now,
  }) {
    final workspace = Workspace(
      id: workspaceId,
      name: workspaceId,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      ownerUserId: 'alice',
    );
    final db = createTestDatabase(workspaceId: workspaceId);
    addTearDown(db.close);
    final service = GitHubClients(
      credentials: credentials,
      apps: apps,
      workspaceApps: WorkspaceGitHubAppSettings(
        secrets: secrets,
        install: apps,
      ),
      workspaceLookup: (id) async => id == workspaceId ? workspace : null,
      members: _Members(),
      connect: ConnectClient(settings: ConnectSettings(secrets: secrets)),
      isLinkedRepo: (ws, owner, repo) async {
        linkedAsked++;
        return linked.contains('${owner.toLowerCase()}/${repo.toLowerCase()}');
      },
      mayReadRepo: (_, _, _, _) async => true,
      repoAccess: RepoAccessRegistry(cacheFor: (_) => db.cacheDao),
      confirmRepo: (_, _, _, _, _) async {},
      confirmPersonRequest: (_, _, _, _, _) async {},
      rest: github,
      maxCachedGrants: maxCachedGrants,
      now: now,
    );
    addTearDown(service.close);
    return service;
  }

  Future<GitHubScopedGrant> push(GitHubClients service) => service.mintScoped(
    workspaceId: workspaceId,
    owner: 'acme',
    repo: 'api',
    scope: GitHubTokenScope.write,
    actingUserId: 'alice',
    viaPerson: true,
  );

  Future<GitHubScopedGrant> read(
    GitHubClients service, {
    String repo = 'api',
  }) => service.mintScoped(
    workspaceId: workspaceId,
    owner: 'acme',
    repo: repo,
    scope: GitHubTokenScope.read,
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('signing in as another account revokes what the old sign-in was '
      'narrowed into, and the next push mints anew', () async {
    final service = clients();
    final first = await push(service);
    expect(identical(await push(service), first), isTrue, reason: 'cached');
    await signIn('ghu_alice_second');
    await settle();
    expect(github.userRevokes, [('Iv1.client', first.token)]);
    final second = await push(service);
    expect(second.token, isNot(first.token));
    expect(github.downscopes, 2);
  });

  test('a mint that lands after a forget is revoked, not cached or handed '
      'out', () async {
    final service = clients();
    github.repoGate = Completer();
    final pending = push(service);
    await settle();
    await service.forgetPerson('alice');
    github.repoGate!.complete();
    await expectLater(
      pending,
      throwsA(
        isA<GitHubScopeRefused>().having(
          (e) => e.code,
          'code',
          GitHubRefusal.providerUnavailable,
        ),
      ),
    );
    expect(github.userRevokes.single.$2, 'ghu_child0');
    github.repoGate = null;
    final fresh = await push(service);
    expect(fresh.token, 'ghu_child1');
    expect(
      github.calls.where((c) => c.path == '/repos/acme/api'),
      hasLength(2),
      reason: 'the repository facts read during the forget were not cached',
    );
  });

  test('a narrowed token is revoked with the App that narrowed it, even after '
      'the App was rotated', () async {
    final service = clients();
    final child = await push(service);
    await apps.save(
      ProviderApp.github,
      appId: '4242',
      clientId: 'Iv1.rotated',
      clientSecret: 'rotated',
      privateKeyPem: testPem,
    );
    await service.forgetAll();
    expect(github.userRevokes, [('Iv1.client', child.token)]);
    expect(
      logLines.where((l) => l.contains('"github.token.revoked"')),
      isNotEmpty,
    );
  });

  test('a narrowed token wider than asked is revoked before it is '
      'refused', () async {
    github.extraScopedPermissions = const {'administration': 'write'};
    final service = clients();
    await expectLater(push(service), throwsA(isA<GitHubScopeRefused>()));
    expect(github.userRevokes, [('Iv1.client', 'ghu_child0')]);
  });

  test('an installation token that covers another repository id is revoked '
      'and refused', () async {
    mintedRepositoryIds = [8];
    final service = clients();
    await expectLater(read(service), throwsA(isA<GitHubScopeRefused>()));
    expect(github.installationRevokes, mintedInstallationTokens);
  });

  test('a repository no longer linked has its cached tokens revoked', () async {
    var clock = DateTime.now().toUtc();
    final service = clients(now: () => clock);
    final grant = await read(service);
    linked = {};
    // Past the few seconds whether it is linked is remembered.
    clock = clock.add(const Duration(seconds: 6));
    await expectLater(read(service), throwsA(isA<GitHubScopeRefused>()));
    expect(github.installationRevokes, [grant.token]);
  });

  test('whether a repository is linked, and the lane, are asked once per few '
      'seconds; unlinking applies at once', () async {
    final service = clients();
    linkedAsked = 0;
    final grant = await read(service);
    await read(service);
    await read(service);
    expect(linkedAsked, 1);
    expect(
      logLines.where((l) => l.contains('"event":"github.lane.resolved"')),
      hasLength(1),
      reason: 'written when the lane changes, not per mint',
    );
    linked = {};
    await service.forgetRepo(workspaceId, 'acme', 'api');
    expect(github.installationRevokes, [grant.token]);
    await expectLater(read(service), throwsA(isA<GitHubScopeRefused>()));
    expect(linkedAsked, 2);
  });

  test('unlinking a repository revokes its GitHub grants and deletes its '
      'own bot token', () async {
    final service = clients();
    final grant = await read(service);
    Repo repo(String id, String owner, String name, ForgeHost forge) => Repo(
      id: id,
      name: '$owner/$name',
      path: '/src/$owner/$name',
      remoteOwner: owner,
      remoteName: name,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      forge: forge,
    );
    final api = repo('r-api', 'acme', 'api', ForgeHost.github);
    final lab = repo('r-lab', 'group', 'lab', ForgeHost.gitlab);
    final db = createTestDatabase(workspaceId: workspaceId);
    addTearDown(db.close);
    final tokens = ForgeAutomationTokens(
      secrets: secrets,
      registry: RepoAccessRegistry(cacheFor: (_) => db.cacheDao),
      identify: (forge, token) async => (
        name: 'Deploy bot',
        login: 'project_1_bot',
        kind: 'project',
        scopes: const ['read_api', 'write_repository'],
      ),
      probe: (forge, token, owner, name) async => 200,
    );
    await tokens.save(
      workspaceId,
      forge: ForgeHost.gitlab,
      token: 'glpat-bot',
      linked: [lab],
      repo: lab,
    );
    bool labSlot(String key) => key.contains('r-lab');
    expect(await secrets.keysMatching(labSlot), hasLength(1));

    for (final unlinkedRepo in [api, lab]) {
      await forgetUnlinkedRepo(
        workspaceId,
        unlinkedRepo,
        github: service,
        automationTokens: tokens,
      );
    }
    expect(github.installationRevokes, [grant.token]);
    expect(await secrets.keysMatching(labSlot), isEmpty);
  });

  test('a grant evicted from a full cache is revoked', () async {
    final service = clients(maxCachedGrants: 1);
    final first = await read(service);
    // Another scope is another cached grant.
    await service.mintScoped(
      workspaceId: workspaceId,
      owner: 'acme',
      repo: 'api',
      scope: GitHubTokenScope.review,
    );
    await settle();
    expect(github.installationRevokes, [first.token]);
  });

  test('a stateless 520-character installation token is minted, cached, '
      'revoked and logged only as its hash', () async {
    nextInstallationToken = (n) => statelessInstallationToken('$n');
    final service = clients();
    final grant = await read(service);
    expect(grant.token.length, greaterThan(500));
    expect(grant.token, contains('.'));
    expect(identical(await read(service), grant), isTrue, reason: 'cached');
    await service.forgetAll();
    expect(github.installationRevokes, [grant.token]);
    final revoked = logLines.singleWhere(
      (l) => l.contains('"github.token.revoked"'),
    );
    expect(revoked, contains(forgeHashedToken(grant.token)));
    for (final line in logLines) {
      expect(line, isNot(contains(grant.token)));
      expect(line, isNot(contains(grant.token.substring(9, 60))));
    }
  });

  test('an installation token GitHub still accepts after the DELETE is '
      'recorded as a failed revocation', () async {
    github.probeAfterRevoke = 200;
    final service = clients();
    await read(service);
    await service.forgetAll();
    expect(
      logLines.where((l) => l.contains('"github.token.revoke_failed"')),
      hasLength(1),
    );
    expect(
      logLines.where((l) => l.contains('"github.token.revoked"')),
      isEmpty,
    );
  });

  group('a repository GitHub hides from the person', () {
    Future<List<RepoAccessIssue>> link(GitHubClients service) async =>
        (await service.verifyLink(
          workspaceId,
          'alice',
          'acme',
          'api',
        )).warnings;

    test('not selected in the installation is the App\'s answer, with '
        'where to select it', () async {
      github.repoStatus = 404;
      repoInstallationStatus = 404;
      final found = await link(clients());
      expect(found.single.state, RepoAccessState.repoNotSelected);
      expect(
        found.single.installUrl,
        'https://github.com/organizations/acme/settings/installations/42',
      );
      expect(mintedInstallationTokens, isEmpty, reason: 'nothing minted');
    });

    test('an owner without the App is "not installed", with the install '
        'link', () async {
      github.repoStatus = 404;
      installations = [];
      final found = await link(clients());
      expect(found.single.state, RepoAccessState.appNotInstalled);
      expect(
        found.single.installUrl,
        'https://github.com/apps/cc-test/installations/new',
      );
    });

    test('a repository the App reaches but the person cannot see is still '
        'refused', () async {
      github.repoStatus = 404;
      await expectLater(link(clients()), throwsA(isA<ValidationException>()));
    });

    test('the poller\'s classification mints nothing', () async {
      github.repoStatus = 404;
      repoInstallationStatus = 404;
      final found = await clients().classifyRepo(workspaceId, 'acme', 'api');
      expect(found.first.state, RepoAccessState.repoNotSelected);
      expect(mintedInstallationTokens, isEmpty);
    });
  });
}
