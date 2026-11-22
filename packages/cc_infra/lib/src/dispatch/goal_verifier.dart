import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_block.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_check_broken_notice.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart'
    show WakeFields;
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_budget_shares.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_checks_outcome.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/limit_park.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_infra/src/dispatch/goal_store.dart';

/// Runs a goal's checks (`GoalCheckRunner.run`).
typedef GoalChecksRun =
    Future<GoalChecksOutcome> Function({
      required String workspaceId,
      required String spaceId,
      required String conversationId,
      required String agentId,
      required GoalContract contract,
    });

/// The checker agent of a space (`SpaceCheckerRepository.checkerOf`).
typedef SpaceCheckerOf =
    Future<String?> Function(String workspaceId, String spaceId);

/// The worktree fingerprint of a goal's conversation now.
typedef GoalFingerprintOf = Future<String?> Function(AgentGoalRun goal);

/// The hold details a verification stop leaves on a paused goal
/// (`AgentGoalRun.holdDetail`; a broken check's is
/// `check_broken: <command>`).
// ignore: avoid_classes_with_only_static_members
abstract final class GoalHoldDetails {
  /// Three verification rounds failed.
  static const String verificationFailed = 'verification_failed';

  /// The reviewer could not tell, or its run failed, stopped or answered
  /// nothing.
  static const String cannotVerify = 'cannot_verify';

  /// The reviewer cannot be woken: the checker agent is deleted, archived or
  /// not dispatchable, or the review's wake was refused or skipped. A person
  /// picks another checker (`setChecker`) and resumes, which verifies the
  /// pending claim again.
  static const String checkerUnavailable = 'checker_unavailable';

  /// A person paused the goal (or stopped its run) while its claim was being
  /// verified: resuming verifies the claim again.
  static const String claimPending = 'claim_pending';

  /// The checks need a sandbox the server does not have.
  static const String sandboxUnavailable =
      GoalChecksOutcome.sandboxUnavailableKind;

  /// The prefix of a broken check's detail, followed by its command.
  static const String checkBroken = 'check_broken';

  /// Three segments in a row made no progress.
  static const String stalled = 'stalled';

  /// The goal waited on the same owed work, without progress, for
  /// `GoalProgressMarks.maxWait`.
  static const String stalledWaiting = 'stalled_waiting';

  /// A segment's wake could not be delivered (`wake_skipped: <kind>`).
  static const String wakeSkipped = 'wake_skipped';

  /// Whether [detail] is a stop of the verification (resuming it clears the
  /// round count).
  static bool isVerificationStop(String? detail) =>
      detail == verificationFailed || detail == cannotVerify;

  /// Whether resuming a goal with [detail] restarts verification from the
  /// claim it holds (the checks could not run; the claim was never judged).
  static bool restartsVerification(String? detail) =>
      detail == sandboxUnavailable ||
      detail == checkerUnavailable ||
      (detail != null && detail.startsWith(checkBroken));
}

/// Verifies a goal's completion claim (plan section 8, "Verification", with
/// amendment A1): the contract's checks, then an independent review run,
/// then the outcome. Started by the supervisor when a segment that claimed
/// completion ends; the review run's end arrives as [AgentRunSettled].
///
/// Every write is a compare-and-set on the goal's row ([GoalStore.transition])
/// that applies only while the goal still waits on this claim (`hold:
/// verifying`), so a pause, a cancel or a second verification in between
/// wins. The review run's cost is charged to the goal whatever happened to
/// it meanwhile.
///
/// A verification's review is the one its own wake starts
/// ([GoalVerification.reviewWakeId], recorded before the wake is written);
/// a new pass ([start]) never inherits the last one's run. A review that
/// ended while nothing applied its answer (the goal was paused, the server
/// stopped in between) is read from its run log by [recover]; one that gave
/// no answer of its own (a transient failure) is asked again once
/// ([GoalVerification.maxReviewAsks]); one at its provider's usage limit is
/// asked again after the reset (a `limitReset` wake marked
/// [WakeFields.review]); a reviewer that cannot be woken stops the
/// verification for a person ([GoalHoldDetails.checkerUnavailable]).
class GoalVerifier {
  /// Creates the verifier.
  GoalVerifier({
    required this._store,
    required this._runChecks,
    required this._fingerprintOf,
    required this._spaceCheckerOf,
    required this._agents,
    required this._runLogs,
  });

  final GoalStore _store;
  final GoalChecksRun _runChecks;
  final GoalFingerprintOf _fingerprintOf;
  final SpaceCheckerOf _spaceCheckerOf;
  final AgentRepository _agents;
  final AgentRunLogRepository _runLogs;

  /// The most goals' checks that run at once, server-wide. A check is a
  /// build or a test suite in a sandbox (up to 30 minutes each); two at once
  /// keep one goal's long suite from holding up every other goal's
  /// verification while bounding what the checks take from the host, whose
  /// agent runs need it too. While another workspace's checks wait, one
  /// workspace runs at most [maxChecksPerWorkspace] of them; the waiting
  /// checks are served round-robin by workspace (each workspace's in its
  /// order).
  static const int maxConcurrentChecks = 2;

