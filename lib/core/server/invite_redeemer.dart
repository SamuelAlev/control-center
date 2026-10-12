import 'dart:convert';

import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:http/http.dart' as http;

/// Thrown when the server refuses an invite code at redemption — invalid,
/// already redeemed, or expired. `toString` returns the bare message (no
/// type prefix) so string-rendered surfaces stay readable. Distinct from a
/// malformed response, which is a server-side fault, not a user error.
class InviteRejectedException implements Exception {
  /// Creates an [InviteRejectedException] with a user-safe [message].
  const InviteRejectedException(this.message);

  /// What went wrong, safe to show to the user.
  final String message;

  @override
  String toString() => message;
}

/// The credential + connection material a redeemed invite yields.
class RedeemedInvite {
  /// Creates a [RedeemedInvite].
  const RedeemedInvite({
    required this.deviceId,
    required this.psk,
    required this.verifiedFingerprint,
    this.descriptor,
    this.serverUrl,
    this.workspaceId,
  });

  /// The freshly minted device credential id.
  final String deviceId;

  /// The pairing key (returned exactly once; store it in the keychain).
  final String psk;

  /// Fingerprint proved by invite-authenticated Noise; empty only for the
  /// public demo, whose first-party origin remains the initial trust anchor.
  final String verifiedFingerprint;

  /// The server's connection descriptor map (every path + the identity
  /// fingerprint to pin), when the server published one.
  final Map<String, dynamic>? descriptor;

  /// The server's advertised RPC URL (fallback when no descriptor).
  final String? serverUrl;

  /// The workspace the invite admits to.
  final String? workspaceId;
}

/// Redeems a 256-bit invite over Noise on `/invites/secure`. The code itself
/// and the device PSK appear only inside authenticated encrypted records.
/// A network intermediary sees only the one-way public invite routing id.
/// The first server identity is authenticated by possession of the out-of-band
/// invite; an existing stored identity pin must still be enforced by callers.
Future<RedeemedInvite> redeemInviteAt({
  required Uri httpBase,
  required String code,
  required String platform,
  String? deviceLabel,
  String? pinnedFingerprint,
  Duration timeout = const Duration(seconds: 15),
}) async {
  String hash;
  try {
    hash = InvitePairingProof.codeHash(code);
  } on FormatException {
    throw const InviteRejectedException('Invite is invalid or expired');
  }
  final routeId = InvitePairingProof.routeIdFromHash(hash);
  final uri = httpBase.replace(
    scheme: httpBase.scheme == 'https' ? 'wss' : 'ws',
    path: '/invites/secure',
    query: '',
    fragment: '',
  );
  WsClientChannel? raw;
  SecureChannelConnection? connection;
  try {
    raw = await WsClientChannel.connect(uri).timeout(timeout);
    connection = await connectSecureChannel(
      channel: raw,
      deviceId: 'invite:$routeId',
      psk: InvitePairingProof.pskFromHash(hash),
      pinnedFingerprint: pinnedFingerprint,
      timeout: timeout,
    );
    final answer = connection.channel.incoming.first.timeout(timeout);
    await connection.channel.send({
      'type': 'invite_redeem',
      'code': code,
      'platform': platform,
      if (deviceLabel != null && deviceLabel.isNotEmpty)
        'device_label': deviceLabel,
    });
    final frame = await answer;
    if (frame['type'] != 'invite_redeemed' ||
        frame['result'] is! Map<String, dynamic>) {
      throw const InviteRejectedException('Invite is invalid or expired');
    }
    final body = frame['result'] as Map<String, dynamic>;
    final deviceId = body['device_id'];
    final psk = body['psk'];
    if (deviceId is! String || deviceId.isEmpty ||
        psk is! String || psk.isEmpty) {
      throw StateError('Malformed invite response');
    }
    return RedeemedInvite(
      deviceId: deviceId,
      psk: psk,
      verifiedFingerprint: connection.serverFingerprint,
      descriptor: (body['descriptor'] as Map?)?.cast<String, dynamic>(),
      serverUrl: body['server_url'] as String?,
      workspaceId: body['workspace_id'] as String?,
    );
  } on InviteRejectedException {
    rethrow;
  } on StateError {
    rethrow;
  } on ServerIdentityMismatchException {
    throw const InviteRejectedException('Server identity changed');
  } on SecureHandshakeException {
    throw const InviteRejectedException('Invite is invalid or expired');
  } catch (_) {
    throw const InviteRejectedException(
      'Could not reach the server to redeem the invite',
    );
  } finally {
    await (connection?.channel ?? raw)?.close();
  }
}

/// Public demo bootstrap has no out-of-band 256-bit secret. The initial web
/// origin remains trusted (an active proxy can replace its JavaScript), but
/// the server encrypts the new per-device PSK to this client's ephemeral key.
/// Never use this path for a high-entropy workspace invite.
Future<RedeemedInvite> redeemPublicDemoAt({
  required Uri httpBase,
  required String code,
  required String platform,
  http.Client Function()? httpClientFactory,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final recipient = await CredentialSeal.newRecipient();
  final client = (httpClientFactory ?? http.Client.new)();
  try {
    final response = await client.post(
      httpBase.replace(path: '/invites/redeem'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'platform': platform,
        'handoff_key': recipient.publicKey,
      }),
    ).timeout(timeout);
    if (response.statusCode != 200) {
      throw const InviteRejectedException('Invite is invalid or expired');
    }
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic> ||
        json.containsKey('psk') ||
        json['box'] is! Map) {
      throw StateError('Malformed demo response');
    }
    final body = await CredentialSeal.open(
      recipientPrivateKey: recipient.privateKey,
      envelope: (json['box'] as Map).cast<String, dynamic>(),
      context: 'cc-public-demo-v1',
    );
    final deviceId = body['device_id'];
    final psk = body['psk'];
    if (deviceId is! String || deviceId.isEmpty ||
        psk is! String || psk.isEmpty) {
      throw StateError('Malformed demo response');
    }
    return RedeemedInvite(
      deviceId: deviceId,
      psk: psk,
      verifiedFingerprint: '',
      descriptor: (body['descriptor'] as Map?)?.cast<String, dynamic>(),
      serverUrl: body['server_url'] as String?,
      workspaceId: body['workspace_id'] as String?,
    );
  } on InviteRejectedException {
    rethrow;
  } on StateError {
    rethrow;
  } catch (_) {
    throw const InviteRejectedException('Could not redeem the demo invitation');
  } finally {
    client.close();
  }
}
