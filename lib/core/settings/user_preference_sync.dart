import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/settings/synced_preference.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The `user_preferences` key recording which keys this user has already
/// promoted from device-local storage.
///
/// Holds a JSON array of key names. It rides the same synced row-space as the
/// preferences themselves, so it is atomically visible to every device the user
/// signs in from.
///
/// **This marker is load-bearing.** Without it, promotion is "push my local
/// value whenever the server has none", and deleting a synced key on device A
/// lets device B — which still holds the local copy — immediately re-promote
/// it. The setting becomes undeletable. The marker makes the first promotion
/// terminal.
const String promotionMarkerKey = 'cc.promotion.v1';

/// Writes one preference to the server. `null` deletes.
///
/// The composition root passes `RemoteIdentityRepository.prefsSet`.
typedef PreferencePush = Future<void> Function(String key, String? value);

/// Two-way sync of the [SyncedPreference] registry against the server.
///
/// Local [AppPreferences] stays the **synchronous read path** — every settings
/// notifier reads it in `build()`, and it must keep working offline and before
/// the RPC session exists. The server is the convergence point, not the read
/// path. So:
///
///  * **Pull**: write the server's value into the local store (muted) and
///    invalidate the owning providers, which re-read and decode it.
///  * **Push**: observe the *store's* change stream rather than N providers, so
///    a write from anywhere — a settings screen, onboarding, the command
///    palette — is caught.
///
/// Loop safety has two layers. The primary guard is `_serverMirror`: a push is
/// skipped when the value already equals what the server last reported. The
/// second is [ObservableKeyValueBackend.muted] around the pull write, because
/// the write → stream → push path is implicit here and a missed comparison
/// would be an infinite RPC loop rather than one wasted write.
///
/// Pushes are held until the one-time promotion pass resolves ([_armed]),
/// otherwise a local write racing the pass would push a value the pass is about
/// to reconcile.
class UserPreferenceSync {
  /// Creates a sync over [registry], reading and writing through [ref].
  ///
  /// [push] is a narrow function rather than the identity repository so this
  /// stays a `core/` type with no dependency on cc_data or the identity feature
  /// (which would invert the Dependency Rule), and so tests can drive it with a
  /// two-line fake. The composition root supplies
  /// `repository.prefsSet`.
  UserPreferenceSync({
    required this.ref,
    required this.registry,
    required PreferencePush push,
    this.debounce = const Duration(milliseconds: 300),
  }) : _pushToServer = push;

  /// Provider handle used to read the store and to invalidate.
  final Ref ref;

  /// The keys that follow the user.
  final List<SyncedPreference> registry;

  final PreferencePush _pushToServer;

  /// How long a burst of local writes to one key is coalesced before pushing.
  final Duration debounce;

  late final Map<String, SyncedPreference> _byKey = {
    for (final entry in registry) entry.key: entry,
  };

  /// Last value the server reported per key — the primary echo guard.
  final Map<String, String?> _serverMirror = {};

  /// Keys already promoted, decoded from [promotionMarkerKey].
  final Set<String> _promoted = {};

  /// Pushes are dropped until the promotion pass resolves.
  bool _armed = false;

  final Map<String, Timer> _pending = {};
  StreamSubscription<String>? _changes;
  bool _disposed = false;

  AppPreferences get _prefs => ref.read(appPreferencesProvider);
  ObservableKeyValueBackend get _backend => ref.read(keyValueBackendProvider);

  /// Applies [server] as the authoritative snapshot, promoting any local values
  /// the server has never seen. Idempotent: after the first run the server
  /// holds the key, so later runs take the pull branch.
  Future<void> bootstrap(Map<String, String> server) async {
    _promoted
      ..clear()
      ..addAll(_decodeMarker(server[promotionMarkerKey]));

    var markerChanged = false;
    for (final entry in registry) {
      final remote = server[entry.key];
      if (remote != null) {
        _applyRemote(entry, remote);
        continue;
      }
      final local = _prefs.getString(entry.key);
      if (local == null || _promoted.contains(entry.key)) {
        // Either nothing to promote, or this key was already promoted once and
        // has since been deleted on another device. Re-pushing would resurrect
        // it permanently.
        _serverMirror[entry.key] = null;
        continue;
      }
      if (!_withinLimit(entry, local)) {
        continue;
      }
      _serverMirror[entry.key] = local;
      _promoted.add(entry.key);
      markerChanged = true;
      unawaited(_pushToServer(entry.key, local).catchError((_) {}));
    }

    if (markerChanged) {
      unawaited(
        _pushToServer(promotionMarkerKey, jsonEncode(_promoted.toList()..sort()))
            .catchError((_) {}),
      );
    }

    _armed = true;
    _listenForLocalWrites();
  }

  /// Applies a later server snapshot. Pull only — promotion already ran.
  void applyServerSnapshot(Map<String, String> server) {
    if (!_armed) {
      return;
    }
    _promoted
      ..clear()
      ..addAll(_decodeMarker(server[promotionMarkerKey]));
    for (final entry in registry) {
      final remote = server[entry.key];
      if (remote == null) {
        _serverMirror[entry.key] = null;
        continue;
      }
      _applyRemote(entry, remote);
    }
  }

  /// Writes a server value into the local store and refreshes its readers.
  ///
  /// Skips entirely when the local value already matches, so an echoed
  /// snapshot does not churn providers (and so a pull never notifies).
  void _applyRemote(SyncedPreference entry, String remote) {
    _serverMirror[entry.key] = remote;
    if (_prefs.getString(entry.key) == remote) {
      return;
    }
    _backend.muted = true;
    try {
      _backend.set(entry.key, remote);
    } finally {
      _backend.muted = false;
    }
    entry.onPulled?.call(ref);
  }

  void _listenForLocalWrites() {
    _changes ??= _backend.changes.listen((key) {
      final entry = _byKey[key];
      if (entry == null || _disposed) {
        return;
      }
      _pending[key]?.cancel();
      _pending[key] = Timer(debounce, () => _push(entry));
    });
  }

  void _push(SyncedPreference entry) {
    _pending.remove(entry.key);
    if (!_armed || _disposed) {
      return;
    }
    final value = _prefs.getString(entry.key);
    if (_serverMirror[entry.key] == value) {
      return;
    }
    if (value != null && !_withinLimit(entry, value)) {
      return;
    }
    _serverMirror[entry.key] = value;
    if (value != null && !_promoted.contains(entry.key)) {
      _promoted.add(entry.key);
      unawaited(
        _pushToServer(promotionMarkerKey, jsonEncode(_promoted.toList()..sort()))
            .catchError((_) {}),
      );
    }
    // Fire-and-forget: a preference write must never block the UI or surface an
    // error into theming. An offline write is dropped; the next snapshot
    // reconciles.
    unawaited(_pushToServer(entry.key, value).catchError((_) {}));
  }

  bool _withinLimit(SyncedPreference entry, String value) =>
      utf8.encode(value).length <= entry.maxBytes;

  Set<String> _decodeMarker(String? raw) {
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toSet();
      }
    } on FormatException {
      // A corrupt marker must not wedge sync. Treating it as empty risks one
      // re-promotion, which is far better than dropping every future push.
    }
    return {};
  }

  /// Cancels the local-write subscription and any debounced pushes.
  void dispose() {
    _disposed = true;
    for (final timer in _pending.values) {
      timer.cancel();
    }
    _pending.clear();
    unawaited(_changes?.cancel());
    _changes = null;
  }
}