  /// A workspace's share of [maxConcurrentChecks] while another waits.
  static const int maxChecksPerWorkspace = 1;

  /// How long after a review run's end its own settlement is left to apply
  /// its answer before [recover] reads it from the run log.
  static const Duration settleGrace = Duration(minutes: 1);

  /// Review run id → its goal, from the dispatch (bounded).
  final LinkedHashMap<String, String> _reviews = LinkedHashMap();

  static const int _maxRemembered = 512;

  int _checksRunning = 0;
  final Map<String, int> _checksByWorkspace = {};
  final List<({String workspaceId, Completer<void> turn})> _checkWaiters = [];
  String? _lastCheckWorkspace;

  /// Verifies the claim [goal] holds (`hold: verifying`, the claim in
  /// `verification`): first what its review already said or is doing
  /// ([recover]); otherwise a new pass that runs the checks and, when they
  /// pass or there are none, asks for the review.
  Future<void> start(AgentGoalRun goal) async {
    final claim = goal.verification;
    if (claim == null || !_awaitsClaim(goal)) {
      return;
    }
    if (await recover(goal)) {
      return;
    }
    final contract = goal.contract;
    var checked = claim.copyWith(
      checks: const [],
      removeVerdict: true,
      removeReviewRunId: true,
      removeReviewerAgentId: true,
      removeReviewWakeId: true,
      reviewAsks: 0,
      at: _store.now(),
    );
    if (contract != null && contract.checks.isNotEmpty) {
      final current = await _fingerprintOf(goal);
      final unchanged = claim.lastFailedFingerprint;
      if (unchanged != null && current == unchanged) {
        // The workspace is exactly as it was when the checks last failed:
        // they would fail again. Not rerun; the round still counts.
        checked = checked.copyWith(
          checks: [
            for (final check in contract.checks)
              GoalCheckResult(
                run: check.run,
                where: check.where,
                skippedUnchanged: true,
              ),
          ],
          fingerprint: current,
        );
      } else {
        final outcome = await _withCheckSlot(
          goal.workspaceId,
          () => _runChecks(
            workspaceId: goal.workspaceId,
            spaceId: goal.spaceId,
            conversationId: goal.conversationId,
            agentId: goal.agentId,
            contract: contract,
          ),
        );
        if (outcome.status == GoalChecksStatus.sandboxUnavailable) {
          await _stop(
            goal,
            claim,
            detail: GoalHoldDetails.sandboxUnavailable,
            summary:
                "The goal's checks could not run: no sandbox is available on "
                'this server. Resume the goal once one is.',
          );
          return;
        }
        checked = checked.copyWith(
          checks: outcome.results,
          fingerprint: outcome.fingerprint,
        );
        if (outcome.anyBroken) {
          await _checkBroken(goal, checked);
          return;
        }
      }
    }
    if (!checked.checksPassed) {
      await _failed(goal, checked);
      return;
    }
    await _review(goal, checked);
  }

  /// Settles what [goal]'s verification already has, without running the
  /// checks again: a verdict its review gave while the goal was paused is
  /// applied; a review run that ended unapplied is read from its run log; a
  /// review wake recorded but not written is written; a review wake that
  /// settled without a run is handled as its settlement would have been.
  /// Returns false when there is nothing to settle (a new pass is due), true
  /// otherwise (including "its review is still on its way").
  Future<bool> recover(AgentGoalRun goal) async {
    final v = goal.verification;
    if (v == null || !_awaitsClaim(goal)) {
      return true;
    }
    final runId = v.reviewRunId;
    if (runId != null && runId.isNotEmpty) {
      if (v.verdict != null) {
        await _decideRecorded(goal, runId);
        return true;
      }
      final log = await _runLogs.getById(goal.workspaceId, runId);
      if (log == null) {
        await _askAgain(
          goal,
          runId: runId,
          costMicros: 0,
          why: 'its run is gone',
        );
        return true;
      }
      if (log.isActive) {
        return true;
      }
      final ended = log.completedAt;
      if (ended != null &&
          log.endReason != RunEndReason.serverStopped &&
          _store.now().difference(ended) < settleGrace) {
        return true; // Its settlement is still being handled.
      }
      await _settleReview(
        goal,
        runId: runId,
        status: log.status,
        endReason: log.endReason ?? RunEndReason.error,
        costMicros: log.totalCostMicrosWithChildren,
        limitResetsAt: null,
      );
      return true;
    }
    final wakeId = v.reviewWakeId;
    if (wakeId == null) {
      return false;
    }
    final wake = await _store.wakes.getById(goal.workspaceId, wakeId);
    if (wake == null) {
      // Recorded, then the server stopped before the wake was written.
      await _insertRecordedReview(goal, v, wakeId);
      return true;
    }
    switch (wake.state) {
      case WakeState.pending || WakeState.held || WakeState.claimed:
        return true;
      case WakeState.delivered:
        final run = wake.deliveredRunId;
        if (run == null) {
          return false;
        }
        final ran = await _runLogs.getById(goal.workspaceId, run);
        if (ran != null &&
            !ran.isActive &&
            ran.endReason == RunEndReason.serverStopped) {
          // The server stopped under the review and its wake was not
          // delivered again (that happens only for the wakes the stopped
          // run reported): a new review wake asks the same question.
          await _askAfterStop(goal, wakeId);
          return true;
        }
        await reviewStarted(goal.workspaceId, goal.id, run, wakeId: wakeId);
        final reread = await _store.goals.getById(goal.workspaceId, goal.id);
        return reread == null ||
            reread.verification?.reviewRunId != run ||
            await recover(reread);
      case WakeState.skipped || WakeState.expired || WakeState.cancelled:
        if (wake.state == WakeState.cancelled &&
            (wake.stateReason ?? '').startsWith('goal_')) {
          return false; // The goal's own cancel (a pause): a new pass.
        }
        await onReviewWakeSettled(
          WakeSettlement(
            wake: wake,
            state: wake.state,
            reason: wake.stateReason,
          ),
        );
        return true;
    }
  }

