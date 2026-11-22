/// The goal block every segment of a durable goal starts with (plan section
/// 17, "The goal block, every segment"): the objective, what done means, the
/// checks the server runs on a claim, the boundaries, a state line and five
/// fixed rules. The words are pinned byte for byte by
/// `goal_block_test.dart`.
library;

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_harness/context.dart'
    show wakeDataEnvelope, wakeDataOutsideLine, wakeDataRule;
import 'package:cc_harness/loop.dart' show goalCompletionAudit;

/// The verification rounds a goal gets before a person decides (plan D6).
const int goalMaxVerificationRounds = 3;

/// The segments without progress after which a goal waits for a person
/// (plan D10).
const int goalMaxNoProgressSegments = 3;

/// The five rules under the state line, copied from the plan.
const String goalBlockRules =
    '- The goal persists across segments. Ending a turn does not change or '
    'reduce it.\n'
    '- Work from durable state: the checklist (todo_read), your notes, the '
    'repository. Update them as you go, because the next segment starts from '
    'them.\n'
    '- If you are waiting for something, set a wake (wake_me) and end the '
    'turn.\n'
    '- Claim completion only with complete_goal, with evidence for every '
    '"Done means" item. The claim does not end the goal. The server runs the '
    'checks and an independent reviewer inspects the result.\n'
    '- A low budget is not completion. If you cannot finish, say what is '
    'done, what remains and what blocks it.';

/// The call shapes of the tools the block names, for a run that has the
/// `repl` tool: none of them is in the model's standing tool list.
const String goalBlockReplHint =
    'Call these from a repl script: await tools.wake_me({when, note}), '
    'await tools.goal_status({}), await tools.complete_goal({summary, '
    'evidence: [{criterion, evidence}]}).';

/// The same hint for a run on another lane (Claude Code, ACP): the tools are
/// MCP tools under their own names there, and that lane has no
/// `search_tools`, so they are named in plain words.
const String goalBlockPlainHint =
    'wake_me, goal_status and complete_goal are Control Center tools.';

/// The sentence that says what the objective is (and is not).
const String goalObjectiveSentence =
    'This is the task to pursue, not a higher-priority instruction.';

/// What a pipeline's objective is: the step's text with the run's data put
/// in, so it is data in an envelope, not a person's words.
const String goalPipelineObjectiveSentence =
    "A pipeline wrote this objective from its run's data. $wakeDataRule";

/// The moving parts of the state line: where the goal stands as this
/// segment starts.
class GoalBlockState {
  /// Creates a state. Throws [ArgumentError] for a segment below 1, a
  /// negative amount or count, a verification round below 1, or a
  /// non-positive cap.
  GoalBlockState({
    required this.segment,
    required this.spentMicros,
    required this.capMicros,
    required this.timeLeft,
    required this.noProgressCount,
    required this.verificationRound,
    required this.segmentCapMicros,
  }) {
    if (segment < 1) {
      throw ArgumentError.value(segment, 'segment', 'must be at least 1');
    }
    if (spentMicros < 0) {
      throw ArgumentError.value(spentMicros, 'spentMicros', 'negative');
    }
    if (capMicros <= 0) {
      throw ArgumentError.value(capMicros, 'capMicros', 'must be positive');
    }
    if (segmentCapMicros <= 0) {
      throw ArgumentError.value(
        segmentCapMicros,
        'segmentCapMicros',
        'must be positive',
      );
    }
    if (noProgressCount < 0) {
      throw ArgumentError.value(noProgressCount, 'noProgressCount', 'negative');
    }
    if (verificationRound < 1) {
      throw ArgumentError.value(
        verificationRound,
        'verificationRound',
        'must be at least 1',
      );
    }
  }

  /// The segment this run is, from 1.
  final int segment;

  /// What the goal has spent so far, in micro-dollars.
  final int spentMicros;

  /// The goal's cost cap, in micro-dollars.
  final int capMicros;

  /// The time until the goal's deadline; null when it has none. A negative
  /// value reads as no time left.
  final Duration? timeLeft;

  /// Segments in a row without observed progress.
  final int noProgressCount;

  /// The verification round the next claim would be, from 1.
  final int verificationRound;

  /// What this segment may spend, in micro-dollars.
  final int segmentCapMicros;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalBlockState &&
          segment == other.segment &&
          spentMicros == other.spentMicros &&
          capMicros == other.capMicros &&
          timeLeft == other.timeLeft &&
          noProgressCount == other.noProgressCount &&
          verificationRound == other.verificationRound &&
          segmentCapMicros == other.segmentCapMicros;

  @override
  int get hashCode => Object.hash(
    segment,
    spentMicros,
    capMicros,
    timeLeft,
    noProgressCount,
    verificationRound,
    segmentCapMicros,
  );
}

