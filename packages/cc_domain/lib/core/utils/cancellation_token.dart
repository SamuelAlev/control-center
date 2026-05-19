import 'dart:async';

/// Thrown by cancellation-aware operations when their [CancellationToken] is
/// cancelled while they wait.
class CancelledException implements Exception {
  /// Creates a [CancelledException] carrying an optional [reason].
  const CancelledException([this.reason]);

  /// The reason passed to `CancellationTokenSource.cancel`, if any.
  final Object? reason;

  @override
  String toString() =>
      reason == null ? 'CancelledException' : 'CancelledException: $reason';
}

/// A read-only view of a cancellation signal — the Dart analog of the web
/// `AbortSignal`.
///
/// Long-running or queued async work (a semaphore wait, a request budget, an
/// isolated subprocess) takes a token so a caller that stops waiting (parent
/// aborted, wall-clock elapsed) also stops occupying resources. A token is
/// produced by a [CancellationTokenSource]; consumers only ever see this view.
abstract interface class CancellationToken {
  /// Combines several tokens into one that is cancelled as soon as ANY of
  /// [tokens] is cancelled (the web `AbortSignal.any`). The combined token
  /// adopts the reason of whichever source cancels first; if any source is
  /// already cancelled it is born cancelled.
  factory CancellationToken.any(Iterable<CancellationToken> tokens) {
    final source = CancellationTokenSource();
    for (final token in tokens) {
      if (token.isCancelled) {
        source.cancel(token.reason);
        return source.token;
      }
    }
    for (final token in tokens) {
      // unawaited: each child propagates its cancellation into the combined
      // source; the first to fire wins (cancel is idempotent).
      token.whenCancelled.then((_) => source.cancel(token.reason));
    }
    return source.token;
  }

  /// A token that is never cancelled. Useful as a default.
  static const CancellationToken none = _NeverCancelledToken();

  /// Whether cancellation has been requested.
  bool get isCancelled;

  /// The reason supplied to `cancel`, or null.
  Object? get reason;

  /// Completes when cancellation is requested. Already complete if the token is
  /// already cancelled. Never completes with an error.
  Future<void> get whenCancelled;

  /// Throws [CancelledException] (carrying [reason]) when already cancelled;
  /// otherwise returns normally.
  void throwIfCancelled();
}

/// Owns a [CancellationToken] and the right to [cancel] it — the Dart analog of
/// the web `AbortController`.
class CancellationTokenSource {
  CancellationTokenSource();

  final _CancellationToken _token = _CancellationToken();

  /// The token controlled by this source.
  CancellationToken get token => _token;

  /// Whether [cancel] has already been called.
  bool get isCancelled => _token.isCancelled;

  /// Requests cancellation. Idempotent — a second call (or a call after the
  /// token is already cancelled) is a no-op and keeps the original [reason].
  void cancel([Object? reason]) => _token._cancel(reason);
}

class _CancellationToken implements CancellationToken {
  bool _cancelled = false;
  Object? _reason;
  Completer<void>? _completer;

  @override
  bool get isCancelled => _cancelled;

  @override
  Object? get reason => _reason;

  @override
  Future<void> get whenCancelled {
    if (_cancelled) {
      return Future<void>.value();
    }
    return (_completer ??= Completer<void>()).future;
  }

  @override
  void throwIfCancelled() {
    if (_cancelled) {
      throw CancelledException(_reason);
    }
  }

  void _cancel(Object? reason) {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    _reason = reason;
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}

class _NeverCancelledToken implements CancellationToken {
  const _NeverCancelledToken();

  @override
  bool get isCancelled => false;

  @override
  Object? get reason => null;

  @override
  Future<void> get whenCancelled => const _NeverFuture();

  @override
  void throwIfCancelled() {}
}

/// A future that never completes — backs [CancellationToken.none] so awaiting
/// its cancellation simply never fires (no allocation per access).
class _NeverFuture implements Future<void> {
  const _NeverFuture();

  @override
  Stream<void> asStream() => const Stream<void>.empty();

  @override
  Future<void> catchError(Function onError, {bool Function(Object error)? test}) =>
      this;

  @override
  Future<R> then<R>(FutureOr<R> Function(void value) onValue,
          {Function? onError}) =>
      Completer<R>().future;

  @override
  Future<void> timeout(Duration timeLimit, {FutureOr<void> Function()? onTimeout}) =>
      Future<void>.delayed(timeLimit).then((_) => onTimeout?.call());

  @override
  Future<void> whenComplete(FutureOr<void> Function() action) => this;
}