  /// Records that the run [runId] started by review wake [wakeId] is the
  /// review of [goalId]'s claim (called with the run id as the dispatch
  /// returns it). Only the wake its verification waits for counts.
  Future<void> reviewStarted(
    String workspaceId,
    String goalId,
    String runId, {
    required String wakeId,
  }) async {
    final goal = await _store.goals.getById(workspaceId, goalId);
    if (goal?.verification?.reviewWakeId != wakeId) {
      return;
    }
    _remember(workspaceId, runId, goalId);
    await _store.transition(goal!, (g) {
      final v = g.verification;
      if (v == null ||
          v.reviewWakeId != wakeId ||
          v.verdict != null ||
          (v.reviewRunId != null && v.reviewRunId!.isNotEmpty)) {
        return null;
      }
      return g.copyWith(
        verification: v.copyWith(reviewRunId: runId),
        updatedAt: _store.now(),
      );
    });
  }

  /// Whether [runId] is (or was, recently) the review run of a goal of
  /// [workspaceId].
  Future<bool> isReviewRun(String workspaceId, String runId) async =>
      _reviews.containsKey(_runKey(workspaceId, runId)) ||
      await _goalReviewedBy(workspaceId, runId) != null;

  /// Handles the end of a run: when it is a review run, reads its verdict,
  /// charges its cost to the goal and applies the outcome. Returns whether
  /// it was a review run.
  Future<bool> onRunSettled(AgentRunSettled event) async {
    final goal = await _goalReviewedBy(event.workspaceId, event.runId);
    if (goal == null) {
      return false;
    }
    await _settleReview(
      goal,
      runId: event.runId,
      status: event.status,
      endReason: event.endReason,
      costMicros: event.costMicros,
      limitResetsAt: event.limitResetsAt,
    );
    return true;
  }

  /// Handles a review wake that settled without a run. Only the wake the
  /// verification waits for counts. A person's cancel pauses the goal (the
  /// claim stays pending); a wake skipped or expired for want of a sandbox
  /// stops it for that; any other skip or expiry (the reviewer deleted,
  /// archived or paused, a read-only run its backend cannot hold, refused
  /// dispatches) stops it as [GoalHoldDetails.checkerUnavailable].
  Future<void> onReviewWakeSettled(WakeSettlement settled) async {
    final wake = settled.wake;
    final goalId = wake.detail.goalId;
    if (!isGoalReviewWake(wake) ||
        goalId == null ||
        settled.state == WakeState.delivered) {
      return;
    }
    final goal = await _store.goals.getById(wake.workspaceId, goalId);
    final claim = goal?.verification;
    if (goal == null ||
        claim == null ||
        !_awaitsClaim(goal) ||
        claim.reviewWakeId != wake.id ||
        (claim.reviewRunId != null && claim.reviewRunId!.isNotEmpty)) {
      return;
    }
    if (settled.state == WakeState.cancelled) {
      if ((settled.reason ?? '').startsWith('goal_')) {
        return;
      }
      await _pauseCancelled(goal);
      return;
    }
    final kind = settled.reason ?? settled.state.name;
    if (kind == WakeStateReasons.sandboxUnavailable) {
      await _stop(
        goal,
        claim,
        detail: GoalHoldDetails.sandboxUnavailable,
        summary:
            'The review of the claim could not run: a read-only run needs a '
            'sandbox, and none is available on this server. Resume the goal '
            'once one is.',
      );
      return;
    }
    await _stopChecker(goal, claim, kind);
  }

