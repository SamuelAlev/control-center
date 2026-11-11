import 'package:cc_domain/cc_domain.dart'
    show AuthException, ForgeAccessRefusedException;
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_role_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_server_core/src/runtime/server_skill_evaluation_wiring.dart';
import 'package:test/test.dart';

/// A repository-backed skill is that repository's code: evaluating it needs
/// the caller's own forge read on top of the `evals` permission, with the
/// code ops' refusal. A workspace skill asks no forge.
void main() {
  final forgeReads = <String>[];
  final authorize = skillEvaluationAuthorizer(
    workspaceExists: (id) async => id == 'ws1',
    memberships: _Members(),
    roles: _Roles(),
    workspaces: _Workspaces(),
    forgeRead:
        ({required workspaceId, required userId, required repoId}) async {
          forgeReads.add('$userId:$repoId');
          if (repoId == 'vault') {
            throw const ForgeAccessRefusedException(
              'Your GitHub account cannot read this repository.',
              forge: ForgeHost.github,
              code: 'forge_cannot_read',
            );
          }
        },
  );
  const adam = UserPrincipal('adam');

  setUp(forgeReads.clear);

  test('a repository skill needs forge read, admins included', () async {
    await authorize('ws1', adam, write: true, repoId: 'widgets');
    await expectLater(
      authorize('ws1', adam, write: true, repoId: 'vault'),
      throwsA(
        isA<ForgeAccessRefusedException>().having(
          (e) => e.code,
          'code',
          'forge_cannot_read',
        ),
      ),
    );
    await expectLater(
      authorize('ws1', adam, write: false, repoId: 'vault'),
      throwsA(isA<ForgeAccessRefusedException>()),
    );
    expect(forgeReads, ['adam:widgets', 'adam:vault', 'adam:vault']);
  });

  test('a workspace skill asks no forge', () async {
    await authorize('ws1', adam, write: true);
    expect(forgeReads, isEmpty);
  });

  test('an unlinked repository is refused before any forge question', () async {
    await expectLater(
      authorize('ws1', adam, write: true, repoId: 'elsewhere'),
      throwsA(isA<AuthException>()),
    );
    expect(forgeReads, isEmpty);
  });
}

class _Members implements WorkspaceMembershipRepository {
  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      WorkspaceMember(
        id: 'm-$userId',
        workspaceId: workspaceId,
        userId: userId,
        role: WorkspaceRole.admin,
        joinedAt: DateTime(2026),
      );

  @override
  Future<Map<String, RepoGrantLevel>> getRepoGrants(
    String workspaceId,
    String userId,
  ) async => const {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Roles implements WorkspaceRoleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workspaces implements WorkspaceRepository {
  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => repoId == 'widgets' || repoId == 'vault';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
