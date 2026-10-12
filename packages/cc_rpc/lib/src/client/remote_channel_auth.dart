import 'dart:async';

import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/channel/secure_channel_handshake.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';

/// The result of a successful client-side channel authentication.
class AuthenticatedRemoteChannel {
  /// Creates an [AuthenticatedRemoteChannel].
  const AuthenticatedRemoteChannel({
    required this.channel,
    required this.serverFingerprint,
  });

  /// The authenticated transport, ready for a [RemoteRpcClient].
  final RemoteRpcChannelPort channel;

  /// The verified SHA-256 fingerprint of the server's Ed25519 public key.
  /// Identity verification is mandatory, including the first connection.
  final String serverFingerprint;
}

/// Thrown when a server refuses a device or fails secure authentication.
class AuthRejectedException implements Exception {
  /// Creates an [AuthRejectedException] with a user-safe [message].
  const AuthRejectedException(this.message);

  /// What went wrong, safe to show to the user.
  final String message;

  @override
  String toString() => message;
}

/// Establishes the same Noise secure session on direct and broker channels,
/// verifies the pinned server identity, then waits for encrypted approval.
Future<AuthenticatedRemoteChannel> authenticateRemoteChannel({
  required RemoteRpcChannelPort channel,
  required String deviceId,
  required String psk,
  String? pinnedFingerprint,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final SecureChannelConnection connection;
  try {
    connection = await connectSecureChannel(
      channel: channel,
      deviceId: deviceId,
      psk: psk,
      pinnedFingerprint: pinnedFingerprint,
      timeout: timeout,
    );
  } on SecureHandshakeException catch (error) {
    throw AuthRejectedException(error.message);
  }
  final secure = connection.channel;
  try {
    final approved = await secure.incoming.first.timeout(timeout);
    if (approved['type'] != 'approved') {
      throw const AuthRejectedException('Server did not approve the device');
    }
  } catch (_) {
    await secure.close();
    rethrow;
  }
  return AuthenticatedRemoteChannel(
    channel: secure,
    serverFingerprint: connection.serverFingerprint,
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
  Duration requestTimeout = const Duration(seconds: 30),
}) async {
  final authed = await authenticateRemoteChannel(
    channel: channel,
    deviceId: deviceId,
    psk: psk,
    pinnedFingerprint: pinnedFingerprint,
    timeout: timeout,
  );
  final client = RemoteRpcClient(authed.channel, timeout: requestTimeout)
    ..start();
  try {
    await client.initialize();
    return (client: client, serverFingerprint: authed.serverFingerprint);
  } catch (_) {
    try {
      await client.close();
    } finally {
      await authed.channel.close();
    }
    rethrow;
  }
}