  // ------------------------------------------------------------------ steps

  /// A broken check (A1): the contract's fault. The round does not count,
  /// the worker hears nothing, and a person must fix the check; the claim
  /// stays in `verification` so that resuming verifies it again.
  Future<void> _checkBroken(AgentGoalRun goal, GoalVerification checked) async {
    final broken = checked.checks.firstWhere((c) => c.broken);
    final notice = goalCheckBrokenNotice(broken);
    final detail = '${GoalHoldDetails.checkBroken}: ${broken.run}';
    await _stop(
      goal,
      checked,
      detail: detail.length > AgentGoalRun.maxHoldDetailLength
          ? detail.substring(0, AgentGoalRun.maxHoldDetailLength)
          : detail,
      summary: notice.sentence,
    );
  }

  /// A failed round (a check failed or was not rerun): a round more, and
  /// the worker's next segment carries the notice, or a person decides
  /// after the last round.
  Future<void> _failed(AgentGoalRun goal, GoalVerification checked) async {
    final failedAt = checked.fingerprint ?? checked.lastFailedFingerprint;
    final applied = await _store.transition(goal, (g) {
      if (!_awaitsClaim(g)) {
        return null;
      }
      return _afterFailedRound(
        g.copyWith(updatedAt: _store.now()),
        checked.copyWith(lastFailedFingerprint: failedAt),
      );
    });
    if (applied == null) {
      return;
    }
    await _announce(applied, null);
  }

  /// The review: a fresh, read-only, capped run of the goal's checker (the
  /// space's when it names none, its own agent when there is none) in the
  /// goal's conversation. A checker that cannot be woken stops the
  /// verification; no other reviewer stands in for it.
  Future<void> _review(AgentGoalRun goal, GoalVerification checked) async {
    final reviewer =
        goal.checkerAgentId ??
        await _spaceCheckerOf(goal.workspaceId, goal.spaceId) ??
        goal.agentId;
    final wakeId = _store.newWakeId();
    final recorded = await _store.transition(goal, (g) {
      if (!_awaitsClaim(g)) {
        return null;
      }
      return g.copyWith(
        verification: checked.copyWith(
          reviewerAgentId: reviewer,
          reviewWakeId: wakeId,
          removeLastFailedFingerprint: true,
        ),
        updatedAt: _store.now(),
      );
    });
    if (recorded == null) {
      return;
    }
    await _insertRecordedReview(recorded, recorded.verification!, wakeId);
  }

  /// Writes the review wake [wakeId] that [v] already names, or stops the
  /// verification when it cannot be: no budget left, the reviewer cannot be
  /// woken, or the queue refused the wake.
  Future<void> _insertRecordedReview(
    AgentGoalRun goal,
    GoalVerification v,
    String wakeId,
  ) async {
    if (goalReviewCapMicros(goal) <= 0) {
      await _stop(
        goal,
        v,
        detail: GoalHoldDetails.cannotVerify,
        summary:
            'The goal spent its whole budget before the claim could be '
            'reviewed. Raise the budget or close the goal as done.',
      );
      return;
    }
    final reviewer = v.reviewerAgentId ?? goal.agentId;
    final why = await _unavailable(goal.workspaceId, reviewer);
    if (why != null) {
      await _stopChecker(goal, v, why);
      return;
    }
    final worker = await _agents.getById(goal.workspaceId, goal.agentId);
    final wake = await _store.insertReviewWake(
      goal,
      wakeId: wakeId,
      round: v.round,
      reviewerAgentId: reviewer,
      goalAgentName: worker?.name,
      outputSchema: goalReviewOutputSchema,
    );
    if (wake == null) {
      await _stopChecker(goal, v, 'the review wake was refused');
    }
  }

  /// Why [agentId] cannot review: gone, or not dispatchable; null when it
  /// can.
  Future<String?> _unavailable(String workspaceId, String agentId) async {
    final agent = await _agents.getById(workspaceId, agentId);
    if (agent == null) {
      return 'the reviewer no longer exists';
    }
    if (!agent.isDispatchable) {
      return 'the reviewer ${agent.name} is ${agent.lifecycleStatus.name}';
    }
    return null;
  }

