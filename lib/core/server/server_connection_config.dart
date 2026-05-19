import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/core/providers/storage_providers.dart';

/// How the desktop reaches the `cc_server` that owns its data.
///
/// The desktop is a thin client: it never opens the database itself. It either
/// spawns a `cc_server` subprocess on this machine ([local]) or connects to
/// paired servers elsewhere ([remote]). Both paths end in a `RemoteRpcClient`
/// the whole UI talks to over RPC.
///
/// VESTIGIAL FIRST-RUN GATE — this enum predates the descriptor-driven
/// [ServerConnectionStore]. It survives only because the first-run setup screen
/// (`_ServerSetupScreen` in `server_backend.dart`) uses it to choose between
/// spawning a local server vs connecting to a remote one. The actual,
/// ongoing connection state is descriptor-driven: a [ServerEntry] holds a full
/// `ConnectionDescriptor`, and the enum is NOT consulted for connection
/// management after setup. It is a setup-time UX toggle, not a second source
/// of truth for connection state.
enum ServerConnectionMode {
  /// Spawn and supervise a local `cc_server`, which owns the database on this
  /// machine. The default, self-contained, single-user setup.
  local,

  /// Connect to a paired `cc_server` running elsewhere. The data lives on that
  /// server; this desktop is purely a renderer.
  remote;

  /// Parses a persisted [value], defaulting to [local] for null/unknown input.
  static ServerConnectionMode fromName(String? value) => switch (value) {
    'remote' => ServerConnectionMode.remote,
    _ => ServerConnectionMode.local,
  };
}

/// One paired server this client can connect to (PRD 15 §10 multi-server).
///
/// A client can be paired with several servers (home LAN box, work VPS) and
/// switch between them; each keeps its own [descriptor], TOFU
/// [pinnedFingerprint], and device credential. The PSK is a secret and lives
/// in the OS keychain under [ServerConnectionStore.pskKeyFor] — never inside
/// this value object.
class ServerEntry {
  /// Creates an entry. [pinnedFingerprint] defaults to the descriptor's
  /// fingerprint (the pin travels with the invite/QR that created the entry).
  ServerEntry({
    required this.descriptor,
    required this.deviceId,
    String? pinnedFingerprint,
    DateTime? pairedAt,
  }) : pinnedFingerprint = pinnedFingerprint ?? descriptor.fingerprint,
       pairedAt = pairedAt ?? DateTime.now();

  /// Deserializes from prefs JSON.
  factory ServerEntry.fromJson(Map<String, dynamic> json) => ServerEntry(
    descriptor: ConnectionDescriptor.fromJson(
      (json['descriptor'] as Map).cast<String, dynamic>(),
    ),
    deviceId: json['device_id'] as String? ?? '',
    pinnedFingerprint: json['pin'] as String?,
    pairedAt: DateTime.tryParse(json['paired_at'] as String? ?? ''),
  );

  /// Every known way to reach this server + its published identity.
  final ConnectionDescriptor descriptor;

  /// This client's device credential id on that server.
  final String deviceId;

  /// The TOFU-pinned identity fingerprint. Enforced on every connect; a
  /// mismatch is a hard refusal (re-pair via a fresh invite).
  final String pinnedFingerprint;

  /// When this client paired with the server.
  final DateTime pairedAt;

  /// The server's stable id.
  String get serverId => descriptor.serverId;

  /// The server's display name.
  String get name => descriptor.serverName;

  /// Serializes to prefs JSON (no secrets).
  Map<String, dynamic> toJson() => {
    'descriptor': descriptor.toJson(),
    'device_id': deviceId,
    'pin': pinnedFingerprint,
    'paired_at': pairedAt.toIso8601String(),
  };

  /// Copy with a refreshed [descriptor] (server re-published its paths) —
  /// the pin is deliberately kept: a descriptor refresh must never be able
  /// to rotate the identity a client trusts.
  ServerEntry withDescriptor(ConnectionDescriptor updated) => ServerEntry(
    descriptor: updated,
    deviceId: deviceId,
    pinnedFingerprint: pinnedFingerprint,
    pairedAt: pairedAt,
  );

  /// Copy with the TOFU pin set (first verified connect of a manual entry).
  ServerEntry withPin(String fingerprint) => ServerEntry(
    descriptor: descriptor,
    deviceId: deviceId,
    pinnedFingerprint: fingerprint,
    pairedAt: pairedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ServerEntry &&
      other.descriptor == descriptor &&
      other.deviceId == deviceId &&
      other.pinnedFingerprint == pinnedFingerprint;

  @override
  int get hashCode => Object.hash(descriptor, deviceId, pinnedFingerprint);
}

/// Canonicalizes a user-entered server URL into the exact `ws(s)://…/rpc`
/// endpoint `cc_server` upgrades, or returns null when it cannot be a valid
/// WebSocket URL.
///
/// Forgives the shapes people actually type: a bare `host:port` (assumes
/// `ws://`), an `http`/`https` scheme (mapped to `ws`/`wss`), and a missing
/// path (defaulted to `/rpc`). Query and fragment are dropped.
String? normalizeServerUrl(String raw) {
  var text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  if (!text.contains('://')) {
    text = 'ws://$text';
  }
  final parsed = Uri.tryParse(text);
  if (parsed == null || parsed.host.isEmpty) {
    return null;
  }
  final scheme = switch (parsed.scheme) {
    'ws' || 'wss' => parsed.scheme,
    'http' => 'ws',
    'https' => 'wss',
    _ => null,
  };
  if (scheme == null) {
    return null;
  }
  final path = (parsed.path.isEmpty || parsed.path == '/')
      ? '/rpc'
      : parsed.path;
  return Uri(
    scheme: scheme,
    host: parsed.host,
    port: parsed.hasPort ? parsed.port : null,
    path: path,
  ).toString();
}

/// Reads/writes the client's server list across [AppPreferences] (non-secret
/// fields) and [SecureStore] (per-server pairing keys).
///
/// Shared deliberately by the boot-time resolver (which runs before Riverpod
/// is up, so it takes the backends directly) and the settings notifiers.
/// Both use the same keys, so a change in Settings is what the next boot (or
/// the in-app server switch) reads.
class ServerConnectionStore {
  /// Creates a store over the given storage backends.
  const ServerConnectionStore(this._prefs, this._secure);

