import 'dart:io';

import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_domain/cc_domain.dart' show ForgeAccessRefusedException;
import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeCredentialSource;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/testing/fake_repo_repository.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog, RepoOp, RepoOpContext;
import 'package:cc_infra/cc_infra.dart'
    show
        ForgeAuthInterceptor,
        ForgeCredentialUnavailable,
        GitHubAppClient,
        mapHttpException;
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart' show repoToWire;
import 'package:cc_server_core/src/catalog/repo_link_ops.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_link_check.dart';
import 'package:cc_server_core/src/forge/forge_repo_pins.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/repo_path_guard.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:path/path.dart' as p;
import 'package:rhttp/rhttp.dart'
    show
        HttpBody,
        HttpBodyJson,
        HttpMethod,
        HttpRequest,
        RhttpStatusCodeException;
import 'package:test/test.dart';

import '../helpers/test_database.dart';
import 'github_clients_test.dart' show testPem;

/// A linked repository is pinned by the forge's durable id: a repository
/// renamed or transferred keeps its link (the stored path follows it), and
/// another repository created at the old path receives no token, push or
/// request until an admin relinks it. GitHub, GitLab and Bitbucket alike.
void main() {
  const ws = 'ws';
  late _Repos repos;
  late RepoAccessRegistry registry;
  late ForgeRepoPins pins;
  late List<String> audit;

  Repo repo({
    ForgeHost forge = ForgeHost.github,
    String owner = 'acme',
    String name = 'api',
    String pinnedTo = '',
  }) => Repo(
    id: 'r1',
    name: '$owner/$name',
    path: '/checkouts/api',
    forge: forge,
    remoteOwner: owner,
    remoteName: name,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    forgeRepoId: pinnedTo,
  );

  Future<RepoAccessState?> recorded(Repo r) async => (await registry.issueFor(
    ws,
    forge: r.forge,
    owner: r.remoteOwner,
    name: r.remoteName,
  ))?.state;

  setUp(() {
    repos = _Repos();
    final db = createTestDatabase(workspaceId: ws);
    addTearDown(db.close);
    registry = RepoAccessRegistry(cacheFor: (_) => db.cacheDao);
    pins = ForgeRepoPins(repos: repos, access: registry);
    audit = [];
    final previous = CcHostLog.sink;
    CcHostLog.sink = (level, message, [error, stackTrace]) {
      if (message.contains('forge.repo.')) {
        audit.add(message);
      }
    };
    addTearDown(() => CcHostLog.sink = previous);
  });

  group('GitHub, at every mint', () {
    late Directory dir;
    late FileSecretsStore secrets;
    late ForgeCredentials credentials;
    late _GitHub github;
    late List<Map<String, Object?>> tokenRequests;
    late String installedOn;
    late GitHubClients clients;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('cc_repo_pin_');
      addTearDown(() => dir.deleteSync(recursive: true));
      secrets = FileSecretsStore(dataDir: dir.path);
      github = _GitHub();
      tokenRequests = [];
      installedOn = 'acme';
      final apps = ProviderAppSettings(
        secrets: secrets,
        githubAppFactory: ({required appId, required pem}) => GitHubAppClient(
          appId: appId,
          privateKeyPem: pem,
          httpClient: TestHttpClient(
            handler: (request) {
              final path = httpRequestUri(request).path;
              if (path == '/app/installations') {
                return httpTextResponse(request, [
                  {
                    'id': 42,
                    'account': {'login': installedOn},
                    'target_type': 'Organization',
                  },
                ]);
              }
              if (path == '/app/installations/42/access_tokens') {
                final body = (request.body! as HttpBodyJson).json as Map;
                tokenRequests.add(body.cast<String, Object?>());
                return httpTextResponse(request, {
                  'token': 'ghs_minted${tokenRequests.length}',
                  'expires_at': DateTime.now()
                      .toUtc()
                      .add(const Duration(hours: 1))
                      .toIso8601String(),
                  'permissions': body['permissions'],
                  'repository_selection': 'selected',
                  'repositories': [
                    {'id': github.id, 'name': github.name},
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
      final workspace = Workspace(
        id: ws,
        name: ws,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        ownerUserId: 'alice',
      );
      clients = GitHubClients(
        credentials: credentials,
        apps: apps,
        workspaceApps: WorkspaceGitHubAppSettings(
          secrets: secrets,
          install: apps,
        ),
        workspaceLookup: (id) async => id == ws ? workspace : null,
        members: _Members(),
        connect: ConnectClient(settings: ConnectSettings(secrets: secrets)),
        isLinkedRepo: (workspaceId, owner, name) async => (await repos.getAll(
          workspaceId,
        )).any((r) => r.fullName.toLowerCase() == '$owner/$name'.toLowerCase()),
        mayReadRepo: (_, _, _, _) async => true,
        repoAccess: registry,
        confirmRepo: pins.confirm,
        confirmPersonRequest: pins.confirmPersonRequest,
        rest: github,
      );
      addTearDown(clients.close);
    });

    Future<Object> mint({
      GitHubTokenScope scope = GitHubTokenScope.read,
      String? actingUserId,
      bool viaPerson = false,
      bool fresh = false,
    }) async {
      try {
        return (await clients.mintScoped(
          workspaceId: ws,
          owner: 'acme',
          repo: 'api',
          scope: scope,
          actingUserId: actingUserId,
          viaPerson: viaPerson,
          fresh: fresh,
        )).token;
      } on GitHubScopeRefused catch (e) {
        return e.code;
      }
    }

    test('a row linked before ids were kept is pinned on the first '
        'authorized read, once', () async {
      repos.seed(ws, [repo()]);
      expect(await mint(), 'ghs_minted1');
      expect((await repos.getById(ws, 'r1'))!.forgeRepoId, '7');
      expect(await mint(fresh: true), 'ghs_minted2');
      expect(repos.writes, 1);
      expect(audit, hasLength(1));
      expect(audit.single, contains('"forge.repo.pinned"'));
      // Read with the accountable person's own token, never anonymously.
      expect(github.asked.toSet(), {('/repos/acme/api', 'ghu_alice')});
    });

    test('another repository at the linked path gets no token, no push, and '
        'the link is marked for an admin to relink', () async {
      repos.seed(ws, [repo(pinnedTo: '6')]);
      expect(await mint(), GitHubRefusal.repoReplaced);
      // A push (a person's work published as them) is refused the same way.
      expect(
        await mint(
          scope: GitHubTokenScope.write,
          actingUserId: 'alice',
          viaPerson: true,
        ),
        GitHubRefusal.repoReplaced,
      );
      expect(tokenRequests, isEmpty);
      expect(await recorded(repo()), RepoAccessState.repoReplaced);
      expect((await repos.getById(ws, 'r1'))!.forgeRepoId, '6');
      expect(audit.first, contains('"forge.repo.replaced"'));
      // Automation now stops at the record, before GitHub is asked.
      final asked = github.asked.length;
      expect(await mint(), GitHubRefusal.repoReplaced);
      expect(github.asked, hasLength(asked));
    });

    test('a repository GitHub renamed keeps its link: the stored path follows '
        'it and the token is minted for it', () async {
      repos.seed(ws, [repo(pinnedTo: '7')]);
      github
        ..movedTo = 7
        ..name = 'engine'
        ..owner = 'acme-labs';
      installedOn = 'acme-labs';
      expect(await mint(), 'ghs_minted1');
      final stored = (await repos.getById(ws, 'r1'))!;
      expect((stored.remoteOwner, stored.remoteName), ('acme-labs', 'engine'));
      expect(stored.name, 'acme-labs/engine');
      expect(stored.forgeRepoId, '7');
      expect(tokenRequests.single['repositories'], ['engine']);
      expect(github.asked, [
        ('/repos/acme/api', 'ghu_alice'),
        ('/repositories/7', 'ghu_alice'),
      ]);
      expect(audit.single, contains('"forge.repo.moved"'));
    });

    test("the linker's read pins a link, and a relink is not held against "
        'the pin it replaces', () async {
      repos.seed(ws, [repo(pinnedTo: '6')]);
      final verdict = await clients.verifyLink(ws, 'alice', 'acme', 'api');
      expect(verdict.forgeRepoId, '7');
      expect(repos.writes, 0);
    });
  });

  group('GitLab and Bitbucket, at every request', () {
    late Map<String, ForgeRepoAnswer> answers;
    late List<String> read;

    setUp(() {
      answers = {};
      read = [];
      pins = ForgeRepoPins(
        repos: repos,
        access: registry,
        read: (forge, token, owner, name) async {
          read.add('${forge.wire}:$token:$owner/$name');
          return answers['${forge.wire}:$owner/$name'] ??
              (status: 404, repo: null);
        },
      );
    });

    for (final (forge, id, otherId) in [
      (ForgeHost.gitlab, '41', '99'),
      (ForgeHost.bitbucket, '{a1b2}', '{c3d4}'),
    ]) {
      group(forge.displayName, () {
        Repo linked({String pinnedTo = ''}) =>
            repo(forge: forge, owner: 'group', name: 'app', pinnedTo: pinnedTo);

        void answer(String id, {String owner = 'group', String name = 'app'}) =>
            answers['${forge.wire}:group/app'] = (
              status: 200,
              repo: (id: id, owner: owner, name: name),
            );

        test('a row linked before ids were kept is pinned on the first '
            'authorized read, once', () async {
          repos.seed(ws, [linked()]);
          answer(id);
          await pins.confirmRequest(ws, linked(), 'tok');
          await pins.confirmRequest(ws, linked(pinnedTo: id), 'tok');
          expect((await repos.getById(ws, 'r1'))!.forgeRepoId, id);
          expect(repos.writes, 1);
          expect(read, ['${forge.wire}:tok:group/app']);
        });

        test('another repository at the path is refused locally (409) and '
            'marked for relinking', () async {
          repos.seed(ws, [linked(pinnedTo: id)]);
          answer(otherId);
          await expectLater(
            pins.confirmRequest(ws, linked(pinnedTo: id), 'tok'),
            throwsA(
              isA<ForgeCredentialUnavailable>().having(
                (e) => e.statusCode,
                'status',
                409,
              ),
            ),
          );
          expect(await recorded(linked()), RepoAccessState.repoReplaced);
          expect((await repos.getById(ws, 'r1'))!.forgeRepoId, id);
        });

        test('the refusal names the forge', () async {
          repos.seed(ws, [linked(pinnedTo: id)]);
          await expectLater(
            pins.confirm(ws, forge, 'group', 'app', (
              id: otherId,
              owner: 'group',
              name: 'app',
            )),
            throwsA(
              isA<ForgeAccessRefusedException>()
                  .having((e) => e.code, 'code', 'repo_replaced')
                  .having((e) => e.forge, 'forge', forge),
            ),
          );
        });

        test('a rename that keeps the id moves the stored path', () async {
          repos.seed(ws, [linked(pinnedTo: id)]);
          answer(id, owner: 'group/sub', name: 'renamed');
          await pins.confirmRequest(ws, linked(pinnedTo: id), 'tok');
          final stored = (await repos.getById(ws, 'r1'))!;
          expect(
            (stored.remoteOwner, stored.remoteName, stored.forgeRepoId),
            ('group/sub', 'renamed', id),
          );
        });

        test('a pinned repository whose id cannot be read is not sent to; '
            'one not pinned yet goes out as before', () async {
          repos.seed(ws, [linked(pinnedTo: id)]);
          await expectLater(
            pins.confirmRequest(ws, linked(pinnedTo: id), 'tok'),
            throwsA(isA<ForgeCredentialUnavailable>()),
          );
          await pins.confirmRequest(ws, linked(), 'tok');
          expect(repos.writes, 0);
        });

        test('the request itself never leaves the machine', () async {
          repos.seed(ws, [linked(pinnedTo: id)]);
          answer(otherId);
          // The interceptor every repository client authenticates through.
          final auth = ForgeAuthInterceptor(
            forge: forge,
            tokenLookup: (_) async {
              await pins.confirmRequest(ws, linked(pinnedTo: id), 'tok');
              return 'tok';
            },
          );
          await expectLater(
            auth.beforeRequest(
              HttpRequest(
                method: HttpMethod.get,
                url: '${forge.apiBaseUrl}/anything',
              ),
            ),
            throwsA(
              isA<RhttpStatusCodeException>().having(
                (e) => e.statusCode,
                'status',
                409,
              ),
            ),
          );
        });
      });
    }
  });

  // A person's own requests (their review, merge, comment) ride their own
  // token, not a repository's client: every one that names a linked
  // repository confirms it first, through the same pins, so a person never
  // acts on another repository created at a linked path. The lanes'
  // lookups (`GitHubClients.personHttp`, the GitLab/Bitbucket actor
  // factory) call [ForgeRepoPins.confirmPersonRequest] exactly so.
  group("a person's own request, on every forge", () {
    late Map<String, ForgeRepoAnswer> answers;
    late List<String> read;

    setUp(() {
      answers = {};
      read = [];
      pins = ForgeRepoPins(
        repos: repos,
        access: registry,
        read: (forge, token, owner, name) async {
          read.add('${forge.wire}:$owner/$name');
          return answers['${forge.wire}:$owner/$name'] ??
              (status: 404, repo: null);
        },
      );
    });

    ForgeAuthInterceptor person(ForgeHost forge) => ForgeAuthInterceptor(
      forge: forge,
      tokenLookup: (_) async => 'tok',
      requestTokenLookup: (forge, method, url, jsonBody) async {
        await pins.confirmPersonRequest(ws, forge, url, jsonBody, 'tok');
        return 'tok';
      },
    );

    Future<void> send(
      ForgeHost forge,
      HttpMethod method,
      String path, {
      Object? json,
    }) => person(forge).beforeRequest(
      HttpRequest(
        method: method,
        url: '${forge.apiBaseUrl}$path',
        body: json == null ? null : HttpBody.json(json),
      ),
    );

    for (final (forge, base, id, otherId) in [
      (ForgeHost.github, '/repos/group/app', '41', '99'),
      (ForgeHost.gitlab, '/projects/group%2Fapp', '41', '99'),
      (ForgeHost.bitbucket, '/repositories/group/app', '{a1b2}', '{c3d4}'),
    ]) {
      group(forge.displayName, () {
        Repo linked({String pinnedTo = ''}) =>
            repo(forge: forge, owner: 'group', name: 'app', pinnedTo: pinnedTo);
        void answer(String id) => answers['${forge.wire}:group/app'] = (
          status: 200,
          repo: (id: id, owner: 'group', name: 'app'),
        );
        final pull = forge == ForgeHost.github
            ? '$base/pulls/1'
            : forge == ForgeHost.gitlab
            ? '$base/merge_requests/1'
            : '$base/pullrequests/1';
        final merge = '$pull/merge';
        final mergeMethod = forge == ForgeHost.bitbucket
            ? HttpMethod.post
            : HttpMethod.put;

        test('a PR fetch and a merge on a replaced repository are refused '
            'locally as repo_replaced, naming the forge', () async {
          repos.seed(ws, [linked(pinnedTo: id)]);
          answer(otherId);
          for (final (method, path) in [
            (HttpMethod.get, pull),
            (mergeMethod, merge),
          ]) {
            Object? failure;
            try {
              await send(forge, method, path);
            } on RhttpStatusCodeException catch (e) {
              failure = e;
            }
            expect(failure, isA<RhttpStatusCodeException>(), reason: path);
            final mapped = mapAppExceptionToRpc(
              mapHttpException(failure! as RhttpStatusCodeException),
            );
            expect(mapped?.data, {
              'kind': 'repo_replaced',
              'forge': forge.wire,
            }, reason: path);
          }
          // One read of the path, trusted for both requests.
          expect(read, ['${forge.wire}:group/app']);
          expect((await repos.getById(ws, 'r1'))!.forgeRepoId, id);
        });

        test('the linked repository itself goes through', () async {
          repos.seed(ws, [linked(pinnedTo: id)]);
          answer(id);
          await send(forge, HttpMethod.get, pull);
          await send(forge, mergeMethod, merge);
        });

        test('a row linked before ids were kept is pinned on its first '
            'request (trust on first use)', () async {
          repos.seed(ws, [linked()]);
          answer(id);
          await send(forge, HttpMethod.get, pull);
          expect((await repos.getById(ws, 'r1'))!.forgeRepoId, id);
          expect(repos.writes, 1);
        });

        test(
          'a request naming no linked repository goes out unchecked',
          () async {
            repos.seed(ws, [linked(pinnedTo: id)]);
            answer(otherId);
            await send(forge, HttpMethod.get, '/user');
            expect(read, isEmpty);
          },
        );
      });
    }

    test('a GitHub GraphQL request is confirmed by the repository its '
        'variables name', () async {
      repos.seed(ws, [repo(owner: 'group', name: 'app', pinnedTo: '41')]);
      answers['github:group/app'] = (
        status: 200,
        repo: (id: '99', owner: 'group', name: 'app'),
      );
      await expectLater(
        send(
          ForgeHost.github,
          HttpMethod.post,
          '/graphql',
          json: {
            'query': 'query { repository { id } }',
            'variables': {'owner': 'group', 'name': 'app'},
          },
        ),
        throwsA(isA<RhttpStatusCodeException>()),
      );
    });
  });

  group('linking', () {
    late Directory root;
    late Map<String, RepoOp> ops;
    late String checkout;

    setUp(() {
      root = Directory(
        Directory.systemTemp
            .createTempSync('cc_repo_pin_link_')
            .resolveSymbolicLinksSync(),
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final dataDir = p.join(root.path, 'data');
      checkout = p.join(dataDir, ws, 'repos', 'api');
      Directory(checkout).createSync(recursive: true);
      ops = {
        for (final op in buildRepoLinkOps(
          repos: repos,
          requireRepoRead:
              ({
                required workspaceId,
                required userId,
                required repoId,
              }) async {},
          members: null,
          pathGuard: RepoPathGuard(
            dataDir: dataDir,
            workspaceDir: (w) async => p.join(dataDir, w),
            serverOwnerUserId: 'u-owner',
          ),
          inspector: _Inspector(),
          verifyRepoLink:
              ({required workspaceId, required userId, required repo}) async =>
                  (forgeRepoId: '7', warnings: <RepoAccessIssue>[]),
        ))
          op.name: op,
      };
    });

    Future<void> upsert(Repo r, {bool relink = false}) =>
        ops['repos.upsert']!.handler(
          RepoOpContext(
            args: {'repo': repoToWire(r), if (relink) 'relink': true},
            workspaceId: ws,
            deviceId: 'd',
            userId: 'u-admin',
            role: WorkspaceRole.admin,
          ),
        );

    Repo here({String name = 'acme/api', String pinnedTo = ''}) => Repo(
      id: 'r1',
      name: name,
      path: checkout,
      remoteOwner: 'acme',
      remoteName: 'api',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      forgeRepoId: pinnedTo,
    );

    test("a link is pinned to the linker's verified read; a client cannot "
        'name the pin, and an edit keeps it', () async {
      await upsert(here(pinnedTo: 'forged'));
      expect((await repos.getById(ws, 'r1'))!.forgeRepoId, '7');
      await upsert(here(name: 'API'));
      final stored = (await repos.getById(ws, 'r1'))!;
      expect((stored.name, stored.forgeRepoId), ('API', '7'));
    });

    test(
      'a relink re-reads the repository and pins what it reads now',
      () async {
        repos.seed(ws, [here(pinnedTo: '6')]);
        await upsert(here());
        expect((await repos.getById(ws, 'r1'))!.forgeRepoId, '6');
        await upsert(here(), relink: true);
        expect((await repos.getById(ws, 'r1'))!.forgeRepoId, '7');
      },
    );
  });
}

final class _Repos extends FakeRepoRepository {
  int writes = 0;

  @override
  Future<String> upsert(String workspaceId, Repo repo) {
    writes++;
    return super.upsert(workspaceId, repo);
  }
}

/// GitHub's repository reads: `GET /repos/acme/api` (or a 301 to the
/// repository's id when it moved) and `GET /repositories/{id}`.
final class _GitHub extends GitHubRest {
  int id = 7;
  String owner = 'acme';
  String name = 'api';
  int? movedTo;
  final asked = <(String, String?)>[];

  @override
  Future<GitHubRestResponse> send(
    String method,
    String path, {
    Map<String, String>? query,
    String? bearer,
    ({String clientId, String clientSecret})? basic,
    Object? body,
  }) async {
    final repository = GitHubRestResponse(200, {
      'id': id,
      'name': name,
      'owner': {'id': 9, 'login': owner},
      'private': true,
      'permissions': {'admin': true, 'push': true, 'pull': true},
    });
    if (method == 'GET' && path == '/repos/acme/api') {
      asked.add((path, bearer));
      final moved = movedTo;
      return moved == null
          ? repository
          : GitHubRestResponse(
              301,
              {'url': 'https://api.github.com/repositories/$moved'},
              headers: {
                'location': 'https://api.github.com/repositories/$moved',
              },
            );
    }
    if (method == 'GET' && path == '/repositories/$id') {
      asked.add((path, bearer));
      return repository;
    }
    return const GitHubRestResponse(404, null);
  }
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
        role: WorkspaceRole.admin,
        joinedAt: DateTime.utc(2026),
      );
}

final class _Inspector implements GitRepoInspectorPort {
  @override
  Future<GitRepoInfo> inspect(String path) async => GitRepoInfo(
    path: path,
    forge: ForgeHost.github,
    owner: 'acme',
    repoName: 'api',
    branch: 'main',
  );
}
