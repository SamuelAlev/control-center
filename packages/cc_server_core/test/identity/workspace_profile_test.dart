import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_server_core/src/identity/workspace_profile.dart';
import 'package:test/test.dart';

void main() {
  final created = DateTime.utc(2024, 1, 1);
  final user = User(
    id: 'u-1',
    handle: 'sam',
    displayName: 'Sam Account',
    email: 'sam@example.com',
    gitAuthorName: 'Sam Git',
    gitAuthorEmail: 'sam@git.example',
    createdAt: created,
  );

  WorkspaceMember member({
    required String workspaceId,
    String? displayName,
    String? email,
    String? gitAuthorName,
    String? gitAuthorEmail,
  }) => WorkspaceMember(
    id: 'm-$workspaceId',
    workspaceId: workspaceId,
    userId: user.id,
    role: WorkspaceRole.member,
    joinedAt: created,
    displayName: displayName,
    email: email,
    gitAuthorName: gitAuthorName,
    gitAuthorEmail: gitAuthorEmail,
  );

  group('applyMemberOverlay', () {
    test('empty overlay uses the global user', () {
      final overlaid = applyMemberOverlay(user, member(workspaceId: 'ws-a'));
      expect(overlaid.displayName, 'Sam Account');
      expect(overlaid.email, 'sam@example.com');
      expect(overlaid.gitAuthorName, 'Sam Git');
      expect(overlaid.gitAuthorEmail, 'sam@git.example');
      expect(overlaid.handle, 'sam');
    });

    test('set overlay replaces name, email and git author', () {
      final overlaid = applyMemberOverlay(
        user,
        member(
          workspaceId: 'ws-a',
          displayName: 'Sam Here',
          email: 'sam@ws-a.example',
          gitAuthorName: 'Sam A',
          gitAuthorEmail: 'sam-a@git.example',
        ),
      );
      expect(overlaid.displayName, 'Sam Here');
      expect(overlaid.email, 'sam@ws-a.example');
      expect(overlaid.gitAuthorName, 'Sam A');
      expect(overlaid.gitAuthorEmail, 'sam-a@git.example');
      expect(overlaid.handle, 'sam');
    });
  });

  group('resolveWorkspaceGitIdentity', () {
    test(
      'uses the overlay in that workspace and leaves others unchanged',
      () async {
        final users = _Users({user.id: user});
        final members = _Members({
          'ws-a': member(
            workspaceId: 'ws-a',
            gitAuthorName: 'Sam A',
            gitAuthorEmail: 'a@git.example',
          ),
          'ws-b': member(workspaceId: 'ws-b'),
        });

        final a = await resolveWorkspaceGitIdentity(
          users: users,
          members: members,
          userId: user.id,
          workspaceId: 'ws-a',
        );
        final b = await resolveWorkspaceGitIdentity(
          users: users,
          members: members,
          userId: user.id,
          workspaceId: 'ws-b',
        );

        expect(a, (name: 'Sam A', email: 'a@git.example'));
        expect(b, (name: 'Sam Git', email: 'sam@git.example'));
      },
    );

    test('an unknown user has no identity, and nobody stands in', () async {
      final a = await resolveWorkspaceGitIdentity(
        users: _Users({user.id: user}),
        members: _Members({}),
        userId: 'u-unknown',
        workspaceId: 'ws-a',
      );
      expect(a, isNull);
    });
  });

  group('resolveAgentCommitIdentity', () {
    final other = User(
      id: 'u-2',
      handle: 'bo',
      displayName: 'Bo',
      email: 'bo@example.com',
      gitAuthorName: 'Bo Git',
      gitAuthorEmail: 'bo@git.example',
      createdAt: created,
    );
    final users = _Users({user.id: user, other.id: other});
    final members = _Members({});

    Future<AgentCommitIdentity?> resolve(
      String? userId, {
      GitHubUser? account,
    }) => resolveAgentCommitIdentity(
      users: users,
      members: members,
      ownerUserId: user.id,
      githubAccount: (_, _) async => account,
      userId: userId,
      workspaceId: 'ws-a',
    );

    test('the owner commits as themselves and may sign', () async {
      expect(
        await resolve(user.id),
        AgentCommitIdentity.owner(name: 'Sam Git', email: 'sam@git.example'),
      );
    });

    test('another member is author via their GitHub noreply; Control Center '
        'commits, unsigned', () async {
      final id = await resolve(
        other.id,
        account: const GitHubUser(login: 'bo', avatarUrl: '', id: 7),
      );
      expect(
        id,
        AgentCommitIdentity.member(
          name: 'Bo Git',
          email: '7+bo@users.noreply.github.com',
        ),
      );
      expect(id!.mayHostSign, isFalse);
    });

    test(
      'a member without GitHub authors with their workspace git email',
      () async {
        expect(
          await resolve(other.id),
          AgentCommitIdentity.member(name: 'Bo Git', email: 'bo@git.example'),
        );
      },
    );

    test('a run nobody requested is Control Center throughout', () async {
      expect(await resolve(null), AgentCommitIdentity.unrequested());
    });

    test('an unknown requester has no identity', () async {
      expect(await resolve('u-unknown'), isNull);
    });
  });
}

class _Users implements UserRepository {
  _Users(this.byId);
  final Map<String, User> byId;

  @override
  Future<User?> getById(String id) async => byId[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements WorkspaceMembershipRepository {
  _Members(this.byWorkspace);
  final Map<String, WorkspaceMember> byWorkspace;

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async {
    final member = byWorkspace[workspaceId];
    if (member == null || member.userId != userId) {
      return null;
    }
    return member;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
