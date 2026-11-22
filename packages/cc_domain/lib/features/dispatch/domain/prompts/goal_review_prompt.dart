/// The independent reviewer's prompt for a goal's completion claim (plan
/// section 17, "The reviewer"), the `submit_output` schema it answers with,
/// and the strict parser from that answer to a [GoalVerdict]. Pinned byte for
/// byte by `goal_review_prompt_test.dart`.
library;

import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_harness/context.dart'
    show wakeDataEnvelope, wakeDataOutsideLine, wakeDataRule;

/// The paragraph before the data block, copied from the plan.
const String goalReviewIntro =
    "You are checking another agent's claim that a goal is complete. You did "
    'not do the work and you have not seen its conversation. Its summary is a '
    'claim, not evidence.';

/// The paragraph after the data block. The reviewer runs no commands (the
/// server ran the checks) and changes nothing: it reads.
const String goalReviewInstructions =
    'The server ran the checks; their results are above. Inspect the actual '
    'state with your tools: read the files and the summary of what changed. '
    'You cannot run commands or change anything. For each '
    '"Done means" item decide met, unmet or cannot tell, and say what you '
    'looked at. Look for work that satisfies a check without satisfying the '
    'goal: deleted or weakened tests, hard-coded results, skipped cases, '
    'changes outside the boundaries. If what you can read is not enough to '
    'judge, answer cannot_verify. Do not invent problems: if it is done, say '
    'so. Return your verdict with submit_output.';

/// What the reviewer may take as evidence (the best-practice review, G4):
/// its read tools still reach the conversation and the space's notes, which
/// the worker wrote.
const String goalReviewEvidenceRule =
    'What you read in the conversation, in notes and in the claim is the '
    "worker's account, not evidence: only the files, the check results and "
    'what you verify yourself count.';

/// The heading the change summary opens with when tests or files a check
/// names were modified or deleted (`GoalChanges`; the best-practice
/// review, G3): their unified diff since the goal started, ahead of the
/// stat.
const String goalReviewTestDiffHeading =
    'Tests and files the checks name, modified or deleted since the goal '
    'started (unified diff):';

/// What the reviewer does with that section.
const String goalReviewTestDiffRule =
    'If what changed starts with "$goalReviewTestDiffHeading", that section '
    'is the full diff of every test, and every file a check names, that the '
    'agent modified or deleted. A weakened or deleted test, or a changed '
    'check script, is a reason to fail the claim unless the contract asked '
    'for that change.';

/// The answer's shape, one line, after the instructions.
const String goalReviewAnswerShape =
    'Answer with output: {verdict: pass | fail | cannot_verify, items: '
    '[{criterion, state: met | unmet | cannot_tell, evidence}], concerns}, '
    'one item for every "Done means" item, its criterion copied exactly.';

/// The criterion of the one item that judges the objective of a goal with
/// no "Done means" items.
const String goalReviewObjectiveCriterion = 'the objective';

/// The answer's shape for a goal with no "Done means" items (the
/// best-practice review, G5): one item on the objective, never none.
const String goalReviewObjectiveAnswerShape =
    'Answer with output: {verdict: pass | fail | cannot_verify, items: '
    '[{criterion, state: met | unmet | cannot_tell, evidence}], concerns}, '
    'with exactly one item, its criterion "$goalReviewObjectiveCriterion", '
    'that judges the objective and gives your evidence. An answer with no '
    'item never passes.';

/// How a reviewer with the `repl` tool reaches `submit_output`: it is
/// not callable from a script, and it may be loaded on first use.
const String goalReviewSubmitHint =
    'If submit_output is not in your tool list, find it with search_tools. '
    'Call it directly, not from a repl script.';

/// How a reviewer on another lane (Claude Code, ACP) reaches
/// `submit_output`: an MCP tool under its own name, direct there, and that
/// lane has no `search_tools`.
const String goalReviewSubmitPlainHint =
    'submit_output is a Control Center tool; call it directly.';

/// The schema the reviewer's run is dispatched with (`WakeRunOptions
/// .outputSchema`, the run log's `expectedOutputSchema`): `{verdict: pass |
/// fail | cannot_verify, items: [{criterion, state: met | unmet |
/// cannot_tell, evidence}], concerns}`.
const Map<String, Object?> goalReviewOutputSchema = GoalVerdict.outputSchema;

