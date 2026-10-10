import 'dart:async';
import 'dart:io';

/// Settles [process]'s stdin for a sandbox `exec`.
///
/// With [stream], each chunk is written as it arrives and stdin closes when the
/// stream completes — the lane a CLI that takes input mid-run reads. Otherwise
/// [input] (when non-null) is written and stdin closes immediately, so a CLI
/// that reads it gets EOF instead of blocking forever.
///
/// A child that exits first turns the remaining writes into broken-pipe
/// errors. Those are dropped: the exit code is what reports the run, and an
/// unhandled `IOSink` error would take down the host instead.
void settleStdin(Process process, {String? input, Stream<String>? stream}) {
  final stdin = process.stdin;
  unawaited(stdin.done.catchError((Object _) {}));
  if (stream == null) {
    if (input != null) {
      stdin.write(input);
    }
    unawaited(stdin.close().catchError((Object _) {}));
    return;
  }
  unawaited(() async {
    try {
      await for (final chunk in stream) {
        stdin.write(chunk);
        await stdin.flush();
      }
    } on Object catch (_) {
      // Broken pipe: the child is gone.
    }
    try {
      await stdin.close();
    } on Object catch (_) {}
  }());
}
