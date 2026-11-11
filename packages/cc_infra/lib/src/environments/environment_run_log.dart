import 'dart:async';

import 'package:cc_domain/features/environments/domain/repositories/environment_repositories.dart';
import 'package:cc_infra/src/environments/environment_command_runner.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The output of one lifecycle run, written to its record while it grows.
///
/// A start can take a quarter of an hour, and a record that fills in only at
/// the end shows nothing for all of it. Lines land here as they are printed
/// and reach the record at most once per [flushInterval]; the run's last
/// write is the caller's (`EnvironmentRunRepository.finish`, with [text]).
class EnvironmentRunLog {
  /// Creates the log of run [id].
  EnvironmentRunLog({
    required this.id,
    required this.workspaceId,
    required this._runs,
    this.flushInterval = const Duration(milliseconds: 500),
    int maxChars = 64 * 1024,
    this._onFlushed,
  }) : _tail = EnvironmentOutputTail(maxChars: maxChars);

  /// The run.
  final String id;

  /// Its workspace.
  final String workspaceId;

  /// Minimum gap between writes.
  final Duration flushInterval;

  final EnvironmentRunRepository _runs;
  final void Function()? _onFlushed;
  final EnvironmentOutputTail _tail;
  Timer? _pending;
  bool _closed = false;

  /// Everything kept so far.
  String get text => _tail.toString();

  /// Adds one line.
  void line(String line) {
    _tail.addLine(line);
    _schedule();
  }

  /// Adds [lines], in order.
  void lines(Iterable<String> lines) => lines.forEach(line);

  /// Adds what a command said: its output as it is, its progress as a line a
  /// person can read.
  void event(EnvironmentCommandEvent event) => switch (event) {
    EnvironmentCommandOutput(:final line) => this.line(line),
    EnvironmentCommandProgress(:final progress) => line(progress.logLine),
    EnvironmentCommandExit() => null,
  };

  /// Stops writing. The caller finishes the record with [text].
  void close() {
    _closed = true;
    _pending?.cancel();
    _pending = null;
  }

  void _schedule() {
    if (_closed || _pending != null) {
      return;
    }
    _pending = Timer(flushInterval, () {
      _pending = null;
      unawaited(
        _runs
            .updateOutput(workspaceId, id, text)
            .then((_) {
              if (!_closed) {
                _onFlushed?.call();
              }
            })
            .catchError((Object e) {
              CcInfraLog.warning(
                'environment run output write failed for $id: $e',
              );
            }),
      );
    });
  }
}
