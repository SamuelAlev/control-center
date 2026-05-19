import 'dart:async';

import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/crypto/remote_control_crypto.dart';
import 'package:cc_rpc/src/crypto/server_identity.dart';

/// The result of a successful client-side channel authentication.
class AuthenticatedRemoteChannel {
  /// Creates an [AuthenticatedRemoteChannel].
  const AuthenticatedRemoteChannel({
    required this.channel,
    required this.serverFingerprint,
  });

  /// The authenticated transport, ready for a [RemoteRpcClient].
  final RemoteRpcChannelPort channel;

  /// The server's verified identity fingerprint (SHA-256 hex of its Ed25519
  /// public key). Empty only when the server presented no identity — which
  /// [authenticateRemoteChannel] refuses whenever a pin exists.
  final String serverFingerprint;
}

/// Thrown when the server refuses the device credential — an `auth_denied`
/// frame or a PSK proof mismatch. `toString` returns the bare message (no
/// type prefix) so string-rendered surfaces stay readable.
class AuthRejectedException implements Exception {
  /// Creates an [AuthRejectedException] with a user-safe [message].
  const AuthRejectedException(this.message);

  /// What went wrong, safe to show to the user.
  final String message;

  @override
  String toString() => message;
}

/// Runs the client side of the mutual PSK handshake over any
/// [RemoteRpcChannelPort] (direct WS or broker relay), verifying the
/// server's Ed25519 identity and enforcing the TOFU pin (PRD 15 §9).
///
/// Protocol: client sends `{type:'auth', device_id, nonce, proof}`; the
/// server replies `auth_response` carrying its mutual PSK proof **and** its
/// identity (`sid_pub` + `sid_sig`, a signature over the client's fresh
/// nonce), then `approved`. Failure modes are all hard stops:
///
///  * `auth_denied` / bad PSK proof → [AuthRejectedException] (wrong device
///    credential).
///  * [pinnedFingerprint] set and the server presents no identity, a
///    different fingerprint, or an invalid signature →
///    [ServerIdentityMismatchException] — the rebind/MITM signal. No
///    "continue anyway" path exists by design.
///
/// On success returns the channel plus the **verified** fingerprint, which a
/// first-time caller pins (TOFU).
Future<AuthenticatedRemoteChannel> authenticateRemoteChannel({
  required RemoteRpcChannelPort channel,
  required String deviceId,
  required String psk,
  String? pinnedFingerprint,
  Duration timeout = const Duration(seconds: 15),
}) async {
  // Attach the handshake listeners BEFORE sending auth so the replies (which
  // arrive only after the server reads our frame) are never missed.
  final authReply = channel.incoming
      .firstWhere(
        (f) => f['type'] == 'auth_response' || f['type'] == 'auth_denied',
      )
      .timeout(timeout);
  final approved = channel.incoming
      .firstWhere((f) => f['type'] == 'approved')
      .timeout(timeout);
  // Keep `approved`'s error handled even if we bail before awaiting it (a
  // failed auth makes the server close without ever sending `approved`, so
  // this future times out — without this it would surface as an unhandled
  // async error).
  unawaited(approved.catchError((_) => <String, dynamic>{}));

  final nonce = RemoteControlCrypto.generateNonce();
  final proof = RemoteControlCrypto.respondToChallenge(
    nonce: nonce,
    psk: psk,
    localFingerprint: '',
    remoteFingerprint: '',
  );
  await channel.send({
    'type': 'auth',
    'device_id': deviceId,
    'nonce': nonce,
    'proof': proof,
  });

  final Map<String, dynamic> resp;
  try {
    resp = await authReply;
  } catch (e) {
    await channel.close();
    throw StateError('Server did not complete auth: $e');
  }
  if (resp['type'] == 'auth_denied') {
    await channel.close();
    throw const AuthRejectedException(
      'Server rejected the device. Confirm the device id is paired on the '
      'server and the pairing key matches the one the server issued.',
    );
  }
  final ok = RemoteControlCrypto.verifyChallengeResponse(
    nonce: nonce,
    psk: psk,
    localFingerprint: '',
    remoteFingerprint: '',
    response: resp['response'] as String? ?? '',
  );
  if (!ok) {
    await channel.close();
    throw const AuthRejectedException('Server auth proof mismatch');
  }

  // Identity verification (TOFU pinning). The server signs OUR nonce, so a
  // replayed proof from an earlier session never verifies.
  final sidPub = resp['sid_pub'] as String? ?? '';
  final sidSig = resp['sid_sig'] as String? ?? '';
  var fingerprint = '';
  if (sidPub.isNotEmpty && sidSig.isNotEmpty) {
    final valid = await ServerIdentityCrypto.verifyChallenge(
      nonce: nonce,
      publicKeyB64: sidPub,
      signatureB64: sidSig,
    );
    if (valid) {
      fingerprint = ServerIdentityCrypto.fingerprintOf(sidPub);
    }
  }
  final pin = pinnedFingerprint ?? '';
  if (pin.isNotEmpty && fingerprint != pin) {
    await channel.close();
    throw ServerIdentityMismatchException(
      expectedFingerprint: pin,
      actualFingerprint: fingerprint,
    );
  }

  try {
    await approved;
  } catch (e) {
    await channel.close();
    throw StateError('Server did not approve the device: $e');
  }
  return AuthenticatedRemoteChannel(
    channel: channel,
    serverFingerprint: fingerprint,
  );
}

/// [authenticateRemoteChannel] + a started, initialized [RemoteRpcClient].
Future<({RemoteRpcClient client, String serverFingerprint})>
authenticateRemoteClient({
  required RemoteRpcChannelPort channel,
  required String deviceId,
  required String psk,
  String? pinnedFingerprint,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final authed = await authenticateRemoteChannel(
    channel: channel,
    deviceId: deviceId,
    psk: psk,
    pinnedFingerprint: pinnedFingerprint,
    timeout: timeout,
  );
  final client = RemoteRpcClient(authed.channel)..start();
  await client.initialize();
  return (client: client, serverFingerprint: authed.serverFingerprint);
}
