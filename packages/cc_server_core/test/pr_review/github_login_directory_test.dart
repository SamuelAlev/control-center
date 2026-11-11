import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/identity/github_login_directory.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
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

/// A credential lookup over a per-user map; null (not signed in) by default.
GitHubCredentialLookup _credentials(Map<String, ProviderToken?> tokens) =>
    (userId, workspaceId) async => tokens[userId];

ProviderToken _signIn(String accountId, String login) =>
    ProviderToken(accessToken: 't', accountId: accountId, accountLogin: login);

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
    test('maps a numeric account id to its member', () async {
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _credentials({'u1': _signIn('583231', 'octocat')}),
      );

      expect((await directory.memberForAccountId('ws1', 583231))?.userId, 'u1');
    });

    test('a different account that took the old login does not map', () async {
      // Somebody registered the freed "octocat" login; their id differs.
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _credentials({'u1': _signIn('583231', 'octocat')}),
      );

      expect(await directory.memberForAccountId('ws1', 9999999), isNull);
    });

    test('a sign-in without an account id never maps', () async {
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _credentials({
          'u1': const ProviderToken(accessToken: 't', accountLogin: 'octocat'),
        }),
      );

      expect(await directory.memberForAccountId('ws1', 583231), isNull);
      expect(await directory.memberForAccountId('ws1', 0), isNull);
      expect(await directory.memberForAccountId('', 583231), isNull);
    });

    test(
      'an account signed in by a user of ANOTHER workspace resolves to null',
      () async {
        // The reverse index is built per workspace from that workspace's
        // members; a foreign workspace's user is simply absent from it.
        final directory = GitHubLoginDirectory(
          members: _FakeMembershipRepository([_member('u1')]),
          credentials: _credentials({
            'u1': _signIn('1', 'octocat'),
            'u9': _signIn('9', 'intruder'),
          }),
        );

        expect(await directory.memberForAccountId('ws1', 9), isNull);
      },
    );

    test('the lookup is per workspace', () async {
      final looked = <(String, String)>[];
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: (userId, workspaceId) async {
          looked.add((userId, workspaceId));
          return _signIn('1', 'octocat');
        },
      );

      await directory.memberForAccountId('ws1', 1);

      expect(looked, [('u1', 'ws1')]);
    });

    test('an account two members hold resolves to neither', () async {
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([
          _member('first'),
          _member('second'),
        ]),
        credentials: _credentials({
          'first': _signIn('7', 'shared'),
          'second': _signIn('7', 'shared'),
        }),
      );

      expect(await directory.memberForAccountId('ws1', 7), isNull);
    });

    test(
      'rebuilds after the TTL, so a new member becomes resolvable',
      () async {
        var now = DateTime(2026, 8, 26, 12);
        final members = _FakeMembershipRepository([_member('u1')]);
        final tokens = <String, ProviderToken?>{'u1': _signIn('1', 'octocat')};
        final directory = GitHubLoginDirectory(
          members: members,
          credentials: _credentials(tokens),
          now: () => now,
        );

        expect(await directory.memberForAccountId('ws1', 2), isNull);

        members.members.add(_member('u2'));
        tokens['u2'] = _signIn('2', 'newbie');
        // Inside the TTL: the cached index still answers.
        now = now.add(const Duration(minutes: 1));
        expect(await directory.memberForAccountId('ws1', 2), isNull);
        // Past it: the index rebuilds from the current members.
        now = now.add(const Duration(minutes: 5));
        expect((await directory.memberForAccountId('ws1', 2))?.userId, 'u2');
      },
    );

    test('membership removal revokes a cached mapping before TTL', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final members = _FakeMembershipRepository([_member('u1')]);
      final directory = GitHubLoginDirectory(
        members: members,
        credentials: _credentials({'u1': _signIn('1', 'octocat')}),
        eventBus: bus,
      );

      expect((await directory.memberForAccountId('ws1', 1))?.userId, 'u1');
      members.members = [];
      expect((await directory.memberForAccountId('ws1', 1))?.userId, 'u1');

      bus.publish(
        WorkspaceMemberRemoved(
          workspaceId: 'ws1',
          userId: 'u1',
          occurredAt: DateTime(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(await directory.memberForAccountId('ws1', 1), isNull);
    });

    test('role change refreshes the cached write permission', () async {
      final bus = DomainEventBus();
      addTearDown(bus.dispose);
      final members = _FakeMembershipRepository([_member('u1')]);
      final directory = GitHubLoginDirectory(
        members: members,
        credentials: _credentials({'u1': _signIn('1', 'octocat')}),
        eventBus: bus,
      );

      expect(
        (await directory.memberForAccountId('ws1', 1))!.role.canWrite,
        isTrue,
      );
      members.members = [_member('u1', role: WorkspaceRole.viewer)];
      bus.publish(
        WorkspaceMemberRoleChanged(
          workspaceId: 'ws1',
          userId: 'u1',
          role: WorkspaceRole.viewer,
          occurredAt: DateTime(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        (await directory.memberForAccountId('ws1', 1))!.role.canWrite,
        isFalse,
      );
    });

    test('a GitHub sign-in maps before the cached index expires', () async {
      final changes =
          StreamController<({String userId, String? workspaceId})>.broadcast();
      addTearDown(changes.close);
      final tokens = <String, ProviderToken?>{};
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: _credentials(tokens),
        githubSignInChanges: changes.stream,
      );

      expect(await directory.memberForAccountId('ws1', 1), isNull);
      tokens['u1'] = _signIn('1', 'octocat');
      changes.add((userId: 'u1', workspaceId: null));
      await Future<void>.delayed(Duration.zero);
      expect((await directory.memberForAccountId('ws1', 1))?.userId, 'u1');

      // Disconnecting drops the mapping as promptly.
      tokens['u1'] = null;
      changes.add((userId: 'u1', workspaceId: 'ws1'));
      await Future<void>.delayed(Duration.zero);
      expect(await directory.memberForAccountId('ws1', 1), isNull);
    });

    test('an index built across an invalidation is not cached', () async {
      final tokens = <String, ProviderToken?>{};
      final gate = Completer<void>();
      var reads = 0;
      final directory = GitHubLoginDirectory(
        members: _FakeMembershipRepository([_member('u1')]),
        credentials: (userId, workspaceId) async {
          reads++;
          final token = tokens[userId];
          if (reads == 1) {
            await gate.future;
          }
          return token;
        },
      );

      final stale = directory.memberForAccountId('ws1', 1);
      await Future<void>.delayed(Duration.zero);
      tokens['u1'] = _signIn('1', 'octocat');
      directory.invalidate('ws1');
      gate.complete();
      expect(await stale, isNull);
      expect((await directory.memberForAccountId('ws1', 1))?.userId, 'u1');
    });
  });
}
