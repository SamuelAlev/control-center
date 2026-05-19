import 'dart:convert';

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
    this.descriptor,
    this.serverUrl,
    this.workspaceId,
  });

  /// The freshly minted device credential id.
  final String deviceId;

  /// The pairing key (returned exactly once; store it in the keychain).
  final String psk;

  /// The server's connection descriptor map (every path + the identity
  /// fingerprint to pin), when the server published one.
  final Map<String, dynamic>? descriptor;

  /// The server's advertised RPC URL (fallback when no descriptor).
  final String? serverUrl;

  /// The workspace the invite admits to.
  final String? workspaceId;
}

/// Redeems a one-time invite [code] against `POST <httpBase>/invites/redeem`
/// — the pre-auth endpoint that JIT-provisions the user and mints their first
/// device credential (PRD 14 §4, carried over any topology per PRD 15 §6).
///
/// Throws [InviteRejectedException] when the server refuses the code, or a
/// [StateError] with a user-safe message on unreachability / malformed
/// responses.
Future<RedeemedInvite> redeemInviteAt({
  required Uri httpBase,
  required String code,
  required String platform,
  String? deviceLabel,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final client = http.Client();
  try {
    final response = await client
        .post(
          httpBase.replace(path: '/invites/redeem'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'code': code,
            'platform': platform,
            if (deviceLabel != null && deviceLabel.isNotEmpty)
              'device_label': deviceLabel,
          }),
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw const InviteRejectedException('Invite is invalid or expired');
    }
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw StateError('Malformed invite response');
    }
    final deviceId = body['device_id'] as String? ?? '';
    final psk = body['psk'] as String? ?? '';
    if (deviceId.isEmpty || psk.isEmpty) {
      throw StateError('Malformed invite response');
    }
    return RedeemedInvite(
      deviceId: deviceId,
      psk: psk,
      descriptor: (body['descriptor'] as Map?)?.cast<String, dynamic>(),
      serverUrl: body['server_url'] as String?,
      workspaceId: body['workspace_id'] as String?,
    );
  } on InviteRejectedException {
    rethrow;
  } on StateError {
    rethrow;
  } catch (e) {
    throw StateError('Could not reach the server to redeem the invite: $e');
  } finally {
    client.close();
  }
}
