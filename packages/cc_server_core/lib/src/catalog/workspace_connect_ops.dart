import 'package:cc_connect_core/cc_connect_core.dart' show ConnectConfig;
import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/klipy_gifs.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_github_app_settings.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';

/// Where one of a workspace's provider lanes gets its credentials now.
enum WorkspaceLaneSource {
  /// The workspace's own app (or its own Slack app connection).
  workspaceOwn('workspace_own'),

  /// The server's own app or key, inherited.
  serverOwn('server_own'),

  /// A Control Center Connect: the workspace's or the server's.
  connect('connect'),

  /// Nothing.
  off('off');

  const WorkspaceLaneSource(this.wire);

  /// The wire spelling.
  final String wire;
}

/// One row of `workspaceConnect.status`'s `lanes`.
typedef WorkspaceLaneStatus = ({
  String provider,
  WorkspaceLaneSource source,
  String error,
});

/// The `workspaceConnect.*` ops: which Connect (or which apps) one
/// workspace's sign-ins and provider lanes use.
///
/// `status` is for any member (the settings page shows everyone where their
/// sign-in goes); the install id and pending pins are admin only. `set`,
/// `test` and `confirmPins` are admin only. The dispatcher validates the
/// workspace and the caller's role before a handler runs. Empty when the
/// host wires no Connect (demo, tests).
///
/// [slackOwnApp] answers whether the workspace runs its own Slack app
/// connection, which stays available in every mode.
List<RepoOp> buildWorkspaceConnectOps({
  required WorkspaceRepository workspaceRepository,
  required ConnectSettings? settings,
  required ConnectClient? connect,
  required ProviderAppSettings? apps,
  WorkspaceGitHubAppSettings? workspaceGitHub,
  WorkspaceProviderAppSettings? workspaceApps,
  KlipyGifs? klipy,
  Future<bool> Function(String workspaceId)? slackOwnApp,
}) {
  if (settings == null || connect == null || apps == null) {
    return const [];
  }

  Future<Workspace> workspaceOf(RepoOpContext ctx) async {
    final workspace = await workspaceRepository.getById(ctx.workspaceId!);
    if (workspace == null || workspace.deletedAt != null) {
      throw const NotFoundException('Workspace not found');
    }
    return workspace;
  }

  Future<List<WorkspaceLaneStatus>> lanes(
    Workspace workspace,
    ConnectRoute route,
    ConnectConfig? config,
  ) async {
    WorkspaceLaneStatus row(
      String provider,
      WorkspaceLaneSource source, [
      String error = '',
    ]) => (provider: provider, source: source, error: error);

    WorkspaceLaneStatus fromState(
      String provider,
      OwnAppState state,
      WorkspaceLaneSource whenComplete,
      String partialError,
    ) => switch (state) {
      OwnAppState.complete => row(provider, whenComplete),
      OwnAppState.partial => row(
        provider,
        WorkspaceLaneSource.off,
        partialError,
      ),
      OwnAppState.none => row(provider, WorkspaceLaneSource.off),
    };

    Future<WorkspaceLaneStatus> appLane(
      String provider,
      ProviderApp server,
      WorkspaceAppProvider? own, {
      required bool connectHas,
    }) async {
      if (route.workspaceOwnApps) {
        if (own == null) {
          final status = await workspaceGitHub?.status(workspace);
          if (status == null) {
            return row(provider, WorkspaceLaneSource.off);
          }
          return fromState(
            provider,
            status.state,
            WorkspaceLaneSource.workspaceOwn,
            status.error,
          );
        }
        final status = await workspaceApps?.status(workspace.id, own);
        if (status == null) {
          return row(provider, WorkspaceLaneSource.off);
        }
        return fromState(
          provider,
          status.state,
          WorkspaceLaneSource.workspaceOwn,
          status.error,
        );
      }
      if (route.serverOwnApps) {
        return fromState(
          provider,
          (await apps.status(server)).effectiveState,
          WorkspaceLaneSource.serverOwn,
          OwnAppIncomplete(server).message,
        );
      }
      return row(
        provider,
        connectHas ? WorkspaceLaneSource.connect : WorkspaceLaneSource.off,
      );
    }

    final slackOwn = await slackOwnApp?.call(workspace.id) ?? false;
    final klipySource = await klipy?.source(workspace.id);
    return [
      await appLane(
        'github',
        ProviderApp.github,
        null,
        connectHas: config?.github != null,
      ),
      await appLane(
        'google',
        ProviderApp.google,
        WorkspaceAppProvider.google,
        connectHas: config?.google != null,
      ),
      await appLane(
        'linear',
        ProviderApp.linear,
        WorkspaceAppProvider.linear,
        connectHas: config?.linear != null,
      ),
      row(
        'slack',
        slackOwn
            ? WorkspaceLaneSource.workspaceOwn
            : config?.slack != null
            ? WorkspaceLaneSource.connect
            : WorkspaceLaneSource.off,
      ),
      row('klipy', switch (klipySource) {
        KlipyLaneSource.workspaceOwn => WorkspaceLaneSource.workspaceOwn,
        KlipyLaneSource.own => WorkspaceLaneSource.serverOwn,
        KlipyLaneSource.connect => WorkspaceLaneSource.connect,
        KlipyLaneSource.off || null => WorkspaceLaneSource.off,
      }),
    ];
  }

  Future<Map<String, Object?>> status(
    RepoOpContext ctx, {
    bool refresh = false,
  }) async {
    final workspace = await workspaceOf(ctx);
    final server = await settings.choice();
    final route = settings.routeOf(
      workspace,
      ConnectRoute(
        mode: WorkspaceConnectMode.inherit,
        target: ConnectTarget.server(server),
        serverOwnApps: !server.mode.usesConnect,
      ),
    );
    final state = await connect.configState(route.target, refresh: refresh);
    final usable = state.usable;
    final admin = ctx.role?.isAdmin ?? false;
    // Pending pins are the workspace's to confirm only for its own custom
    // Connect; a change at the server's Connect is the server owner's.
    final ownPins =
        route.mode == WorkspaceConnectMode.custom && state.pendingPins != null;
    return {
      'mode': workspace.connectMode.wireName,
      'url': workspace.connectMode == WorkspaceConnectMode.custom
          ? workspace.connectUrl
          : '',
      'server_mode': server.mode.name,
      'server_url': server.mode.usesConnect ? server.baseUrl : '',
      'effective_mode': route.effectiveMode,
      'locked': settings.lockedByEnvironment,
      'health': !route.target.enabled
          ? 'off'
          : usable
          ? 'ok'
          : 'down',
      'error': state.error,
      'stale': state.stale,
      'epoch': state.config?.epoch ?? 0,
      'lanes': [
        for (final lane in await lanes(
          workspace,
          route,
          usable ? state.config : null,
        ))
          {
            'provider': lane.provider,
            'source': lane.source.wire,
            'error': lane.error,
          },
      ],
      if (admin) 'install_id': state.installId,
      if (admin && ownPins) 'pending_pins': state.pendingPins,
    };
  }

  return [
    RepoOp(
      name: 'workspaceConnect.status',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.member,
      handler: status,
    ),
    RepoOp(
      name: 'workspaceConnect.set',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      requiredArgs: const ['mode'],
      handler: (ctx) async {
        final workspace = await workspaceOf(ctx);
        var mode = switch (ctx.args['mode']) {
          'inherit' => WorkspaceConnectMode.inherit,
          'hosted' => WorkspaceConnectMode.hosted,
          'custom' => WorkspaceConnectMode.custom,
          'own' => WorkspaceConnectMode.own,
          _ => throw const ValidationException(
            'mode must be inherit, hosted, custom or own.',
          ),
        };
        if (mode.usesOwnConnect && settings.lockedByEnvironment) {
          throw const ValidationException(
            'This server\'s operator pinned where sign-ins go '
            '(CC_CONNECT_URL), so a workspace cannot choose its own Connect '
            'server. Use the server\'s choice or this workspace\'s own apps.',
          );
        }
        var url = '';
        if (mode == WorkspaceConnectMode.custom) {
          final raw = ctx.args['url'];
          url = await ConnectSettings.checkWorkspaceConnectUrl(
            raw is String ? raw : '',
          );
          if (ConnectSettings.isHostedUrl(url)) {
            mode = WorkspaceConnectMode.hosted;
            url = '';
          }
        }
        if (workspace.connectMode != mode || workspace.connectUrl != url) {
          await workspaceRepository.upsert(
            workspace.copyWith(
              connectMode: mode,
              connectUrl: url,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
          settings.workspaceChoiceChanged(workspace.id);
          forgeAudit(ForgeAuditEvent.connectChoiceChanged, {
            'scope': 'workspace',
            'user_id': ctx.userId,
            'workspace_id': workspace.id,
            'from': workspace.connectMode.name,
            'to': mode.name,
          });
        }
        return status(ctx, refresh: true);
      },
    ),
    RepoOp(
      name: 'workspaceConnect.test',
      kind: RepoOpKind.read,
      minRole: WorkspaceRole.admin,
      handler: (ctx) => status(ctx, refresh: true),
    ),
    RepoOp(
      name: 'workspaceConnect.confirmPins',
      kind: RepoOpKind.mutate,
      minRole: WorkspaceRole.admin,
      handler: (ctx) async {
        final workspace = await workspaceOf(ctx);
        final route = await settings.routeFor(workspace.id);
        if (route.mode != WorkspaceConnectMode.custom ||
            !route.target.enabled) {
          throw const ValidationException(
            'Only a workspace using its own custom Connect server has pins '
            'to confirm here.',
          );
        }
        await connect.confirmPendingPins(route.target);
        settings.workspaceChoiceChanged(workspace.id);
        forgeAudit(ForgeAuditEvent.connectPinsConfirmed, {
          'scope': 'workspace',
          'user_id': ctx.userId,
          'workspace_id': workspace.id,
          'origin': route.target.origin,
        });
        return status(ctx, refresh: true);
      },
    ),
  ];
}
