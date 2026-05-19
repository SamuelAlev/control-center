import 'dart:async';

import 'package:cc_domain/core/utils/cancellation_token.dart';

/// The outcome of [mapWithConcurrencyLimit].
///
/// [results] is parallel to the input list: each entry holds the value produced
/// for that item, or `null` for an item that was skipped because execution was
/// [aborted] before a worker reached it.
class ParallelResult<R> {
  /// Creates a [ParallelResult] from ordered [results] and an [aborted] flag.
  const ParallelResult({required this.results, required this.aborted});

  /// Results in input order. A `null` entry marks an item skipped on abort
  /// (note that `R` may itself be nullable, so `null` is not by itself proof of
  /// a skip — read [aborted] alongside it).
  final List<R?> results;

  /// Whether the external [CancellationToken] cancelled before every item was
  /// processed, leaving [results] partial.
  final bool aborted;
}

/// Runs [fn] over [items] with at most [concurrency] in-flight calls, using a
/// worker-pool. Results are returned in input order.
///
/// A `concurrency <= 0` or non-finite value is treated as `items.length`; the
/// effective limit is then clamped to `[1, items.length]`.
///
/// Failure handling:
/// - On a non-cancellation error from any [fn], execution **fails fast**: the
///   internal signal is cancelled so in-flight siblings can stop, and the
///   error is rethrown to the caller.
/// - On external cancellation (via [signal]), the call returns the partial
///   [ParallelResult] with `aborted: true`; entries for items not yet reached
///   stay `null`.
///
/// Each invocation of [fn] receives a combined signal (external ∪ internal),
/// so a sibling failure or external cancellation both surface through it.
Future<ParallelResult<R>> mapWithConcurrencyLimit<T, R>(
  List<T> items,
  int concurrency,
  Future<R> Function(T item, int index, CancellationToken signal) fn, {
  CancellationToken? signal,
}) async {
  final external = signal ?? CancellationToken.none;
  final results = List<R?>.filled(items.length, null);

  if (items.isEmpty) {
    return ParallelResult<R>(results: results, aborted: external.isCancelled);
  }

  final effective = concurrency > 0 ? concurrency : items.length;
  final limit = effective < 1
      ? 1
      : (effective > items.length ? items.length : effective);

  // Internal source fans a fail-fast or external abort out to all workers.
  final internal = CancellationTokenSource();
  final workerSignal = CancellationToken.any(<CancellationToken>[
    external,
    internal.token,
  ]);

  var nextIndex = 0;
  Object? firstError;
  StackTrace? firstStackTrace;

  Future<void> worker() async {
    while (true) {
      if (workerSignal.isCancelled) {
        return;
      }
      final index = nextIndex++;
      if (index >= items.length) {
        return;
      }
      try {
        results[index] = await fn(items[index], index, workerSignal);
      } catch (error, stackTrace) {
        // When the external signal aborted, treat this as a clean stop rather
        // than a failure: fn is expected to have handled its own cancellation.
        if (external.isCancelled) {
          return;
        }
        // Fail fast: cancel siblings and remember the first error to rethrow.
        if (firstError == null) {
          firstError = error;
          firstStackTrace = stackTrace;
        }
        internal.cancel(error);
        return;
      }
    }
  }

  await Future.wait(<Future<void>>[
    for (var i = 0; i < limit; i++) worker(),
  ]);

  if (firstError != null && !external.isCancelled) {
    Error.throwWithStackTrace(
      firstError!,
      firstStackTrace ?? StackTrace.current,
    );
  }

  return ParallelResult<R>(results: results, aborted: external.isCancelled);
}