  /// The review run [runId] ended ([status], [endReason], costing
  /// [costMicros]): a server stop leaves the claim pending (the review's
  /// wake is delivered again); a usage limit parks the review until the
  /// reset; a failure is asked again once; anything else is read for its
  /// verdict and applied.
  Future<void> _settleReview(
    AgentGoalRun goal, {
    required String runId,
    required RunStatus status,
    required RunEndReason endReason,
    required int costMicros,
    required DateTime? limitResetsAt,
  }) async {
    switch (endReason) {
      case RunEndReason.serverStopped:
        // Not the reviewer's answer. The cost counts; nothing starts during
        // a shutdown: the queue delivers the review's wake again at boot.
        await _store.transition(
          goal,
          (g) => _isReviewOf(g, runId)
              ? g.copyWith(
                  costMicros: g.costMicros + costMicros,
                  verification: g.verification!.copyWith(
                    removeReviewRunId: true,
                    at: _store.now(),
                  ),
                  updatedAt: _store.now(),
                )
              : null,
        );
        _reviews.remove(_runKey(goal.workspaceId, runId));
      case RunEndReason.usageLimit:
        await _parkReview(
          goal,
          runId: runId,
          costMicros: costMicros,
          reset: LimitPark.honouredReset(limitResetsAt, _store.now()),
        );
      case RunEndReason.error || RunEndReason.silence:
        await _askAgain(
          goal,
          runId: runId,
          costMicros: costMicros,
          why: 'the review run ended in ${endReason.wire}',
        );
      case RunEndReason.completed ||
          RunEndReason.budget ||
          RunEndReason.stoppedByUser:
        final verdict = await _verdictOf(
          goal,
          workspaceId: goal.workspaceId,
          runId: runId,
          status: status,
          endReason: endReason,
        );
        await _applyVerdict(goal, runId, verdict, costMicros: costMicros);
    }
  }

  /// Charges [costMicros] and stores [verdict] as review [runId]'s answer;
  /// decides it when the goal still waits on the claim (a paused goal
  /// decides at its resume, [recover]).
  Future<void> _applyVerdict(
    AgentGoalRun goal,
    String runId,
    GoalVerdict verdict, {
    required int costMicros,
  }) async {
    var decided = false;
    final applied = await _store.transition(goal, (g) {
      decided = false;
      if (!_isReviewOf(g, runId)) {
        return null;
      }
      final v = g.verification!.copyWith(
        reviewRunId: runId,
        verdict: verdict,
        at: _store.now(),
      );
      final charged = g.copyWith(
        costMicros: g.costMicros + costMicros,
        verification: v,
        updatedAt: _store.now(),
      );
      if (!_awaitsClaim(g)) {
        return charged;
      }
      decided = true;
      return _outcome(charged, v, verdict);
    });
    if (applied == null || !decided) {
      return;
    }
    await _announce(applied, verdict);
  }

  /// Applies the verdict review [runId] gave while the goal was paused.
  Future<void> _decideRecorded(AgentGoalRun goal, String runId) async {
    GoalVerdict? verdict;
    final applied = await _store.transition(goal, (g) {
      final v = g.verification;
      if (!_awaitsClaim(g) || v?.reviewRunId != runId || v?.verdict == null) {
        return null;
      }
      verdict = v!.verdict;
      return _outcome(g.copyWith(updatedAt: _store.now()), v, v.verdict!);
    });
    if (applied != null) {
      await _announce(applied, verdict);
    }
  }

  AgentGoalRun _outcome(
    AgentGoalRun charged,
    GoalVerification v,
    GoalVerdict verdict,
  ) => switch (verdict.verdict) {
    GoalVerdictOutcome.pass => charged.copyWith(
      status: AgentGoalStatus.completed,
      summary: v.claimSummary,
      removeHold: true,
      removeHoldDetail: true,
      removeHoldUntil: true,
      verification: v.copyWith(removeLastFailedFingerprint: true),
    ),
    GoalVerdictOutcome.cannotVerify => charged.copyWith(
      status: AgentGoalStatus.paused,
      hold: GoalHold.needsReview,
      holdDetail: GoalHoldDetails.cannotVerify,
    ),
    GoalVerdictOutcome.fail => _afterFailedRound(
      charged,
      v.copyWith(removeLastFailedFingerprint: true),
    ),
  };

  /// Review [runId] gave no answer of its own ([why]): asked again once
  /// (charging [costMicros]), then the claim cannot be verified.
  Future<void> _askAgain(
    AgentGoalRun goal, {
    required String runId,
    required int costMicros,
    required String why,
  }) async {
    final wakeId = _store.newWakeId();
    final verdict = _cannotVerify(why);
    var exhausted = false;
    var decided = false;
    final asked = await _store.transition(goal, (g) {
      decided = false;
      if (!_isReviewOf(g, runId)) {
        return null;
      }
      final v = g.verification!;
      final charged = g.copyWith(
        costMicros: g.costMicros + costMicros,
        updatedAt: _store.now(),
      );
      exhausted = v.reviewAsks >= GoalVerification.maxReviewAsks;
      if (exhausted) {
        final answered = v.copyWith(
          reviewRunId: runId,
          verdict: verdict,
          at: _store.now(),
        );
        decided = _awaitsClaim(g);
        return decided
            ? _outcome(
                charged.copyWith(verification: answered),
                answered,
                verdict,
              )
            : charged.copyWith(verification: answered);
      }
      return charged.copyWith(
        verification: v.copyWith(
          removeReviewRunId: true,
          reviewWakeId: wakeId,
          reviewAsks: v.reviewAsks + 1,
          at: _store.now(),
        ),
      );
    });
    _reviews.remove(_runKey(goal.workspaceId, runId));
    if (asked == null) {
      return;
    }
    if (exhausted) {
      if (decided) {
        await _announce(asked, verdict);
      }
      return;
    }
    if (!_awaitsClaim(asked)) {
      return; // Paused meanwhile: the resume writes the recorded wake.
    }
    await _store.say(
      asked,
      'Durable /goal: the review of the claim gave no answer ($why); asking '
      'the reviewer once more.',
    );
    await _insertRecordedReview(asked, asked.verification!, wakeId);
  }

