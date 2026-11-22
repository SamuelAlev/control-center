import 'dart:convert';

import 'package:cc_domain/cc_domain.dart'
    show
        GoalNotActiveSegmentException,
        GoalRefusedException,
        ValidationException;
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/ports/goal_supervision_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_budget_shares.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/context.dart'
    show newWakeDataNonce, wakeDataEnvelope;
import 'package:cc_mcp/src/mcp_scoped_tool.dart';

/// What `complete_goal` tells the model after a claim is recorded: what
/// happens next and what to do now. Pinned by
/// `goal_supervision_tools_test.dart`.
const String goalClaimRecordedNext =
    'The server is now running the checks, then an independent reviewer '
    'inspects the result. You will be woken with the result; end your turn.';

/// `complete_goal`: the calling agent claims its active goal is complete
/// (plan section 8, "Verification"). The claim does not close the goal: it
/// is recorded (`hold: verifying`) and, when the segment ends, the server
/// runs the goal's checks and an independent review.
///
/// The caller's identity is the call's: `agent_id` and `conversation_id` are
/// forced from the run's scope, and only the goal's active segment may
/// claim, proven by the run's attested `runLogId` (the gateway transport's,
/// or the in-process harness's: [callForRun]). Anything else is refused with
/// `goal_not_active_segment`; evidence that leaves a "Done means" item
/// uncovered with `goal_evidence_incomplete`; a second claim while one is
/// verified with `goal_claim_pending`.
class CompleteGoalTool extends McpScopedTool {
  /// Creates a [CompleteGoalTool].
  CompleteGoalTool({required this._supervisionPort});

  final GoalSupervisionPort _supervisionPort;

  /// The most evidence entries one claim may carry.
  static const int maxEvidence = 40;

  @override
  String get name => 'complete_goal';

  /// A script that verifies each item and then claims is a good use (plan
  /// section 16): the claim closes nothing, the server verifies it.
  @override
  bool get scriptCallable => true;

  /// The in-process harness's call carries its run's attested scope.
  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  /// The goal is the calling run's: who calls is never an argument.
  @override
  Set<String> get forcedScopeKeys => const {'agent_id', 'conversation_id'};

  /// Only a run with a session identity can name its own goal.
  @override
  Set<String> get requiredScopeKeys => const {'agent_id', 'conversation_id'};

  /// An HTTP caller must prove which run it is: only the goal's active
  /// segment may claim.
  @override
  bool get requiresRunGrant => true;

  @override
  String get description =>
      'Claim that your active goal is fully achieved, with a summary and, '
      'for every "Done means" item, the evidence (the command you ran and '
      'its result, the file and line, the pull request), checked against '
      'the real state. The claim does not close the goal: the server runs '
      "the goal's checks and an independent reviewer inspects the result.";

