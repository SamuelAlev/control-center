import 'dart:async';

import 'package:cc_domain/core/domain/events/digest_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/entities/improvement_proposal.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/unattended_policy.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cron_scheduler.dart';
import 'package:cc_domain/features/pipelines/domain/services/schedule_spec.dart';

/// A held wake, as the digest lists it.
typedef HeldWakeView = ({
  String id,
  String spaceId,
  String conversationId,
  String agentId,
  String? requestedByUserId,
  String summary,
});

/// A request that waits on a person, as the digest lists it.
typedef PendingRequestDigestView = ({
  String id,
  String summary,
  String agentId,
  String? requestedByUserId,
  String? goalId,
  String? spaceId,
  String? conversationId,
  DateTime deadline,
});

/// What [WaitingDigestService] reads. Every read takes the workspace.
class WaitingDigestPorts {
  /// Creates the ports.
  const WaitingDigestPorts({
    required this.workspaceIds,
    required this.readSetting,
    required this.writeSetting,
    required this.timeZoneOf,
    required this.heldGoals,
    required this.heldWakes,
    required this.pendingProposals,
    required this.pendingRequests,
    required this.goalById,
    required this.admins,
    required this.isMember,
    required this.canReadSpace,
    required this.stopping,
  });

  /// Every live workspace.
  ///
  /// CROSS-WORKSPACE BY DESIGN: the digest timer visits each workspace; every
  /// read after this one is scoped to the workspace it visits.
  final Future<List<String>> Function() workspaceIds;

  /// A workspace setting's stored text, or null.
  final Future<String?> Function(String workspaceId, String key) readSetting;

  /// Writes a workspace setting.
  final Future<void> Function(String workspaceId, String key, String value)
  writeSetting;

  /// The workspace's time zone (`wake_rule_limits.default_time_zone`, UTC
  /// when unset).
  final Future<String> Function(String workspaceId) timeZoneOf;

  /// The workspace's goals held on `hold`.
  final Future<List<AgentGoalRun>> Function(String workspaceId, GoalHold hold)
  heldGoals;

  /// The workspace's held wakes.
  final Future<List<HeldWakeView>> Function(String workspaceId) heldWakes;

  /// The workspace's improvement proposals still waiting for a decision.
  final Future<List<ImprovementProposal>> Function(String workspaceId)
  pendingProposals;

  /// The workspace's approvals and questions of runs the server started
  /// that wait with a deadline now (`UnattendedRequests.pendingIn`).
  final Future<List<PendingRequestDigestView>> Function(String workspaceId)
  pendingRequests;

  /// A goal of the workspace, or null.
  final Future<AgentGoalRun?> Function(String workspaceId, String goalId)
  goalById;

  /// The workspace's admins and owner: who gets what no person asked for.
  final Future<List<String>> Function(String workspaceId) admins;

  /// Whether `userId` is a member of the workspace now.
  final Future<bool> Function(String workspaceId, String userId) isMember;

  /// Whether `userId` may read space `spaceId`.
  final Future<bool> Function(String workspaceId, String userId, String spaceId)
  canReadSpace;

  /// Whether the server is shutting down.
  final bool Function() stopping;
}

/// The once-a-day digest of what is waiting (plan section 12, "One digest
/// a day lists what is waiting"): for each person and workspace, the goals
/// in `needsReview` or `hold: person`, the held wakes, the improvement
/// proposals still waiting for a decision and the approvals and questions
/// of runs the server started (goal or not), sent through the notification
/// feed and Web Push as [WaitingDigest] at a fixed local hour
/// ([UnattendedPolicy.digestHour], default 09:00 in the workspace's time
/// zone).
///
/// A plain timer checks every [tick]. Each workspace's slot is the latest
/// daily `0 <hour> * * *` slot at or before now, found with the schedules'
/// own slot arithmetic ([PipelineCronScheduler.nextSlotAfter]) in the
/// workspace's zone. A slot is evaluated once: its local day is written to
/// [daySettingKey] before anything is published, so a restart never sends
/// it twice and something that starts waiting at 11:00 waits for the next
/// day's digest. Nothing is published when nothing waits. A server that was
/// down at the hour sends that day's digest when it comes back the same
/// local day; a later day's hour replaces it.
///
/// Who receives what: an item belongs to the person it acts for (a goal's,
/// a wake's or a request's run's or, through its goal, a proposal's
/// requester); a request of a goal already listed is not listed again; an
/// item no person asked for, or whose person has left the workspace, goes
/// to the workspace's admins. Each recipient sees only items in spaces they
/// may read.
class WaitingDigestService {
  /// Creates the service. `scheduler` carries the zone converters.
  WaitingDigestService({
    required DomainEventBus eventBus,
    required this._ports,
    required this._scheduler,
    required this._toLocal,
    DateTime Function()? now,
    this.tick = const Duration(minutes: 1),
  }) : _bus = eventBus,
       _now = now ?? DateTime.now;

