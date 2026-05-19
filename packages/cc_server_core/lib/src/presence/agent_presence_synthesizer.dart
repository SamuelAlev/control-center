import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:cc_host/cc_host.dart';

/// Synthesizes agent entries for the presence lane (PRD 16 §2/§3
/// clarification: agents have no client, so their presence comes from the
/// server's own run/lifecycle signals, on the SAME roster as humans).
///
/// Exactly ONE entry per `(workspace, agent)` is published per pass, decided by
/// a single representative run (live beats lingering-done, then newest) — an
/// agent with several concurrent runs must not have its state, locus and cost
/// decided by whichever run happened to be written last.
///
/// Sources:
///  * active run logs → `running` (with live running cost) and, briefly,
///    `done` after completion;
///  * the pending-approval registry → `blocked` (the fail-closed gate is
///    visible on the roster, not buried in a panel);
///  * the run's space AND conversation → a [SpaceLocus], so "where is this
///    agent working" is a roster fact precise enough to follow.
///
/// A 10s re-publish heartbeat keeps entries alive through long quiet tool
/// calls; entries expire from the hub like any other participant when a run
/// vanishes.
class AgentPresenceSynthesizer {
  /// Creates a synthesizer. Call [start].
  AgentPresenceSynthesizer({
    required this.hub,
    required this.runLogs,
    required this.agents,
    this.confirmations,
    this.doneLinger = const Duration(seconds: 20),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// The presence hub to publish into.
  final PresenceHub hub;

  /// CROSS-WORKSPACE BY DESIGN: the synthesizer fans presence out per
  /// workspace from the global run-log stream (like the startup reconcilers);
  /// each published entry lands only on its own workspace's roster.
  final AgentRunLogRepository runLogs;

  /// Names for the roster (denormalized into each entry).
  final AgentRepository agents;

  /// Pending fail-closed approvals (→ `blocked` state). Optional in tests.
  final PendingConfirmationRegistry? confirmations;

  /// How long a completed run keeps its agent on the roster as `done`.
  final Duration doneLinger;

  final DateTime Function() _now;

  StreamSubscription<List<AgentRunLog>>? _runsSub;
  StreamSubscription<List<PendingConfirmation>>? _confSub;
  Timer? _heartbeat;

  List<AgentRunLog> _latestRuns = const [];
  Set<String> _blockedSpaces = const {};
  final Map<String, String> _agentNames = {};

  /// The `(workspaceId, agentId)` pairs currently published, so a vanished
  /// run is removed promptly instead of waiting for hub expiry.
  final Set<String> _published = {};

  /// A pass is in flight; see [_publish].
  bool _publishing = false;

  /// A trigger arrived while a pass was in flight — run exactly one more.
  bool _rerunRequested = false;

  /// How many recent runs the synthesizer observes. Presence only cares about
  /// runs that are currently active or completed within [doneLinger], which
  /// are by definition among the newest rows — the unbounded `watchAll` would
  /// re-materialize (and retain) the entire run history on every run-log
  /// write for the lifetime of the server.
  static const int recentRunWindow = 500;

  /// Begins synthesizing.
  Future<void> start() async {
    _runsSub = runLogs.watchRecent(recentRunWindow).listen((runs) {
      _latestRuns = runs;
      unawaited(_publish());
    });
    _confSub = confirmations?.pending.listen((pending) {
      // Approvals are raised against the SPACE, so the blocked set is keyed
      // by space and matched against the run's space. It used to compare a
      // confirmation's id with `run.conversationId`, which only lined up while
      // a conversation's id WAS its space's id.
      _blockedSpaces = {
        for (final p in pending)
          if (p.request.spaceId.isNotEmpty) p.request.spaceId,
      };
      unawaited(_publish());
    });
    _heartbeat = Timer.periodic(
      PresenceCadence.heartbeat,
      (_) => unawaited(_publish()),
    );
  }

  /// Runs [_publishOnce], never concurrently.
  ///
  /// Passes are triggered from three independent sources (the run-log stream,
  /// the approval registry, the heartbeat) and [_publishOnce] awaits inside its
  /// loop, so two passes could interleave their `publishAgent` calls. With the
  /// old per-run publishing that made an agent's roster entry depend on which
  /// pass happened to write last — its locus flip-flopped between the
  /// conversations of its concurrent runs and follow-mode (which rides the
  /// locus) navigated the follower back and forth for as long as the agent ran.
  /// Serializing collapses overlapping triggers into one trailing pass.
  Future<void> _publish() async {
    if (_publishing) {
      _rerunRequested = true;
      return;
    }
    _publishing = true;
    try {
      do {
        _rerunRequested = false;
        await _publishOnce();
      } while (_rerunRequested);
    } finally {
      _publishing = false;
    }
  }

  Future<void> _publishOnce() async {
    final now = _now();
    // ONE entry per (workspace, agent). The roster answers "what is this agent
    // doing *now*", so a single representative run decides its state, locus and
    // cost — see [_outranks]. Publishing every eligible run and letting the last
    // write win meant the run-log stream's order decided the winner: it arrives
    // newest-first, so the OLDEST eligible run won. A run that had just
    // finished elsewhere could hold the roster's locus (and report `done` with
    // its cost) while the agent was live in another conversation.
    final representative = <String, AgentRunLog>{};
    for (final run in _latestRuns) {
      final workspaceId = run.workspaceId;
      if (workspaceId == null || workspaceId.isEmpty) {
        continue;
      }
      if (!_isEligible(run, now)) {
        continue;
      }
      final key = '$workspaceId|${run.agentId}';
      final incumbent = representative[key];
      if (incumbent == null || _outranks(run, incumbent)) {
        representative[key] = run;
      }
    }

    final next = <String>{};
    for (final entry in representative.entries) {
      final run = entry.value;
      final state = !_isLive(run)
          ? AgentLiveState.done
          : (run.spaceId != null && _blockedSpaces.contains(run.spaceId))
          ? AgentLiveState.blockedOnApproval
          : AgentLiveState.running;
      // Non-null: only runs with a workspace become representatives.
      final name = await _nameOf(run.workspaceId!, run.agentId);
      hub.publishAgent(
        // Non-null: only runs with a workspace become representatives.
        workspaceId: run.workspaceId!,
        agentId: run.agentId,
        displayName: name,
        status: AgentLiveStatus(
          state: state,
          costUsd: run.cost.estimatedCostCents / 100,
        ),
        // The SPACE is what a route names; the conversation only picks which
        // tab inside it to focus. Publishing the conversation id AS the space
        // id sent every follower to `/spaces/<conversationId>` — a space that
        // does not exist — so clicking a running agent on the presence rail
        // went nowhere. The two ids are always distinct; there is deliberately
        // no `?? conversationId` fallback for a run with no space, because
        // that is exactly the substitution that failed silently.
        locus: (run.spaceId?.isNotEmpty ?? false)
            ? SpaceLocus(
                spaceId: run.spaceId!,
                conversationId: run.conversationId,
              )
            : null,
      );
      next.add(entry.key);
    }
    // Prompt removal for agents whose runs ended past the linger window.
    for (final key in _published.difference(next)) {
      final parts = key.split('|');
      hub.remove(parts[0], 'agent:${parts[1]}');
    }
    _published
      ..clear()
      ..addAll(next);
  }

  /// Whether [run] is currently in flight.
  bool _isLive(AgentRunLog run) =>
      run.status == RunStatus.running || run.status == RunStatus.pending;

  /// Whether [run] belongs on the roster at [now]: in flight, or finished
  /// within [doneLinger].
  bool _isEligible(AgentRunLog run, DateTime now) =>
      _isLive(run) ||
      (run.status == RunStatus.completed &&
          run.completedAt != null &&
          now.difference(run.completedAt!) < doneLinger);

  /// Whether [candidate] should represent the agent instead of [incumbent]: a
  /// live run always beats a lingering finished one, then the most recently
  /// started wins, with the run id as a final tiebreak. Total and independent
  /// of iteration order, so every pass over the same runs publishes the same
  /// entry (a flapping locus is what drove follow-mode in circles).
  bool _outranks(AgentRunLog candidate, AgentRunLog incumbent) {
    final candidateLive = _isLive(candidate);
    if (candidateLive != _isLive(incumbent)) {
      return candidateLive;
    }
    if (candidate.startedAt != incumbent.startedAt) {
      return candidate.startedAt.isAfter(incumbent.startedAt);
    }
    return candidate.id.compareTo(incumbent.id) > 0;
  }

  Future<String> _nameOf(String workspaceId, String agentId) async {
    final cached = _agentNames[agentId];
    if (cached != null) {
      return cached;
    }
    final agent = await agents.getById(workspaceId, agentId);
    final name = agent?.name ?? agentId;
    _agentNames[agentId] = name;
    return name;
  }

  /// Stops synthesizing (published entries expire from the hub naturally).
  Future<void> stop() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    await _runsSub?.cancel();
    await _confSub?.cancel();
  }
}
