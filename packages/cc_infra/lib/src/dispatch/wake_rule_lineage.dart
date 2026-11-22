part of 'wake_rule_service.dart';

/// Where a lineage stands, as `list_wakes` and the Schedules wire show it on
/// each of its rules: its root, the runs it has left and when it ends.
typedef WakeLineageStatus = ({
  String rootRuleId,
  int runsLeft,
  DateTime endsAt,
});

/// The lineage a run is in: its root, and the rule whose own wake started
/// the run (null when a wake that carries the lineage started it: a peer's
/// message or reply, a ticket's completion, a limit reset; or another run's
/// tool call did, by a direct dispatch).
typedef _Lineage = ({WakeRule? parent, WakeRule root});

/// The lineage half of [WakeRuleService] (plan section 9, "Chains"): a rule
/// an agent makes in a run that a wake of a lineage started belongs to that
/// lineage. A lineage travels with the work it starts: every wake a run in
/// it causes carries its root ([WakeFields.lineageRoot], written by the
/// queue, [WakeQueueService.lineageRootOfRuns]), so a run that wake starts
/// is in it too. The lineage ends when its root does (`expiresAt`), and its
/// runs and cost count against the root's caps (its `maxRuns`, or
/// [WakeRuleBounds.lineageMaxRuns]; its cost cap). A person extends it only
/// by changing the root. Lineages exist only among agent-made rules: a
/// person's own rule and message, and a goal's rules and wakes, start
/// none. A run a person's rule started is a person's run (decision
/// xxxviii): a rule an agent sets in it is a new root with its own caps,
/// the wakes it causes carry no root, and nothing an agent does ends the
/// person's rule through a lineage.
extension on WakeRuleService {
  /// The lineage run [runId] is in: from each wake that started or reached
  /// it, a rule's own wake (that rule's root) or a wake that carries a root.
  /// When they name two lineages, the older root's (created first; the
  /// smaller id on a tie). Null for none, a goal-bound rule's (the goal
  /// ends its rules) or a person's rule's (its run is a person's run).
  ///
  /// A run with no wake that another run's tool call started by a direct
  /// dispatch (a reviewer `dispatch_reviewers` started, a team leader an
  /// agent's `assign_ticket` routed to) is in the lineage of the run that
  /// started it, with no rule of its own ([WakeRulePorts.startedByRun]; at
  /// most [_startedByHops] such steps back).
  Future<_Lineage?> _lineageOfRun(
    String ws,
    String runId, {
    int hops = 0,
  }) async {
    final wakeIds = await _ports.runWakeIds(ws, runId);
    if (wakeIds.isEmpty) {
      final from = hops < _startedByHops
          ? await _ports.startedByRun(ws, runId)
          : null;
      if (from == null || from == runId) {
        return null;
      }
      final lineage = await _lineageOfRun(ws, from, hops: hops + 1);
      return lineage == null ? null : (parent: null, root: lineage.root);
    }
    _Lineage? best;
    for (final wakeId in wakeIds) {
      final wake = await _wakes.getById(ws, wakeId);
      if (wake == null || wake.workspaceId != ws) {
        continue;
      }
      final ruleId = wake.detail.ruleId;
      final carried = wake.detail.fields[WakeFields.lineageRoot];
      WakeRule? parent;
      String? rootId;
      if (ruleId != null &&
          (_isRuleReason(wake.reason) ||
              wake.reason == WakeReason.limitReset)) {
        parent = await _rules.getById(ws, ruleId);
        if (parent == null ||
            parent.goalId != null ||
            parent.origin == WakeRuleOrigin.person) {
          continue;
        }
        rootId = parent.rootRuleId ?? parent.id;
      } else if (carried is String && carried.isNotEmpty) {
        rootId = carried;
      } else {
        continue;
      }
      final root = rootId == parent?.id
          ? parent
          : await _rules.getById(ws, rootId);
      if (root == null ||
          root.workspaceId != ws ||
          root.goalId != null ||
          root.origin == WakeRuleOrigin.person) {
        continue;
      }
      if (best == null || _older(root, best.root)) {
        best = (parent: parent, root: root);
      } else if (best.parent == null && best.root.id == root.id) {
        best = (parent: parent, root: root);
      }
    }
    return best;
  }

  /// The root id of the oldest lineage the runs [runIds] are in, for the
  /// queue to put on a wake they cause.
  Future<String?> _lineageRootOfRuns(String ws, List<String> runIds) async {
    WakeRule? oldest;
    for (final runId in runIds) {
      final root = (await _lineageOfRun(ws, runId))?.root;
      if (root != null && (oldest == null || _older(root, oldest))) {
        oldest = root;
      }
    }
    return oldest?.id;
  }

  static bool _older(WakeRule a, WakeRule b) =>
      a.id != b.id &&
      (a.createdAt.isBefore(b.createdAt) ||
          (a.createdAt.isAtSameMomentAs(b.createdAt) &&
              a.id.compareTo(b.id) < 0));