  final DomainEventBus _bus;
  final WaitingDigestPorts _ports;
  final PipelineCronScheduler _scheduler;
  final DateTime Function(DateTime utc, String timeZone) _toLocal;
  final DateTime Function() _now;

  /// How often the timer checks.
  final Duration tick;

  /// The workspace setting holding the local day (`YYYY-MM-DD`) whose
  /// digest slot was last evaluated.
  static const String daySettingKey = 'unattended_digest_day';

  Timer? _timer;
  Future<void>? _running;

  /// Starts the timer. The first check is one [tick] away, off the boot
  /// path.
  void start() {
    _timer ??= Timer.periodic(tick, (_) => _check());
  }

  void _check() {
    if (_running != null || _ports.stopping()) {
      return;
    }
    _running = runOnce().whenComplete(() => _running = null);
  }

  /// Evaluates every workspace's slot once. Returns the digests published.
  Future<List<WaitingDigest>> runOnce() async {
    final sent = <WaitingDigest>[];
    List<String> workspaces;
    try {
      workspaces = await _ports.workspaceIds();
    } on Object {
      return sent;
    }
    for (final ws in workspaces) {
      if (_ports.stopping()) {
        break;
      }
      try {
        sent.addAll(await runFor(ws));
      } on Object {
        // One workspace failing leaves the others their digest.
      }
    }
    return sent;
  }

  /// Evaluates [workspaceId]'s current slot: publishes its digests unless
  /// the slot was already evaluated. Returns the digests published.
  Future<List<WaitingDigest>> runFor(String workspaceId) async {
    final now = _now().toUtc();
    final policy = UnattendedPolicy.fromSetting(
      await _ports.readSetting(workspaceId, unattendedPolicySettingKey),
    );
    final zone = await _ports.timeZoneOf(workspaceId);
    final slot = currentSlot(now, policy.digestHour, zone);
    if (slot == null) {
      return const [];
    }
    final day = _day(_toLocal(slot, zone));
    // A late digest is sent the same local day only: before today's hour
    // the latest slot is yesterday's, which today's digest replaces.
    if (day != _day(_toLocal(now, zone)) ||
        await _ports.readSetting(workspaceId, daySettingKey) == day) {
      return const [];
    }
    // Written first: a crash after this sends nothing twice.
    await _ports.writeSetting(workspaceId, daySettingKey, day);
    final byPerson = await _itemsByPerson(workspaceId);
    final digests = <WaitingDigest>[];
    for (final MapEntry(key: userId, value: items) in byPerson.entries) {
      if (items.isEmpty) {
        continue;
      }
      final digest = WaitingDigest(
        workspaceId: workspaceId,
        forUserId: userId,
        day: day,
        items: items,
        occurredAt: now,
      );
      try {
        _bus.publish(digest);
      } on StateError {
        // The bus closed (shutdown).
        break;
      }
      digests.add(digest);
    }
    return digests;
  }

  /// The latest daily slot at [hour] in [zone] at or before [nowUtc], or
  /// null when none is computable.
  DateTime? currentSlot(DateTime nowUtc, int hour, String zone) {
    final spec = _DailySpec(hour, zone);
    // One slot falls in every day: the first after a day ago is today's,
    // unless today's has not come yet (a short DST day).
    final first = _scheduler.nextSlotAfter(
      spec,
      nowUtc.subtract(const Duration(days: 1)),
    );
    if (first == null) {
      return null;
    }
    if (!first.isAfter(nowUtc)) {
      return first;
    }
    final earlier = _scheduler.nextSlotAfter(
      spec,
      nowUtc.subtract(const Duration(days: 2)),
    );
    return earlier != null && !earlier.isAfter(nowUtc) ? earlier : null;
  }