  @override
  String get resultNote =>
      'JSON {status: "verifying", goal_id, round, next}; next says what '
      'happens now (end your turn).';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'agent_id': {
        'type': 'string',
        'description': 'Your own agent id (filled from your run).',
      },
      'conversation_id': {
        'type': 'string',
        'description': "Your run's conversation (filled from your run).",
      },
      'summary': {
        'type': 'string',
        'description': 'What was achieved, at most 4,000 characters.',
      },
      'evidence': {
        'type': 'array',
        'description':
            'One entry per "Done means" item; criterion is the item\'s '
            'number (from 1) or its exact text.',
        'items': {
          'type': 'object',
          'properties': {
            'criterion': {'type': 'string'},
            'evidence': {'type': 'string'},
          },
          'required': ['criterion', 'evidence'],
        },
      },
    },
    'required': [
      'workspace_id',
      'agent_id',
      'conversation_id',
      'summary',
      'evidence',
    ],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String || agentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final conversationId = arguments['conversation_id'];
    if (conversationId is! String || conversationId.isEmpty) {
      return CallResult.error('Missing or invalid argument: conversation_id');
    }
    final summary = arguments['summary'];
    if (summary is! String || summary.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: summary');
    }
    final evidence = _evidence(arguments['evidence']);
    if (evidence == null) {
      return CallResult.error(
        'Missing or invalid argument: evidence (a list of at most '
        '$maxEvidence {criterion, evidence} objects, each text within its '
        'limit)',
      );
    }

    try {
      final goal = await _supervisionPort.claimCompletion(
        workspaceId,
        agentId,
        conversationId: conversationId,
        // Only an attested scope proves which run is calling.
        callingRunId: context.scope?.attested == true
            ? context.scope?.runLogId
            : null,
        summary: summary,
        evidence: evidence,
      );
      return CallResult.success(
        jsonEncode({
          'status': 'verifying',
          'goal_id': goal.id,
          'round': goal.verification?.round ?? goal.verificationRounds + 1,
          'next': goalClaimRecordedNext,
        }),
      );
    } on GoalNotActiveSegmentException catch (e) {
      return _refusal(e.message, GoalNotActiveSegmentException.kind);
    } on GoalRefusedException catch (e) {
      return _refusal(e.message, e.code ?? 'goal_refused');
    } on ValidationException catch (e) {
      return CallResult.error(e.message);
    }
  }

  static CallResult _refusal(String message, String kind) => CallResult(
    content: [CallResultContent(type: 'text', text: message)],
    isError: true,
    structured: {'kind': kind},
  );

  static List<GoalClaimEvidence>? _evidence(Object? raw) {
    if (raw is! List || raw.length > maxEvidence) {
      return null;
    }
    final out = <GoalClaimEvidence>[];
    for (final item in raw) {
      if (item is! Map) {
        return null;
      }
      final criterion = item['criterion'];
      final text = item['evidence'];
      if (criterion is! String || text is! String) {
        return null;
      }
      try {
        out.add(GoalClaimEvidence(criterion: criterion, evidence: text));
      } on ArgumentError {
        return null;
      }
    }
    return out;
  }
}

