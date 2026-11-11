import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show RpcErrorCodes, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/forge_automation_token_ops.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_automation_tokens.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_person_token_check.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/rpc_exception_mapper.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

Repo _repo(
  String id,
  String owner,
  String name, {
  ForgeHost forge = ForgeHost.gitlab,
}) => Repo(
  id: id,
  name: '$owner/$name',
  path: '/src/$owner/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  forge: forge,
);

/// GitLab and Bitbucket automation rides only the automation-token slot: a
/// repository's own token wins over the workspace's, nothing falls back to a
/// person, a missing token pauses the repository in the registry, and the
/// ops are admin-only and stay inside their workspace.
void main() {
  late Directory dir;
  late FileSecretsStore secrets;
  late RepoAccessRegistry registry;
  late ForgeAutomationTokens tokens;

  /// token → status the forge answers when that token reads a repository
  /// (keyed `token|owner/name`; a bare token key applies to every repo).
  late Map<String, int?> readable;
  late List<String> probed;

  final api = _repo('r-api', 'group', 'api');
  final web = _repo('r-web', 'group', 'web');
  final bb = _repo('r-bb', 'team', 'svc', forge: ForgeHost.bitbucket);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_automation_tokens_');
    secrets = FileSecretsStore(dataDir: dir.path);
    final dbs = {
      for (final ws in ['ws-a', 'ws-b'])
        ws: createTestDatabase(workspaceId: ws),
    };
    for (final db in dbs.values) {
      addTearDown(db.close);
    }
    registry = RepoAccessRegistry(cacheFor: (ws) => dbs[ws]!.cacheDao);
    readable = {};
    probed = [];
    tokens = ForgeAutomationTokens(
      secrets: secrets,
      registry: registry,
      identify: (forge, token) async {
        if (token.startsWith('glpat-person')) {
          throw const ValidationException('This is a personal access token.');
        }
        return (
          name: 'Deploy bot',
          login: 'project_1_bot',
          kind: 'project',
          scopes: const ['read_api', 'write_repository'],
        );
      },
      probe: (forge, token, owner, name) async {
        probed.add('$token|$owner/$name');
        return readable.containsKey('$token|$owner/$name')
            ? readable['$token|$owner/$name']
            : readable.containsKey(token)
            ? readable[token]
            : 404;
      },
    );
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<RepoAccessIssue?> issue(String ws, Repo repo) => registry.issueFor(
    ws,
    forge: repo.forge,
    owner: repo.remoteOwner,
    name: repo.remoteName,
  );

  group('slot resolution', () {
    test("a repository's own token wins over the workspace's", () async {
      readable['ws-token'] = 200;
      readable['repo-token'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'ws-token',
        linked: [api, web],
      );
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'repo-token',
        linked: [api, web],
        repo: api,
      );
      expect(await tokens.tokenForRepo('ws-a', api), 'repo-token');
      expect(await tokens.tokenForRepo('ws-a', web), 'ws-token');
      // A workspace slot is per forge.
      expect(await tokens.tokenForRepo('ws-a', bb), isNull);
    });

    test('no slot means no token: a person\'s own token is never used, and '
        'the repository is paused', () async {
      // A member with their own GitLab token changes nothing.
      final creds = ForgeCredentials(
        users: UserCredentialsStore(secrets),
        personTokenCheck: (forge, token) async =>
            const PersonTokenAccepted((login: 'alice', id: '1')),
      );
      await creds.setToken(ForgeHost.gitlab, 'glpat-alice', userId: 'alice');

      expect(await tokens.tokenForRepo('ws-a', api), isNull);
      expect(
        await creds.tokenFor(ForgeHost.gitlab, workspaceId: 'ws-a'),
        isNull,
      );
      final paused = await issue('ws-a', api);
      expect(paused?.state, RepoAccessState.automationTokenMissing);
      expect(paused?.state.blocksAutomation, isTrue);
      expect(paused?.repoId, api.id);
      expect(paused?.message, contains('Settings → Repositories'));
    });

    test('a token in one workspace never reaches another', () async {
      readable['a-token'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'a-token',
        linked: [api],
      );
      expect(await tokens.tokenForRepo('ws-a', api), 'a-token');
      expect(await tokens.tokenForRepo('ws-b', api), isNull);
      expect(await tokens.list('ws-b', [api]), isEmpty);
      expect(
        (await issue('ws-b', api))?.state,
        RepoAccessState.automationTokenMissing,
      );
      expect(await issue('ws-a', api), isNull);
    });

    test('GitHub repositories never take an automation token', () async {
      final gh = _repo('r-gh', 'acme', 'api', forge: ForgeHost.github);
      expect(await tokens.tokenForRepo('ws-a', gh), isNull);
      expect(await issue('ws-a', gh), isNull);
      await expectLater(
        tokens.save(
          'ws-a',
          forge: ForgeHost.github,
          token: 'ghp_x',
          linked: [gh],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('saving', () {
    test('a workspace token that reads none of the repositories it would '
        'serve is refused, even when the forge names a bot', () async {
      readable['ws-token'] = 403;
      await expectLater(
        tokens.save(
          'ws-a',
          forge: ForgeHost.gitlab,
          token: 'ws-token',
          linked: [api, web],
        ),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        tokens.save(
          'ws-a',
          forge: ForgeHost.gitlab,
          token: 'ws-token',
          linked: [bb],
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('Link a GitLab repository first'),
          ),
        ),
      );
      expect(await tokens.list('ws-a', [api, web]), isEmpty);
    });

    test('a personal token is refused and nothing is stored', () async {
      readable['glpat-person'] = 200;
      await expectLater(
        tokens.save(
          'ws-a',
          forge: ForgeHost.gitlab,
          token: 'glpat-person',
          linked: [api],
          repo: api,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(await tokens.list('ws-a', [api]), isEmpty);
    });

    test(
      'a repository token that cannot read its repository is refused',
      () async {
        readable['weak'] = 404;
        await expectLater(
          tokens.save(
            'ws-a',
            forge: ForgeHost.gitlab,
            token: 'weak',
            linked: [api],
            repo: api,
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('cannot read group/api'),
            ),
          ),
        );
        expect(
          await secrets.keysMatching((k) => k.contains('r-api')),
          isEmpty,
        );
      },
    );

    test('a workspace token un-pauses what it reads and pauses what it '
        'cannot', () async {
      await tokens.tokenForRepo('ws-a', api);
      await tokens.tokenForRepo('ws-a', web);
      readable['ws-token|group/api'] = 200;
      readable['ws-token|group/web'] = 403;
      final saved = await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'ws-token',
        linked: [api, web, bb],
      );
      expect(saved.unreadable, ['group/web']);
      expect(saved.info.scope, AutomationTokenScope.workspace);
      expect(await issue('ws-a', api), isNull);
      expect((await issue('ws-a', web))?.message, contains('cannot read'));
      // Bitbucket repositories are not covered by a GitLab token.
      expect(probed.where((p) => p.contains('team/svc')), isEmpty);
    });

    test('the list says who the bot is and never carries the token', () async {
      readable['secret-token'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'secret-token',
        linked: [api],
        repo: api,
      );
      final list = await tokens.list('ws-a', [api]);
      expect(list, hasLength(1));
      final json = list.single.toJson();
      expect(json['scope'], 'repo');
      expect(json['repo_id'], api.id);
      expect(json['bot_name'], 'Deploy bot');
      expect(json['status'], 'active');
      expect(json.toString(), isNot(contains('secret-token')));
      expect(json.values, isNot(contains('secret-token')));
    });
  });

  group('clearing and checking', () {
    test('clearing a repository token falls back to the workspace token, '
        'and clearing that pauses the repository', () async {
      readable['ws-token'] = 200;
      readable['repo-token'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'ws-token',
        linked: [api],
      );
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'repo-token',
        linked: [api],
        repo: api,
      );
      expect(
        await tokens.clear(
          'ws-a',
          forge: ForgeHost.gitlab,
          linked: [api],
          repoId: api.id,
        ),
        isTrue,
      );
      expect(await tokens.tokenForRepo('ws-a', api), 'ws-token');
      expect(await issue('ws-a', api), isNull);

      await tokens.clear('ws-a', forge: ForgeHost.gitlab, linked: [api]);
      expect(
        (await issue('ws-a', api))?.state,
        RepoAccessState.automationTokenMissing,
      );
    });

    test(
      'a token the forge refuses is marked rejected and no longer used',
      () async {
        readable['revoked'] = 200;
        await tokens.save(
          'ws-a',
          forge: ForgeHost.gitlab,
          token: 'revoked',
          linked: [api],
          repo: api,
        );
        readable['revoked'] = 401;
        final found = await tokens.check('ws-a', api);
        expect(found?.state, RepoAccessState.automationTokenMissing);
        expect(found?.message, contains('refused'));
        expect(
          (await tokens.list('ws-a', [api])).single.status,
          AutomationTokenStatus.rejected,
        );
        expect(await tokens.tokenForRepo('ws-a', api), isNull);
      },
    );

    test('an unreachable forge is transient, never a pause', () async {
      readable['tok'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'tok',
        linked: [api],
        repo: api,
      );
      readable['tok'] = null;
      expect(
        (await tokens.check('ws-a', api))?.state,
        RepoAccessState.transient,
      );
    });

    test("an unlinked repository's token is not listed, and listing "
        'deletes nothing', () async {
      readable['tok'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'tok',
        linked: [api],
        repo: api,
      );
      expect(await tokens.list('ws-a', const []), isEmpty);
      expect(
        await secrets.keysMatching((k) => k.contains('r-api')),
        hasLength(1),
        reason: 'list() is a read',
      );
      expect(await tokens.list('ws-a', [api]), hasLength(1));
    });

    test("unlinking deletes the repository's own token, and the sweep "
        'prunes any left', () async {
      readable['tok'] = 200;
      for (final repo in [api, web]) {
        await tokens.save(
          'ws-a',
          forge: ForgeHost.gitlab,
          token: 'tok',
          linked: [api, web],
          repo: repo,
        );
      }
      await tokens.forgetRepo('ws-a', api);
      expect(await secrets.keysMatching((k) => k.contains('r-api')), isEmpty);
      expect(await tokens.pruneUnlinked('ws-a', [api]), 1);
      expect(await secrets.keysMatching((k) => k.contains('r-web')), isEmpty);
    });

    test('deleting a workspace deletes its automation tokens', () async {
      readable['tok'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'tok',
        linked: [api],
      );
      await tokens.save(
        'ws-b',
        forge: ForgeHost.gitlab,
        token: 'tok',
        linked: [api],
      );
      await WorkspaceGitHubAppSettings(
        secrets: secrets,
        install: ProviderAppSettings(secrets: secrets),
      ).deleteForWorkspace('ws-a');
      expect(await tokens.list('ws-a', [api]), isEmpty);
      expect(await tokens.list('ws-b', [api]), hasLength(1));
    });
  });

  group('forge.*AutomationToken ops', () {
    late RepoOpDispatcher dispatcher;
    const roles = {
      'ws-a': {'ada': WorkspaceRole.admin, 'mia': WorkspaceRole.member},
      'ws-b': {'bea': WorkspaceRole.owner},
    };
    final linked = {
      'ws-a': [api, bb],
      'ws-b': [web],
    };

    setUp(() {
      dispatcher = RepoOpDispatcher(
        registry: RepoOpRegistry(
          buildForgeAutomationTokenOps(
            tokens: tokens,
            linkedRepos: (ws) async => linked[ws] ?? const [],
          ),
        ),
        resolveRole: (ws, user) async => roles[ws]?[user],
        workspaceExists: (ws) async => roles.containsKey(ws),
        mapException: mapAppExceptionToRpc,
      );
    });

    Future<Map<String, dynamic>> call(
      String op,
      String user,
      Map<String, dynamic> args,
    ) => dispatcher.call(
      id: 1,
      params: {'op': op, 'args': args},
      deviceId: 'dev-$user',
      userId: user,
      sessionCapability: SessionCapability.fullClient,
    );

    int? code(Map<String, dynamic> res) =>
        (res['error'] as Map?)?['code'] as int?;
    Map<String, dynamic> data(Map<String, dynamic> res) =>
        ((res['result'] as Map)['data'] as Map).cast<String, dynamic>();

    test('an admin stores a repository token and lists only its '
        'description', () async {
      readable['bot-token'] = 200;
      final saved = await call('forge.setAutomationToken', 'ada', {
        'workspace_id': 'ws-a',
        'forge': 'gitlab',
        'token': 'bot-token',
        'repo_id': api.id,
      });
      expect(saved['error'], isNull);
      expect(data(saved)['scope'], 'repo');
      expect(saved.toString(), isNot(contains('bot-token')));
      final list = await call('forge.listAutomationTokens', 'ada', {
        'workspace_id': 'ws-a',
      });
      final entries = (data(list)['tokens'] as List).cast<Map>();
      expect(entries.single['bot_login'], 'project_1_bot');
      expect(entries.single.values, isNot(contains('bot-token')));
      expect(await tokens.tokenForRepo('ws-a', api), 'bot-token');
    });

    test('a member can neither read nor change the slots', () async {
      readable['x'] = 200;
      for (final op in [
        'forge.listAutomationTokens',
        'forge.setAutomationToken',
        'forge.clearAutomationToken',
      ]) {
        final res = await call(op, 'mia', {
          'workspace_id': 'ws-a',
          'forge': 'gitlab',
          'token': 'x',
        });
        expect(code(res), RpcErrorCodes.unauthorized, reason: op);
      }
      expect(await tokens.list('ws-a', [api]), isEmpty);
    });

    test("another workspace's admin reaches none of its slots or "
        'repositories', () async {
      readable['a'] = 200;
      readable['b'] = 200;
      await tokens.save(
        'ws-a',
        forge: ForgeHost.gitlab,
        token: 'a',
        linked: [api],
      );
      // Not a member of ws-a.
      final res = await call('forge.clearAutomationToken', 'bea', {
        'workspace_id': 'ws-a',
        'forge': 'gitlab',
      });
      expect(code(res), RpcErrorCodes.unauthorized);
      expect(await tokens.tokenForRepo('ws-a', api), 'a');
      // In their own workspace, ws-a's repository is not theirs to name.
      final cross = await call('forge.setAutomationToken', 'bea', {
        'workspace_id': 'ws-b',
        'forge': 'gitlab',
        'token': 'b',
        'repo_id': api.id,
      });
      expect(code(cross), RpcErrorCodes.notFound);
      expect(await tokens.list('ws-b', [web]), isEmpty);
    });

    test('an unknown workspace is refused before any lookup', () async {
      final res = await call('forge.listAutomationTokens', 'ada', {
        'workspace_id': 'ws-ghost',
      });
      expect(code(res), RpcErrorCodes.notFound);
    });

    test('GitHub is refused', () async {
      final res = await call('forge.setAutomationToken', 'ada', {
        'workspace_id': 'ws-a',
        'forge': 'github',
        'token': 'ghp_x',
      });
      expect(res['error'], isNotNull);
      expect(await tokens.list('ws-a', [api]), isEmpty);
    });
  });

  group('bitbucketAccessTokenIdentity', () {
    const accessToken = 'ATCTT3xFfGN0abcdef';
    const refusal = {
      'type': 'error',
      'error': {'message': 'Token is invalid or not supported for this endpoint'},
    };

    test('an access token, refused by /2.0/user, is accepted', () {
      for (final status in [401, 403]) {
        final who = bitbucketAccessTokenIdentity(accessToken, status, refusal);
        expect(who.kind, 'access_token', reason: '$status');
      }
    });

    test('a refusal proves nothing for a token not shaped like an access '
        'token', () {
      for (final token in ['garbage', 'ATATT3xperson', 'x-token-auth']) {
        for (final status in [401, 403]) {
          expect(
            () => bitbucketAccessTokenIdentity(token, status, refusal),
            throwsA(isA<ValidationException>()),
            reason: '$token $status',
          );
        }
      }
    });

    test('any other answer proves nothing', () {
      for (final status in [204, 301, 400, 404, 410]) {
        expect(
          () => bitbucketAccessTokenIdentity(accessToken, status, null),
          throwsA(isA<ValidationException>()),
          reason: '$status',
        );
      }
    });

    test('an app user is the bot and keeps its name', () {
      final who = bitbucketAccessTokenIdentity(accessToken, 200, const {
        'type': 'app_user',
        'display_name': 'Deploy bot',
        'account_id': 'x',
      });
      expect(who.name, 'Deploy bot');
      expect(who.kind, 'access_token');
    });

    test("a person's OAuth bearer, answering as a user, is refused", () {
      for (final body in [
        const {'type': 'user', 'nickname': 'ada', 'display_name': 'Ada'},
        const {'type': 'team', 'display_name': 'Acme'},
        const {'display_name': 'No type'},
        null,
      ]) {
        expect(
          () => bitbucketAccessTokenIdentity(accessToken, 200, body),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('as a person'),
            ),
          ),
          reason: '$body',
        );
      }
    });

    test('with no answer to judge by, nothing is accepted', () {
      for (final status in [null, 429, 500, 503]) {
        expect(
          () => bitbucketAccessTokenIdentity(accessToken, status, null),
          throwsA(isA<ValidationException>()),
          reason: '$status',
        );
      }
    });
  });
}