  Future<Map<String, List<WaitingDigestItem>>> _itemsByPerson(
    String workspaceId,
  ) async {
    final owned = <String?, List<WaitingDigestItem>>{};
    void add(String? userId, WaitingDigestItem item) =>
        (owned[userId] ??= []).add(item);

    final listedGoals = <String>{};
    for (final (hold, type) in [
      (GoalHold.needsReview, WaitingDigestItemType.goalReview),
      (GoalHold.person, WaitingDigestItemType.goalPerson),
    ]) {
      for (final goal in await _ports.heldGoals(workspaceId, hold)) {
        if (goal.workspaceId != workspaceId || goal.status.isTerminal) {
          continue;
        }
        listedGoals.add(goal.id);
        add(
          goal.requestedByUserId,
          WaitingDigestItem(
            type: type,
            id: goal.id,
            summary: _short(goal.userText),
            spaceId: goal.spaceId,
            conversationId: goal.conversationId,
            agentId: goal.agentId,
          ),
        );
      }
    }
    for (final wake in await _ports.heldWakes(workspaceId)) {
      add(
        wake.requestedByUserId,
        WaitingDigestItem(
          type: WaitingDigestItemType.heldWake,
          id: wake.id,
          summary: _short(wake.summary),
          spaceId: wake.spaceId,
          conversationId: wake.conversationId,
          agentId: wake.agentId,
        ),
      );
    }
    for (final request in await _ports.pendingRequests(workspaceId)) {
      // A goal segment's request: its goal's line already says it waits.
      if (listedGoals.contains(request.goalId)) {
        continue;
      }
      add(
        request.requestedByUserId,
        WaitingDigestItem(
          type: WaitingDigestItemType.request,
          id: request.id,
          summary: _short(request.summary),
          spaceId: request.spaceId,
          conversationId: request.conversationId,
          agentId: request.agentId,
          expiresAt: request.deadline.toUtc(),
        ),
      );
    }
    final goalOwners = <String, String?>{};
    for (final proposal in await _ports.pendingProposals(workspaceId)) {
      if (proposal.workspaceId != workspaceId) {
        continue;
      }
      final goalId = proposal.goalId;
      String? owner;
      if (goalId != null) {
        owner = goalOwners.containsKey(goalId)
            ? goalOwners[goalId]
            : goalOwners[goalId] = (await _ports.goalById(
                workspaceId,
                goalId,
              ))?.requestedByUserId;
      }
      add(
        owner,
        WaitingDigestItem(
          type: WaitingDigestItemType.improvement,
          id: proposal.id,
          summary: _short(proposal.change),
          spaceId: proposal.spaceId,
          conversationId: proposal.conversationId,
          agentId: proposal.agentId,
        ),
      );
    }

    final byPerson = <String, List<WaitingDigestItem>>{};
    final unowned = [...?owned.remove(null)];
    for (final MapEntry(key: userId, value: items) in owned.entries) {
      // What acted for a person who has left is nobody's now: the admins
      // are the ones who can still stop it.
      if (await _ports.isMember(workspaceId, userId!)) {
        byPerson[userId] = [...items];
      } else {
        unowned.addAll(items);
      }
    }
    if (unowned.isNotEmpty) {
      for (final admin in await _ports.admins(workspaceId)) {
        (byPerson[admin] ??= []).addAll(unowned);
      }
    }
    // Each recipient sees only what they may read.
    for (final userId in byPerson.keys.toList()) {
      final readable = <WaitingDigestItem>[];
      for (final item in byPerson[userId]!) {
        final space = item.spaceId;
        if (space == null ||
            await _ports.canReadSpace(workspaceId, userId, space)) {
          readable.add(item);
        }
      }
      byPerson[userId] = readable;
    }
    return byPerson;
  }

  /// Stops the timer.
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _running;
  }
}

String _day(DateTime local) =>
    '${local.year.toString().padLeft(4, '0')}-'
    '${local.month.toString().padLeft(2, '0')}-'
    '${local.day.toString().padLeft(2, '0')}';

String _short(String text) {
  final line = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  return line.length <= 120 ? line : '${line.substring(0, 119)}…';
}

/// `0 <hour> * * *` in [timezone]: the digest's daily slot.
class _DailySpec implements ScheduleSpec {
  _DailySpec(int hour, this.timezone)
    : cronSchedule = CronSchedule.tryParse('0 $hour * * *');

  @override
  final CronSchedule? cronSchedule;

  @override
  final String timezone;

  @override
  int? get intervalSeconds => null;
}
