import 'dart:async';

import 'package:meta/meta.dart';

/// One in-flight "pilot" per identical child prompt prefix.
///
/// A provider's cache entry only becomes readable once the request that
/// writes it has begun responding, so N children launched in the same instant
/// each pay the full write premium for a prefix they all share. The first
/// child of a given shape becomes the pilot; its siblings wait for it to start
/// streaming and then read what it wrote. The wait is bounded by [maxWait] — a
/// slow pilot must cost a cache hit, never the fan-out itself.
class SubagentPilotGate {
  /// Creates a gate whose siblings wait at most [maxWait] for their pilot.
  SubagentPilotGate({this.maxWait = const Duration(seconds: 8)});

  /// The longest a sibling waits for its pilot to start streaming.
  final Duration maxWait;

  final Map<String, Completer<void>> _pilots = {};

  /// Enters the gate for [key], the child's prompt-prefix shape.
  ///
  /// The first caller for a key becomes its pilot and returns at once. A
  /// later caller waits until that pilot releases, [abandoned] completes or
  /// [maxWait] passes, whichever comes first, and never fails.
  ///
  /// Returns the release to call once this caller's request has started
  /// streaming, and again when it ends: idempotent, and a no-op for a sibling.
  /// The pilot is registered before this returns its future, so callers that
  /// enter in the same instant see it.
  Future<void Function()> enter(
    String key, {
    required Future<void> abandoned,
  }) async {
    final existing = _pilots[key];
    if (existing != null) {
      await Future.any([
        existing.future,
        abandoned,
      ]).timeout(maxWait).catchError((Object _) {});
      return _noRelease;
    }
    final owned = Completer<void>();
    _pilots[key] = owned;
    return () {
      if (!owned.isCompleted) {
        owned.complete();
      }
      if (identical(_pilots[key], owned)) {
        _pilots.remove(key);
      }
    };
  }

  /// Whether a pilot currently holds [key].
  @visibleForTesting
  bool isPiloting(String key) => _pilots.containsKey(key);

  static void _noRelease() {}
}
