import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/pr_merge_conflict_ops.dart';
import 'package:cc_server_core/src/pr_review/pr_merge_conflict_service.dart';
import 'package:test/test.dart';

Repo _repo(String name) => Repo(
  id: 'r-$name',
  name: name,
  path: '/tmp/$name',
  remoteOwner: 'acme',
  remoteName: name,
  createdAt: DateTime(2025),
  updatedAt: DateTime(2025),
);

/// `pr_review.mergeConflicts` / `fixMergeConflicts` read the PR as the bot,
/// so they first require that the caller may see the repo's pull requests:
/// linked, their read grant, AND their own forge sign-in.
void main() {
  final widgets = _repo('widgets');
  final vault = _repo('vault');
  late List<String> probed;
  late List<RepoOp> ops;

  setUp(() {
    probed = [];
    final members = _Members()
      ..add('gina', WorkspaceRole.member)
      ..grants['gina'] = {
        widgets.id: RepoGrantLevel.read,
        vault.id: RepoGrantLevel.read,
      }
      ..add('nora', WorkspaceRole.member);
    ops = buildPrMergeConflictOps(
      PrMergeConflictService(
        refs: (workspaceId, owner, repo, prNumber) async {
          probed.add('$owner/$repo');
          return (title: 'PR', baseRef: 'main', headRef: 'feature');
        },
        conflictFiles:
            ({
              required workspaceId,
              required owner,
              required repo,
              required prNumber,
              required baseRef,
              required userId,
            }) async => ['lib/a.dart'],
        ensureSpace:
            ({
              required workspaceId,
              required repoFullName,
              required prNumber,
              required title,
            }) async => null,
        defaultAgent: (_) async => null,
        conversations: _Conversations(),
        messaging: _Messaging(),
        messagingRepository: _MessagingRepository(),
      ),
      linkedRepos: (workspaceId) async =>
          workspaceId == 'ws1' ? [widgets, vault] : const [],
      members: members,
      // gina's own GitHub sign-in reads widgets, not vault.
      forgeAccess: (workspaceId, userId, repo) async {
        if (repo.id != widgets.id) {
          throw const AuthException('Your GitHub account cannot read it.');
        }
      },
    );
  });

  Future<Object?> run(String op, String user, String repo) => ops
      .singleWhere((o) => o.name == op)
      .handler(
        RepoOpContext(
          args: {
            'workspace_id': 'ws1',
            'owner': 'acme',
            'repo': repo,
            'pr_number': 3,
          },
          workspaceId: 'ws1',
          deviceId: 'dev-$user',
          userId: user,
        ),
      );

  test('a caller who may see the repo gets its conflicts', () async {
    final result = await run('pr_review.mergeConflicts', 'gina', 'widgets');
    expect((result as Map)['files'], ['lib/a.dart']);
    expect(probed, ['acme/widgets']);
  });

  test('no forge access, no grant or no link: refused before any '
      'forge read', () async {
    for (final (op, user, repo, matcher) in [
      // A grant, but their own sign-in cannot read the repo.
      ('pr_review.mergeConflicts', 'gina', 'vault', isA<AuthException>()),
      ('pr_review.fixMergeConflicts', 'gina', 'vault', isA<AuthException>()),
      // Forge reach is moot without a grant.
      ('pr_review.mergeConflicts', 'nora', 'widgets', isA<AuthException>()),
      // Not linked to this workspace at all.
      (
        'pr_review.mergeConflicts',
        'gina',
        'elsewhere',
        isA<WorkspaceMismatchException>(),
      ),
    ]) {
      await expectLater(
        run(op, user, repo),
        throwsA(matcher),
        reason: '$op $user $repo',
      );
    }
    expect(probed, isEmpty);
  });
}

class _Members implements WorkspaceMembershipRepository {
  final _members = <String, WorkspaceMember>{};
  final grants = <String, Map<String, RepoGrantLevel>>{};

  void add(String userId, WorkspaceRole role) =>
      _members[userId] = WorkspaceMember(
        id: 'ws1-$userId',
        workspaceId: 'ws1',
        userId: userId,
        role: role,
        joinedAt: DateTime(2025),
      );

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      workspaceId == 'ws1' ? _members[userId] : null;

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => Map.of(grants[userId] ?? const {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Conversations implements ConversationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messaging implements MessagingPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MessagingRepository implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
