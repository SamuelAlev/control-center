import 'package:cc_domain/cc_domain.dart' show RepoOpKind;
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/workspaces/domain/usecases/create_workspace.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/remote_rpc_catalog.dart'
    show workspaceToWire;
import 'package:uuid/uuid.dart';

/// Repo-RPC op that creates a workspace at a server chokepoint.
///
/// Id minting, name trim and `WorkspaceCreated` live in
/// [CreateWorkspaceUseCase]. Owner membership is recorded here — the same
/// bootstrap `workspace.upsert` runs on a create — so the caller is a member
/// before the next workspace-scoped call. Injected via `extraOps`.
List<RepoOp> buildWorkspaceCreateOps({
  required WorkspaceRepository workspaceRepository,
  required WorkspaceMembershipRepository? identityMembers,
  required DomainEventBus? eventBus,
}) => [
  RepoOp(
    name: 'workspace.create',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['name'],
    handler: (ctx) async {
      final workspace = await CreateWorkspaceUseCase(
        repository: workspaceRepository,
        eventBus: eventBus,
      ).execute(CreateWorkspaceCommand(name: ctx.args['name'] as String));
      final members = identityMembers;
      if (members != null &&
          await members.getMember(workspace.id, ctx.userId) == null) {
        await members.upsert(
          WorkspaceMember(
            id: const Uuid().v4(),
            workspaceId: workspace.id,
            userId: ctx.userId,
            role: WorkspaceRole.owner,
            joinedAt: DateTime.now(),
          ),
        );
        eventBus?.publish(
          WorkspaceMemberAdded(
            workspaceId: workspace.id,
            userId: ctx.userId,
            role: WorkspaceRole.owner,
            occurredAt: DateTime.now(),
          ),
        );
      }
      final stored = workspace.ownerUserId != null
          ? workspace
          : workspace.copyWith(ownerUserId: ctx.userId);
      if (stored.ownerUserId != workspace.ownerUserId) {
        await workspaceRepository.upsert(stored);
      }
      return {'workspace': workspaceToWire(stored)};
    },
  ),
];
