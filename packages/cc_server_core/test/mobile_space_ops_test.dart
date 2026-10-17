import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOpContext;
import 'package:cc_server_core/src/catalog/mobile_space_ops.dart';
import 'package:test/test.dart';

void main() {
  final messaging = _Spaces();
  final members = _Members();
  final ops = buildMobileSpaceOps(messaging: messaging, members: members);
  final op = ops.firstWhere(
    (item) => item.name == 'messaging.addUserParticipant',
  );
  RepoOpContext ctx(String workspace, String space, String user) =>
      RepoOpContext(
        workspaceId: workspace,
        deviceId: 'device-caller',
        userId: 'caller',
        args: {
          'workspace_id': 'ws-other', // forged request cannot replace context
          'space_id': space,
          'user_id': user,
        },
      );

  test('adds only real members to spaces in the bound workspace', () async {
    expect(await op.handler(ctx('ws-a', 'space-a', 'alice')), {'ok': true});
    expect(messaging.added, ('ws-a', 'space-a', 'alice', PrincipalType.user));
    messaging.added = null;
    await expectLater(
      op.handler(ctx('ws-b', 'space-a', 'alice')),
      throwsA(isA<NotFoundException>()),
    );
    expect(messaging.added, isNull);
    await expectLater(
      op.handler(ctx('ws-a', 'space-a', 'outsider')),
      throwsA(isA<NotFoundException>()),
    );
    expect(messaging.added, isNull);
  });
  test('base branches cannot be read from another workspace', () async {
    final branches = ops.firstWhere(
      (item) => item.name == 'messaging.getSpaceRepoBranches',
    );
    expect(await branches.handler(ctx('ws-a', 'space-a', 'alice')), {
      'branches': {'repo-a': 'main'},
    });
    await expectLater(
      branches.handler(ctx('ws-b', 'space-a', 'alice')),
      throwsA(isA<NotFoundException>()),
    );
  });
}

class _Spaces implements MessagingRepository {
  (String, String, String, PrincipalType)? added;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      workspaceId == 'ws-a' && spaceId == 'space-a';

  @override
  Future<Map<String, String>> spaceRepoBranches(
    String workspaceId,
    String spaceId,
  ) async => {'repo-a': 'main'};

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    added = (workspaceId, spaceId, principalId, participantType);
  }
}

class _Members implements WorkspaceMembershipRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      workspaceId == 'ws-a' && userId == 'alice'
      ? WorkspaceMember(
          id: 'member-a',
          workspaceId: workspaceId,
          userId: userId,
          role: WorkspaceRole.member,
          joinedAt: DateTime.utc(2026),
        )
      : null;
}