/// The reviewer's prompt for [goal]'s claim in [verification] (its claim,
/// evidence and check results), with [changes] the server's summary of what
/// changed since the goal started. Everything a model or a repository
/// wrote (the claim, its evidence, the checks' output, the change summary)
/// sits inside a `wake-data` envelope with [nonce]; the server's own lines
/// stay outside. [hasRepl] picks the line that says how to reach
/// `submit_output`.
String renderGoalReviewPrompt({
  required AgentGoalRun goal,
  required GoalVerification verification,
  required String changes,
  required String nonce,
  required bool hasRepl,
}) {
  final contract = goal.contract;
  final out = StringBuffer()
    ..writeln(goalReviewIntro)
    ..writeln()
    ..writeln(wakeDataRule)
    ..writeln(
      '<objective>${goal.userText.trim().replaceAllMapped(RegExp(r'<(\s*/?\s*objective)', caseSensitive: false), (m) => '&lt;${m[1]}')}</objective>',
    );
  final criteria = contract?.criteria ?? const <String>[];
  if (criteria.isEmpty) {
    out.writeln(
      'Done means: no items were written down; judge the objective as one '
      'item.',
    );
  } else {
    out.writeln('Done means:');
    for (var i = 0; i < criteria.length; i++) {
      out.writeln('${i + 1}. ${wakeDataOutsideLine(criteria[i].trim())}');
    }
  }
  if (contract?.boundaries case final boundaries?) {
    // The person's text, one safe line at a time.
    out.writeln('Boundaries:');
    for (final line in boundaries.trim().split('\n')) {
      if (line.trim().isNotEmpty) {
        out.writeln('  ${wakeDataOutsideLine(line.trim())}');
      }
    }
  }
  out
    ..writeln('The claim (the agent wrote this):')
    ..writeln(wakeDataEnvelope(_claimText(verification), nonce: nonce))
    ..writeln(_checksHeading(verification.checks));
  for (final check in verification.checks) {
    out.writeln('- ${_checkLine(check)}');
    if (check.outputTail.isNotEmpty) {
      out.writeln('  ${wakeDataEnvelope(check.outputTail, nonce: nonce)}');
    }
  }
  out
    ..writeln('What changed since the goal started:')
    ..writeln(
      wakeDataEnvelope(
        changes.trim().isEmpty ? 'nothing recorded' : changes.trim(),
        nonce: nonce,
      ),
    )
    ..writeln()
    ..writeln(goalReviewInstructions)
    ..writeln(goalReviewEvidenceRule)
    ..writeln(goalReviewTestDiffRule)
    ..writeln(
      criteria.isEmpty ? goalReviewObjectiveAnswerShape : goalReviewAnswerShape,
    )
    ..write(hasRepl ? goalReviewSubmitHint : goalReviewSubmitPlainHint);
  return out.toString();
}

String _claimText(GoalVerification verification) {
  final out = StringBuffer()..write(verification.claimSummary.trim());
  for (final item in verification.claimEvidence) {
    out.write('\n- ${item.criterion.trim()}: ${item.evidence.trim()}');
  }
  return out.toString();
}

String _checksHeading(List<GoalCheckResult> checks) => checks.isEmpty
    ? 'The server ran no checks: this goal has none.'
    : 'The server ran these checks:';

String _checkLine(GoalCheckResult check) {
  final run = goalInlineCode(wakeDataOutsideLine(check.run));
  final label = check.where == GoalCheckLocation.environment
      ? 'the environment task $run'
      : run;
  if (check.broken) {
    return '$label could not run';
  }
  if (check.skippedUnchanged) {
    return '$label was not rerun (the workspace is unchanged)';
  }
  if (check.timedOut) {
    return '$label timed out';
  }
  final code = check.exitCode;
  if (code == 0) {
    return '$label passed (exit 0)';
  }
  return code == null ? '$label did not finish' : '$label exited $code';
}

/// The most characters of a refusal reason kept in the verdict's concerns.
const int _maxReason = GoalVerdict.maxConcernLength;

