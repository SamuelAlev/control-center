import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';

/// Persistence port for wake rules (`wake_rules`).
///
/// Every method is workspace-scoped: [insertWithinLimits] takes the
/// workspace from the rule, every other method takes `workspaceId` first.
///
/// There is no full-row update: a fire, a skip, a cost, a schedule, a status
/// change and new limits are each one conditional statement on the stored
/// row, so a writer holding an older copy never undoes another writer's
/// change (a person's pause, a fire's count).
///
/// A stored rule the entity refuses (an import or a hand edit) is left out
/// of every read; a read that meets one that has not ended ends it
/// (`invalid_row`), so it neither fires nor counts against a limit.
abstract interface class WakeRuleRepository {
  /// Inserts [rule] unless the rules that have not ended would then exceed a
  /// limit, checked in one transaction with the insert: [perConversation]
  /// for the rule's agent in its conversation, [perAgent] for the agent,
  /// [perWorkspace] for the workspace (active and paused rules count, since
  /// a paused rule can resume); and, when [lineage] is given, the lineage's
  /// runs and cost ([lineageTotals]) below its caps. Returns the first limit
  /// that refused, in that order, or null when the rule was written. Throws
  /// when its id exists.
  Future<WakeRuleLimit?> insertWithinLimits(
    WakeRule rule, {
    required int perConversation,
    required int perAgent,
    required int perWorkspace,
    required WakeLineageCap? lineage,
  });

  /// The runs and cost of the lineage whose root is [rootRuleId]: the root's
  /// and those of every rule naming it as root, whatever their status.
  Future<WakeLineageTotals> lineageTotals(
    String workspaceId,
    String rootRuleId,
  );

  /// Records a fire of the `active` rule [id]: `run_count + 1`,
  /// `cost_micros + costMicrosDelta`, `last_fired_at` and `updated_at` =
  /// [firedAt], `next_fire_at` = [nextFireAt] (null: none). Returns false
  /// when the rule is not active (a person paused or ended it meanwhile).
  Future<bool> recordFire(
    String workspaceId, {
    required String id,
    required int costMicrosDelta,
    required DateTime? nextFireAt,
    required DateTime firedAt,
  });

  /// Records a fire of the `active` self-paced rule [id] (`run_count + 1`,
  /// `last_fired_at` and `updated_at` = [firedAt]) and leaves
  /// `next_fire_at` as it is: the loop's next slot is written when the run
  /// settles ([setNextAfterRun]), which may come first. Returns false when
  /// the rule is not active.
  Future<bool> recordLoopFire(
    String workspaceId, {
    required String id,
    required DateTime firedAt,
  });

  /// Writes the `active` self-paced rule [id]'s next slot [nextFireAt] after
  /// a run it started settled, in one conditional write: only while
  /// `next_fire_at` is null or still [delivered] (the slot whose wake the
  /// run carried; null for none). The chosen delay is cleared. Returns false
  /// when the rule is not active or already names another slot.
  Future<bool> setNextAfterRun(
    String workspaceId, {
    required String id,
    required DateTime? delivered,
    required DateTime nextFireAt,
    required DateTime now,
  });

  /// Records a skipped slot of the `active` rule [id]: `skip_count + 1`,
  /// `next_fire_at` = [nextFireAt], `updated_at` = [now]. Returns false when
  /// the rule is not active.
  Future<bool> recordSkip(
    String workspaceId, {
    required String id,
    required DateTime? nextFireAt,
    required DateTime now,
  });

  /// Adds [micros] (at least 0) to the rule's `cost_micros`, whatever its
  /// status (a run's cost lands after the rule may have ended), as one
  /// atomic increment. Returns the new total, or null when there is no rule
  /// [id], so the caller can end the rule at its cap.
  Future<int?> addCost(
    String workspaceId, {
    required String id,
    required int micros,
    required DateTime now,
  });

