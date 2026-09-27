import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Non-secret, filesystem-safe identifiers for snapshots. The server directory
/// allows forgetting a pairing to remove *every* user's cached views at once.
String snapshotServerKey(String serverId) =>
    sha256.convert(utf8.encode(serverId)).toString();

/// Bind a snapshot to both the handshake-verified server key and the user
/// returned by that authenticated connection, never to a device PSK.
String snapshotIdentityKey(String fingerprint, String userId) =>
    sha256.convert(utf8.encode(jsonEncode([fingerprint, userId]))).toString();
