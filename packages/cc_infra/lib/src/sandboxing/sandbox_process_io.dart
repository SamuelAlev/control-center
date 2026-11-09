import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The child-process plumbing every `SandboxPort.exec` shares: line
/// forwarding that can be drained, the exec timeout, and the stop sequence.
///
/// One copy, because the copies drifted: the no-isolation adapter drained a
/// child's output before reporting its exit and the native one did not, so a
/// `claude -p` turn's final `result` line could arrive after the run had
/// already stopped parsing.

/// One child stream being forwarded line by line.
class ProcessLineForwarding {
  ProcessLineForwarding._(this._subscription, this.done);

  /// Starts forwarding [stream] to [onLine], one decoded line at a time.
  ///
  /// `allowMalformed: true` is load-bearing: the throwing decoder turns one bad
  /// byte from a chatty CLI into a zone-level error that ends the forwarding
  /// while `exec` keeps awaiting the exit code, and the run then completes
  /// with no output and no error.
  factory ProcessLineForwarding.start(
    Stream<List<int>> stream,
    void Function(String line) onLine,
  ) {
    final done = Completer<void>();
    void finish([Object? _, Object? _]) {
      if (!done.isCompleted) {
        done.complete();
      }
    }

    // Cancelled by [cancel] — [drainForwardings] always calls it.
    // ignore: cancel_subscriptions
    final subscription = stream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(onLine, onDone: finish, onError: finish, cancelOnError: true);
    return ProcessLineForwarding._(subscription, done.future);
  }

  final StreamSubscription<String> _subscription;

  /// Completes once every line the stream carried has been forwarded.
  final Future<void> done;

  /// Stops forwarding without waiting for the stream to end.
  Future<void> cancel() => _subscription.cancel();
}

/// How long [drainForwardings] waits for output after the child exited.
///
/// Bounded because a pipe outlives its writer when a grandchild inherited it
/// (a backgrounded `sleep 600 &` keeps stdout open): waiting for end-of-file
/// there would park the exec until the grandchild dies.
const Duration processOutputDrainGrace = Duration(seconds: 5);

/// Waits until every forwarding in [forwardings] has delivered its last line,
/// or [grace] has passed, then cancels whatever is still open.
Future<void> drainForwardings(
  List<ProcessLineForwarding> forwardings, {
  Duration grace = processOutputDrainGrace,
}) async {
  try {
    await Future.wait([for (final f in forwardings) f.done]).timeout(grace);
  } on TimeoutException {
    // A descendant still holds the pipe; what it writes now is not this
    // exec's output.
  }
  for (final f in forwardings) {
    await f.cancel();
  }
}

/// Awaits [process] with an optional [timeout], killing it (SIGTERM → 2s →
/// SIGKILL) and reporting exit code 124 — the `timeout(1)` convention — when
/// the deadline passes.
///
/// The `SandboxPort.exec` contract has always declared a `timeout`; no adapter
/// honoured it, so a chatty (non-silent) agent had NO hard runtime bound at
/// all — only the dispatch layer's silence heuristic, which a process that
/// prints anything at all never trips.
Future<int> awaitExitWithTimeout(
  Process process,
  Duration? timeout,
  void Function(String message)? onTimeoutMessage,
) async {
  if (timeout == null) {
    return process.exitCode;
  }
  try {
    return await process.exitCode.timeout(timeout);
  } on TimeoutException {
    onTimeoutMessage?.call(
      '[sandbox] command exceeded ${timeout.inSeconds}s — terminating',
    );
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      await process.exitCode;
    }
    return 124;
  }
}

/// SIGTERM → 3s → SIGKILL → 2s, awaited: a child that traps SIGTERM otherwise
/// outlives the "destroyed" sandbox, holding its worktree and its egress.
Future<void> terminateProcess(Process process) async {
  process.kill();
  try {
    await process.exitCode.timeout(const Duration(seconds: 3));
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // Unreapable; nothing further this layer can do.
    }
  }
}
