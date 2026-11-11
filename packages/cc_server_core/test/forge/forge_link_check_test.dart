import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/catalog/repo_link_guard.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_credentials.dart';
import 'package:cc_server_core/src/forge/forge_link_check.dart';
import 'package:cc_server_core/src/forge/forge_person_token_check.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// GitLab and Bitbucket links are checked with the linking member's own
/// token (what automation meets is ForgeAutomationTokens' check).
void main() {
  late Directory dir;
  late ForgeCredentials credentials;
  late List<(ForgeHost, String, String, String)> probes;
  late int? answer;
  late ForgeLinkChecker checker;
  late RepoAccessRegistry registry;

  const ws = 'ws1';

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_forge_link_');
    credentials = ForgeCredentials(
      users: UserCredentialsStore(FileSecretsStore(dataDir: dir.path)),
      personTokenCheck: (forge, token) async =>
          PersonTokenAccepted((login: token, id: '1')),
    );
    probes = [];
    answer = 200;
    checker = ForgeLinkChecker(
      credentials: credentials,
      read: (forge, token, owner, name) async {
        probes.add((forge, token, owner, name));
        return (
          status: answer,
          repo: answer == 200 ? (id: '41', owner: owner, name: name) : null,
        );
      },
    );
    final db = createTestDatabase(workspaceId: ws);
    addTearDown(db.close);
    registry = RepoAccessRegistry(cacheFor: (_) => db.cacheDao);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<RepoAccessIssue?> check({
    String? userId = 'alice',
    ForgeHost forge = ForgeHost.gitlab,
  }) async =>
      (await checker.check(ws, forge, 'group', 'app', userId: userId)).issue;

  test(
    'a person without a token is not signed in, and nothing is asked',
    () async {
      final issue = await check();
      expect(issue?.state, RepoAccessState.ownerNotSignedIn);
      expect(probes, isEmpty);
      expect(
        (await check(userId: null))?.state,
        RepoAccessState.ownerNotSignedIn,
      );
    },
  );

  test("the probe carries only that person's own token", () async {
    await credentials.setToken(ForgeHost.gitlab, 'alice-gl', userId: alice);
    await credentials.setToken(ForgeHost.gitlab, 'bob-gl', userId: 'bob');
    expect(await check(), isNull);
    expect(probes.single, (ForgeHost.gitlab, 'alice-gl', 'group', 'app'));
  });

  test("the linker's read is what pins the link: the forge's id for the "
      'repository, and none from a read that failed', () async {
    await credentials.setToken(ForgeHost.gitlab, 'alice-gl', userId: alice);
    expect(
      (await checker.check(ws, ForgeHost.gitlab, 'group', 'app', userId: alice))
          .forgeRepoId,
      '41',
    );
    answer = 404;
    expect(
      (await checker.check(ws, ForgeHost.gitlab, 'group', 'app', userId: alice))
          .forgeRepoId,
      isEmpty,
    );
  });

  test('statuses map to what automation will meet', () async {
    await credentials.setToken(
      ForgeHost.bitbucket,
      'alice@example.com:bb',
      userId: alice,
    );
    for (final (status, state) in [
      (401, RepoAccessState.ownerNotSignedIn),
      (403, RepoAccessState.ownerCannotSee),
      (404, RepoAccessState.ownerCannotSee),
      (500, RepoAccessState.transient),
      (null, RepoAccessState.transient),
    ]) {
      answer = status;
      expect(
        (await check(forge: ForgeHost.bitbucket))?.state,
        state,
        reason: '$status',
      );
    }
  });

  test('a transient answer never overwrites a blocking record', () async {
    await recordForgeLinkCheck(
      registry,
      ws,
      ForgeHost.gitlab,
      'group',
      'app',
      await check(),
    );
    answer = 500;
    await credentials.setToken(ForgeHost.gitlab, 'alice-gl', userId: alice);
    await recordForgeLinkCheck(
      registry,
      ws,
      ForgeHost.gitlab,
      'group',
      'app',
      await check(),
    );
    final stored = await registry.issueFor(
      ws,
      forge: ForgeHost.gitlab,
      owner: 'group',
      name: 'app',
    );
    expect(stored?.state, RepoAccessState.ownerNotSignedIn);

    // A clean read clears it.
    answer = 200;
    await recordForgeLinkCheck(
      registry,
      ws,
      ForgeHost.gitlab,
      'group',
      'app',
      await check(),
    );
    expect(
      await registry.issueFor(
        ws,
        forge: ForgeHost.gitlab,
        owner: 'group',
        name: 'app',
      ),
      isNull,
    );
  });

  test('access warnings carry state, message and install link only', () {
    final now = DateTime.utc(2026);
    expect(
      accessWarningsWire([
        RepoAccessIssue(
          forge: ForgeHost.github,
          owner: 'acme',
          name: 'api',
          state: RepoAccessState.repoNotSelected,
          since: now,
          checkedAt: now,
          message: 'Pick it in the installation.',
          installUrl: 'https://github.com/settings/installations/1',
        ),
        RepoAccessIssue(
          forge: ForgeHost.gitlab,
          owner: 'group',
          name: 'app',
          state: RepoAccessState.ownerNotSignedIn,
          since: now,
          checkedAt: now,
          message: 'Nobody accountable has a token.',
        ),
      ]),
      [
        {
          'state': 'repo_not_selected',
          'message': 'Pick it in the installation.',
          'install_url': 'https://github.com/settings/installations/1',
        },
        {
          'state': 'owner_not_signed_in',
          'message': 'Nobody accountable has a token.',
        },
      ],
    );
  });
}

const alice = 'alice';
