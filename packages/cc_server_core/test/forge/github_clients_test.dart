import 'dart:async';
import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectErrorCode, GitHubMintActor, GitHubTokenScope;
import 'package:cc_domain/cc_domain.dart'
    show NeedsSignInException, NetworkException, ValidationException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeCredentialSource;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_infra/cc_infra.dart'
    show ForgeCredentialUnavailable, GitHubAppClient;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';
import 'package:cc_server_core/src/forge/github_graphql_policy.dart';
import 'package:cc_server_core/src/forge/github_minter.dart';
import 'package:cc_server_core/src/forge/github_request_policy.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/forge/skill_source_github.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:rhttp/rhttp.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

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
  late RepoAccessRegistry repoAccess;
  late ForgeCredentials credentials;

  const workspaceId = 'ws';

  setUp(() {
    final db = createTestDatabase(workspaceId: workspaceId);
    addTearDown(db.close);
    repoAccess = RepoAccessRegistry(cacheFor: (_) => db.cacheDao);
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
    Set<String> skillSources = const {},
    String? member,
    Set<String>? readers,
    GitHubRest? rest,
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
        credentials: credentials = ForgeCredentials(users: users),
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
        repoAccess: repoAccess,
        confirmRepo: (_, _, _, _, _) async {},
        confirmPersonRequest: (_, _, _, _, _) async {},
        rest: rest,
        // Every member may read every linked repository unless [readers]
        // names who may.
        mayReadRepo: (ws, userId, owner, repo) async =>
            readers == null ||
            readers.contains(
              '$userId:${owner.toLowerCase()}/'
              '${repo.toLowerCase()}',
            ),
      )
      ..isSkillSource = (ws, owner, repo) async =>
          ws == workspaceId &&
          skillSources.contains('${owner.toLowerCase()}/${repo.toLowerCase()}');
  }

  Future<String> refusal(Future<Object?> call) async {
    try {
      await call;
    } on GitHubScopeRefused catch (e) {
      return e.code.wire;
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
    // The runtime forgets everything GitHub on a Connect change.
    choice.addListener(() => unawaited(github.forgetAll()));
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

  test('acting through a person with nobody acting is refused, never '
      'minted for the workspace owner', () async {
    final github = await clients(member: 'alice');
    expect(
      await refusal(
        github.mintScoped(
          workspaceId: workspaceId,
          owner: 'acme',
          repo: 'api',
          scope: GitHubTokenScope.write,
          viaPerson: true,
        ),
      ),
      GitHubRefusal.needsRequester.wire,
    );
    expect(appRequests, isEmpty);
  });

  test('automation for a person needs their read grant on that repo, not '
      'only membership', () async {
    final github = await clients(member: 'bob', readers: const {});
    expect(
      await refusal(
        github.mintScoped(
          workspaceId: workspaceId,
          owner: 'acme',
          repo: 'api',
          scope: GitHubTokenScope.read,
          actingUserId: 'bob',
        ),
      ),
      'access_denied',
    );
    expect(
      await github.accountableHuman(
        workspaceId,
        actingUserId: 'bob',
        owner: 'acme',
        repo: 'api',
      ),
      isNull,
    );
    // Membership alone still bounds work that names no repository.
    expect(
      await github.accountableHuman(workspaceId, actingUserId: 'bob'),
      'bob',
    );
    final granted = await clients(member: 'bob', readers: {'bob:acme/api'});
    expect(
      await granted.accountableHuman(
        workspaceId,
        actingUserId: 'bob',
        owner: 'acme',
        repo: 'api',
      ),
      'bob',
    );
    expect(appRequests.where((p) => p.endsWith('/access_tokens')), isEmpty);
  });

  group('skill sources', () {
    Future<String> mint(
      GitHubClients github, {
      GitHubTokenScope scope = GitHubTokenScope.read,
      bool skillSource = true,
      bool viaPerson = false,
    }) => refusal(
      github.mintScoped(
        workspaceId: workspaceId,
        owner: 'acme',
        repo: 'skills',
        scope: scope,
        skillSource: skillSource,
        viaPerson: viaPerson,
      ),
    );

    test('a registered source passes the link gate for a read', () async {
      final github = await clients(
        member: 'alice',
        skillSources: {'acme/skills'},
      );
      // Past the gate, the mint stops at the accountable person's sign-in.
      expect(await mint(github), 'needs_sign_in');
    });

    test('only the skill-source client may ask', () async {
      final github = await clients(
        member: 'alice',
        skillSources: {'acme/skills'},
      );
      expect(await mint(github, skillSource: false), 'access_denied');
    });

    test(
      'a source never gets more than read, nor a person narrowing',
      () async {
        final github = await clients(
          member: 'alice',
          skillSources: {'acme/skills'},
        );
        for (final scope in [
          GitHubTokenScope.review,
          GitHubTokenScope.bot,
          GitHubTokenScope.write,
        ]) {
          expect(await mint(github, scope: scope), 'access_denied');
        }
        expect(await mint(github, viaPerson: true), 'access_denied');
        expect(appRequests, isEmpty, reason: 'the App was never asked');
      },
    );

    test('an unregistered repository is still refused', () async {
      final github = await clients(member: 'alice');
      expect(await mint(github), 'access_denied');
    });

    test('the skill-source client sends nothing but one-repository '
        'reads', () async {
      final github = await clients(
        member: 'alice',
        skillSources: {'acme/skills'},
      );
      try {
        await github.tokenForRequest(
          workspaceId,
          'acme',
          method: 'GET',
          url: '/user',
          skillSource: true,
        );
        fail('expected ForgeCredentialUnavailable');
      } on ForgeCredentialUnavailable catch (e) {
        expect(e.statusCode, 404);
      }
    });

    test('without a person the router names the refusal instead of a '
        'missing repository', () async {
      final github = await clients(member: 'alice');
      await expectLater(
        SkillSourceGitHub(github).clientFor(workspaceId, 'acme', 'other'),
        throwsA(
          isA<NetworkException>()
              .having((e) => e.code, 'code', 'access_denied')
              .having((e) => e.message, 'message', contains('skill sources')),
        ),
      );
    });

    test('a person who is not signed in gets no fallback', () async {
      final github = await clients(member: 'alice');
      await expectLater(
        SkillSourceGitHub(
          github,
        ).clientFor(workspaceId, 'acme', 'other', actingUserId: 'alice'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  test(
    'linking needs the linker signed in when a GitHub lane exists',
    () async {
      final github = await clients(member: 'alice');
      await expectLater(
        github.verifyLink(workspaceId, 'alice', 'acme', 'api'),
        throwsA(
          isA<NeedsSignInException>().having((e) => e.lane, 'lane', 'github'),
        ),
      );
    },
  );

  group(
    'an automation request with no credential is never sent anonymously',
    () {
      Future<int> status(
        GitHubClients github,
        String url, {
        String method = 'GET',
        String? actingUserId,
      }) async {
        try {
          await github.tokenForRequest(
            workspaceId,
            'acme',
            method: method,
            url: url,
            actingUserId: actingUserId,
          );
        } on ForgeCredentialUnavailable catch (e) {
          return e.statusCode;
        }
        fail('expected ForgeCredentialUnavailable');
      }

      test('a refused mint reads as GitHub hiding the repo', () async {
        final github = await clients(member: 'alice');
        expect(await status(github, '/repos/acme/secrets/pulls'), 404);
      });

      test('nobody signed in reads as unauthenticated', () async {
        final github = await clients(member: null);
        expect(await status(github, '/repos/acme/api/pulls'), 401);
      });

      test('a request about no one repository never rides a person when '
          'nobody is acting', () async {
        final github = await clients(member: 'alice');
        expect(await status(github, '/graphql', method: 'POST'), 403);
        expect(await status(github, '/user'), 403);
        expect(appRequests, isEmpty);
      });

      test('a request about no one repository never rides a person, even '
          'one who is acting and signed in', () async {
        final github = await clients(member: 'alice');
        await credentials.storeSignIn(
          ForgeHost.github,
          'alice',
          ProviderToken(
            accessToken: 'ghu_alice',
            refreshToken: 'ghr_refresh',
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
            source: ForgeCredentialSource.oauth,
            accountLogin: 'alice',
            accountId: '1',
            appId: 'Iv1.client',
          ),
        );
        expect(
          await github.personToken('alice', workspaceId: workspaceId),
          'ghu_alice',
          reason: 'alice is signed in, so only the rule keeps her token out',
        );
        for (final (method, url) in [
          ('POST', '/graphql'),
          ('GET', '/graphql'),
          ('GET', '/user'),
          ('GET', '/search/issues?q=is:pr'),
          ('PATCH', '/user'),
        ]) {
          expect(
            await status(github, url, method: method, actingUserId: 'alice'),
            403,
            reason: '$method $url',
          );
        }
        expect(appRequests, isEmpty);
      });

      test('another owner gets nothing from this client', () async {
        final github = await clients(member: 'alice');
        expect(await status(github, '/repos/other/api/pulls'), 404);
        expect(appRequests, isEmpty);
      });
    },
  );

  test('with no GitHub lane, a link has nothing to check', () async {
    final github = await clients(ownApp: false, member: 'alice');
    await github.verifyLink(workspaceId, 'alice', 'acme', 'api');
  });

  test('a dot segment is never linked, lane or not', () async {
    for (final ownApp in [false, true]) {
      final github = await clients(ownApp: ownApp, member: 'alice');
      for (final (owner, repo) in [
        ('..', 'api'),
        ('acme', '.'),
        ('acme', '%2e%2e'),
        ('acme', 'a/b'),
      ]) {
        await expectLater(
          github.verifyLink(workspaceId, 'alice', owner, repo),
          throwsA(isA<ValidationException>()),
          reason: '$owner/$repo with ownApp: $ownApp',
        );
      }
    }
  });

  group('forRepo', () {
    Future<int> status(
      GitHubClients github,
      String url, {
      String method = 'GET',
      Object? body,
      String? actingUserId,
      bool viaPerson = false,
    }) async {
      try {
        await github.tokenForRepoRequest(
          workspaceId,
          'acme',
          'api',
          method: method,
          url: url,
          body: body,
          actingUserId: actingUserId,
          viaPerson: viaPerson,
        );
      } on ForgeCredentialUnavailable catch (e) {
        return e.statusCode;
      }
      fail('expected ForgeCredentialUnavailable');
    }

    test('anything about another repository fails locally', () async {
      final github = await clients(member: null);
      expect(await status(github, '/repos/acme/other/pulls'), 404);
      expect(await status(github, '/repos/other/api/pulls'), 404);
      expect(await status(github, '/user'), 404);
      expect(await status(github, '/orgs/acme/members'), 404);
      expect(
        await status(github, '/search/issues?q=repo:acme/other+is:open'),
        404,
      );
      expect(
        await status(
          github,
          '/search/issues?q=${Uri.encodeQueryComponent('repo:acme/api org:x')}',
        ),
        404,
      );
      expect(appRequests, isEmpty);
    });

    test('this repository, GraphQL and a search confined to it reach the '
        'mint', () async {
      // Nobody accountable signed in: the mint is reached and refuses 401.
      final github = await clients(member: null);
      expect(await status(github, '/repos/acme/api/pulls'), 401);
      expect(
        await status(
          github,
          '/graphql',
          method: 'POST',
          body: const {'query': 'query { viewer { login } }'},
        ),
        401,
      );
      expect(
        await status(
          github,
          '/search/issues?q=${Uri.encodeQueryComponent('repo:acme/api is:open')}',
        ),
        401,
      );
    });

    test('the request guard allows only this repository', () {
      expect(
        refuseGitHubRequestOutsideRepo(
          'acme',
          'api',
          'GET',
          '/repos/acme/api',
        ),
        isNull,
      );
      expect(
        refuseGitHubRequestOutsideRepo('acme', 'api', 'POST', '/graphql'),
        isNull,
      );
      expect(
        refuseGitHubRequestOutsideRepo('acme', 'api', 'GET', '/repos/acme/x'),
        isNotNull,
      );
      expect(
        refuseGitHubRequestOutsideRepo('acme', 'api', 'GET', '/user'),
        isNotNull,
      );
    });

    test(
      'a GraphQL mutation reaches the mint only when it is listed',
      () async {
        final github = await clients(member: null);
        // Listed: the mint is reached and refuses 401 (nobody accountable).
        expect(
          await status(
            github,
            '/graphql',
            method: 'POST',
            body: const {
              'query':
                  'mutation { addComment(input: {}) { clientMutationId } }',
            },
          ),
          401,
        );
        // Unlisted: refused locally, nothing minted.
        final before = appRequests.length;
        expect(
          await status(
            github,
            '/graphql',
            method: 'POST',
            body: const {
              'query': 'mutation { deleteRef(input: {}) { clientMutationId } }',
            },
          ),
          403,
        );
        expect(appRequests, hasLength(before));
      },
    );

    test('acting through a person needs a person', () async {
      final github = await clients(member: 'alice');
      expect(
        await status(github, '/repos/acme/api/pulls', viaPerson: true),
        401,
      );
    });

    test(
      'httpForRepo with actingUserId and viaPerson: false mints an '
      'installation token (ghs_, bot scope) rather than using the person token',
      () async {
        final app = ProviderAppSettings(
          secrets: secrets,
          githubAppFactory: ({required appId, required pem}) => GitHubAppClient(
            appId: appId,
            privateKeyPem: pem,
            httpClient: TestHttpClient(
              handler: (request) {
                final uri = httpRequestUri(request);
                appRequests.add(uri.path);
                if (uri.path == '/app/installations') {
                  return httpTextResponse(request, const [
                    {
                      'id': 99,
                      'account': {'login': 'acme', 'id': 1},
                      'target_type': 'Organization',
                      'repository_selection': 'selected',
                    },
                  ]);
                }
                if (uri.path == '/app/installations/99/access_tokens') {
                  return httpTextResponse(request, {
                    'token': 'ghs_review_bot',
                    'expires_at': DateTime.now()
                        .toUtc()
                        .add(const Duration(hours: 1))
                        .toIso8601String(),
                    'repository_selection': 'selected',
                    'repositories': const [
                      {'id': 101, 'name': 'api'},
                    ],
                    'permissions': GitHubTokenScope.bot.permissions,
                  }, statusCode: 201);
                }
                return httpTextResponse(request, const {
                  'message': 'Not Found',
                }, statusCode: 404);
              },
            ),
          ),
        );
        apps = app;
        final github = await clients(
          member: 'alice',
          rest: _OwnAppRepoFactsRest(),
        );
        await credentials.storeSignIn(
          ForgeHost.github,
          'alice',
          ProviderToken(
            accessToken: 'ghu_alice_personal',
            refreshToken: 'ghr_refresh',
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
            source: ForgeCredentialSource.oauth,
            accountLogin: 'alice',
            accountId: '1',
            appId: 'Iv1.client',
          ),
        );

        final token = await github.tokenForRepoRequest(
          workspaceId,
          'acme',
          'api',
          method: 'POST',
          url: 'https://api.github.com/repos/acme/api/pulls/1/comments',
          actingUserId: 'alice',
        );

        expect(token, 'ghs_review_bot');
        expect(token, isNot('ghu_alice_personal'));
        expect(
          appRequests,
          contains('/app/installations/99/access_tokens'),
        );
      },
    );
  });

  group('the repo access registry', () {
    test('a recent blocking record refuses automation before GitHub is '
        'asked, with its install link', () async {
      final github = await clients(member: 'alice');
      await repoAccess.record(
        workspaceId,
        forge: ForgeHost.github,
        owner: 'acme',
        name: 'api',
        state: RepoAccessState.repoNotSelected,
        installUrl:
            'https://github.com/organizations/acme/settings/installations/1',
      );
      try {
        await github.mintScoped(
          workspaceId: workspaceId,
          owner: 'acme',
          repo: 'api',
          scope: GitHubTokenScope.read,
        );
        fail('expected GitHubScopeRefused');
      } on GitHubScopeRefused catch (e) {
        expect(e.code, GitHubRefusal.repoNotSelected);
        expect(e.installUrl?.host, 'github.com');
      }
      expect(appRequests, isEmpty);
    });

    test('a person acting is not held by the automation record', () async {
      final github = await clients(member: 'alice');
      await repoAccess.record(
        workspaceId,
        forge: ForgeHost.github,
        owner: 'acme',
        name: 'api',
        state: RepoAccessState.appNotInstalled,
      );
      // Past the gate, the mint stops at alice's own sign-in.
      expect(
        await refusal(
          github.mintScoped(
            workspaceId: workspaceId,
            owner: 'acme',
            repo: 'api',
            scope: GitHubTokenScope.read,
            actingUserId: 'alice',
          ),
        ),
        'needs_sign_in',
      );
    });

    test('a transient record does not gate automation', () async {
      final github = await clients(member: 'alice');
      await repoAccess.record(
        workspaceId,
        forge: ForgeHost.github,
        owner: 'acme',
        name: 'api',
        state: RepoAccessState.transient,
      );
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
    });

    test('forgetting a workspace drops its GitHub records', () async {
      final github = await clients(member: 'alice');
      await repoAccess.record(
        workspaceId,
        forge: ForgeHost.github,
        owner: 'acme',
        name: 'api',
        state: RepoAccessState.appNotInstalled,
      );
      await github.forgetWorkspace(workspaceId);
      expect(
        await repoAccess.issueFor(
          workspaceId,
          forge: ForgeHost.github,
          owner: 'acme',
          name: 'api',
        ),
        isNull,
      );
    });
  });

  group('on a Connect lane', () {
    Future<String> mint(
      GitHubClients github,
      GitHubTokenScope scope, {
      bool viaPerson = false,
    }) => refusal(
      GitHubMinter(
        credentials: credentials,
        lanes: github.lanes,
        connect: ConnectClient(settings: ConnectSettings(secrets: secrets)),
        rest: GitHubRest(),
        confirmRepo: (_, _, _, _, _) async {},
        now: DateTime.now,
      ).mint(
        lane: GitHubLane.connect,
        workspaceId: workspaceId,
        owner: 'acme',
        repo: 'api',
        scope: scope,
        human: 'alice',
        viaPerson: viaPerson,
      ),
    );

    test('the shared App never pushes or opens a pull request with nobody '
        'asking: refused before Connect is asked', () async {
      final github = await clients(ownApp: false, member: 'alice');
      expect(
        await mint(github, GitHubTokenScope.write),
        GitHubRefusal.needsRequester.wire,
      );
      expect(appRequests, isEmpty);
    });

    test('the bot keeps reading and commenting; reviews need an install '
        'the Connect operator listed', () {
      for (final scope in [
        GitHubTokenScope.read,
        GitHubTokenScope.review,
        GitHubTokenScope.comment,
      ]) {
        expect(scope.connectBotMayHold, isTrue, reason: '$scope');
        expect(scope.connectBotNeedsListing, isFalse, reason: '$scope');
      }
      expect(GitHubTokenScope.bot.connectBotMayHold, isFalse);
      expect(GitHubTokenScope.bot.connectBotNeedsListing, isTrue);
      expect(GitHubTokenScope.write.connectBotMayHold, isFalse);
      expect(GitHubTokenScope.write.connectBotNeedsListing, isFalse);
      // Conversation writes ask for `comment`, which the bot holds anywhere.
      for (final (method, path) in [
        ('POST', '/repos/acme/api/issues/1/comments'),
        ('POST', '/repos/acme/api/issues/1/labels'),
        ('POST', '/repos/acme/api/issues/1/assignees'),
        ('POST', '/repos/acme/api/issues/1/reactions'),
        ('POST', '/repos/acme/api/issues/comments/5/reactions'),
      ]) {
        expect(
          githubScopeForRequest(method, 'https://api.github.com$path')?.scope,
          GitHubTokenScope.comment,
          reason: '$method $path',
        );
      }
      for (final field in [
        'addComment',
        'addReaction',
        'addLabelsToLabelable',
        'addAssigneesToAssignable',
      ]) {
        expect(
          githubGraphQlMutationScopes[field],
          GitHubTokenScope.comment,
          reason: field,
        );
      }
      // Reviews stay at `bot`.
      for (final path in [
        '/repos/acme/api/pulls/1/reviews',
        '/repos/acme/api/pulls/1/comments',
        '/repos/acme/api/pulls/comments/4/reactions',
      ]) {
        expect(
          githubScopeForRequest('POST', 'https://api.github.com$path')?.scope,
          GitHubTokenScope.bot,
          reason: path,
        );
      }
      for (final field in [
        'addPullRequestReview',
        'submitPullRequestReview',
        'addPullRequestReviewThread',
      ]) {
        expect(
          githubGraphQlMutationScopes[field],
          GitHubTokenScope.bot,
          reason: field,
        );
      }
    });

    test('a review is not refused before Connect is asked: only Connect '
        'knows whether this install is listed', () async {
      final github = await clients(ownApp: false, member: 'alice');
      // Alice holds no Connect sign-in here, so asking fails on that, not
      // on a refusal made up front.
      expect(
        await mint(github, GitHubTokenScope.bot),
        GitHubRefusal.needsSignIn.wire,
      );
    });

    group('who a token nobody acts through comes from', () {
      GitHubScopedGrant grant(String token) => GitHubScopedGrant(
        token: token,
        scope: GitHubTokenScope.bot,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        lane: GitHubLane.connect,
        workspaceId: workspaceId,
        owner: 'acme',
        repo: 'api',
      );

      Future<(List<GitHubMintActor>, Object)> decide(
        GitHubTokenScope scope, {
        required String? human,
        required bool listed,
      }) async {
        final asked = <GitHubMintActor>[];
        Object outcome;
        try {
          outcome = (await connectBotOrPerson(
            scope: scope,
            human: human,
            mint: (actor) async {
              asked.add(actor);
              if (actor == GitHubMintActor.app &&
                  scope == GitHubTokenScope.bot &&
                  !listed) {
                throw const GitHubScopeRefused(
                  GitHubRefusal.needsRequester,
                  'not listed',
                );
              }
              return grant(actor == GitHubMintActor.app ? 'ghs_bot' : 'ghu_p');
            },
          )).token;
        } on GitHubScopeRefused catch (e) {
          outcome = e.code;
        }
        return (asked, outcome);
      }

      test('an unlisted install publishes a review as the requester', () async {
        final (asked, outcome) = await decide(GitHubTokenScope.bot, human: 'alice', listed: false);
        expect(asked, [GitHubMintActor.app, GitHubMintActor.user]);
        expect(outcome, 'ghu_p');
      });

      test('a listed install publishes a review as the bot', () async {
        final (asked, outcome) = await decide(GitHubTokenScope.bot, human: 'alice', listed: true);
        expect(asked, [GitHubMintActor.app]);
        expect(outcome, 'ghs_bot');
      });

      test('with nobody accountable the review is refused, typed, never '
          'dropped', () async {
        final (asked, outcome) = await decide(
          GitHubTokenScope.bot,
          human: null,
          listed: false,
        );
        expect(asked, [GitHubMintActor.app]);
        expect(outcome, GitHubRefusal.needsRequester);
      });

      test('a comment still goes out as the bot', () async {
        final (asked, outcome) = await decide(GitHubTokenScope.comment, human: 'alice', listed: false);
        expect(asked, [GitHubMintActor.app]);
        expect(outcome, 'ghs_bot');
      });

      test('a write is never the bot\'s and never asked for', () async {
        final (asked, outcome) = await decide(GitHubTokenScope.write, human: 'alice', listed: true);
        expect(asked, <GitHubMintActor>[]);
        expect(outcome, GitHubRefusal.needsRequester);
      });
    });
  });

  test('a rate limit is transient: the next caller asks again, and no '
      'sign-in is cleared or asked for', () async {
    // Connect answers `rate_limited` for its own ceilings (`github_account`,
    // `github_address`, `github_ceiling`, `github_app_install`) as GitHub
    // does for its own: the same refusal.
    expect(
      GitHubRefusal.fromConnect(ConnectErrorCode.rateLimited),
      GitHubRefusal.rateLimited,
    );
    expect(ConnectErrorCode.rateLimited.clearsGrant, isFalse);
    expect(GitHubRefusal.rateLimited.isTransient, isTrue);

    final rest = _RateLimitedOnce();
    final github = await clients(member: 'alice', rest: rest);
    await credentials.storeSignIn(
      ForgeHost.github,
      'alice',
      ProviderToken(
        accessToken: 'ghu_alice',
        refreshToken: 'ghr_refresh',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 8)),
        source: ForgeCredentialSource.oauth,
        accountLogin: 'alice',
        accountId: '1',
        appId: 'Iv1.client',
      ),
    );
    Future<String> mint() => refusal(
      github.mintScoped(
        workspaceId: workspaceId,
        owner: 'acme',
        repo: 'api',
        scope: GitHubTokenScope.read,
        actingUserId: 'alice',
      ),
    );
    expect(await mint(), GitHubRefusal.rateLimited.wire);
    // Not cached: GitHub is asked again, and its definite answer is.
    expect(await mint(), GitHubRefusal.accessDenied.wire);
    expect(await mint(), GitHubRefusal.accessDenied.wire);
    expect(rest.repoReads, 2);
    expect(
      await github.personToken('alice', workspaceId: workspaceId),
      'ghu_alice',
    );
  });

  group('classifyGitHubRepoRead', () {
    GitHubRefusal classify(
      int status, {
      Map<String, String> headers = const {},
      String message = '',
    }) => classifyGitHubRepoRead(
      GitHubRestResponse(status, {'message': message}, headers: headers),
    );

    test('a hidden repository is access denied, never a sign-in', () {
      expect(classify(404), GitHubRefusal.accessDenied);
      expect(classify(403), GitHubRefusal.accessDenied);
      expect(classify(401), GitHubRefusal.needsSignIn);
    });

    test('a rate limit is transient, however GitHub says it', () {
      expect(classify(429), GitHubRefusal.rateLimited);
      expect(
        classify(403, headers: {'x-ratelimit-remaining': '0'}),
        GitHubRefusal.rateLimited,
      );
      expect(
        classify(403, headers: {'retry-after': '60'}),
        GitHubRefusal.rateLimited,
      );
      expect(
        classify(403, message: 'You have exceeded a secondary rate limit.'),
        GitHubRefusal.rateLimited,
      );
      expect(
        classify(403, headers: {'x-ratelimit-remaining': '4999'}),
        GitHubRefusal.accessDenied,
      );
    });

    test('an organization enforcing SAML asks for single sign-on', () {
      expect(
        classify(
          403,
          headers: {'x-github-sso': 'required; url=https://github.com/orgs/a'},
        ),
        GitHubRefusal.ssoRequired,
      );
      expect(
        classify(
          403,
          message:
              'Resource protected by organization SAML '
              'enforcement.',
        ),
        GitHubRefusal.ssoRequired,
      );
    });

    test('GitHub failing is unavailable', () {
      expect(classify(502), GitHubRefusal.providerUnavailable);
      expect(classify(0), GitHubRefusal.providerUnavailable);
    });
  });

  test('a granted permission set is within the asked one only when no '
      'permission is added or raised', () {
    const asked = {'contents': 'write', 'metadata': 'read'};
    expect(gitHubPermissionsWithin(asked, asked), isTrue);
    expect(gitHubPermissionsWithin({'contents': 'read'}, asked), isTrue);
    expect(
      gitHubPermissionsWithin({'contents': 'write', 'issues': 'read'}, asked),
      isFalse,
    );
    expect(gitHubPermissionsWithin({'metadata': 'write'}, asked), isFalse);
  });

  group('remintOnUnauthorized', () {
    HttpRequest request({bool authorized = true}) => HttpRequest(
      method: HttpMethod.get,
      url: 'https://api.github.com/repos/acme/api',
      headers: HttpHeaders.rawMap({
        if (authorized) 'Authorization': 'Bearer ghs_child',
        'Accept': 'application/vnd.github+json',
      }),
    );

    test('a 401 on an authorized request drops the grant and retries '
        'without the stale token', () async {
      var drops = 0;
      final retry = remintOnUnauthorized(() async => drops++);
      final sent = request();
      expect(
        retry.shouldRetry(httpTextResponse(sent, '', statusCode: 401), null),
        isTrue,
      );
      final next = await retry.beforeRetry(0, sent, null, null);
      expect(drops, 1);
      final headers = next!.headers! as HttpHeaderRawMap;
      expect(headers.map.keys, ['Accept']);
    });

    test('anything else is answered as it came', () {
      final retry = remintOnUnauthorized(() async {});
      expect(
        retry.shouldRetry(
          httpTextResponse(request(), '', statusCode: 404),
          null,
        ),
        isFalse,
      );
      expect(
        retry.shouldRetry(
          httpTextResponse(request(authorized: false), '', statusCode: 401),
          null,
        ),
        isFalse,
      );
    });
  });
}

/// GitHub rate-limiting the first repository read, then answering it.
final class _RateLimitedOnce extends GitHubRest {
  int repoReads = 0;

  @override
  Future<GitHubRestResponse> send(
    String method,
    String path, {
    Map<String, String>? query,
    String? bearer,
    ({String clientId, String clientSecret})? basic,
    Object? body,
  }) async {
    if (path == '/repos/acme/api') {
      repoReads++;
      return repoReads == 1
          ? const GitHubRestResponse(
              403,
              {'message': 'API rate limit exceeded'},
              headers: {'x-ratelimit-remaining': '0'},
            )
          : const GitHubRestResponse(404, {'message': 'Not Found'});
    }
    return const GitHubRestResponse(404, {'message': 'Not Found'});
  }
}

/// Answers repository facts for `acme/api` when probed with Alice's token.
final class _OwnAppRepoFactsRest extends GitHubRest {
  @override
  Future<GitHubRestResponse> send(
    String method,
    String path, {
    Map<String, String>? query,
    String? bearer,
    ({String clientId, String clientSecret})? basic,
    Object? body,
  }) async {
    if (path == '/repos/acme/api' && bearer == 'ghu_alice_personal') {
      return const GitHubRestResponse(200, {
        'id': 101,
        'owner': {'login': 'acme', 'id': 1},
        'name': 'api',
        'private': true,
        'permissions': {'push': true, 'pull': true},
      });
    }
    return const GitHubRestResponse(404, {'message': 'Not Found'});
  }
}