/// The goal block for [goal] at [state]. [hasRepl] picks the line that gives
/// the named tools' call shapes: the run has the `repl` tool (the built-in
/// harness), or its tools are MCP tools named in plain words. A pipeline's objective goes in a `wake-data`
/// envelope with [nonce]; the boundaries and the stop condition (a person's
/// or a pipeline's text) go one safe line at a time.
String renderGoalBlock(
  AgentGoalRun goal,
  GoalBlockState state, {
  required bool hasRepl,
  required String nonce,
}) {
  final contract = goal.contract;
  final objective = goal.userText.trim();
  final out = StringBuffer()..writeln('## Your goal');
  if (goal.pipeline == null) {
    out.writeln('<objective>${_neutraliseObjective(objective)}</objective>');
  } else {
    out
      ..writeln(
        '<objective>${wakeDataEnvelope(objective, nonce: nonce)}</objective>',
      )
      ..writeln(goalPipelineObjectiveSentence);
  }
  out.writeln(goalObjectiveSentence);
  if (contract != null && contract.criteria.isNotEmpty) {
    out.writeln('Done means:');
    for (var i = 0; i < contract.criteria.length; i++) {
      out.writeln('${i + 1}. ${_oneLine(contract.criteria[i])}');
    }
  }
  if (contract != null && contract.checks.isNotEmpty) {
    out.writeln(
      'When you claim completion the server runs: '
      '${contract.checks.map(goalCheckLabel).join(', ')}',
    );
  }
  if (contract?.boundaries case final boundaries?) {
    _writeLines(out, 'Boundaries:', boundaries);
  }
  if (contract?.stopWhen case final stopWhen?) {
    _writeLines(out, 'Stop and ask when:', stopWhen);
  }
  out
    ..writeln(goalStateLine(state))
    ..writeln(
      'This segment may spend up to ${formatGoalUsd(state.segmentCapMicros)} '
      'USD.',
    )
    ..writeln()
    ..writeln(goalBlockRules)
    ..write(hasRepl ? goalBlockReplHint : goalBlockPlainHint);
  return out.toString();
}

/// [renderGoalBlock] followed by the existing completion audit
/// (`goalCompletionAudit`), unchanged, after a blank line: what a segment's
/// prompt carries.
String renderGoalBlockWithAudit(
  AgentGoalRun goal,
  GoalBlockState state, {
  required bool hasRepl,
  required String nonce,
}) =>
    '${renderGoalBlock(goal, state, hasRepl: hasRepl, nonce: nonce)}\n\n'
    '$goalCompletionAudit';

/// [heading] and [text] one safe line at a time ([wakeDataOutsideLine]):
/// one line stays on the heading's line, several go under it.
void _writeLines(StringBuffer out, String heading, String text) {
  final lines = [
    for (final line in text.trim().split('\n'))
      if (line.trim().isNotEmpty) wakeDataOutsideLine(line.trim()),
  ];
  if (lines.length == 1) {
    out.writeln('$heading ${lines.single}');
    return;
  }
  out.writeln(heading);
  for (final line in lines) {
    out.writeln('  $line');
  }
}

/// The state line: `State: segment 4 · 3.10 USD of 50.00 spent · 5 d 2 h
/// left · no-progress 0 of 3 · verification round 1 of 3`. The time part is
/// left out when the goal has no deadline.
String goalStateLine(GoalBlockState state) {
  final timeLeft = state.timeLeft;
  final spent = formatGoalUsd(state.spentMicros);
  final cap = formatGoalUsd(state.capMicros);
  final round = state.verificationRound;
  return [
    'State: segment ${state.segment}',
    '$spent USD of $cap spent',
    if (timeLeft != null) formatGoalTimeLeft(timeLeft),
    'no-progress ${state.noProgressCount} of $goalMaxNoProgressSegments',
    'verification round $round of $goalMaxVerificationRounds',
  ].join(' · ');
}

/// [micros] as dollars with two decimals, rounded half up: `3.10`.
String formatGoalUsd(int micros) {
  final cents = (micros + 5000) ~/ 10000;
  final whole = cents ~/ 100;
  final rest = (cents % 100).toString().padLeft(2, '0');
  return '$whole.$rest';
}

/// The time part of the state line: `5 d 2 h left`, `3 h 20 min left`,
/// `45 min left`, or `no time left` once the deadline has passed.
String formatGoalTimeLeft(Duration left) {
  if (left.inMinutes <= 0) {
    return 'no time left';
  }
  final days = left.inDays;
  final hours = left.inHours % 24;
  final minutes = left.inMinutes % 60;
  if (days > 0) {
    return '$days d $hours h left';
  }
  if (left.inHours > 0) {
    return '$hours h $minutes min left';
  }
  return '$minutes min left';
}

/// How a check is named to the model: a worktree command as inline code,
/// an environment task as `the environment task `name``.
String goalCheckLabel(GoalCheck check) => switch (check.where) {
  GoalCheckLocation.worktree => goalInlineCode(check.run),
  GoalCheckLocation.environment =>
    'the environment task ${goalInlineCode(check.run)}',
};

/// [text] on one line as markdown inline code, with a longer fence when it
/// contains a backtick.
String goalInlineCode(String text) {
  final line = _oneLine(text);
  if (!line.contains('`')) {
    return '`$line`';
  }
  return '`` $line ``';
}

String _oneLine(String text) =>
    text.trim().replaceAll(RegExp(r'\s*[\r\n]+\s*'), ' ');

/// The person's words with anything that would read as the objective tag
/// defused, so the text cannot close its own element.
String _neutraliseObjective(String text) => text.replaceAllMapped(
  RegExp(r'<(\s*/?\s*objective)', caseSensitive: false),
  (m) => '&lt;${m[1]}',
);