  /// Refuses a rule that would join [lineage] after it ended (its expiry
  /// passed, its root ended: [_lineageClosed]; or a one-off set after its
  /// expiry), ending the rule that tried, if it is still active, once.
  Future<void> _requireLineageOpen(
    _Lineage lineage,
    WakeTrigger trigger,
    DateTime now,
  ) async {
    final root = lineage.root;
    final ended = _lineageClosed(root, now);
    if (!ended &&
        !(trigger is OnceAt && !trigger.at.isBefore(root.expiresAt))) {
      return;
    }
    final parent = lineage.parent ?? root;
    if (ended) {
      await end(parent.workspaceId, parent.id, WakeRuleEndReason.expired);
    }
    throw WakeRuleService._refuse(
      WakeRuleRefusals.lineageEnded,
      root.status == WakeRuleStatus.ended &&
              root.endReason != WakeRuleEndReason.fired
          ? 'This chain of wakes (it started with wake ${root.id}) ended '
                'when that wake ended; nothing set from it fires later.'
          : _lineageEndedMessage(root, ended ? 'ended' : 'ends'),
    );
  }

  /// Ends the rule that tried to extend a lineage past its caps, once (the
  /// transition happens at most once, and its person is told through
  /// `wake_rule_ended`), and refuses the new rule.
  Future<Never> _lineageSpent(_Lineage lineage) async {
    final root = lineage.root;
    final spent = await _rules.lineageTotals(root.workspaceId, root.id);
    // The rule whose wake started the run ends; a run a carried wake
    // started has none, and the root keeps its own state.
    final parent = lineage.parent;
    if (parent != null) {
      await end(
        parent.workspaceId,
        parent.id,
        spent.costMicros >= root.costCapMicros
            ? WakeRuleEndReason.costCap
            : WakeRuleEndReason.runCap,
      );
    }
    throw WakeRuleService._refuse(
      WakeRuleRefusals.lineageEnded,
      'This chain of wakes (it started with wake ${root.id}) spent its '
      '${_lineageRunCapOf(root)} runs or its cost cap, so it makes no more '
      'wakes. A person can raise the limits of ${root.id}.',
    );
  }

  /// [root] ended: a lineage it roots ends with it, unless it ended by
  /// firing (a one-off root; its lineage runs to its expiry). Each rule of
  /// the lineage that has not ended ends with the root's reason when that
  /// is a cap or the expiry, and as `cancelled` otherwise (a person deleted
  /// the root, its person left, its row could not be read), each with its
  /// own row and [WakeRuleEnded]. A goal's or a person's rule roots none.
  Future<void> _endLineageOf(WakeRule root, WakeRuleEndReason reason) async {
    if (root.rootRuleId != null ||
        root.goalId != null ||
        root.origin == WakeRuleOrigin.person ||
        reason == WakeRuleEndReason.fired) {
      return;
    }
    final childReason = switch (reason) {
      WakeRuleEndReason.expired ||
      WakeRuleEndReason.runCap ||
      WakeRuleEndReason.costCap => reason,
      _ => WakeRuleEndReason.cancelled,
    };
    for (final child in await _rules.listByRoot(root.workspaceId, root.id)) {
      if (child.workspaceId == root.workspaceId &&
          child.status != WakeRuleStatus.ended) {
        await end(root.workspaceId, child.id, childReason);
      }
    }
  }

  static String _lineageEndedMessage(WakeRule root, String verb) =>
      'This chain of wakes (it started with wake ${root.id}) $verb at '
      '${root.expiresAt.toUtc().toIso8601String()}; nothing set from it '
      'fires later. A person can extend ${root.id}.';

  /// The runs [rule]'s lineage has left: for a rule of a lineage, the
  /// root's cap (or the lineage default) less every rule's runs; for a root
  /// with a run cap, that cap less the same. A person's rule is held to its
  /// own `maxRuns` alone (it roots no lineage): that less its own runs. Null
  /// for a rule held to its own `maxRuns` alone (a goal's, or a person's
  /// with none).
  Future<int?> _lineageRunsLeft(WakeRule rule) async {
    if (rule.goalId != null) {
      return null;
    }
    if (rule.origin == WakeRuleOrigin.person && rule.rootRuleId == null) {
      final own = rule.maxRuns;
      return own == null ? null : own - rule.runCount;
    }
    final rootId = rule.rootRuleId;
    final root = rootId == null
        ? rule
        : await _rules.getById(rule.workspaceId, rootId);
    final cap = root == null
        ? WakeRuleBounds.lineageMaxRuns
        : rootId == null
        ? root.maxRuns
        : _lineageRunCapOf(root);
    if (cap == null) {
      return null;
    }
    final spent = await _rules.lineageTotals(
      rule.workspaceId,
      rootId ?? rule.id,
    );
    return cap - spent.runs;
  }

