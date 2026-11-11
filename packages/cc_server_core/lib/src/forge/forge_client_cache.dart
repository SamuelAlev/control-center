import 'dart:async';

import 'package:cc_infra/cc_infra.dart' show ForgeHttpClientFactory;
import 'package:rhttp/rhttp.dart';

/// The forge HTTP clients built for one kind of caller, keyed by who and
/// what they act for.
///
/// Bounded: past [maxEntries] the least recently used client is retired. A
/// retired client (evicted, or forgotten because its identity changed) is
/// disposed after [grace], so a caller that took it just before keeps
/// working through the requests it is making; [close] disposes at once.
final class ForgeClientCache<K, V extends Object> {
  /// Creates a cache that releases a client with `dispose`.
  ForgeClientCache({
    required this._dispose,
    this.maxEntries = 256,
    this.grace = const Duration(minutes: 2),
  });

  /// A cache of [RhttpClient]s.
  static ForgeClientCache<K, RhttpClient> http<K>() =>
      ForgeClientCache(dispose: (client) => client.dispose());

  /// A cache of [ForgeHttpClientFactory]s (each holds a client per forge).
  static ForgeClientCache<K, ForgeHttpClientFactory> factories<K>() =>
      ForgeClientCache(dispose: (factory) => factory.dispose());

  /// How many clients are kept.
  final int maxEntries;

  /// How long a retired client lives on before it is disposed.
  final Duration grace;

  final void Function(V client) _dispose;
  final Map<K, V> _clients = {};

  /// How many clients are cached.
  int get length => _clients.length;

  /// The client for [key], built with [build] when there is none.
  V get(K key, V Function() build) {
    final hit = _clients.remove(key);
    if (hit != null) {
      return _clients[key] = hit;
    }
    while (_clients.length >= maxEntries) {
      _retire(_clients.remove(_clients.keys.first) as V);
    }
    return _clients[key] = build();
  }

  /// Retires every client whose key [match] accepts.
  void retireWhere(bool Function(K key) match) {
    final gone = [
      for (final MapEntry(:key, :value) in _clients.entries)
        if (match(key)) (key, value),
    ];
    for (final (key, client) in gone) {
      _clients.remove(key);
      _retire(client);
    }
  }

  /// Disposes every client now.
  void close() {
    for (final client in _clients.values) {
      _dispose(client);
    }
    _clients.clear();
  }

  void _retire(V client) => Timer(grace, () => _dispose(client));
}
