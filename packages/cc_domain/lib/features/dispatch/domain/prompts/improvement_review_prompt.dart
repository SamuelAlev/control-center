/// The improvement review's prompt (plan section 13, "Learning from
/// finished work"), the `submit_output` schema it answers with, and the
/// strict parser from that answer to proposal drafts. Pinned byte for byte by
/// `improvement_review_prompt_test.dart`.
library;

import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart'
    show goalInlineCode;
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart'
    show goalReviewSubmitHint, goalReviewSubmitPlainHint;
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart'
    show GoalVerdictOutcomeWire;
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_harness/context.dart'
    show wakeDataEnvelope, wakeDataOutsideLine, wakeDataRule;

/// The heading of the review run's per-turn section.
const String improvementReviewHeading = '## Improvement review';

/// The paragraph that opens the section.
const String improvementReviewIntro =
    'You are looking back at finished work in this conversation for what '
    'would make the next similar task go better. You change nothing: you '
    'read, and you return proposals that a person accepts or rejects.';

/// What the review looks for, A12 included: a person's correction outranks
/// the agent's own account.
const String improvementReviewInstructions =
    'Look for something that would make the next similar task go better: a '
    'fact about this workspace or a repository that was hard to find, a rule '
    'the work should have followed, a note for this agent, or a change to a '
    'skill. What the person corrected, refused or redirected (a steer, a '
    'denied approval, "no, do X") is the strongest evidence and outranks the '
    "agent's own account of what went well; a proposal built on it quotes "
    "the person's message id. Every proposal needs evidence from this work: "
    'run ids, message ids, or the commands of the checks above. A shortcut '
    'that happened to work once is not a lesson. At most three proposals are '
    'accepted, and none is a fine answer.';

/// The answer's shape and what each field means.
const String improvementReviewAnswerShape =
    'Answer with output: {proposals: [{kind: memory_fact | policy | '
    'agent_note | skill_edit | skill_new, scope: agent | repository | '
    'workspace, operation: add | replace | remove, target, repository, skill, '
    'change, evidence: {runIds, messageIds, checks}, expected}]}. memory_fact '
    'and policy are workspace or repository (name the repository), '
    'agent_note is agent, skill_edit and skill_new are workspace (name the '
    'skill; skill_new only adds). target: for add, the topic of a '
    'memory_fact or the domain of a policy; for replace or remove, the id of '
    'the fact or policy, or the exact passage of the note or the skill. '
    'change and expected are at most 600 characters each; checks are the '
    'commands of the checks listed above.';

/// The most proposals one review returns.
const int maxImprovementProposals = 3;