  /// Writes a new review wake for [goal]'s claim in place of [stoppedWakeId],
  /// whose run the server stopped. Not an ask of the reviewer's
  /// ([GoalVerification.reviewAsks]): the reviewer never answered.
  Future<void> _askAfterStop(AgentGoalRun goal, String stoppedWakeId) async {
    final wakeId = _store.newWakeId();
    final asked = await _store.transition(goal, (g) {
      final v = g.verification;
      if (v == null ||
          !_awaitsClaim(g) ||
          v.reviewWakeId != stoppedWakeId ||
          v.verdict != null ||
          (v.reviewRunId?.isNotEmpty ?? false)) {
        return null;
      }
      return g.copyWith(
        verification: v.copyWith(reviewWakeId: wakeId, at: _store.now()),
        updatedAt: _store.now(),
      );
    });
    if (asked == null) {
      return;
    }
    await _store.say(
      asked,
      'Durable /goal: the server stopped during the review of the claim; '
      'asking the reviewer again.',
    );
    await _insertRecordedReview(asked, asked.verification!, wakeId);
  }

  /// Review [runId] reached its provider's usage limit: with a reset to
  /// honour and parks left, the review is asked again after the reset (a
  /// `limitReset` wake marked [WakeFields.review], the goal's `parkCount`
  /// one more); without a reset it is asked again once like a failure;
  /// with no park left the goal pauses for a person as a segment does
  /// (`needsReview`, [LimitPark.goalHoldDetail]), the claim kept for the
  /// review a Resume asks again (never `cannot_verify`: nobody judged it).
  Future<void> _parkReview(
    AgentGoalRun goal, {
    required String runId,
    required int costMicros,
    required DateTime? reset,
  }) async {
    if (reset == null) {
      await _askAgain(
        goal,
        runId: runId,
        costMicros: costMicros,
        why: 'the review run reached a usage limit with no reset to wait for',
      );
      return;
    }
    if (goal.parkCount >= LimitPark.maxGoalParks) {
      await _pauseOutOfParks(goal, runId: runId, costMicros: costMicros);
      return;
    }
    final v = goal.verification!;
    final reviewer = v.reviewerAgentId ?? goal.agentId;
    final log = await _runLogs.getById(goal.workspaceId, runId);
    final provider = LimitPark.providerLabel(
      adapter: log?.adapter,
      modelId: log?.modelId,
    );
    final worker = await _agents.getById(goal.workspaceId, goal.agentId);
    final wake = await _store.insertReviewLimitWake(
      goal,
      runId: runId,
      reset: reset,
      provider: provider,
      round: v.round,
      reviewerAgentId: reviewer,
      goalAgentName: worker?.name,
      outputSchema: goalReviewOutputSchema,
    );
    if (wake == null) {
      await _askAgain(
        goal,
        runId: runId,
        costMicros: costMicros,
        why: 'the review reached a usage limit and could not wait for it',
      );
      return;
    }
    final parked = await _store.transition(
      goal,
      (g) => !_isReviewOf(g, runId)
          ? null
          : g.copyWith(
              costMicros: g.costMicros + costMicros,
              parkCount: g.parkCount + 1,
              verification: g.verification!.copyWith(
                removeReviewRunId: true,
                reviewWakeId: wake.id,
                at: _store.now(),
              ),
              updatedAt: _store.now(),
            ),
    );
    _reviews.remove(_runKey(goal.workspaceId, runId));
    if (parked == null) {
      return;
    }
    await _store.say(
      parked,
      'Durable /goal: the review of the claim reached the $provider usage '
      'limit. It is asked again after the reset, at '
      '${LimitPark.stamp(LimitPark.resumeAt(reset))} (park '
      '${parked.parkCount} of ${LimitPark.maxGoalParks}).',
    );
  }

