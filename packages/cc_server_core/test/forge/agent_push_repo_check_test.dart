import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/forge/agent_push_repo_check.dart';
import 'package:test/test.dart';

final class _Members implements WorkspaceMembershipRepository {
  _Members(this.roles, this.grants);

  final Map<String, WorkspaceRole> roles;
  final Map<String, Map<String, RepoGrantLevel>> grants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    final role = roles[userId];
    return role == null
        ? null
        : WorkspaceMember(
            id: 'm-$userId',
            workspaceId: workspaceId,
            userId: userId,
            role: role,
            joinedAt: DateTime.utc(2026),
          );
  }

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => grants[userId] ?? const {};
}

Repo _repo(String id, String owner, String name, {ForgeHost? forge}) => Repo(
  id: id,
  name: name,
  path: '/src/$name',
  forge: forge ?? ForgeHost.github,
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// The push gateway's repository check holds a run to the requester's own
/// Control Center grant on the repository, not to what GitHub lets them do.
void main() {
  final check = agentPushRepoCheck(
    linkedRepos: (ws) async => ws == 'ws'
        ? [
            _repo('r-api', 'acme', 'api'),
            _repo('r-web', 'acme', 'web'),
            _repo('r-lab', 'acme', 'lab', forge: ForgeHost.gitlab),
          ]
        : const [],
    members: _Members(
      {
        'writer': WorkspaceRole.member,
        'reader': WorkspaceRole.member,
        'admin': WorkspaceRole.admin,
      },
      {
        'writer': {'r-api': RepoGrantLevel.write},
        'reader': {'r-api': RepoGrantLevel.read, 'r-web': RepoGrantLevel.read},
      },
    ),
  );

  test('a requester with the write grant may push to that repo only', () async {
    expect(await check('ws', 'acme', 'api', 'writer'), isTrue);
    expect(await check('ws', 'ACME', 'Api', 'writer'), isTrue);
    expect(await check('ws', 'acme', 'web', 'writer'), isFalse);
  });

  test('a read grant is not enough to have an agent push', () async {
    expect(await check('ws', 'acme', 'api', 'reader'), isFalse);
  });

  test('admins hold every linked repo; outsiders none', () async {
    expect(await check('ws', 'acme', 'web', 'admin'), isTrue);
    expect(await check('ws', 'acme', 'api', 'stranger'), isFalse);
  });

  test('a repo not linked as a GitHub repo of this workspace is '
      'refused for everyone', () async {
    expect(await check('ws', 'acme', 'secrets', 'admin'), isFalse);
    expect(await check('ws', 'acme', 'lab', 'admin'), isFalse);
    expect(await check('other', 'acme', 'api', 'admin'), isFalse);
    expect(await check('ws', 'acme', 'secrets', null), isFalse);
  });

  test('a run nobody requested is bounded by the linked repo alone; its '
      'token is bounded when minted', () async {
    expect(await check('ws', 'acme', 'web', null), isTrue);
    expect(await check('ws', 'acme', 'web', ''), isTrue);
  });

  group('the fetch credential for a GitLab or Bitbucket repo', () {
    final personAsked = <(ForgeHost, String, String)>[];
    final automationAsked = <(String, String)>[];
    var personTokens = <String, String>{};
    var automationTokens = <String, String>{};
    final fetch = agentFetchCredential(
      linkedRepos: (ws) async => ws == 'ws'
          ? [
              _repo('r-api', 'acme', 'api'),
              _repo('r-lab', 'acme/platform', 'lab', forge: ForgeHost.gitlab),
              _repo('r-ui', 'acme', 'shop-ui', forge: ForgeHost.bitbucket),
            ]
          : const [],
      personToken: (forge, userId, ws) async {
        personAsked.add((forge, userId, ws));
        return personTokens[userId];
      },
      automationToken: (ws, repo) async {
        automationAsked.add((ws, repo.id));
        return automationTokens[repo.id];
      },
    );
    const lab = (forge: ForgeHost.gitlab, owner: 'acme/platform', name: 'lab');
    const ui = (forge: ForgeHost.bitbucket, owner: 'acme', name: 'shop-ui');

    setUp(() {
      personAsked.clear();
      automationAsked.clear();
      personTokens = {'ada': 'person-test-token'};
      automationTokens = {'r-lab': 'automation-test-token'};
    });

    test('a run for a person fetches on their own token only', () async {
      expect(await fetch('ws', lab, 'ada'), (
        token: 'person-test-token',
        refusal: null,
      ));
      expect(personAsked, [(ForgeHost.gitlab, 'ada', 'ws')]);

      final bo = await fetch('ws', ui, 'bo');
      expect(bo.token, isNull);
      expect(
        bo.refusal,
        'Connect your Bitbucket account to do this as yourself.',
      );
      expect(automationAsked, isEmpty, reason: 'never the automation token');
    });

    test('a run nobody requested fetches on the automation token', () async {
      expect(await fetch('ws', lab, null), (
        token: 'automation-test-token',
        refusal: null,
      ));
      expect(await fetch('ws', lab, ''), (
        token: 'automation-test-token',
        refusal: null,
      ));
      final missing = await fetch('ws', ui, null);
      expect(missing.token, isNull);
      expect(missing.refusal, startsWith('Automation on '));
      expect(automationAsked, [
        ('ws', 'r-lab'),
        ('ws', 'r-lab'),
        ('ws', 'r-ui'),
      ]);
      expect(personAsked, isEmpty);
    });

    test('the linked repo is matched in any letter case, on its own '
        'forge', () async {
      final found = await fetch('ws', (
        forge: ForgeHost.gitlab,
        owner: 'ACME/Platform',
        name: 'Lab',
      ), null);
      expect(found.token, 'automation-test-token');
    });

    test(
      'an unlinked repo, another workspace, or GitHub gets nothing',
      () async {
        for (final (ws, repo) in const [
          ('ws', (forge: ForgeHost.gitlab, owner: 'acme', name: 'other')),
          // Linked on Bitbucket, asked on GitLab.
          ('ws', (forge: ForgeHost.gitlab, owner: 'acme', name: 'shop-ui')),
          ('other', lab),
          ('ws', (forge: ForgeHost.github, owner: 'acme', name: 'api')),
        ]) {
          final answer = await fetch(ws, repo, 'ada');
          expect(answer.token, isNull, reason: '$ws $repo');
          expect(answer.refusal, isNotEmpty);
        }
        expect(personAsked, isEmpty);
        expect(automationAsked, isEmpty);
      },
    );
  });
}