/// `goal_status`: the calling agent's active goal in its conversation, read
/// only: the contract, the state line's values, the hold, the strikes, the
/// budget left, the last verification and the goal's pending wakes. Identity
/// is forced from the scope; text that came from a command, the worker or a
/// reviewer is wrapped in a `wake-data` envelope.
class GoalStatusTool extends McpScopedTool {
  /// Creates the tool.
  GoalStatusTool({
    required this._supervisionPort,
    required this._wakes,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final GoalSupervisionPort _supervisionPort;
  final WakeRepository _wakes;
  final DateTime Function() _now;

  /// The most characters of a check's output tail in the result.
  static const int maxOutputTail = 500;

  @override
  String get name => 'goal_status';

  /// A read: a script may check its goal before it claims.
  @override
  bool get scriptCallable => true;

  /// The in-process harness's call carries its run's scope.
  @override
  Future<CallResult> callForRun(
    Map<String, dynamic> arguments,
    McpCallScope scope, {
    Future<void>? abandoned,
  }) =>
      callScoped(arguments, McpCallContext(scope: scope), abandoned: abandoned);

  @override
  Set<String> get forcedScopeKeys => const {'agent_id', 'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {'agent_id', 'conversation_id'};

  @override
  String get description =>
      'Read your active goal: its contract, segment, spend and budget left, '
      'no-progress strikes, hold, last verification and pending goal wakes. '
      'Changes nothing.';

  @override
  String get resultNote =>
      'JSON {goal: null, notice} or {goal: {goal_id, objective, status, hold, '
      'hold_detail, state_line, segment, spent_micros, cap_micros, '
      'budget_left_micros, segment_cap_micros, time_left_seconds, strikes, '
      'max_strikes, failures, verification_round, max_rounds, contract: '
      '{criteria, checks: [{run, where}], boundaries, stop_when} or null, '
      'last_verification: {round, at, claim_summary, checks: [{run, where, '
      'exit_code, timed_out, broken, skipped_unchanged, passed, output_tail}], '
      'verdict: {verdict, items: [{criterion, state, evidence}], concerns} or '
      'null, approved} or null, pending_wakes: [{wake_id, reason, state, '
      'not_before}]}}; claim_summary, output_tail, evidence and each concern '
      'are wrapped in wake-data tags.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'agent_id': {
        'type': 'string',
        'description': 'Your own agent id (filled from your run).',
      },
      'conversation_id': {
        'type': 'string',
        'description': "Your run's conversation (filled from your run).",
      },
    },
    'required': ['workspace_id', 'agent_id', 'conversation_id'],
  };

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String || agentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final conversationId = arguments['conversation_id'];
    if (conversationId is! String || conversationId.isEmpty) {
      return CallResult.error('Missing or invalid argument: conversation_id');
    }
    final goal = await _supervisionPort.activeGoalForAgent(
      workspaceId,
      agentId,
    );
    if (goal == null || goal.status != AgentGoalStatus.active) {
      return _json({'goal': null, 'notice': 'You have no active goal.'});
    }
    if (goal.conversationId != conversationId) {
      return _json({
        'goal': null,
        'notice': 'Your active goal runs in another conversation.',
      });
    }
    final pending = [
      for (final wake in await _wakes.listForConversation(
        workspaceId,
        conversationId,
        states: const {WakeState.pending, WakeState.held},
      ))
        if (wake.detail.goalId == goal.id)
          {
            'wake_id': wake.id,
            'reason': wake.reason.wire,
            'state': wake.state.wire,
            'not_before': wake.notBefore.toUtc().toIso8601String(),
          },
    ];
    return _json({'goal': _goalJson(goal, pending, newWakeDataNonce())});
  }

  Map<String, Object?> _goalJson(
    AgentGoalRun goal,
    List<Map<String, Object?>> pending,
    String nonce,
  ) {
    final deadline = goal.deadlineAt;
    final timeLeft = deadline?.difference(_now());
    final segmentCap = goalSegmentCapMicros(goal);
    final left = goal.costCapMicros - goal.costMicros;
    final state = GoalBlockState(
      segment: goal.runCount + 1,
      spentMicros: goal.costMicros < 0 ? 0 : goal.costMicros,
      capMicros: goal.costCapMicros,
      timeLeft: timeLeft,
      noProgressCount: goal.noProgressStreak,
      verificationRound: goal.verificationRounds + 1,
      segmentCapMicros: segmentCap <= 0 ? 1 : segmentCap,
    );
    final contract = goal.contract;
    return {
      'goal_id': goal.id,
      'objective': goal.userText,
      'status': goal.status.wire,
      'hold': goal.hold?.wire,
      'hold_detail': goal.holdDetail,
      'state_line': goalStateLine(state),
      'segment': goal.runCount + 1,
      'spent_micros': goal.costMicros,
      'cap_micros': goal.costCapMicros,
      'budget_left_micros': left < 0 ? 0 : left,
      'segment_cap_micros': segmentCap,
      'time_left_seconds': timeLeft?.inSeconds,
      'strikes': goal.noProgressStreak,
      'max_strikes': goalMaxNoProgressSegments,
      'failures': goal.consecutiveFailures,
      'verification_round': goal.verificationRounds + 1,
      'max_rounds': goalMaxVerificationRounds,
      'contract': contract == null
          ? null
          : {
              'criteria': contract.criteria,
              'checks': [
                for (final check in contract.checks)
                  {'run': check.run, 'where': check.where.wire},
              ],
              'boundaries': contract.boundaries,
              'stop_when': contract.stopWhen,
            },
      'last_verification': _verificationJson(goal.verification, nonce),
      'pending_wakes': pending,
    };
  }

  static Map<String, Object?>? _verificationJson(
    GoalVerification? v,
    String nonce,
  ) {
    if (v == null) {
      return null;
    }
    String wrap(String text) => wakeDataEnvelope(text, nonce: nonce);
    final verdict = v.verdict;
    return {
      'round': v.round,
      'at': v.at.toIso8601String(),
      'claim_summary': wrap(v.claimSummary),
      'checks': [
        for (final check in v.checks)
          {
            'run': check.run,
            'where': check.where.wire,
            'exit_code': check.exitCode,
            'timed_out': check.timedOut,
            'broken': check.broken,
            'skipped_unchanged': check.skippedUnchanged,
            'passed': check.passed,
            'output_tail': wrap(_tail(check.outputTail)),
          },
      ],
      'verdict': verdict == null
          ? null
          : {
              'verdict': verdict.verdict.wire,
              'items': [
                for (final item in verdict.items)
                  {
                    'criterion': item.criterion,
                    'state': item.state.wire,
                    'evidence': wrap(item.evidence),
                  },
              ],
              'concerns': [for (final c in verdict.concerns) wrap(c)],
            },
      'approved': v.approvedByUserId != null,
    };
  }

  static String _tail(String text) => text.length <= maxOutputTail
      ? text
      : text.substring(text.length - maxOutputTail);

  static CallResult _json(Map<String, Object?> body) =>
      CallResult.success(jsonEncode(body));
}