  Future<void> _pauseOutOfParks(
    AgentGoalRun goal, {
    required String runId,
    required int costMicros,
  }) async {
    // The review a Resume asks: recorded now, written by [recover] when the
    // goal verifies again (the checks already passed; not an ask of the
    // reviewer's, who never answered).
    final nextReview = _store.newWakeId();
    final paused = await _store.transition(
      goal,
      (g) => !_isReviewOf(g, runId)
          ? null
          : g.copyWith(
              status: AgentGoalStatus.paused,
              hold: GoalHold.needsReview,
              holdDetail: LimitPark.goalHoldDetail,
              removeHoldUntil: true,
              costMicros: g.costMicros + costMicros,
              verification: g.verification!.copyWith(
                removeReviewRunId: true,
                reviewWakeId: nextReview,
                at: _store.now(),
              ),
              updatedAt: _store.now(),
            ),
    );
    _reviews.remove(_runKey(goal.workspaceId, runId));
    if (paused == null) {
      return;
    }
    final summary =
        'The provider usage limit stopped the goal '
        '${paused.parkCount + 1} times, the last time during the review of '
        'its claim. Resume it to ask for the review again after the next '
        'reset.';
    await _store.say(paused, 'Durable /goal waits for a person: $summary');
    _store.publishSettled(paused, summary: summary);
  }

  /// A person cancelled the review's wake: the goal pauses as at a person's
  /// pause, the claim pending.
  Future<void> _pauseCancelled(AgentGoalRun goal) async {
    final paused = await _store.transition(
      goal,
      (g) => !_awaitsClaim(g)
          ? null
          : g.copyWith(
              status: AgentGoalStatus.paused,
              hold: GoalHold.byPerson,
              holdDetail: GoalHoldDetails.claimPending,
              removeHoldUntil: true,
              updatedAt: _store.now(),
            ),
    );
    if (paused == null) {
      return;
    }
    await _store.cancelWakes(paused, 'goal_stopped');
    await _store.say(
      paused,
      "Durable /goal paused: its review's wake was cancelled. Resume it to "
      'verify the claim again.',
    );
  }

  /// The reviewer cannot be woken ([why]): the verification stops for a
  /// person, who picks another checker and resumes.
  Future<void> _stopChecker(
    AgentGoalRun goal,
    GoalVerification claim,
    String why,
  ) => _stop(
    goal,
    claim,
    detail: GoalHoldDetails.checkerUnavailable,
    summary:
        'The review of the claim could not start ($why). Pick another '
        'checker and resume the goal to verify the claim again, or close it '
        'as done.',
  );

  /// Pauses [goal] for a person (`hold: needsReview`, [detail]) with
  /// [claim] kept as its verification, and tells them.
  Future<void> _stop(
    AgentGoalRun goal,
    GoalVerification claim, {
    required String detail,
    required String summary,
  }) async {
    final stopped = await _store.transition(goal, (g) {
      if (!_awaitsClaim(g)) {
        return null;
      }
      return g.copyWith(
        status: AgentGoalStatus.paused,
        hold: GoalHold.needsReview,
        holdDetail: detail,
        verification: claim,
        updatedAt: _store.now(),
      );
    });
    if (stopped == null) {
      return;
    }
    await _store.say(stopped, 'Durable /goal waits for a person: $summary');
    _store.publishSettled(stopped, summary: summary);
  }

  /// Runs [work] for [workspaceId] when it gets one of the
  /// [maxConcurrentChecks] slots ([_passCheckSlots]).
  Future<T> _withCheckSlot<T>(
    String workspaceId,
    Future<T> Function() work,
  ) async {
    final turn = Completer<void>();
    _checkWaiters.add((workspaceId: workspaceId, turn: turn));
    _passCheckSlots();
    await turn.future;
    try {
      return await work();
    } finally {
      _checksRunning--;
      final held = (_checksByWorkspace[workspaceId] ?? 1) - 1;
      if (held <= 0) {
        _checksByWorkspace.remove(workspaceId);
      } else {
        _checksByWorkspace[workspaceId] = held;
      }
      _passCheckSlots();
    }
  }

  /// Gives free check slots to waiting checks, round-robin by workspace
  /// from the one after the workspace served last. A workspace already
  /// running [maxChecksPerWorkspace] checks gets another only while no
  /// other workspace's check waits.
  void _passCheckSlots() {
    while (_checksRunning < maxConcurrentChecks && _checkWaiters.isNotEmpty) {
      final order = <String>[];
      for (final waiter in _checkWaiters) {
        if (!order.contains(waiter.workspaceId)) {
          order.add(waiter.workspaceId);
        }
      }
      final last = _lastCheckWorkspace;
      final start = last == null ? 0 : (order.indexOf(last) + 1) % order.length;
      String? next;
      for (var i = 0; i < order.length; i++) {
        final ws = order[(start + i) % order.length];
        if (order.length == 1 ||
            (_checksByWorkspace[ws] ?? 0) < maxChecksPerWorkspace) {
          next = ws;
          break;
        }
      }
      if (next == null) {
        return;
      }
      final at = _checkWaiters.indexWhere((w) => w.workspaceId == next);
      final waiter = _checkWaiters.removeAt(at);
      _checksRunning++;
      _checksByWorkspace[next] = (_checksByWorkspace[next] ?? 0) + 1;
      _lastCheckWorkspace = next;
      waiter.turn.complete();
    }
  }

