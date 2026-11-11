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

/// Repo-RPC op that creates a workspace: the only way one is created.
///
/// Only the server owner may create a workspace (`serverAuthority`, enforced
/// by the dispatcher, which fails closed when no owner is wired): a workspace
/// spends the server's model credentials and compute on everyone its owner
/// invites. A refusal carries `data.kind: server_owner_required`.
///
/// The server mints the id ([CreateWorkspaceUseCase]), so an id that ever
/// named a workspace here never names a new one. The caller is stamped as
/// owner and recorded as an owner member before the next workspace-scoped
/// call. Injected via `extraOps`.
List<RepoOp> buildWorkspaceCreateOps({
  required WorkspaceRepository workspaceRepository,
  required WorkspaceMembershipRepository identityMembers,
  required DomainEventBus? eventBus,
}) => [
  RepoOp(
    name: 'workspace.create',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    serverAuthority: ServerAuthority.serverOwner,
    requiredArgs: ['name'],
    handler: (ctx) async {
      final workspace = await CreateWorkspaceUseCase(
        repository: workspaceRepository,
        eventBus: eventBus,
      ).execute(CreateWorkspaceCommand(name: ctx.args['name'] as String));
      final now = DateTime.now();
      await identityMembers.upsert(
        WorkspaceMember(
          id: const Uuid().v4(),
          workspaceId: workspace.id,
          userId: ctx.userId,
          role: WorkspaceRole.owner,
          joinedAt: now,
        ),
      );
      eventBus?.publish(
        WorkspaceMemberAdded(
          workspaceId: workspace.id,
          userId: ctx.userId,
          role: WorkspaceRole.owner,
          occurredAt: now,
        ),
      );
      final stored = workspace.copyWith(ownerUserId: ctx.userId);
      await workspaceRepository.upsert(stored);
      return {'workspace': workspaceToWire(stored)};
    },
  ),
];
