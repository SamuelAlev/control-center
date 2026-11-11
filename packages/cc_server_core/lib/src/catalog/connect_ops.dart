import 'package:cc_connect_core/cc_connect_core.dart' show ConnectConfig;
import 'package:cc_domain/cc_domain.dart' show RepoOpKind, ValidationException;
import 'package:cc_host/cc_host.dart' show RepoOp, ServerAuthority;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/install_key_rotation.dart';
import 'package:cc_server_core/src/connect/klipy_gifs.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';

/// Where one Connect-capable lane gets its credentials right now.
enum ConnectLaneSource {
  /// The server's own app or key.
  own,

  /// Control Center Connect.
  connect,

  /// Neither.
  off,
}

/// One row of `connect.status`'s `lanes`.
typedef ConnectLaneStatus = ({
  String lane,
  ConnectLaneSource source,
  String error,
});

/// Resolves every lane's source: an own app wins when complete, a partial
/// own app is an error (never mixed with Connect), and Connect answers only
/// for lanes its verified config advertises.
Future<List<ConnectLaneStatus>> connectLaneStatuses({
  required ProviderAppSettings apps,
  required ConnectConfig? config,
  required KlipyGifs? klipy,
  Future<bool> Function()? slackOwnApp,
}) async {
  Future<ConnectLaneStatus> appLane(
    String lane,
    ProviderApp provider, {
    required bool connectHas,
  }) async {
    // Inactive own apps (a Connect is chosen) read as none: Connect runs
    // the lane, the stored app is only kept for later.
    final state = (await apps.status(provider)).effectiveState;
    return switch (state) {
      OwnAppState.complete => (
        lane: lane,
        source: ConnectLaneSource.own,
        error: '',
      ),
      OwnAppState.partial => (
        lane: lane,
        source: ConnectLaneSource.off,
        error: OwnAppIncomplete(provider).message,
      ),
      OwnAppState.none => (
        lane: lane,
        source: connectHas ? ConnectLaneSource.connect : ConnectLaneSource.off,
        error: '',
      ),
    };
  }

  final klipySource = await klipy?.source();
  return [
    await appLane(
      'github',
      ProviderApp.github,
      connectHas: config?.github != null,
    ),
    await appLane(
      'google',
      ProviderApp.google,
      connectHas: config?.google != null,
    ),
    await appLane(
      'linear',
      ProviderApp.linear,
      connectHas: config?.linear != null,
    ),
    (
      lane: 'slack',
      source: await slackOwnApp?.call() ?? false
          ? ConnectLaneSource.own
          : config?.slack != null
          ? ConnectLaneSource.connect
          : ConnectLaneSource.off,
      error: '',
    ),
    (
      lane: 'klipy',
      source: switch (klipySource) {
        KlipyLaneSource.own ||
        KlipyLaneSource.workspaceOwn => ConnectLaneSource.own,
        KlipyLaneSource.connect => ConnectLaneSource.connect,
        KlipyLaneSource.off || null => ConnectLaneSource.off,
      },
      error: '',
    ),
  ];
}

/// The `connect.*` ops: which Connect this server uses, its trust state, and
/// the install key. Server owner only — it decides where every person's
/// sign-in is brokered.
///
/// [onChanged] runs after anything that changes which identity lanes use
/// (mode, URL, pins, install key), so cached tokens of the old one go.
List<RepoOp> buildConnectOps({
  required ConnectSettings? settings,
  required ConnectClient? connect,
  required ProviderAppSettings? apps,
  KlipyGifs? klipy,
  Future<bool> Function()? slackOwnApp,
  Future<void> Function()? onChanged,
  InstallKeyRotation? keyRotation,
}) {
  if (settings == null || connect == null || apps == null) {
    return const [];
  }

  Future<Map<String, Object?>> status({bool refresh = false}) async {
    final state = await connect.configState(
      await connect.serverTarget(),
      refresh: refresh,
    );
    final config = state.config;
    return {
      'mode': state.choice.mode.name,
      'url': state.choice.baseUrl,
      'locked': state.choice.lockedByEnvironment,
      'install_id': state.installId,
      'usable': state.usable,
      'error': state.error,
      'stale': state.stale,
      'pending_pins': state.pendingPins,
      'epoch': config?.epoch,
      'lanes': [
        for (final lane in await connectLaneStatuses(
          apps: apps,
          config: state.usable ? config : null,
          klipy: klipy,
          slackOwnApp: slackOwnApp,
        ))
          {'lane': lane.lane, 'source': lane.source.name, 'error': lane.error},
      ],
    };
  }

  Future<Map<String, Object?>> changed() async {
    connect.invalidate();
    await onChanged?.call();
    return status(refresh: true);
  }

  return [
    RepoOp(
      name: 'connect.status',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      serverAuthority: ServerAuthority.serverOwner,
      handler: (_) => status(),
    ),
    RepoOp(
      name: 'connect.configure',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      serverAuthority: ServerAuthority.serverOwner,
      requiredArgs: const ['mode'],
      handler: (ctx) async {
        final mode = switch (ctx.args['mode']) {
          'hosted' => ConnectMode.hosted,
          'custom' => ConnectMode.custom,
          'off' => ConnectMode.off,
          _ => throw const ValidationException(
            'mode must be hosted, custom or off.',
          ),
        };
        final url = ctx.args['url'];
        final before = (await settings.choice()).mode;
        await settings.setChoice(mode, url: url is String ? url.trim() : '');
        forgeAudit(ForgeAuditEvent.connectChoiceChanged, {
          'scope': 'server',
          'user_id': ctx.userId,
          'from': before.name,
          'to': mode.name,
        });
        return changed();
      },
    ),
    RepoOp(
      name: 'connect.test',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      serverAuthority: ServerAuthority.serverOwner,
      handler: (_) => status(refresh: true),
    ),
    RepoOp(
      name: 'connect.confirmPins',
      kind: RepoOpKind.mutate,
      workspaceScoped: false,
      serverAuthority: ServerAuthority.serverOwner,
      handler: (ctx) async {
        final target = await connect.serverTarget();
        await connect.confirmPendingPins(target);
        forgeAudit(ForgeAuditEvent.connectPinsConfirmed, {
          'scope': 'server',
          'user_id': ctx.userId,
          'origin': target.origin,
        });
        return changed();
      },
    ),
    if (keyRotation != null)
      RepoOp(
        name: 'connect.rotateKey',
        kind: RepoOpKind.mutate,
        workspaceScoped: false,
        serverAuthority: ServerAuthority.serverOwner,
        handler: (ctx) async {
          // Each Connect retires the old key first: from then on it refuses
          // the old key and every seal made for it, while access tokens it
          // already handed out last until they expire. Every grant reads as
          // "sign in again" from here on. `force` replaces the key even when a
          // Connect could not retire it.
          try {
            await keyRotation.rotate(
              userId: ctx.userId,
              force: ctx.args['force'] == true,
            );
          } on ConnectRetireFailed catch (e) {
            throw ValidationException(e.message);
          }
          return changed();
        },
      ),
  ];
}
