import 'dart:async';

/// Coalesces concurrent loads of the same key into one flight.
///
/// [run] starts `body` for a key only when no flight for that key is in the
/// air; every caller that arrives while it is joins the same future. The
/// flight is forgotten once it settles, so the next [run] loads again.
///
/// Callers that refresh a single-use secret (an OAuth refresh token) must
/// re-read the stored secret **inside** `body`, never before calling [run]:
/// a caller that read the secret just before an earlier flight rotated it
/// would otherwise start a second flight with the spent value.
///
/// [invalidate] detaches the in-flight load: callers arriving afterwards
/// start a fresh flight, and the detached flight's `commit` callback is
/// skipped, so a result loaded before the invalidation is never cached over
/// it.
final class SingleFlight<K, V> {
  final Map<K, Future<V>> _flights = {};

  /// Whether a flight for [key] is in the air.
  bool isRunning(K key) => _flights.containsKey(key);

  /// Runs `body` for [key], or joins the flight already running for it.
  ///
  /// `commit` runs with the result of the flight this call started, only
  /// when [key] was not [invalidate]d while it ran: the place to cache it.
  Future<V> run(
    K key,
    Future<V> Function() body, {
    void Function(V value)? commit,
  }) {
    final running = _flights[key];
    if (running != null) {
      return running;
    }
    late final Future<V> flight;
    flight = Future<V>.sync(body)
        .then((value) {
          if (identical(_flights[key], flight)) {
            commit?.call(value);
          }
          return value;
        })
        .whenComplete(() {
          if (identical(_flights[key], flight)) {
            _flights.remove(key);
          }
        });
    _flights[key] = flight;
    return flight;
  }

  /// Detaches any flight for [key]: its result is not committed and the next
  /// [run] starts afresh.
  void invalidate(K key) => _flights.remove(key);

  /// [invalidate] for every key.
  void invalidateAll() => _flights.clear();
}