  /// Whether the lineage [rule] belongs to (as a member or as its root)
  /// spent its cost cap (the root's). A rule in no lineage is held to its
  /// own cap alone.
  Future<bool> _lineageCostSpent(WakeRule rule) async {
    final left = await _lineageCostLeft(rule);
    return left != null && left <= 0;
  }

  /// What the lineage [rule] belongs to has left of its cost cap: the
  /// root's cap less the cost of every run the lineage paid for (its rules'
  /// runs, and the runs wakes carrying it started, which count on the
  /// root's row: [_chargeCarriedRun]). Null for a rule in no lineage (a
  /// goal's, a person's).
  Future<int?> _lineageCostLeft(WakeRule rule) async {
    if (rule.goalId != null ||
        (rule.origin == WakeRuleOrigin.person && rule.rootRuleId == null)) {
      return null;
    }
    final rootId = rule.rootRuleId ?? rule.id;
    final root = rootId == rule.id
        ? rule
        : await _rules.getById(rule.workspaceId, rootId);
    final spent = await _rules.lineageTotals(rule.workspaceId, rootId);
    return (root?.costCapMicros ?? rule.costCapMicros) - spent.costMicros;
  }

  /// A run's cost cap for [rule]'s next wake: its own ([_perRunCap]), at
  /// most what its lineage has left (never below 1 micro-dollar).
  Future<int> _perRunCapInLineage(WakeRule rule) async {
    final own = _perRunCap(rule);
    final left = await _lineageCostLeft(rule);
    if (left == null || left >= own) {
      return own;
    }
    return left < 1 ? 1 : left;
  }

  /// A run that settled, that no rule's own wake started and that a
  /// lineage reaches (wakes carrying it started the run: a peer's message
  /// or reply, a ticket's completion; or a run in it started this one by a
  /// direct dispatch): its cost counts against the lineage, on its root's
  /// row (the root's cap is the lineage's), and the root ends when the
  /// lineage reached that cap. A person's run that drained such a wake is
  /// the person's.
  Future<void> _chargeCarriedRun(AgentRunSettled event, DateTime now) async {
    final reason = event.wakeReason;
    if (reason == null || reason == WakeReason.userMessage) {
      return;
    }
    final ws = event.workspaceId;
    final lineage = await _lineageOfRun(ws, event.runId);
    if (lineage == null || lineage.parent != null) {
      return;
    }
    final rootId = lineage.root.id;
    await _rules.addCost(
      ws,
      id: rootId,
      micros: event.costMicros < 0 ? 0 : event.costMicros,
      now: now,
    );
    final root = await _rules.getById(ws, rootId);
    if (root != null && root.isActive && await _lineageCostSpent(root)) {
      await end(ws, rootId, WakeRuleEndReason.costCap);
    }
  }

  /// Admission of a wake that carries a lineage and is no rule's own: not
  /// delivered once the lineage ended ([_lineageClosed]) or spent
  /// its cost cap (`budget_blocked`, the existing "a budget blocks a run"
  /// row); else a run it starts spends at most what the lineage has left.
  /// Pushed into the agent's live run it is part of that run, so it is let
  /// through without a cap of its own (a capped wake is never pushed).
  Future<WakeAdmission> _admitCarried(Wake wake, DateTime now) async {
    final rootId = wake.detail.fields[WakeFields.lineageRoot];
    if (wake.detail.ruleId != null || rootId is! String || rootId.isEmpty) {
      return const WakeAdmission.admit();
    }
    final root = await _rules.getById(wake.workspaceId, rootId);
    if (root == null ||
        root.workspaceId != wake.workspaceId ||
        root.goalId != null ||
        root.origin == WakeRuleOrigin.person) {
      return const WakeAdmission.admit();
    }
    final left = await _lineageCostLeft(root);
    if (_lineageClosed(root, now) || left == null || left <= 0) {
      return const WakeAdmission.skip(WakeStateReasons.budgetBlocked);
    }
    if (await _ports.agentBusy(
      wake.workspaceId,
      wake.conversationId,
      wake.agentId,
    )) {
      return const WakeAdmission.admit();
    }
    return WakeAdmission.admitWithin(left);
  }
}

/// Whether the lineage rooted at [root] has ended at [now]: its root's
/// expiry passed, or its root ended for any reason but having fired (a
/// one-off root that fired leaves its lineage running to its expiry). A
/// paused root closes nothing.
bool _lineageClosed(WakeRule root, DateTime now) =>
    !root.expiresAt.isAfter(now) ||
    (root.status == WakeRuleStatus.ended &&
        root.endReason != WakeRuleEndReason.fired);

/// How many direct dispatches back the lineage lookup follows a run started
/// with no wake.
const int _startedByHops = 8;

/// The run cap the lineage rooted at [root] has in all.
int _lineageRunCapOf(WakeRule root) =>
    root.maxRuns ?? WakeRuleBounds.lineageMaxRuns;