  /// [g] after a failed round with [verification] stored: a round more,
  /// and after the last one a pause for a person.
  AgentGoalRun _afterFailedRound(
    AgentGoalRun g,
    GoalVerification verification,
  ) {
    final rounds = g.verificationRounds + 1;
    if (rounds >= goalMaxVerificationRounds) {
      return g.copyWith(
        status: AgentGoalStatus.paused,
        hold: GoalHold.needsReview,
        holdDetail: GoalHoldDetails.verificationFailed,
        verificationRounds: rounds,
        verification: verification,
      );
    }
    return g.copyWith(
      verificationRounds: rounds,
      verification: verification,
      removeHold: true,
      removeHoldDetail: true,
      removeHoldUntil: true,
    );
  }

  /// Tells the conversation and the person what a verification came to,
  /// and starts the worker's next segment after a failed round.
  Future<void> _announce(AgentGoalRun goal, GoalVerdict? verdict) async {
    final v = goal.verification;
    if (goal.status == AgentGoalStatus.completed) {
      final reviewer = v?.reviewerAgentId;
      final who = reviewer == null || reviewer == goal.agentId
          ? 'itself'
          : (await _agents.getById(goal.workspaceId, reviewer))?.name ??
                'its checker';
      final summary = v?.claimSummary ?? '';
      await _store.say(
        goal,
        'Durable /goal completed, verified by $who: $summary',
      );
      _store.publishSettled(goal, summary: summary);
      return;
    }
    if (goal.status == AgentGoalStatus.paused &&
        goal.hold == GoalHold.needsReview) {
      final summary = goal.holdDetail == GoalHoldDetails.cannotVerify
          ? 'The reviewer could not verify the claim. Decide: continue, edit '
                'the contract, or close the goal as done.'
          : 'The claim failed verification $goalMaxVerificationRounds times. '
                'Decide: continue, edit the contract, or close the goal as '
                'done.';
      await _store.say(goal, 'Durable /goal waits for a person: $summary');
      _store.publishSettled(goal, summary: summary);
      return;
    }
    if (goal.status != AgentGoalStatus.active || v == null) {
      return;
    }
    await _store.say(
      goal,
      'The completion claim did not pass verification (round ${v.round} of '
      '$goalMaxVerificationRounds); the agent continues.',
    );
    await _store.insertSegmentWake(goal, verificationRound: v.round);
  }

  Future<GoalVerdict> _verdictOf(
    AgentGoalRun goal, {
    required String workspaceId,
    required String runId,
    required RunStatus status,
    required RunEndReason endReason,
  }) async {
    if (status != RunStatus.completed || endReason != RunEndReason.completed) {
      return _cannotVerify(
        'the review run ended without a verdict (${endReason.wire})',
      );
    }
    final log = await _runLogs.getById(workspaceId, runId);
    final output = log?.outputJson;
    if (output == null) {
      return _cannotVerify('the reviewer submitted no verdict');
    }
    return parseGoalReviewOutput(
      output,
      criteria: goal.contract?.criteria ?? const [],
    );
  }

  static GoalVerdict _cannotVerify(String why) =>
      GoalVerdict(verdict: GoalVerdictOutcome.cannotVerify, concerns: [why]);

  /// The goal whose claim's review is [runId]: one this verifier saw
  /// dispatched, or a held goal whose verification names the run.
  Future<AgentGoalRun?> _goalReviewedBy(
    String workspaceId,
    String runId,
  ) async {
    final goalId = _reviews[_runKey(workspaceId, runId)];
    if (goalId != null) {
      final goal = await _store.goals.getById(workspaceId, goalId);
      if (goal != null) {
        return goal;
      }
    }
    for (final goal in await _store.goals.listHeld(workspaceId)) {
      if (goal.verification?.reviewRunId == runId) {
        _remember(workspaceId, runId, goal.id);
        return goal;
      }
    }
    return null;
  }

  /// Whether [g]'s verification still waits for review [runId]'s answer.
  bool _isReviewOf(AgentGoalRun g, String runId) {
    final v = g.verification;
    if (v == null || v.verdict != null) {
      return false;
    }
    final recorded = v.reviewRunId;
    return recorded == runId ||
        ((recorded == null || recorded.isEmpty) &&
            _reviews[_runKey(g.workspaceId, runId)] == g.id);
  }

  static bool _awaitsClaim(AgentGoalRun g) =>
      g.status == AgentGoalStatus.active &&
      g.hold == GoalHold.verifying &&
      g.verification != null;

  /// A run id is looked up only with its workspace.
  static String _runKey(String workspaceId, String runId) =>
      '$workspaceId\u0000$runId';

  void _remember(String workspaceId, String runId, String goalId) {
    _reviews[_runKey(workspaceId, runId)] = goalId;
    while (_reviews.length > _maxRemembered) {
      _reviews.remove(_reviews.keys.first);
    }
  }
}
