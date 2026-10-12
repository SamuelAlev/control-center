import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/identity/sso_settings_service.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';

/// Device authorization plus the only channel application code may consume.
typedef PairedPeerAuth = ({
  PairedDevicesTableData row,
  String psk,
  SecureRpcChannel channel,
});

/// Authenticates an active device and establishes a forward-secret Noise
/// session. All subsequent RPC and resource traffic uses the returned channel,
/// never the underlying direct/relay transport.
Future<PairedPeerAuth?> authenticatePairedPeer(
  RemoteRpcChannelPort transport, {
  required PairedDeviceDao devicesDao,
  required PairedDeviceSecretsPort secrets,
  ServerIdentity? identity,
  Future<({int maxAgeMinutes, int idleTimeoutMinutes})> Function()? sessionPolicy,
  void Function(String message)? warn,
  Duration timeout = const Duration(seconds: 15),
}) async {
  if (identity == null) {
    warn?.call('Secure connection refused: server identity unavailable');
    await transport.close();
    return null;
  }
  Future<bool> isActive(PairedDevicesTableData row) async {
    if (row.status != PairedDeviceStatus.active ||
        RemotePairingLifecycle.isExpired(row.expiresAt, DateTime.now())) {
      return false;
    }
    final policy = sessionPolicy;
    if (policy == null) {
      return true;
    }
    final bounds = await policy();
    return !SsoSettingsService.violatesSessionPolicy(
      policy: bounds,
      pairedAt: row.pairedAt,
      lastSeenAt: row.lastSeenAt,
      now: DateTime.now(),
    );
  }

  String? authenticatedPsk;
  SecureChannelConnection? connection;
  try {
    connection = await acceptSecureChannel(
      channel: transport,
      readPsk: (deviceId) async {
        final row = await devicesDao.getById(deviceId);
        if (row == null || !await isActive(row)) {
          return null;
        }
        return authenticatedPsk = await secrets.readPsk(deviceId);
      },
      serverPublicKey: identity.publicKeyB64,
      signIdentity: identity.signChallenge,
      timeout: timeout,
    );
    // Revocation or credential rotation during the handshake must not create a
    // live session after the revocation watch already ran.
    final row = await devicesDao.getById(connection.deviceId);
    final currentPsk = await secrets.readPsk(connection.deviceId);
    if (row == null ||
        !await isActive(row) ||
        currentPsk == null ||
        currentPsk != authenticatedPsk) {
      await connection.channel.close();
      return null;
    }
    return (row: row, psk: currentPsk, channel: connection.channel);
  } catch (_) {
    warn?.call('Secure device handshake refused');
    await (connection?.channel ?? transport).close();
    return null;
  }
}
