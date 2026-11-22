import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart'
    show goalReviewSubmitHint, goalReviewSubmitPlainHint;
import 'package:cc_domain/features/dispatch/domain/prompts/improvement_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_harness/context.dart' show wakeDataRule;
import 'package:test/test.dart';

AgentGoalRun _goal() =>
    AgentGoalRun(
      id: 'goal-1',
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
      userText: 'Make the build green',
      costCapMicros: 5000000,
      contract: GoalContract(criteria: const ['the tests pass']),
      createdAt: DateTime.utc(2026, 11, 19),
      updatedAt: DateTime.utc(2026, 11, 19),
    ).copyWith(
      verification: GoalVerification(
        round: 1,
        claimSummary: 'done',
        checks: [
          GoalCheckResult(
            run: 'make test',
            where: GoalCheckLocation.worktree,
            exitCode: 0,
          ),
        ],
        verdict: GoalVerdict(
          verdict: GoalVerdictOutcome.pass,
          concerns: const ['slow suite'],
        ),
        reviewerAgentId: 'checker',
        reviewRunId: 'run-2',
        fingerprint: 'fp',
        at: DateTime.utc(2026, 11, 19, 12),
      ),
    );

Map<String, Object?> _proposal({
  String kind = 'memory_fact',
  String scope = 'workspace',
  String operation = 'add',
  Object? target = 'build',
  Object? repository,
  Object? skill,
  Object? change = 'Run make gen before make test.',
  Object? evidence = const {
    'messageIds': ['m-1'],
  },
  Object? expected = 'The first build passes.',
}) => {
  'kind': kind,
  'scope': scope,
  'operation': operation,
  'target': ?target,
  'repository': ?repository,
  'skill': ?skill,
  'change': ?change,
  'evidence': ?evidence,
  'expected': ?expected,
};

