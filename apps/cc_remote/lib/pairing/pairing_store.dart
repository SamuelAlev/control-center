import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

import 'package:cc_remote/debug_log.dart';
import 'package:web/web.dart' as web;

/// The pairing record persisted on the phone after the first QR scan.
///
/// This is the phone-side twin of the desktop's `PairingPayload`: the desktop
/// base64url-encodes a compact JSON `{v, s, r, k, i, t, x}` into the QR's URL
/// fragment. We can't import the desktop type (it lives in the `control_center`
/// package, which breaks `flutter build web`), so we decode the same wire shape
/// here into an identical record. Field names stay single-letter to match the
/// QR byte-for-byte.
class PairingRecord {
  /// Creates a [PairingRecord].
  const PairingRecord({
    required this.version,
    required this.signalingUrl,
    required this.room,
    required this.psk,
    required this.appInstanceId,
    required this.stunUrls,
    required this.expiresAt,
    this.mode = modeWebrtc,
  });

  /// Decodes a compact-JSON map (the QR payload shape) into a record.
  factory PairingRecord.fromJson(Map<String, dynamic> json) {
    final stun = json['t'];
    final x = json['x'];
    final signaling = (json['s'] as String?) ?? '';
    return PairingRecord(
      version: (json['v'] as num?)?.toInt() ?? currentVersion,
      // Fall back to the hosted broker when a payload omits `s`, so pairing
      // works without the desktop having to spell out the signaling URL.
      signalingUrl: signaling.isEmpty ? defaultSignalingUrl : signaling,
      room: (json['r'] as String?) ?? '',
      psk: (json['k'] as String?) ?? '',
      appInstanceId: (json['i'] as String?) ?? '',
      stunUrls: stun is List
          ? stun.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      expiresAt: x is num
          ? DateTime.fromMillisecondsSinceEpoch(x.toInt(), isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      mode: (json['m'] as String?) ?? modeWebrtc,
    );
  }

  /// WebRTC-to-desktop transport (the default).
  static const String modeWebrtc = 'webrtc';

  /// cc_server-owned relay through the broker (E2E-encrypted frames). In this
  /// mode [room] is the device id and there is no WebRTC/STUN.
  static const String modeRelay = 'relay';

  /// Payload version this client understands.
  static const int currentVersion = 1;

  /// The hosted signaling broker used when a payload omits `s`. Mirrors the
  /// desktop's `PairingPayload.defaultSignalingUrl` (kept in sync by hand, like
  /// [currentVersion]) so this web client stays free of a control-center dep.
  static const String defaultSignalingUrl = 'wss://signaling.usectrl.dev';

  /// Payload version (`v`).
  final int version;

  /// Signaling broker WebSocket URL (`s`).
  final String signalingUrl;

  /// Pairing room code (`r`).
  final String room;

  /// Pre-shared key, base64url without padding (`k`).
  final String psk;

  /// Desktop app-instance id — the signaling peer id of the Mac (`i`).
  final String appInstanceId;

  /// STUN server URLs (`t`).
  final List<String> stunUrls;

  /// When the pairing offer expires (`x`).
  final DateTime expiresAt;

  /// Transport mode (`m`): [modeWebrtc] (default) or [modeRelay].
  final String mode;

  /// Whether this pairing uses the cc_server relay (vs WebRTC-to-desktop).
  bool get isRelay => mode == modeRelay;

  /// Whether this pairing offer has expired.
  ///
  /// Expiry only guards the *first* connect after a fresh scan; a stored record
  /// keeps working across reconnects (the PSK is durable, the broker room is
  /// re-joinable).
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Serializes back to the compact-JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'v': version,
    's': signalingUrl,
    'r': room,
    'k': psk,
    'i': appInstanceId,
    't': stunUrls,
    'x': expiresAt.millisecondsSinceEpoch,
    if (mode != modeWebrtc) 'm': mode,
  };

  @override
  String toString() =>
      'PairingRecord(room: $room, appInstanceId: '
      '$appInstanceId, expired: $isExpired)';
}

