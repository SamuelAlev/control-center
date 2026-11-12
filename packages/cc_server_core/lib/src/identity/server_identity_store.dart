import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_paths.dart' show writePrivateFile;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/server_boot_refusal.dart';
import 'package:path/path.dart' as p;

/// This server's cryptographic identity: an Ed25519 keypair minted at first
/// boot and kept for life (PRD 15 §9), plus the relay-room coordinates
/// derived alongside it (PRD 15 §4).
///
/// The **fingerprint** (SHA-256 hex of the public key) is the server's
/// identity everywhere: in descriptors, invites, pairing QRs and the TOFU
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
/// The file is written owner-only (`0600` at creation, flushed, renamed into
/// place). Rotating it is equivalent to standing up a new server: every client
/// must pair again, which is exactly the TOFU semantics. That is why a file
/// that exists but cannot be read is never replaced by a fresh identity: it is
/// quarantined and the boot refused ([ServerIdentityUnreadable]).
final class ServerIdentityStore {
  ServerIdentityStore._();

  /// The identity file name inside the data dir.
  static const String fileName = 'server_identity.json';

  /// The suffix a quarantined identity file carries, followed by a timestamp.
  static const String quarantineSuffix = '.corrupt-';

  /// Loads the identity, creating and persisting a fresh one only when there
  /// is none at all. [serverName] overrides the stored/derived display name
  /// for this run (config wins over hostname).
  ///
  /// Throws [ServerIdentityUnreadable] when the file cannot be parsed or lacks
  /// its id or seed (the file is moved aside first), and also when a file
  /// quarantined by an earlier boot is still there and no identity file
  /// replaced it: a supervisor that restarts the server must not turn the
  /// refusal into a silent new identity on the second try.
  static Future<ServerIdentity> load(
    String dataDir, {
    String? serverName,
  }) async {
    final file = File('$dataDir/$fileName');
    Map<String, dynamic>? stored;
    if (file.existsSync()) {
      stored = _parse(file);
    } else {
      final quarantined = _quarantined(dataDir);
      if (quarantined.isNotEmpty) {
        throw ServerIdentityUnreadable(
          path: file.path,
          quarantinedAt: quarantined.first,
        );
      }
    }

    final serverId = stored?['server_id'] as String? ?? _uuidV4();
    final seed =
        stored?['identity_seed'] as String? ??
        await ServerIdentityCrypto.generateSeed();
    var relayRoom = _string(stored, 'relay_room');
    var relayOwnerToken = _string(stored, 'relay_owner_token');
    final storedName = _string(stored, 'server_name');
    var dirty = stored == null;

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
      await file.parent.create(recursive: true);
      await writePrivateFile(
        file.path,
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert({
            'server_id': serverId,
            'identity_seed': seed,
            'relay_room': relayRoom,
            'relay_owner_token': relayOwnerToken,
            'server_name': name,
          }),
        ),
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

  /// The stored identity, or a quarantine and [ServerIdentityUnreadable] when
  /// it is not a JSON object carrying a non-empty `server_id` and
  /// `identity_seed` (the two fields the fingerprint and every pin rest on).
  static Map<String, dynamic> _parse(File file) {
    Object? problem;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, dynamic> &&
          _string(decoded, 'server_id').isNotEmpty &&
          _string(decoded, 'identity_seed').isNotEmpty) {
        return decoded;
      }
      problem = 'no server_id or identity_seed';
    } on Object catch (e) {
      problem = e.runtimeType;
    }
    final stamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final quarantined = '${file.path}$quarantineSuffix$stamp';
    file.renameSync(quarantined);
    CcHostLog.error(
      'identity: ${file.path} could not be read ($problem) — moved to '
      '$quarantined. Refusing to start with a new identity.',
    );
    throw ServerIdentityUnreadable(path: file.path, quarantinedAt: quarantined);
  }

  /// Identity files an earlier boot quarantined, newest first.
  static List<String> _quarantined(String dataDir) {
    final dir = Directory(dataDir);
    if (!dir.existsSync()) {
      return const [];
    }
    const prefix = '$fileName$quarantineSuffix';
    return [
      for (final entry in dir.listSync(followLinks: false))
        if (entry is File && p.basename(entry.path).startsWith(prefix))
          entry.path,
    ]..sort((a, b) => b.compareTo(a));
  }

  /// [key] of [map] when it is a string, else empty. A value of another type
  /// is as unusable as a missing one.
  static String _string(Map<String, dynamic>? map, String key) {
    final value = map?[key];
    return value is String ? value : '';
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

/// `server_identity.json` exists but cannot be used, and minting a new identity
/// in its place would force every paired client to pair again.
final class ServerIdentityUnreadable extends ServerBootRefusal {
  /// Creates the refusal for the identity file at [path], whose bytes are kept
  /// at [quarantinedAt].
  const ServerIdentityUnreadable({
    required this.path,
    required this.quarantinedAt,
  });

  /// Where the identity file belongs.
  final String path;

  /// Where the unreadable bytes were moved.
  final String quarantinedAt;

  @override
  String get message =>
      'cc_server: cannot start — the server identity at $path could not be '
      'read, and its bytes are kept at $quarantinedAt. Starting with a new '
      'identity would make every paired client pair again. Restore the file '
      'from a backup to $path, or delete $quarantinedAt to start as a new '
      'server.';
}
