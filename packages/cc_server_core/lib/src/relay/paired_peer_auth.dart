import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';

/// The authenticated paired device and its PSK, returned by
/// [authenticatePairedPeer] on success.
typedef PairedPeerAuth = ({PairedDevicesTableData row, String psk});

/// Runs the mutual PSK challenge for a paired peer over any
/// [RemoteRpcChannelPort], independent of the underlying transport (a direct
/// WebSocket via `LocalRpcServer`, or the broker relay via `RemoteRelayHost`).
///
/// The peer sends `{type:'auth', device_id, nonce, proof}` proving PSK
/// possession; this verifies the device is `active` and unexpired, replies with
/// its own matching proof (`auth_response`), and returns the device row + PSK.
/// Fingerprints are empty — there is no DTLS here; the channel guard is TLS (WS)
/// or the relay's own E2E encryption. Returns null on any failure (fail closed);
/// the caller is responsible for sending `auth_denied` and closing.
Future<PairedPeerAuth?> authenticatePairedPeer(
  RemoteRpcChannelPort transport, {
  required PairedDeviceDao devicesDao,
  required PairedDeviceSecretsPort secrets,
  void Function(String message)? warn,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final Map<String, dynamic> frame;
  try {
    frame = await transport.incoming
        .firstWhere((f) => f['type'] == 'auth')
        .timeout(timeout);
  } catch (e) {
    warn?.call('No auth frame: $e');
    return null;
  }
  final deviceId = frame['device_id'] as String?;
  final nonce = frame['nonce'] as String?;
  final proof = frame['proof'] as String?;
  if (deviceId == null || nonce == null || nonce.isEmpty || proof == null) {
    return null;
  }
  final row = await devicesDao.getById(deviceId);
  final psk = await secrets.readPsk(deviceId);
  if (row == null || psk == null || row.status != PairedDeviceStatus.active) {
    warn?.call(
      'auth denied for $deviceId — '
      'row=${row?.status}, psk=${psk == null ? 'missing' : 'present'}',
    );
    return null;
  }
  if (RemotePairingLifecycle.isExpired(row.expiresAt, DateTime.now())) {
    warn?.call('auth denied for $deviceId — credential expired');
    return null;
  }
  final ok = RemoteControlCrypto.verifyChallengeResponse(
    nonce: nonce,
    psk: psk,
    localFingerprint: '',
    remoteFingerprint: '',
    response: proof,
  );
  if (!ok) {
    warn?.call('auth proof mismatch for $deviceId');
    return null;
  }
  final response = RemoteControlCrypto.respondToChallenge(
    nonce: nonce,
    psk: psk,
    localFingerprint: '',
    remoteFingerprint: '',
  );
  try {
    await transport.send({
      'type': 'auth_response',
      'nonce': nonce,
      'response': response,
    });
  } catch (_) {
    return null;
  }
  return (row: row, psk: psk);
}
