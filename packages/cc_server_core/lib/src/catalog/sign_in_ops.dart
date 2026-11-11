import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInLaneMode, isLoginId;
import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';

/// Resolves the optional `workspace_id` of an unscoped credential or sign-in
/// call (null: server-wide, as during onboarding before any workspace
/// exists). The workspace must be registered and not deleted before its
/// membership database is consulted, and the caller must be a member; the
/// server then decides which credential slot applies there.
Future<String?> checkedOverlayWorkspaceId(
  RepoOpContext ctx, {
  required WorkspaceRepository workspaces,
  WorkspaceMembershipRepository? members,
}) async {
  final raw = ctx.args['workspace_id'];
  final id = raw is String && raw.isNotEmpty ? raw : ctx.workspaceId;
  if (id == null || id.isEmpty) {
    return null;
  }
  final workspace = await workspaces.getById(id);
  if (workspace == null || workspace.isDeleted) {
    throw const NotFoundException('Workspace not found');
  }
  if (members != null && await members.getMember(id, ctx.userId) == null) {
    throw const AuthException('Not a member of this workspace');
  }
  return id;
}

/// Whether a sign-in on [binding] from [workspaceId] would land in the
/// workspace's slot; a lane that cannot say (no workspace for a workspace
/// lane) answers false.
Future<bool> _slotOf(SignInLaneBinding binding, String? workspaceId) async {
  try {
    return await binding.slotFor(workspaceId) != null;
  } on Object {
    return false;
  }
}

/// Lanes whose grant belongs to the workspace rather than to a person.
bool _workspaceLane(ConnectOAuthLane lane) =>
    lane == ConnectOAuthLane.linearApp || lane == ConnectOAuthLane.slack;

