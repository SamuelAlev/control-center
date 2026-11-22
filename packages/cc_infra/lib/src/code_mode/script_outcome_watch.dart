import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// [session]'s outcome, or, when its runner has not reported one by the
/// end of the script's wall clock (person waits excluded: [remaining] is
/// the script's own time left, [overrunMs] how far past it the script is)
/// plus [grace], a sandbox error after the runner is killed. While
/// [personWaiting], the deadline holds and the check waits. Nothing a
/// runner does can keep this waiting forever.
Future<CodeSandboxOutcome> watchOutcome(
  CodeSandboxSession session, {
  required Duration Function() remaining,
  required bool Function() personWaiting,
  required int Function() overrunMs,
  required Duration grace,
  required String executionId,
}) {
  final result = Completer<CodeSandboxOutcome>();
  Timer? timer;
  void settle(CodeSandboxOutcome outcome) {
    timer?.cancel();
    if (!result.isCompleted) {
      result.complete(outcome);
    }
  }

  void check() {
    if (result.isCompleted) {
      return;
    }
    final left =
        remaining() + grace - Duration(milliseconds: math.max(0, overrunMs()));
    if (personWaiting() || left > Duration.zero) {
      // A person wait holds the deadline: check again when the script's
      // own time could have run out.
      timer = Timer(left > Duration.zero ? left : grace, check);
      return;
    }
    CcInfraLog.warning(
      'code mode: the runner of $executionId did not report an outcome '
      '${grace.inSeconds} s past its deadline; killing it.',
    );
    session.terminate();
    // terminate() completes the outcome; this is the last line if even
    // that does not happen.
    timer = Timer(grace, () {
      settle(
        CodeSandboxOutcome(
          status: CodeExecutionStatus.sandboxError,
          errorKind: CodeExecutionErrorKind.unresponsive,
          detail:
              'The script runner did not report how the script ended and '
              'was stopped.',
        ),
      );
    });
  }

  timer = Timer(remaining() + grace, check);
  unawaited(
    session.outcome.then(
      settle,
      onError: (Object e, StackTrace st) {
        CcInfraLog.error('code mode: a runner outcome failed', e, st);
        settle(
          CodeSandboxOutcome(
            status: CodeExecutionStatus.sandboxError,
            errorKind: CodeExecutionErrorKind.hostError,
            detail: 'The host could not read how the script ended.',
          ),
        );
      },
    ),
  );
  return result.future;
}