  final AppPreferences _prefs;
  final SecureStore _secure;

  /// Prefs key holding the [ServerConnectionMode] name. Its presence is how
  /// we detect first run (the user has not chosen yet).
  static const String modeKey = 'server_connection_mode';

  /// Prefs key holding the JSON list of [ServerEntry]s.
  static const String entriesKey = 'server_entries';

  /// Prefs key naming the active server (a [ServerEntry.serverId]).
  static const String activeServerKey = 'server_active_id';

  /// Keychain key for one server's pairing key (PSK).
  static String pskKeyFor(String serverId) => 'server_psk_$serverId';

  /// Whether the user has made a server-connection choice yet.
  bool get isConfigured => _prefs.containsKey(modeKey);

  /// The chosen mode, defaulting to [ServerConnectionMode.local].
  ServerConnectionMode readMode() =>
      ServerConnectionMode.fromName(_prefs.getString(modeKey));

  /// Persists the mode choice.
  Future<void> setMode(ServerConnectionMode mode) =>
      _prefs.setString(modeKey, mode.name);

  /// Every paired server, in stored order.
  List<ServerEntry> readEntries() {
    final raw = _prefs.getString(entriesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((m) {
            try {
              return ServerEntry.fromJson(m.cast<String, dynamic>());
            } catch (_) {
              return null;
            }
          })
          .whereType<ServerEntry>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// The entry for [serverId], or null.
  ServerEntry? entry(String serverId) {
    for (final e in readEntries()) {
      if (e.serverId == serverId) {
        return e;
      }
    }
    return null;
  }

  /// The active server's id, or null when none was chosen yet.
  String? readActiveServerId() => _prefs.getString(activeServerKey);

  /// The active entry: the chosen one, else the first paired server.
  ServerEntry? readActive() {
    final entries = readEntries();
    if (entries.isEmpty) {
      return null;
    }
    final activeId = readActiveServerId();
    for (final e in entries) {
      if (e.serverId == activeId) {
        return e;
      }
    }
    return entries.first;
  }

  /// Marks [serverId] active (the workspace picker groups by server; the
  /// switch itself is owned by the app host).
  Future<void> setActiveServer(String serverId) =>
      _prefs.setString(activeServerKey, serverId);

  /// Adds or replaces [entry] (keyed by server id). When [psk] is non-null it
  /// is written to the keychain (empty deletes it); null leaves it untouched.
  Future<void> upsertEntry(ServerEntry entry, {String? psk}) async {
    // Copy: readEntries() returns an unmodifiable const list when empty.
    final entries = [...readEntries()];
    final index = entries.indexWhere((e) => e.serverId == entry.serverId);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    await _writeEntries(entries);
    if (psk != null) {
      final key = pskKeyFor(entry.serverId);
      if (psk.isEmpty) {
        await _secure.delete(key: key);
      } else {
        await _secure.write(key: key, value: psk);
      }
    }
  }

  /// Replaces [serverId]'s descriptor (server re-published its paths),
  /// keeping the pin. No-op when the server is unknown.
  Future<void> updateDescriptor(
    String serverId,
    ConnectionDescriptor descriptor,
  ) async {
    final existing = entry(serverId);
    if (existing == null || descriptor.serverId != serverId) {
      return;
    }
    await upsertEntry(existing.withDescriptor(descriptor));
  }

  /// Records the TOFU pin after the first verified connect of an entry that
  /// had none (manual URL entry). No-op when the server is unknown.
  Future<void> updatePin(String serverId, String fingerprint) async {
    final existing = entry(serverId);
    if (existing == null) {
      return;
    }
    await upsertEntry(existing.withPin(fingerprint));
  }

  /// Removes [serverId] and deletes its keychain PSK.
  Future<void> removeEntry(String serverId) async {
    final entries = [...readEntries()]
      ..removeWhere((e) => e.serverId == serverId);
    await _writeEntries(entries);
    await _secure.delete(key: pskKeyFor(serverId));
    if (readActiveServerId() == serverId) {
      await _prefs.remove(activeServerKey);
    }
  }

  /// Reads one server's pairing key, or null.
  Future<String?> readPsk(String serverId) =>
      _secure.read(key: pskKeyFor(serverId));

  Future<void> _writeEntries(List<ServerEntry> entries) => _prefs.setString(
    entriesKey,
    jsonEncode([for (final e in entries) e.toJson()]),
  );

  /// Forgets everything — every entry, every PSK, the mode — so
  /// [isConfigured] reads false and the next boot returns to setup. Used by
  /// the web client on explicit disconnect (the pairing key must not linger
  /// in the browser).
  Future<void> clear() async {
    for (final e in readEntries()) {
      await _secure.delete(key: pskKeyFor(e.serverId));
    }
    await _prefs.remove(entriesKey);
    await _prefs.remove(activeServerKey);
    await _prefs.remove(modeKey);
  }
}
