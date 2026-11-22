/// What a person is told when a goal check could not run as written (exit
/// 126 or 127, a spawn failure, an environment task that does not exist): a
/// broken check is the contract's fault, not the work's, so the worker is
/// never sent the failed-verification notice for it and only a person, who
/// edits the contract, can fix it. Pinned by
/// `goal_check_broken_notice_test.dart`.
library;

import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_harness/context.dart' show wakeDataOutsideLine;

/// What the person is asked to do, after the sentence that names the check.
const String goalCheckBrokenAction = 'Fix the check, then resume the goal.';

/// One broken check: the server's sentence for the person and the check's
/// output tail (untrusted; empty when it printed nothing).
class GoalCheckBrokenNotice {
  /// Creates a notice.
  const GoalCheckBrokenNotice({
    required this.sentence,
    required this.outputTail,
  });

  /// `The check `cmd` could not run (exit 127: command not found). Fix the
  /// check, then resume the goal.`
  final String sentence;

  /// The last characters of what the check printed, as it printed them.
  final String outputTail;

  @override
  bool operator ==(Object other) =>
      other is GoalCheckBrokenNotice &&
      sentence == other.sentence &&
      outputTail == other.outputTail;

  @override
  int get hashCode => Object.hash(sentence, outputTail);
}

/// The notice for [check], a broken one. Throws [ArgumentError] when it is
/// not broken.
GoalCheckBrokenNotice goalCheckBrokenNotice(GoalCheckResult check) {
  if (!check.broken) {
    throw ArgumentError.value(check, 'check', 'is not broken');
  }
  final run = goalInlineCode(wakeDataOutsideLine(check.run));
  final subject = check.where == GoalCheckLocation.environment
      ? 'The environment task $run'
      : 'The check $run';
  return GoalCheckBrokenNotice(
    sentence: '$subject could not run (${_why(check)}). $goalCheckBrokenAction',
    outputTail: check.outputTail,
  );
}

/// [goalCheckBrokenNotice] for every broken check of [checks], in order.
List<GoalCheckBrokenNotice> goalCheckBrokenNotices(
  Iterable<GoalCheckResult> checks,
) => [
  for (final check in checks)
    if (check.broken) goalCheckBrokenNotice(check),
];

String _why(GoalCheckResult check) {
  if (check.where == GoalCheckLocation.environment) {
    return 'the environment has no such task, or it cannot run';
  }
  return switch (check.exitCode) {
    127 => 'exit 127: command not found',
    126 => 'exit 126: not executable',
    final int code => 'exit $code',
    null => 'it could not be started',
  };
}
