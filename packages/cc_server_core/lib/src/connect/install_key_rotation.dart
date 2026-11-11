import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';

/// Replaces this server's Connect install key (`connect.rotateKey`).
///
/// For each Connect the old key has an identity for
/// ([ConnectSettings.connectTargets]), the grants it sealed are gathered
/// from every sign-in lane ([SignInLaneBinding.connectSeals]):
///
/// * none: nothing there needs containing, and Connect would refuse a
///   retire without a seal, so that Connect is skipped;
/// * some: each is revoked upstream (GitHub and Slack; a Google seal has no
///   revoke route and lapses), best effort, at most [maxRevokes] of them and
///   within [revokeBudget], a failure logged and not blocking. Then the old
///   identity is retired there, signed with it and carrying one of those
///   seals ([ConnectClient.retireInstall]). From then on that Connect
///   refuses the old key and every seal made for it; access tokens it
///   already handed out last until they expire.
///
/// A Connect that answers `install_blocked` has retired it already. Any
/// other refusal, or an unreachable Connect, fails the rotation with
/// [ConnectRetireFailed] and the old seed stays, unless `force`: then the
/// seed is replaced anyway and the Connects that still accept the old key
/// are logged and returned. Either way the grants already revoked are gone,
/// so everyone signs in again.
final class InstallKeyRotation {
  /// Creates the rotation over [signIn]'s lanes and Connect client.
  InstallKeyRotation({
    required this.signIn,
    this.maxRevokes = 200,
    this.revokeBudget = const Duration(seconds: 30),
  });

  /// The lanes whose grants are revoked, and the Connect client.
  final ProviderSignInService signIn;

  /// Most grants revoked upstream per Connect.
  final int maxRevokes;

  /// How long the revocations at one Connect may take.
  final Duration revokeBudget;

  /// Rotates the key for [userId] (null from a host tool). Returns the
  /// Connects that still accept the old key, empty unless [force].
  Future<List<ConnectRetireFailure>> rotate({
    String? userId,
    bool force = false,
  }) async {
    final connect = signIn.connect;
    final settings = connect.settings;
    final old = await settings.installSeed();
    final workspaces = await settings.workspaceList?.call();
    final workspaceIds = [
      for (final Workspace workspace in workspaces ?? const []) workspace.id,
    ];
    final failures = <ConnectRetireFailure>[];
    var retired = 0;
    for (final target in await settings.connectTargets()) {
      final held = [
        for (final binding in signIn.bindings)
          for (final seal in await binding.connectSeals(
            target.origin,
            workspaceIds,
          ))
            (provider: binding.lane.provider, seal: seal),
      ];
      if (held.isEmpty) {
        continue;
      }
      await _revoke(connect, target, held);
      try {
        await connect.retireInstall(target, held.first.seal, oldSeed: old);
        retired++;
      } on ConnectException catch (e) {
        if (e.code == ConnectErrorCode.installBlocked) {
          retired++;
        } else {
          failures.add((origin: target.origin, error: e.code));
        }
      }
    }
    if (failures.isNotEmpty && !force) {
      throw ConnectRetireFailed(failures);
    }
    await settings.replaceInstallSeed(old);
    forgeAudit(ForgeAuditEvent.connectKeyRotated, {
      'user_id': userId,
      'retired': retired,
      if (failures.isNotEmpty) ...{
        'forced': true,
        'unretired': [
          for (final f in failures) '${f.origin} ${f.error.wire}',
        ].join(', '),
      },
    });
    return failures;
  }

  Future<void> _revoke(
    ConnectClient connect,
    ConnectTarget target,
    List<({ConnectProvider provider, SealRequest seal})> held,
  ) async {
    final revocable = [
      for (final h in held)
        if (h.provider == ConnectProvider.github ||
            h.provider == ConnectProvider.slack)
          h,
    ];
    Future<void> each() async {
      for (final (:provider, :seal) in revocable.take(maxRevokes)) {
        try {
          if (provider == ConnectProvider.github) {
            await connect.githubRevoke(
              target,
              GitHubRevokeRequest(
                workspaceId: seal.workspaceId,
                seal: seal.seal,
              ),
            );
          } else {
            await connect.slackRevoke(target, seal);
          }
        } on Object catch (e) {
          forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
            'lane': provider.name,
            'workspace_id': seal.workspaceId,
            'reason': 'key_rotation:${errorKindOf(e)}',
          });
        }
      }
    }

    try {
      await each().timeout(revokeBudget);
    } on TimeoutException {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'origin': target.origin,
        'reason': 'key_rotation:budget',
      });
    }
    if (revocable.length > maxRevokes) {
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'origin': target.origin,
        'reason': 'key_rotation:limit',
        'count': revocable.length - maxRevokes,
      });
    }
  }
}
