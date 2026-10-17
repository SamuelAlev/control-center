import 'package:cc_domain/cc_domain.dart' show NotFoundException, RepoOpKind;
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;

/// Adds a real workspace member to a collaborative space. The client cannot
/// invent an arbitrary user or use a space id from another workspace.
List<RepoOp> buildMobileSpaceOps({
  required MessagingRepository messaging,
  required WorkspaceMembershipRepository members,
}) => [
  RepoOp(
    name: 'messaging.addUserParticipant',
    kind: RepoOpKind.mutate,
    requiredArgs: ['space_id', 'user_id'],
    handler: (ctx) async {
      final workspaceId = ctx.workspaceId!;
      final spaceId = ctx.args['space_id'] as String;
      final userId = ctx.args['user_id'] as String;
      if (!await messaging.spaceExists(workspaceId, spaceId)) {
        throw const NotFoundException('Space not found');
      }
      if (await members.getMember(workspaceId, userId) == null) {
        throw const NotFoundException('Workspace member not found');
      }
      await messaging.addParticipant(
        workspaceId,
        spaceId,
        userId,
        participantType: PrincipalType.user,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'messaging.getSpaceRepoBranches',
    kind: RepoOpKind.read,
    requiredArgs: ['space_id'],
    handler: (ctx) async {
      final workspaceId = ctx.workspaceId!;
      final spaceId = ctx.args['space_id'] as String;
      if (!await messaging.spaceExists(workspaceId, spaceId)) {
        throw const NotFoundException('Space not found');
      }
      return {
        'branches': await messaging.spaceRepoBranches(workspaceId, spaceId),
      };
    },
  ),
];