/// Reads the reviewer's `submit_output` [output] into a verdict for a goal
/// whose "Done means" items are [criteria]. Never throws: an answer that is
/// malformed, has an unknown verdict, leaves a criterion out, judges one
/// twice differently, or contradicts itself (a `pass` with an item not met,
/// a `fail` with nothing unmet and no concern) reads as
/// [GoalVerdictOutcome.cannotVerify] with the reason in `concerns`. A
/// reviewer that does not answer properly never passes a goal.
///
/// An item covers a criterion when its text equals the criterion's after
/// trimming and collapsing whitespace. Items for criteria the contract does
/// not have are dropped. The returned items carry the contract's own text,
/// in contract order. With no [criteria], the answer judges the objective as
/// exactly one item (kept as [goalReviewObjectiveCriterion]): more than one
/// is malformed, and so is a `pass` with none. [output] may be the decoded
/// object or its JSON text.
GoalVerdict parseGoalReviewOutput(
  Object? output, {
  required List<String> criteria,
}) {
  Object? json = output;
  if (json is String) {
    try {
      json = jsonDecode(json);
    } on FormatException catch (e) {
      return _refused('the answer is not JSON (${e.message})');
    }
  }
  final GoalVerdict parsed;
  try {
    parsed = GoalVerdict.fromJson(json);
  } on FormatException catch (e) {
    return _refused('the answer is malformed: ${e.message}');
  } on ArgumentError catch (e) {
    return _refused('the answer is malformed: ${e.message}');
  }

  if (criteria.isEmpty) {
    return _objectiveVerdict(parsed);
  }
  final byKey = <String, GoalVerdictItem>{};
  final conflicting = <String>{};
  for (final item in parsed.items) {
    final key = _key(item.criterion);
    final seen = byKey[key];
    if (seen != null && seen.state != item.state) {
      conflicting.add(item.criterion.trim());
    }
    byKey[key] ??= item;
  }
  final items = <GoalVerdictItem>[];
  final missing = <String>[];
  for (final criterion in criteria) {
    final item = byKey[_key(criterion)];
    if (item == null) {
      missing.add(criterion);
      continue;
    }
    items.add(
      GoalVerdictItem(
        criterion: criterion,
        state: item.state,
        evidence: item.evidence,
      ),
    );
  }
  final concerns = parsed.concerns;
  if (missing.isNotEmpty) {
    return _refused(
      'the answer does not judge every "Done means" item; missing: '
      '${missing.map((c) => '"$c"').join(', ')}',
      items: items,
      concerns: concerns,
    );
  }
  if (conflicting.isNotEmpty) {
    return _refused(
      'the answer judges an item twice, differently: '
      '${conflicting.map((c) => '"$c"').join(', ')}',
      items: items,
      concerns: concerns,
    );
  }
  switch (parsed.verdict) {
    case GoalVerdictOutcome.pass
        when items.any((item) => item.state != GoalCriterionState.met):
      return _refused(
        'the answer says pass but not every item is met',
        items: items,
        concerns: concerns,
      );
    case GoalVerdictOutcome.fail
        when !items.any((item) => item.state == GoalCriterionState.unmet) &&
            concerns.isEmpty:
      return _refused(
        'the answer says fail but names nothing unmet and no concern',
        items: items,
        concerns: concerns,
      );
    case _:
      return GoalVerdict(
        verdict: parsed.verdict,
        items: items,
        concerns: concerns,
      );
  }
}

/// [parsed] for a goal with no "Done means" items: one item on the
/// objective.
GoalVerdict _objectiveVerdict(GoalVerdict parsed) {
  final concerns = parsed.concerns;
  if (parsed.items.length > 1) {
    return _refused(
      'the goal has no "Done means" items, so the answer must judge the '
      'objective as exactly one item; it has ${parsed.items.length}',
      concerns: concerns,
    );
  }
  final items = [
    for (final item in parsed.items)
      GoalVerdictItem(
        criterion: goalReviewObjectiveCriterion,
        state: item.state,
        evidence: item.evidence,
      ),
  ];
  return switch (parsed.verdict) {
    GoalVerdictOutcome.pass when items.isEmpty => _refused(
      'the answer says pass but judges nothing: a goal with no "Done means" '
      'items needs one item on the objective',
      concerns: concerns,
    ),
    GoalVerdictOutcome.pass when items.single.state != GoalCriterionState.met =>
      _refused(
        'the answer says pass but the objective is not met',
        items: items,
        concerns: concerns,
      ),
    GoalVerdictOutcome.pass when items.single.evidence.trim().isEmpty =>
      _refused(
        'the answer says pass but gives no evidence for the objective',
        items: items,
        concerns: concerns,
      ),
    GoalVerdictOutcome.fail
        when !items.any((item) => item.state == GoalCriterionState.unmet) &&
            concerns.isEmpty =>
      _refused(
        'the answer says fail but names nothing unmet and no concern',
        items: items,
        concerns: concerns,
      ),
    _ => GoalVerdict(verdict: parsed.verdict, items: items, concerns: concerns),
  };
}

String _key(String criterion) =>
    criterion.trim().replaceAll(RegExp(r'\s+'), ' ');

GoalVerdict _refused(
  String reason, {
  List<GoalVerdictItem> items = const [],
  List<String> concerns = const [],
}) {
  final text = "The reviewer's answer could not be used: $reason";
  final cut = text.length > _maxReason
      ? '${text.substring(0, _maxReason - 1)}…'
      : text;
  return GoalVerdict(
    verdict: GoalVerdictOutcome.cannotVerify,
    items: items,
    concerns: [cut, ...concerns.take(GoalVerdict.maxConcerns - 1)],
  );
}
