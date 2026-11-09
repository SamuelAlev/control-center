import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, isLoginId;
import 'package:cc_domain/cc_domain.dart'
    show AuthException, NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/connect/sign_in_service.dart';

/// Resolves the optional `workspace_id` of an unscoped credential or sign-in
/// call. The workspace must exist before its membership database is
/// consulted, and the caller must be a member.
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
  if (await workspaces.getById(id) == null) {
    throw const NotFoundException('Workspace not found');
  }
  if (members != null && await members.getMember(id, ctx.userId) == null) {
    throw const AuthException('Not a member of this workspace');
  }
  return id;
}

/// HTTP origin advertised for own-app OAuth redirects.
String providerOAuthHttpOrigin(String rpcUrl) {
  if (rpcUrl.isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(rpcUrl);
  if (uri == null || uri.host.isEmpty) {
    return '';
  }
  final scheme = uri.scheme == 'wss' || uri.scheme == 'https'
      ? 'https'
      : 'http';
  return Uri(scheme: scheme, host: uri.host, port: uri.port).toString();
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
  Future<void> Function(String userId, ConnectOAuthLane lane)? onDisconnected,
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

  Future<String?> laneWorkspace(RepoOpContext ctx, ConnectOAuthLane lane) async {
    final workspaceId = await workspaceOf(ctx);
    if (!_workspaceLane(lane)) {
      return workspaceId;
    }
    if (workspaceId == null) {
      throw const ValidationException(
        'Connecting this for automation needs a workspace.',
      );
    }
    final member = await members.getMember(workspaceId, ctx.userId);
    if (member == null || !member.role.isAdmin) {
      throw const AuthException(
        'Only workspace admins can connect this for automation.',
      );
    }
    return workspaceId;
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
                    'mode': mode.mode.wire,
                    'redirect_uri':
                        mode.mode == SignInMode.own && origin.isNotEmpty
                        ? providerOAuthRedirectUri(origin, lane.wire).toString()
                        : '',
                    'error': mode.error,
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
        final attempt = await service.complete(
          loginId: loginIdOf(ctx),
          confirmCode: code,
          userId: ctx.userId,
          workspaceId: await workspaceOf(ctx),
        );
        return attempt.toJson();
      },
    ),
    RepoOp(
      name: 'oauth.status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      requiredArgs: ['login_id'],
      handler: (ctx) async => service
          .status(
            loginId: loginIdOf(ctx),
            userId: ctx.userId,
            workspaceId: await workspaceOf(ctx),
          )
          .toJson(),
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
            (connection ?? LaneConnection(lane: lane, connected: false))
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
        await service.binding(lane)!.disconnect(ctx.userId, workspaceId);
        await onDisconnected?.call(ctx.userId, lane);
        return {'ok': true};
      },
    ),
  ];
}