/// The schema the review run is dispatched with (`WakeRunOptions
/// .outputSchema`).
const Map<String, Object?> improvementReviewOutputSchema = {
  'type': 'object',
  'properties': {
    'proposals': {
      'type': 'array',
      'maxItems': maxImprovementProposals,
      'items': {
        'type': 'object',
        'properties': {
          'kind': {
            'type': 'string',
            'enum': [
              'memory_fact',
              'policy',
              'agent_note',
              'skill_edit',
              'skill_new',
            ],
          },
          'scope': {
            'type': 'string',
            'enum': ['agent', 'repository', 'workspace'],
          },
          'operation': {
            'type': 'string',
            'enum': ['add', 'replace', 'remove'],
          },
          'target': {'type': 'string'},
          'repository': {'type': 'string'},
          'skill': {'type': 'string'},
          'change': {'type': 'string', 'maxLength': 600},
          'evidence': {
            'type': 'object',
            'properties': {
              'runIds': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'messageIds': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'checks': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          },
          'expected': {'type': 'string', 'maxLength': 600},
        },
        'required': [
          'kind',
          'scope',
          'operation',
          'change',
          'evidence',
          'expected',
        ],
      },
    },
  },
  'required': ['proposals'],
};

/// The review's per-turn section for the work in [conversationId] (in
/// [spaceId] of [workspaceId]): [goal], the verified goal it follows (null
/// for a `/refine` with no verified goal in the conversation). The goal's
/// objective and the reviewer's concerns sit in `wake-data` envelopes with
/// [nonce]; criteria and check commands are made safe one line at a time.
/// [hasRepl] picks how the reading calls and `submit_output` are named.
String renderImprovementReviewPrompt({
  required String workspaceId,
  required String spaceId,
  required String conversationId,
  required AgentGoalRun? goal,
  required String nonce,
  required bool hasRepl,
}) {
  final out = StringBuffer()
    ..writeln(improvementReviewHeading)
    ..writeln()
    ..writeln(improvementReviewIntro)
    ..writeln()
    ..writeln(wakeDataRule);
  if (goal == null) {
    out.writeln(
      'No verified goal is attached: review the recent work in this '
      'conversation.',
    );
  } else {
    out
      ..writeln('The goal, verified complete:')
      ..writeln(wakeDataEnvelope(goal.userText.trim(), nonce: nonce));
    final contract = goal.contract;
    final criteria = contract?.criteria ?? const <String>[];
    if (criteria.isNotEmpty) {
      out.writeln('Done means:');
      for (var i = 0; i < criteria.length; i++) {
        out.writeln('${i + 1}. ${wakeDataOutsideLine(criteria[i].trim())}');
      }
    }
    final verification = goal.verification;
    final verdict = verification?.verdict;
    out.writeln(
      verdict == null
          ? 'The reviewer gave no verdict.'
          : "The independent reviewer's verdict: ${verdict.verdict.wire}.",
    );
    final concerns = verdict?.concerns ?? const <String>[];
    if (concerns.isNotEmpty) {
      out.writeln(
        'Its concerns: ${wakeDataEnvelope(concerns.join('\n'), nonce: nonce)}',
      );
    }
    final checks = verification?.checks ?? const [];
    if (checks.isEmpty) {
      out.writeln('The goal had no checks.');
    } else {
      out.writeln('Its checks:');
      for (final check in checks) {
        final code = check.exitCode;
        out.writeln(
          '- ${goalInlineCode(wakeDataOutsideLine(check.run))}: '
          '${code == null ? 'did not finish' : 'exit $code'}',
        );
      }
    }
  }
  final where =
      'workspace_id: "$workspaceId", space_id: "$spaceId", '
      'conversation_id: "$conversationId"';
  out.writeln(
    hasRepl
        ? 'Read the conversation in a repl script with '
              '`await tools.get_messages({$where, limit: 50})`. Where your '
              'repl has it, `await history({start: 0, role: "person"})` '
              'pages its whole transcript oldest first, folded turns and '
              'every tool call included; `tool: "<tool name>"` keeps one '
              "tool's calls, and the page's `next_start` is the next "
              "page's `start`."
        : 'Read the conversation with the get_messages tool: '
              '{$where, limit: 50}.',
  );
  out
    ..writeln()
    ..writeln(improvementReviewInstructions)
    ..writeln(improvementReviewAnswerShape)
    ..write(hasRepl ? goalReviewSubmitHint : goalReviewSubmitPlainHint);
  return out.toString();
}

/// One proposal as the review returned it, checked for shape. Its ids and
/// names are the model's: the server resolves [repository], [skill], the
/// evidence ids and [checks] against its own records before a row is
/// written, and drops what does not resolve.
class ImprovementDraft {
  /// Creates a draft.
  const ImprovementDraft({
    required this.kind,
    required this.scope,
    required this.operation,
    required this.target,
    required this.repository,
    required this.skill,
    required this.change,
    required this.expected,
    required this.runIds,
    required this.messageIds,
    required this.checks,
  });

  /// What kind of change.
  final ImprovementKind kind;

  /// Where it applies.
  final ImprovementScope scope;

  /// Add, replace or remove.
  final ImprovementOperation operation;

  /// For add, a fact's topic or a policy's domain; for replace and remove,
  /// the fact or policy id, or the exact passage of a note or skill.
  final String? target;

  /// The repository a repository-scoped proposal names.
  final String? repository;

  /// The skill a skill proposal names.
  final String? skill;

  /// The proposed text.
  final String change;

  /// What should go better.
  final String expected;

  /// Run ids cited.
  final List<String> runIds;

  /// Message ids cited.
  final List<String> messageIds;

  /// Check commands cited.
  final List<String> checks;
}

/// What [parseImprovementReviewOutput] kept and how many it dropped.
typedef ImprovementReviewParse = ({List<ImprovementDraft> drafts, int dropped});

/// The longest [ImprovementDraft.target], in characters.
const int maxImprovementTargetLength = 2000;

final RegExp _skillSlug = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$');

/// Reads the review's `submit_output` [output] (the decoded object or its
/// JSON text) into drafts. Never throws. A proposal is dropped and counted
/// when it is malformed (a missing or mistyped field, an unknown value, a
/// kind and scope that do not go together, a replace or remove without a
/// target, a repository proposal without a repository, a skill proposal
/// without a valid skill name, a `skill_new` that is not an add, text past
/// its limit), when it has no evidence, and when it is the fourth or later.
/// An answer that is not `{proposals: [...]}` keeps nothing and drops one.
ImprovementReviewParse parseImprovementReviewOutput(Object? output) {
  var value = output;
  if (value is String) {
    try {
      value = jsonDecode(value);
    } on FormatException {
      return (drafts: const <ImprovementDraft>[], dropped: 1);
    }
  }
  final list = value is Map ? value['proposals'] : null;
  if (list is! List) {
    return (drafts: const <ImprovementDraft>[], dropped: 1);
  }
  final drafts = <ImprovementDraft>[];
  var dropped = 0;
  for (var i = 0; i < list.length; i++) {
    final draft = i < maxImprovementProposals ? _draft(list[i]) : null;
    if (draft == null) {
      dropped++;
    } else {
      drafts.add(draft);
    }
  }
  return (drafts: drafts, dropped: dropped);
}

ImprovementDraft? _draft(Object? raw) {
  if (raw is! Map) {
    return null;
  }
  final kind = ImprovementKindWire.tryParse(_string(raw['kind']));
  final scope = ImprovementScopeWire.tryParse(_string(raw['scope']));
  final operation = ImprovementOperationWire.tryParse(
    _string(raw['operation']),
  );
  if (kind == null || scope == null || operation == null) {
    return null;
  }
  final allowed = switch (kind) {
    ImprovementKind.memoryFact || ImprovementKind.policy =>
      scope == ImprovementScope.workspace ||
          scope == ImprovementScope.repository,
    ImprovementKind.agentNote => scope == ImprovementScope.agent,
    ImprovementKind.skillEdit => scope == ImprovementScope.workspace,
    ImprovementKind.skillNew =>
      scope == ImprovementScope.workspace &&
          operation == ImprovementOperation.add,
  };
  if (!allowed) {
    return null;
  }
  final change = _text(raw['change'], ImprovementProposal.maxChangeLength);
  final expected = _text(
    raw['expected'],
    ImprovementProposal.maxExpectedLength,
  );
  if (change == null || expected == null) {
    return null;
  }
  final target = _optional(raw, 'target', maxImprovementTargetLength);
  final repository = _optional(raw, 'repository', 200);
  final skill = _optional(raw, 'skill', 128);
  if (target == false || repository == false || skill == false) {
    return null;
  }
  if (operation != ImprovementOperation.add && target == null) {
    return null;
  }
  if (scope == ImprovementScope.repository && repository == null) {
    return null;
  }
  final isSkill =
      kind == ImprovementKind.skillEdit || kind == ImprovementKind.skillNew;
  if (isSkill && (skill == null || !_skillSlug.hasMatch(skill as String))) {
    return null;
  }
  final evidence = raw['evidence'];
  if (evidence is! Map) {
    return null;
  }
  final runIds = _ids(evidence['runIds']);
  final messageIds = _ids(evidence['messageIds']);
  final checks = _ids(evidence['checks']);
  if (runIds == null || messageIds == null || checks == null) {
    return null;
  }
  if (runIds.isEmpty && messageIds.isEmpty && checks.isEmpty) {
    return null;
  }
  return ImprovementDraft(
    kind: kind,
    scope: scope,
    operation: operation,
    target: target as String?,
    repository: repository as String?,
    skill: isSkill ? skill as String : null,
    change: change,
    expected: expected,
    runIds: runIds,
    messageIds: messageIds,
    checks: checks.length > ImprovementEvidence.maxCheckResults
        ? checks.sublist(0, ImprovementEvidence.maxCheckResults)
        : checks,
  );
}

String? _string(Object? value) => value is String ? value.trim() : null;

/// The trimmed text, or null when absent, empty or past [max].
String? _text(Object? value, int max) {
  if (value is! String) {
    return null;
  }
  final text = value.trim();
  return text.isEmpty || text.length > max ? null : text;
}

/// Null when absent or blank, the trimmed text when valid, false when
/// mistyped or past [max].
Object? _optional(Map<Object?, Object?> raw, String key, int max) {
  final value = raw[key];
  if (value == null) {
    return null;
  }
  if (value is! String || value.trim().length > max) {
    return false;
  }
  final text = value.trim();
  return text.isEmpty ? null : text;
}

/// Distinct trimmed non-empty strings; null when not a list of strings or
/// more than [ImprovementEvidence.maxIds].
List<String>? _ids(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is! List || value.any((e) => e is! String)) {
    return null;
  }
  final ids = <String>{
    for (final e in value.cast<String>())
      if (e.trim().isNotEmpty) e.trim(),
  }.toList();
  return ids.length > ImprovementEvidence.maxIds ? null : ids;
}