/// The browser sign-in surface for every provider lane.
///
/// The person is always the authenticated session (`ctx.userId`), never a
/// client argument. Omitted when sign-in is unavailable (demo).
List<RepoOp> buildSignInOps({
  required ProviderSignInService? signIn,
  required WorkspaceRepository workspaces,
  required WorkspaceMembershipRepository members,
  required String pairingServerUrl,
}) {
  final service = signIn;
  if (service == null) {
    return const [];
  }

  Future<String?> workspaceOf(RepoOpContext ctx) => checkedOverlayWorkspaceId(
    ctx,
    workspaces: workspaces,
    members: members,
  );

  ConnectOAuthLane laneOf(RepoOpContext ctx) {
    final lane = ConnectOAuthLane.fromWire(ctx.args['lane'] as String?);
    if (lane == null || service.binding(lane) == null) {
      throw const NotFoundException('Missing or invalid argument: lane');
    }
    return lane;
  }

  /// The caller's workspace for [lane]; a workspace lane (`linear_app`,
  /// `slack`) needs one and needs its admin, checked on every call that
  /// changes the grant (begin, complete, disconnect).
  Future<String?> laneWorkspace(
    RepoOpContext ctx,
    ConnectOAuthLane lane, {
    String? workspaceId,
  }) async {
    final id = workspaceId ?? await workspaceOf(ctx);
    if (!_workspaceLane(lane)) {
      return id;
    }
    if (id == null) {
      throw const ValidationException(
        'Connecting this for automation needs a workspace.',
      );
    }
    final member = await members.getMember(id, ctx.userId);
    if (member == null || !member.role.isAdmin) {
      throw const AuthException(
        'Only workspace admins can connect this for automation.',
      );
    }
    return id;
  }

  String loginIdOf(RepoOpContext ctx) {
    final loginId = ctx.args['login_id'];
    if (loginId is! String || !isLoginId(loginId)) {
      throw const NotFoundException('Missing or invalid argument: login_id');
    }
    return loginId;
  }

  return [
    RepoOp(
      name: 'oauth.lanes',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final workspaceId = await workspaceOf(ctx);
        final origin = providerOAuthHttpOrigin(pairingServerUrl);
        return {
          'lanes': [
            for (final lane in ConnectOAuthLane.values)
              if (service.binding(lane) != null)
                await () async {
                  final mode = await service.modeFor(
                    lane,
                    workspaceId: workspaceId,
                  );
                  return {
                    'lane': lane.wire,
                    'mode': mode.mode.name,
                    'redirect_uri':
                        mode.mode == SignInLaneMode.own && origin.isNotEmpty
                        ? providerOAuthRedirectUri(origin, lane.wire).toString()
                        : '',
                    'error': mode.error,
                    'unavailable_reason': ?mode.reason?.wire,
                  };
                }(),
          ],
        };
      },
    ),
    RepoOp(
      name: 'oauth.begin',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['lane'],
      handler: (ctx) async {
        final lane = laneOf(ctx);
        final attempt = await service.begin(
          lane: lane,
          userId: ctx.userId,
          origin: providerOAuthHttpOrigin(pairingServerUrl),
          workspaceId: await laneWorkspace(ctx, lane),
        );
        return attempt.toJson();
      },
    ),
    RepoOp(
      name: 'oauth.complete',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['login_id', 'code'],
      handler: (ctx) async {
        final code = ctx.args['code'];
        if (code is! String || code.length > 32) {
          throw const NotFoundException('Missing or invalid argument: code');
        }
        final loginId = loginIdOf(ctx);
        final workspaceId = await workspaceOf(ctx);
        final known = service.lookup(
          loginId: loginId,
          userId: ctx.userId,
          workspaceId: workspaceId,
        );
        if (known != null) {
          // The caller may have lost the admin role since the attempt began.
          await laneWorkspace(ctx, known.lane, workspaceId: workspaceId);
        }
        final attempt = await service.complete(
          loginId: loginId,
          confirmCode: code,
          userId: ctx.userId,
          workspaceId: workspaceId,
        );
        return attempt.toJson();
      },
    ),
    RepoOp(
      name: 'oauth.status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['login_id'],
      handler: (ctx) async {
        final loginId = loginIdOf(ctx);
        final attempt = service.lookup(
          loginId: loginId,
          userId: ctx.userId,
          workspaceId: await workspaceOf(ctx),
        );
        return attempt?.toJson() ??
            service.unknownSignInAttemptJson(
              loginId,
              lane: ConnectOAuthLane.fromWire(ctx.args['lane'] as String?),
            );
      },
    ),
    RepoOp(
      name: 'oauth.connections',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async {
        final workspaceId = await workspaceOf(ctx);
        final connections = <Map<String, Object?>>[];
        for (final lane in ConnectOAuthLane.values) {
          final binding = service.binding(lane);
          if (binding == null || (_workspaceLane(lane) && workspaceId == null)) {
            continue;
          }
          final connection = await binding.connection(ctx.userId, workspaceId);
          connections.add(
            (connection ??
                    LaneConnection(
                      lane: lane,
                      status: ForgeConnectionStatus.notConnected,
                      workspaceSlot: await _slotOf(binding, workspaceId),
                    ))
                .toJson(),
          );
        }
        return {'connections': connections};
      },
    ),
    RepoOp(
      name: 'oauth.disconnect',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      requiredArgs: ['lane'],
      handler: (ctx) async {
        final lane = laneOf(ctx);
        final workspaceId = await laneWorkspace(ctx, lane);
        final binding = service.binding(lane)!;
        final before = await binding.connection(ctx.userId, workspaceId);
        await binding.disconnect(ctx.userId, workspaceId);
        forgeAudit(ForgeAuditEvent.grantDisconnected, {
          'lane': lane.wire,
          'user_id': ctx.userId,
          'workspace_id': workspaceId,
          // Connect revokes this sign-in only; an own app's revoke ends that
          // app's grant for the person.
          'revoked': before == null
              ? 'nothing'
              : before.source == SignInLaneMode.connect
              ? 'this_sign_in'
              : 'app_grant',
        });
        return {'ok': true};
      },
    ),
  ];
}
