import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';
import 'package:test/test.dart';

/// Scripts `getForWorkspace`; every other member is unused here and throws
/// loudly through [noSuchMethod] if that changes.
class _FakeMembershipRepository implements WorkspaceMembershipRepository {
  _FakeMembershipRepository(this.members);

  List<WorkspaceMember> members;

  @override
  Future<List<WorkspaceMember>> getForWorkspace(String workspaceId) async =>
      members.where((m) => m.workspaceId == workspaceId).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Scripts `forgeToken` per user id; null (no credential) by default.
class _FakeCredentialsStore implements UserCredentialsStore {
  _FakeCredentialsStore(this.tokens);

  final Map<String, ProviderToken?> tokens;

  @override
  Future<ProviderToken?> forgeToken(String userId, ForgeHost forge) async =>
      tokens[userId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WorkspaceMember _member(
  String userId, {
  WorkspaceRole role = WorkspaceRole.admin,
  String workspaceId = 'ws1',
}) => WorkspaceMember(
  id: 'membership-$userId',
  workspaceId: workspaceId,
  userId: userId,
  role: role,
  joinedAt: DateTime(2026, 1, 1),
);

void main() {
  group('GitHubLoginDirectory', () {
    test('maps a login to its member, case-insensitively', () async {
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _FakeCredentialsStore({
          'u1': const ProviderToken(
            accessToken: 't',
            accountLogin: 'Octocat',
          ),
        }),
      );

      final member = await directory.memberForLogin('ws1', 'octocat');

      expect(member?.userId, 'u1');
    });

    test('a login nobody connected resolves to null', () async {
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _FakeCredentialsStore({
          'u1': const ProviderToken(accessToken: 't', accountLogin: 'octocat'),
        }),
      );

      expect(await directory.memberForLogin('ws1', 'someone-else'), isNull);
    });

    test('a member whose credential carries no login resolves to null',
        () async {
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _FakeCredentialsStore({
          'u1': const ProviderToken(accessToken: 't'),
        }),
      );

      expect(await directory.memberForLogin('ws1', ''), isNull);
      expect(await directory.memberForLogin('', 'octocat'), isNull);
    });

    test('a login connected by a user of ANOTHER workspace resolves to null',
        () async {
      // The reverse index is built per workspace from that workspace's
      // members; a foreign workspace's user is simply absent from it.
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _FakeCredentialsStore({
          'u1': const ProviderToken(accessToken: 't', accountLogin: 'octocat'),
          'u9': const ProviderToken(accessToken: 't', accountLogin: 'intruder'),
        }),
      );

      expect(await directory.memberForLogin('ws1', 'intruder'), isNull);
    });

    test('the oldest member wins a duplicate login claim', () async {
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([
          _member('first'),
          _member('second'),
        ]),
        credentials: _FakeCredentialsStore({
          'first': const ProviderToken(
            accessToken: 't',
            accountLogin: 'shared',
          ),
          'second': const ProviderToken(
            accessToken: 't',
            accountLogin: 'shared',
          ),
        }),
      );

      expect((await directory.memberForLogin('ws1', 'shared'))?.userId,
          'first');
    });

    test('rebuilds after the TTL, so a new member becomes resolvable',
        () async {
      var now = DateTime(2026, 8, 26, 12);
      final members = _FakeMembershipRepository([_member('u1')]);
      final tokens = <String, ProviderToken?>{
        'u1': const ProviderToken(accessToken: 't', accountLogin: 'octocat'),
      };
      final directory = GitHubLoginDirectory(
        members: members,
        credentials: _FakeCredentialsStore(tokens),
        now: () => now,
      );

      expect(await directory.memberForLogin('ws1', 'newbie'), isNull);

      members.members.add(_member('u2'));
      tokens['u2'] = const ProviderToken(
        accessToken: 't',
        accountLogin: 'newbie',
      );
      // Inside the TTL: the cached index still answers.
      now = now.add(const Duration(minutes: 1));
      expect(await directory.memberForLogin('ws1', 'newbie'), isNull);
      // Past it: the index rebuilds from the current members.
      now = now.add(const Duration(minutes: 5));
      expect((await directory.memberForLogin('ws1', 'newbie'))?.userId, 'u2');
    });
  });
}
