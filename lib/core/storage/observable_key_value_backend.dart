import 'dart:async';

import 'package:control_center/core/storage/key_value_backend.dart';

/// A [KeyValueBackend] decorator that announces every write.
///
/// This is the seam that lets per-user preferences sync without every settings
/// notifier learning about the server. The alternative — one `ref.listen` per
/// synced provider — scales with the number of keys and is easy to half-wire
/// (a key that pulls but never pushes looks correct until you switch devices).
/// Observing the *store* instead catches writes from anywhere: settings
/// screens, onboarding, the command palette, a notifier nobody remembered.
///
/// [changes] emits the key of each mutation. `clear()` emits every key that was
/// present, so a listener can reconcile without diffing.
///
/// `muted` suppresses emission while a remote value is being applied locally.
/// Value comparison against the last-known server value is the primary
/// loop-guard; this is the cheap second layer, because the write → stream →
/// push path is implicit and a missed comparison would otherwise be an
/// infinite RPC loop rather than one wasted write.
class ObservableKeyValueBackend implements KeyValueBackend {
  /// Wraps a backing store, announcing its writes on [changes].
  ObservableKeyValueBackend(this._inner);

  final KeyValueBackend _inner;
  final StreamController<String> _changes = StreamController<String>.broadcast();

  /// Keys mutated through this backend, as they happen.
  Stream<String> get changes => _changes.stream;

  /// While true, mutations are applied but not announced.
  ///
  /// Set around a write that originated from the server, so applying it does
  /// not immediately push it back.
  bool muted = false;

  void _announce(String key) {
    if (!muted && !_changes.isClosed) {
      _changes.add(key);
    }
  }

  @override
  bool set(String key, String value) {
    final ok = _inner.set(key, value);
    if (ok) {
      _announce(key);
    }
    return ok;
  }

  @override
  bool remove(String key) {
    final existed = _inner.remove(key);
    if (existed) {
      _announce(key);
    }
    return existed;
  }

  @override
  bool clear() {
    // Snapshot first: after the clear there is nothing left to enumerate.
    final cleared = _inner.keys;
    final changed = _inner.clear();
    if (changed) {
      for (final key in cleared) {
        _announce(key);
      }
    }
    return changed;
  }

  @override
  String get(String key, [String defaultValue = '']) =>
      _inner.get(key, defaultValue);

  @override
  bool contains(String key) => _inner.contains(key);

  @override
  List<String> get keys => _inner.keys;

  @override
  int get size => _inner.size;

  @override
  Map<String, String> getAll() => _inner.getAll();

  @override
  void dispose() {
    unawaited(_changes.close());
    _inner.dispose();
  }
}
