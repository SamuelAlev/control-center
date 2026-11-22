import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';

/// What a script's result says when it hit a limit: each text names the
/// fixes, so the model's next script is not the same one again.
///
/// The host adds [forKind] to a script's detail when it ended at its wall
/// clock or CPU budget ([CodeExecutionErrorKind] `deadline`, `cpu`) or at
/// the interpreter's output cap (`output`), and rejects a tool call past the
/// call limit with [callLimit]. A fix names `store()` only where the
/// script may store (`stores`: not in a read-only run) and `keep()` only
/// where it may keep (`keeps`: a run with an output store that may write).
/// Pinned by `script_fix_hints_test.dart`.
// ignore: avoid_classes_with_only_static_members
abstract final class ScriptFixHints {
  /// After a script ran out of time.
  static String timeout({required bool stores}) =>
      'To finish in time: return partial results before the limit runs out '
      '(`limits().wallMsRemaining` and `cpuMsRemaining` say what is left), '
      '${stores ? '`store()` progress so the next script continues from it, ' : ''}'
      'pass a larger `timeout_ms`, or split the work into several scripts.';

  /// After a script produced more output than the interpreter holds.
  static String output({required bool keeps}) =>
      'Return counts, digests and the part you need, not whole payloads: '
      'filter in the script, '
      '${keeps ? '`keep(value, label)` a large intermediate for a later script, ' : ''}'
      'and check `limits().returnBudgetChars`, how much of what you return is '
      'read whole.';

  /// Why a tool call past the script's call [limit] was refused.
  static String callLimit(int limit, {required bool stores}) =>
      'This script has made $limit tool calls, its limit. Return what you '
      'have${stores ? ' and `store()` progress' : ''}, then continue in '
      'another script; or make fewer calls, one that lists or searches many '
      'items instead of one per item.';

  /// The fix for a script that ended with [errorKind], or null when the
  /// kind names no limit the script can work within.
  static String? forKind(
    String? errorKind, {
    required bool stores,
    required bool keeps,
  }) => switch (errorKind) {
    CodeExecutionErrorKind.deadline ||
    CodeExecutionErrorKind.cpu => timeout(stores: stores),
    CodeExecutionErrorKind.output => output(keeps: keeps),
    _ => null,
  };

  /// [detail] with the fix for [errorKind] after it, on its own line.
  static String? withFix(
    String? detail,
    String? errorKind, {
    required bool stores,
    required bool keeps,
  }) {
    final fix = forKind(errorKind, stores: stores, keeps: keeps);
    if (fix == null) {
      return detail;
    }
    return detail == null || detail.isEmpty ? fix : '$detail\n$fix';
  }
}
