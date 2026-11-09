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
  /// Creates a source with a fresh, un-cancelled token.
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

/// Cancellation-aware stream consumption.
extension CancellableStream<T> on Stream<T> {
  /// Forwards this stream, ending promptly when [token] is cancelled.
  ///
  /// A plain `await for` only notices cancellation when an EVENT arrives, so an
  /// idle or wedged stream (a provider that stopped sending) keeps its consumer
  /// waiting until the source happens to emit. Racing the token against the
  /// subscription lets the consumer go: nothing is read ahead, events are
  /// forwarded one at a time, and on cancellation the source subscription is
  /// cancelled too, which is what lets an observed provider finalize (a usage
  /// recorder emits when its stream terminates).
  Stream<T> untilCancelled(CancellationToken token) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    var finished = false;

    Future<void> release() async {
      if (finished) {
        return;
      }
      finished = true;
      await subscription?.cancel();
      subscription = null;
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          (event) {
            if (!finished) {
              controller.add(event);
            }
          },
          onError: (Object error, StackTrace stack) {
            if (finished) {
              return;
            }
            finished = true;
            controller.addError(error, stack);
            unawaited(controller.close());
          },
          onDone: () {
            if (finished) {
              return;
            }
            finished = true;
            unawaited(controller.close());
          },
        );
        // An already-cancelled token completes immediately, so a consumer
        // cancelled before it subscribed stops on the first microtask.
        unawaited(token.whenCancelled.then((_) => release()));
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        finished = true;
        await subscription?.cancel();
        subscription = null;
      },
    );
    return controller.stream;
  }
}

/// Awaits [future] unless [token] is cancelled first, in which case it returns
/// null without waiting for [future] (whose eventual error is swallowed so an
/// abandoned operation cannot surface as an unhandled async error).
///
/// The caller stops WAITING; whether the work itself stops depends on whether
/// it honours the token it was handed.
Future<T?> raceCancellation<T>(Future<T> future, CancellationToken token) {
  if (token.isCancelled) {
    unawaited(future.then<void>((_) {}, onError: (Object _) {}));
    return Future<T?>.value();
  }
  final done = Completer<T?>();
  future.then(
    (value) {
      if (!done.isCompleted) {
        done.complete(value);
      }
    },
    onError: (Object error, StackTrace stack) {
      if (!done.isCompleted) {
        done.completeError(error, stack);
      }
    },
  );
  unawaited(
    token.whenCancelled.then((_) {
      if (!done.isCompleted) {
        done.complete(null);
      }
    }),
  );
  return done.future;
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
  Future<void> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(void value) onValue, {
    Function? onError,
  }) => Completer<R>().future;

  @override
  Future<void> timeout(
    Duration timeLimit, {
    FutureOr<void> Function()? onTimeout,
  }) => Future<void>.delayed(timeLimit).then((_) => onTimeout?.call());

  @override
  Future<void> whenComplete(FutureOr<void> Function() action) => this;
}