/// Persists the [PairingRecord] in browser IndexedDB and consumes it from the
/// pairing URL fragment on first launch.
///
/// The PSK is sensitive: it must never touch the PWA's HTTP host, so it travels
/// in the URL **fragment** (the browser keeps fragments client-side). On boot we
/// read `location.hash`, persist the record, request persistent storage, then
/// `history.replaceState`-strip the fragment so the PSK leaves the URL bar and
/// history. On later opens there is no fragment, so we reconnect from the
/// stored record without re-scanning.
class PairingStore {
  /// Creates a [PairingStore].
  PairingStore();

  static const String _dbName = 'cc_remote';
  static const int _dbVersion = 1;
  static const String _store = 'kv';
  static const String _pairingKey = 'pairing';
  static const String _peerIdKey = 'peer_id';

  /// The URL fragment as it was at app start, captured before the router could
  /// rewrite it. See [captureBootFragment].
  static String? _bootFragment;

  /// Captures the URL fragment at app start. **Must** be called from `main()`
  /// before `runApp`, because Flutter web + go_router navigate during the first
  /// build (the not-paired → `/connect` redirect), which drops the fragment from
  /// the URL. By then [consumeFromFragment] would see an empty hash. Grabbing it
  /// here preserves the pairing payload regardless of later URL changes.
  static void captureBootFragment(String hash) {
    _bootFragment = hash;
  }

  /// Decodes the boot fragment into a [PairingRecord] WITHOUT persisting it,
  /// and strips the fragment from the address bar so the PSK doesn't linger.
  ///
  /// The caller MUST explicitly confirm before saving. A fragment-delivered
  /// pairing offer used to save + auto-connect unconditionally, which let any
  /// page that opened the PWA with a forged `#<payload>` silently hijack the
  /// channel onto attacker infrastructure (one-click MITM). Holding it as an
  /// unconfirmed offer forces a user confirmation gate first (VULN-004).
  /// One-shot. Returns `null` when there is no fragment or it doesn't decode.
  Future<PairingRecord?> decodeFragmentOffer() async {
    final fragment = _readFragment();
    // One-shot: a later call (e.g. a reconnect) must not re-consume it.
    _bootFragment = null;
    if (fragment.isEmpty) {
      return null;
    }
    final record = _decode(fragment);
    if (record == null) {
      return null;
    }
    _stripFragment();
    return record;
  }

  /// Returns this phone's stable signaling peer id, creating and persisting one
  /// on first use.
  ///
  /// A stable id (vs a fresh one per page load) is what lets the broker's
  /// same-peer-id eviction reclaim this phone's room slot the instant a
  /// refreshed tab re-joins — otherwise the new tab carries a different id, the
  /// old tab's lingering socket is not evicted, and the capacity-2 room briefly
  /// reads "full", bouncing the reconnect.
  Future<String> loadOrCreatePeerId() async {
    try {
      final existing = await _dbGet(_peerIdKey);
      if (existing != null && existing.isNotEmpty) {
        return existing;
      }
    } catch (_) {
      // Fall through to mint a fresh (in-memory) id.
    }
    final id = _generatePeerId();
    try {
      await _dbPut(_peerIdKey, id);
    } catch (_) {
      // Persistence is best-effort; a non-persisted id still works this session.
    }
    return id;
  }

