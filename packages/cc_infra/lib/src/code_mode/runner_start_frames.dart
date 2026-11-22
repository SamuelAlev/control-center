import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/code_mode/runner_frames.dart';
import 'package:cc_infra/src/code_mode/runner_json.dart';

/// The `init` and `exec` frames of one script, encoded before its runner is
/// spawned, with the sizes of the stored values `init` carries.
final class RunnerStartFrames {
  RunnerStartFrames._(this.init, this.exec, this.storeSizes, this.storeTotal);

  /// Encodes the frames of [request].
  ///
  /// Throws [CodeSandboxStartException] when they do not fit in one runner
  /// frame ([CodeModeLimits.maxFrameBytes]), so no runner is spawned for
  /// them. An `init` frame over the cap is the run's tool catalog's doing
  /// (kind [CodeExecutionErrorKind.catalog]): the stored values it also
  /// carries are bounded at [CodeModeLimits.maxStoreTotalBytes], far below
  /// the cap, and no script of the run could be given that catalog.
  static RunnerStartFrames encode(CodeSandboxStart request) {
    final storeSizes = <String, int>{};
    var storeTotal = 0;
    final store = <String, Object?>{};
    // Sent whether or not the script may write: a read-only run's scripts
    // still load() what earlier runs stored ([CodeSandboxStart.store]).
    request.store.forEach((key, json) {
      try {
        final value = jsonDecode(json);
        if (jsonDepth(value) < kRunnerMaxJsonDepth) {
          store[key] = value;
          // What is sent, not the saved text: the runner charges the
          // compact JSON, so spacing in the saved text must not count.
          final size = storedValueBytes(value);
          storeSizes[key] = size;
          storeTotal += size;
        }
      } on FormatException {
        // A stored value that is not JSON cannot be loaded; the database's
        // CHECK makes this unreachable, and leaving the key out is safer
        // than sending the runner a frame it would reject.
      }
    });
    final init = tryJsonEncode({
      'type': 'init',
      'limits': CodeSandboxProcess.runnerLimits(
        request.limits,
        returnBudgetChars: request.returnBudgetChars,
        storeWritable: request.storeWritable,
      ),
      'catalog': request.catalog,
      'store': store,
    });
    final exec = jsonEncode({'type': 'exec', 'code': request.code});
    if (init == null || utf8Length(exec) > CodeModeLimits.maxFrameBytes) {
      throw const CodeSandboxStartException(
        'The script, its tool catalog and its stored values do not fit in '
        'one runner frame.',
        errorKind: 'protocol',
      );
    }
    final initBytes = utf8Length(init);
    if (initBytes > CodeModeLimits.maxFrameBytes) {
      const mib = 1024 * 1024;
      throw CodeSandboxStartException(
        "The run's tool catalog is too large for a script: with its stored "
        'values it takes ${(initBytes / mib).toStringAsFixed(1)} MiB, and a '
        'script is given at most ${CodeModeLimits.maxFrameBytes ~/ mib} MiB. '
        'No script of this run can start; call its tools directly.',
        errorKind: CodeExecutionErrorKind.catalog,
      );
    }
    return RunnerStartFrames._(init, exec, storeSizes, storeTotal);
  }

  /// The `init` frame: limits, catalog and stored values.
  final String init;

  /// The `exec` frame: the script.
  final String exec;

  /// The size of each stored value sent, by key.
  final Map<String, int> storeSizes;

  /// The sum of [storeSizes].
  final int storeTotal;
}