void main() {
  group('the review prompt', () {
    test('pins the fixed texts', () {
      expect(improvementReviewHeading, '## Improvement review');
      expect(
        improvementReviewIntro,
        'You are looking back at finished work in this conversation for what '
        'would make the next similar task go better. You change nothing: you '
        'read, and you return proposals that a person accepts or rejects.',
      );
      // A12: the person's corrections outrank the agent's own account, and a
      // proposal built on one quotes the message id.
      expect(
        improvementReviewInstructions,
        'Look for something that would make the next similar task go better: '
        'a fact about this workspace or a repository that was hard to find, a '
        'rule the work should have followed, a note for this agent, or a '
        'change to a skill. What the person corrected, refused or redirected '
        '(a steer, a denied approval, "no, do X") is the strongest evidence '
        "and outranks the agent's own account of what went well; a proposal "
        "built on it quotes the person's message id. Every proposal needs "
        'evidence from this work: run ids, message ids, or the commands of '
        'the checks above. A shortcut that happened to work once is not a '
        'lesson. At most three proposals are accepted, and none is a fine '
        'answer.',
      );
      expect(maxImprovementProposals, 3);
    });

    test('a /refine with no goal, in a repl run, byte for byte', () {
      final text = renderImprovementReviewPrompt(
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        conversationId: 'conv-1',
        goal: null,
        nonce: 'n0abc1',
        hasRepl: true,
      );
      expect(
        text,
        '## Improvement review\n'
        '\n'
        '$improvementReviewIntro\n'
        '\n'
        '$wakeDataRule\n'
        'No verified goal is attached: review the recent work in this '
        'conversation.\n'
        'Read the conversation in a repl script with `await '
        'tools.get_messages({workspace_id: "ws-1", space_id: "space-1", '
        'conversation_id: "conv-1", limit: 50})`. Where your repl has it, '
        '`await history({start: 0, role: "person"})` pages its whole '
        'transcript oldest first, folded turns and every tool call included; '
        '`tool: "<tool name>"` keeps one tool\'s calls, and the page\'s '
        '`next_start` is the next page\'s `start`.\n'
        '\n'
        '$improvementReviewInstructions\n'
        '$improvementReviewAnswerShape\n'
        '$goalReviewSubmitHint',
      );
    });

    test('a verified goal: objective and concerns stay in envelopes', () {
      final text = renderImprovementReviewPrompt(
        workspaceId: 'ws-1',
        spaceId: 'space-1',
        conversationId: 'conv-1',
        goal: _goal(),
        nonce: 'n0abc1',
        hasRepl: false,
      );
      expect(text, contains('The goal, verified complete:\n<wake-data'));
      expect(text, contains('Make the build green'));
      expect(text, contains('Done means:\n1. the tests pass\n'));
      expect(text, contains("The independent reviewer's verdict: pass."));
      expect(text, contains('Its concerns: <wake-data'));
      expect(text, contains('- `make test`: exit 0'));
      expect(
        text,
        contains(
          'Read the conversation with the get_messages tool: '
          '{workspace_id: "ws-1", space_id: "space-1", conversation_id: '
          '"conv-1", limit: 50}.',
        ),
      );
      expect(text, endsWith(goalReviewSubmitPlainHint));
      // Without `repl` the run is never told to read through a script.
      expect(text, isNot(contains('repl script')));
      expect(text, isNot(contains('await ')));
      expect(text, isNot(contains('history(')));
      expect(
        goalReviewSubmitPlainHint,
        'submit_output is a Control Center tool; call it directly.',
      );
    });

    test('the output schema caps the answer at three', () {
      final proposals =
          (improvementReviewOutputSchema['properties']! as Map)['proposals']
              as Map;
      expect(proposals['maxItems'], 3);
    });
  });

  group('parseImprovementReviewOutput', () {
    test('keeps a well-formed proposal, from an object or its JSON', () {
      final answer = {
        'proposals': [_proposal()],
      };
      for (final input in [answer, jsonEncode(answer)]) {
        final parsed = parseImprovementReviewOutput(input);
        expect(parsed.dropped, 0);
        final draft = parsed.drafts.single;
        expect(draft.kind, ImprovementKind.memoryFact);
        expect(draft.scope, ImprovementScope.workspace);
        expect(draft.operation, ImprovementOperation.add);
        expect(draft.target, 'build');
        expect(draft.messageIds, ['m-1']);
      }
    });

    test('drops a malformed answer', () {
      for (final input in [null, 'not json', 42, <String, Object?>{}]) {
        final parsed = parseImprovementReviewOutput(input);
        expect(parsed.drafts, isEmpty);
        expect(parsed.dropped, 1);
      }
    });

    test('drops a malformed proposal and keeps the others', () {
      final parsed = parseImprovementReviewOutput({
        'proposals': [
          _proposal(kind: 'wisdom'),
          _proposal(change: null),
          _proposal(change: 'x' * 601),
          // An agent note is agent-scoped.
          _proposal(kind: 'agent_note'),
        ],
      });
      expect(parsed.drafts, isEmpty);
      expect(parsed.dropped, 4);
    });

    test('drops a proposal without evidence', () {
      final parsed = parseImprovementReviewOutput({
        'proposals': [
          _proposal(evidence: null),
          _proposal(evidence: const <String, Object?>{}),
          _proposal(
            evidence: const {
              'runIds': [' '],
            },
          ),
        ],
      });
      expect(parsed.drafts, isEmpty);
      expect(parsed.dropped, 3);
    });

    test('drops the fourth and later', () {
      final parsed = parseImprovementReviewOutput({
        'proposals': List.generate(5, (_) => _proposal()),
      });
      expect(parsed.drafts, hasLength(3));
      expect(parsed.dropped, 2);
    });

    test('kind, scope and operation must go together', () {
      final parsed = parseImprovementReviewOutput({
        'proposals': [
          // A replace needs its target.
          _proposal(operation: 'replace', target: null),
          // A repository proposal names its repository.
          _proposal(scope: 'repository'),
          // A new skill only adds, and names a valid skill.
          _proposal(kind: 'skill_new', operation: 'replace', skill: 'lint'),
        ],
      });
      expect(parsed.drafts, isEmpty);
      expect(parsed.dropped, 3);

      final kept = parseImprovementReviewOutput({
        'proposals': [
          _proposal(scope: 'repository', repository: 'acme/shop-ui'),
          _proposal(kind: 'skill_new', skill: 'lint-fix', target: null),
          _proposal(kind: 'agent_note', scope: 'agent', target: null),
        ],
      });
      expect(kept.dropped, 0);
      expect(kept.drafts.map((d) => d.kind), [
        ImprovementKind.memoryFact,
        ImprovementKind.skillNew,
        ImprovementKind.agentNote,
      ]);
      expect(kept.drafts[1].skill, 'lint-fix');
    });
  });
}