  static String _generatePeerId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(12, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Loads the stored record, or `null` when none exists.
  Future<PairingRecord?> load() async {
    try {
      final raw = await _dbGet(_pairingKey);
      if (raw == null) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return PairingRecord.fromJson(decoded);
    } catch (_) {
      // A corrupt record is treated as "not paired" — the user re-scans.
      return null;
    }
  }

  /// Persists [record] and requests persistent storage (best-effort).
  Future<void> save(PairingRecord record) async {
    _requestPersistence();
    try {
      await _dbPut(_pairingKey, jsonEncode(record.toJson()));
    } catch (_) {
      // Persistence is best-effort; the session still works in-memory.
    }
  }

  /// Deletes the stored record (used on unpair / sign out).
  Future<void> clear() async {
    try {
      await _dbDelete(_pairingKey);
    } catch (_) {
      // Best-effort.
    }
  }

  /// Returns the URL fragment without the leading `#`, or '' when absent.
  String _readFragment() {
    // Prefer the fragment captured at boot ([captureBootFragment]); by the time
    // this runs the live `location.hash` has been rewritten by the router. Fall
    // back to a live read when nothing was captured (e.g. unit tests).
    final hash = _bootFragment ?? web.window.location.hash;
    if (hash.isEmpty) {
      return '';
    }
    // Strip the leading '#'. Browsers do not percent-encode base64url chars in
    // a fragment, so no further decoding is needed.
    return hash.startsWith('#') ? hash.substring(1) : hash;
  }

  /// Decodes a base64url fragment into a [PairingRecord], or `null`.
  PairingRecord? _decode(String fragment) {
    try {
      final normalized = base64Url.normalize(fragment);
      final bytes = base64Url.decode(normalized);
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return PairingRecord.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Removes the fragment from the address bar and history without reloading.
  void _stripFragment() {
    final loc = web.window.location;
    final clean = '${loc.pathname}${loc.search}';
    try {
      web.window.history.replaceState(null, '', clean);
    } catch (e, s) {
      // Don't swallow it silently (finding #14): a failure leaves the PSK in the
      // address bar / history, so surface it for diagnosis.
      rlog(
        'pairing',
        'failed to strip PSK from URL fragment — it may remain in history',
        error: e,
        stack: s,
      );
    }
  }

  /// Asks the browser to persist the origin's storage so the PSK survives
  /// eviction. Fire-and-forget — the API is best-effort by design.
  void _requestPersistence() {
    try {
      web.window.navigator.storage.persist();
    } catch (_) {
      // StorageManager is unavailable (private mode, old browser) — non-fatal.
    }
  }

  // --- IndexedDB helpers -------------------------------------------------
  //
  // IndexedDB is callback-based; each [web.IDBRequest] is bridged to a Future
  // via a [Completer]. The store is a flat key/value (`kv`) using out-of-line
  // keys — one row under `pairing` holds the record as a JSON string.

  /// Opens (and on first run, creates) the `kv` object store.
  Future<web.IDBDatabase> _openDb() {
    final completer = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(_dbName, _dbVersion);
    request.onupgradeneeded = ((web.IDBVersionChangeEvent _) {
      final db = request.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_store)) {
        db.createObjectStore(_store);
      }
    }).toJS;
    request.onsuccess = ((web.Event _) {
      completer.complete(request.result as web.IDBDatabase);
    }).toJS;
    request.onerror = ((web.Event _) {
      completer.completeError(StateError('IndexedDB open failed'));
    }).toJS;
    return completer.future;
  }

  Future<void> _dbPut(String key, String value) async {
    final db = await _openDb();
    try {
      final tx = db.transaction(_store.toJS, 'readwrite');
      tx.objectStore(_store).put(value.toJS, key.toJS);
      await _txDone(tx);
    } finally {
      db.close();
    }
  }

  /// Returns the stored Dart string for [key], or `null` when absent.
  Future<String?> _dbGet(String key) async {
    final db = await _openDb();
    try {
      final tx = db.transaction(_store.toJS, 'readonly');
      final store = tx.objectStore(_store);
      final jsResult = await _requestValue(store.get(key.toJS));
      await _txDone(tx);
      if (jsResult == null) {
        return null;
      }
      // Values are stored as JS strings; convert back to a Dart string.
      return (jsResult as JSString).toDart;
    } finally {
      db.close();
    }
  }

  Future<void> _dbDelete(String key) async {
    final db = await _openDb();
    try {
      final tx = db.transaction(_store.toJS, 'readwrite');
      tx.objectStore(_store).delete(key.toJS);
      await _txDone(tx);
    } finally {
      db.close();
    }
  }

  /// Resolves an [web.IDBRequest] to its `result` on success.
  Future<Object?> _requestValue(web.IDBRequest request) {
    final completer = Completer<Object?>();
    request.onsuccess = ((web.Event _) {
      completer.complete(request.result);
    }).toJS;
    request.onerror = ((web.Event _) {
      completer.completeError(StateError('IndexedDB request failed'));
    }).toJS;
    return completer.future;
  }

  /// Completes when the transaction commits (`oncomplete`) or errors.
  Future<void> _txDone(web.IDBTransaction tx) {
    final completer = Completer<void>();
    tx.oncomplete = ((web.Event _) => completer.complete()).toJS;
    tx.onerror = ((web.Event _) => completer.completeError(
      StateError('IndexedDB transaction failed'),
    )).toJS;
    return completer.future;
  }
}