  /// Sets when the rule [id] fires next. [nextDelaySeconds] (60 to 3,600) is
  /// the delay a self-paced rule's agent chose, and is refused for any other
  /// trigger; null clears it. Returns false when the rule has ended (or is
  /// not self-paced while [nextDelaySeconds] is given).
  Future<bool> setNext(
    String workspaceId, {
    required String id,
    required DateTime? nextFireAt,
    required int? nextDelaySeconds,
    required DateTime now,
  });

  /// Moves the rule [id] from one of [from] to [to], with [endReason] set
  /// exactly when [to] is `ended`. Returns whether this call moved it.
  Future<bool> transition(
    String workspaceId, {
    required String id,
    required Set<WakeRuleStatus> from,
    required WakeRuleStatus to,
    required WakeRuleEndReason? endReason,
    required DateTime now,
  });

  /// Replaces what the rule [id] says ([note], at most 4,000 characters) and
  /// what a fire that finds the agent busy does ([whenBusy]) while it has not
  /// ended. [noteEditedByUserId], when given, records the person whose words
  /// the note now is; null leaves that record as it was. Returns false when
  /// the rule has ended or does not exist.
  Future<bool> setTerms(
    String workspaceId, {
    required String id,
    required String note,
    required WakeWhenBusy whenBusy,
    required String? noteEditedByUserId,
    required DateTime now,
  });

  /// Replaces the limits of the rule [id] while it has not ended:
  /// [expiresAt] (not before its creation), [maxRuns] (null: no run cap,
  /// otherwise at least 1), [costCapMicros] (at least 1). Returns false when
  /// the rule has ended or does not exist.
  Future<bool> setLimits(
    String workspaceId, {
    required String id,
    required DateTime expiresAt,
    required int? maxRuns,
    required int costCapMicros,
    required DateTime now,
  });

  /// The rule [id], or null.
  Future<WakeRule?> getById(String workspaceId, String id);

  /// The conversation's rules, newest first, narrowed to [statuses].
  Future<List<WakeRule>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeRuleStatus>? statuses,
  });

  /// The agent's rules, newest first, narrowed to [statuses].
  Future<List<WakeRule>> listForAgent(
    String workspaceId,
    String agentId, {
    Set<WakeRuleStatus>? statuses,
  });

  /// The `active` watches of [kind] (the event subscriptions).
  Future<List<WakeRule>> listActiveByEvent(
    String workspaceId,
    WakeEventKind kind,
  );

  /// The rules (one-offs included) the run [runId] created for [agentId] in
  /// [conversationId], any status, newest first. A rule's pending wake is
  /// the one whose `detail.ruleId` names it.
  Future<List<WakeRule>> listCreatedByRun(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required String runId,
  });

  /// The rules bound to [goalId], newest first.
  Future<List<WakeRule>> listByGoal(String workspaceId, String goalId);

  /// The rules [userId] is accountable for, newest first.
  Future<List<WakeRule>> listByRequester(String workspaceId, String userId);

  /// The rules of the lineage rooted at [rootRuleId] (the rows naming it as
  /// their root, not the root's own), newest first, whatever their status.
  Future<List<WakeRule>> listByRoot(String workspaceId, String rootRuleId);

  /// Every `active` rule in the workspace, oldest first (the rule service
  /// re-arms them at boot).
  Future<List<WakeRule>> listActive(String workspaceId);

  /// How many readable `active` rules the workspace has, narrowed to
  /// [agentId] and [conversationId] when given. The creation limits are
  /// enforced by [insertWithinLimits], not from this count.
  Future<int> countActive(
    String workspaceId, {
    String? agentId,
    String? conversationId,
  });

  /// Watches the conversation's rules that are not ended, newest first.
  Stream<List<WakeRule>> watchForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Watches every rule in the workspace, newest first (the Schedules
  /// screen).
  Stream<List<WakeRule>> watchForWorkspace(String workspaceId);

  /// Deletes the rule [id]. Returns whether it existed.
  Future<bool> delete(String workspaceId, String id);

  /// The ids of the registered workspaces that have `active` rules.
  ///
  /// CROSS-WORKSPACE BY DESIGN: the rule service re-arms rules at boot from
  /// every workspace; each later read is workspace-scoped.
  Future<List<String>> workspacesWithActiveRules();
}
