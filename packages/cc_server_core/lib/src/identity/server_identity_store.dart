import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_rpc/cc_rpc.dart';

/// This server's cryptographic identity: an Ed25519 keypair minted at first
/// boot and kept for life (PRD 15 §9), plus the relay-room coordinates
/// derived alongside it (PRD 15 §4).
///
/// The **fingerprint** (SHA-256 hex of the public key) is the server's
/// identity everywhere: in descriptors, invites, pairing QRs, and the TOFU
/// pins clients hold. The private seed never leaves the data dir.
class ServerIdentity {
  /// Creates a loaded identity. Use [ServerIdentityStore.load].
  const ServerIdentity({
    required this.serverId,
    required this.seedB64,
    required this.publicKeyB64,
    required this.fingerprint,
    required this.relayRoom,
    required this.relayOwnerToken,
    required this.serverName,
  });

  /// Stable server id (UUID-shaped, minted once).
  final String serverId;

  /// The Ed25519 private seed (base64url, no padding). Never serialized to
  /// any wire shape.
  final String seedB64;

  /// The Ed25519 public key (base64url, no padding) — sent to clients during
  /// the auth handshake.
  final String publicKeyB64;

  /// SHA-256 hex of the public key — the pinned identity string.
  final String fingerprint;

  /// The high-entropy signaling-broker room this server owns.
  final String relayRoom;

  /// The secret proving room ownership to the broker across reconnects (the
  /// broker stores only its hash).
  final String relayOwnerToken;

  /// Human-readable server name (config override or hostname).
  final String serverName;

  /// Signs an identity challenge (the client's fresh auth nonce).
  Future<String> signChallenge(String nonce) =>
      ServerIdentityCrypto.signChallenge(seedB64: seedB64, nonce: nonce);
}

/// Loads (or mints, on first boot) the server identity from
/// `<dataDir>/server_identity.json`.
///
/// The file is chmod-600-equivalent by directory convention (the data dir
/// already holds the SQLite DB and PSK store); rotating it is equivalent to
/// standing up a new server — every client must re-pair, which is exactly
/// the TOFU semantics.
final class ServerIdentityStore {
  ServerIdentityStore._();

  /// The identity file name inside the data dir.
  static const String fileName = 'server_identity.json';

  /// Loads the identity, creating and persisting a fresh one when absent or
  /// unreadable. [serverName] overrides the stored/derived display name for
  /// this run (config wins over hostname).
  static Future<ServerIdentity> load(
    String dataDir, {
    String? serverName,
  }) async {
    final file = File('$dataDir/$fileName');
    Map<String, dynamic>? stored;
    if (file.existsSync()) {
      try {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          stored = decoded;
        }
      } catch (_) {
        // Unreadable identity → treated as first boot (a fresh identity is
        // the only safe recovery; clients will refuse via TOFU until
        // re-paired, which is the correct loud failure).
      }
    }

    var serverId = stored?['server_id'] as String? ?? '';
    var seed = stored?['identity_seed'] as String? ?? '';
    var relayRoom = stored?['relay_room'] as String? ?? '';
    var relayOwnerToken = stored?['relay_owner_token'] as String? ?? '';
    final storedName = stored?['server_name'] as String? ?? '';
    var dirty = false;

    if (serverId.isEmpty) {
      serverId = _uuidV4();
      dirty = true;
    }
    if (seed.isEmpty) {
      seed = await ServerIdentityCrypto.generateSeed();
      dirty = true;
    }
    if (relayRoom.isEmpty) {
      relayRoom = RemoteControlCrypto.generateRoomCode();
      dirty = true;
    }
    if (relayOwnerToken.isEmpty) {
      relayOwnerToken = RemoteControlCrypto.generatePsk();
      dirty = true;
    }
    final name = (serverName?.trim().isNotEmpty ?? false)
        ? serverName!.trim()
        : (storedName.isNotEmpty ? storedName : Platform.localHostname);
    if (name != storedName) {
      dirty = true;
    }

    if (dirty) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'server_id': serverId,
          'identity_seed': seed,
          'relay_room': relayRoom,
          'relay_owner_token': relayOwnerToken,
          'server_name': name,
        }),
      );
    }

    final publicKey = await ServerIdentityCrypto.publicKeyFromSeed(seed);
    return ServerIdentity(
      serverId: serverId,
      seedB64: seed,
      publicKeyB64: publicKey,
      fingerprint: ServerIdentityCrypto.fingerprintOf(publicKey),
      relayRoom: relayRoom,
      relayOwnerToken: relayOwnerToken,
      serverName: name,
    );
  }

  static String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
