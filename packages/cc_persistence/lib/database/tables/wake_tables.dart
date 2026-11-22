import 'package:cc_persistence/database/tables/agent_goal_runs_table.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:drift/drift.dart';

/// The wake queue's durable outbox (`Wake`): one reason for the server to run
/// an agent in a conversation, or to tell a running agent something.
///
/// A wake goes with its conversation and its agent (`CASCADE`): it can never
/// be delivered without them. Its space is not a key: the conversation
/// already goes with the space. The run it was delivered to is a value, not
/// a key: retention deletes settled wakes after 14 days, long before runs.
///
/// [dedupKey] is unique: a producer inserts with `ON CONFLICT DO NOTHING`, so
/// a retry never writes a second wake. The due scan walks `(state,
/// not_before)`; the per-conversation and per-agent reads walk their own
/// index.
@TableIndex(
  name: 'uq_agent_wakes_dedup_key',
  columns: {#dedupKey},
  unique: true,
)
@TableIndex(
  name: 'idx_agent_wakes_state_not_before',
  columns: {#state, #notBefore},
)
@TableIndex(
  name: 'idx_agent_wakes_conversation_agent_state',
  columns: {#conversationId, #agentId, #state},
)
@TableIndex(name: 'idx_agent_wakes_agent_state', columns: {#agentId, #state})
class AgentWakesTable extends Table {
  /// Unique wake id.
  TextColumn get id => text()();

  /// Owning workspace (this file's workspace).
  TextColumn get workspaceId => text()();

  /// Space of the target conversation. Not a key: the conversation goes with
  /// its space, and the wake with the conversation.
  TextColumn get spaceId => text()();

  /// Target conversation. `CASCADE`: a wake means nothing without it.
  TextColumn get conversationId =>
      text().references(ConversationsTable, #id, onDelete: KeyAction.cascade)();

  /// Target agent. `CASCADE`: a wake means nothing without it.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// Why the agent is woken: a `WakeReason` wire name.
  TextColumn get reason => text().check(
    // ignore: recursive_getters
    reason.isIn(AgentsStoredValues.wakeReason),
  )();

  /// How it enters a live run: a `WakeLane` wire name.
  TextColumn get lane => text()
      .check(
        // ignore: recursive_getters
        lane.isIn(AgentsStoredValues.wakeLane),
      )
      .withDefault(const Constant('aside'))();

  /// Text for the agent: data, at most 4,000 characters (checked by the
  /// entity).
  TextColumn get payload => text()();

  /// `WakeDetail` as a JSON object: goal, rule and slot, ask, ticket, source,
  /// event. Producers cancel by its `goalId`, `ruleId` and `askId` keys.
  TextColumn get detail => text()
      // ignore: recursive_getters
      .check(isJsonObject(detail))
      .withDefault(const Constant('{}'))();

  /// `WakeRunOptions` as a JSON object; null for the defaults.
  TextColumn get runOptions =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(runOptions))();

  /// The idempotency key (`goal:<id>:<runCount>`, `rule:<id>:<slot>`, …).
  TextColumn get dedupKey => text()();

  /// When it may be delivered.
  DateTimeColumn get notBefore => dateTime()();

  /// When it stops mattering; null for never.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// The accountable person, or null for the bot. No key: users live in
  /// `global.db`.
  TextColumn get requestedByUserId => text().nullable()();

  /// JSON array of the agent ids that led here, oldest first.
  TextColumn get chain => text()
      // ignore: recursive_getters
      .check(isJsonArray(chain))
      .withDefault(const Constant('[]'))();

  /// Whether the source is told when the work this wake starts settles.
  BoolColumn get expectsReply => boolean().withDefault(const Constant(false))();

  /// Where it is: a `WakeState` wire name.
  TextColumn get state => text()
      .check(
        // ignore: recursive_getters
        state.isIn(AgentsStoredValues.wakeState),
      )
      .withDefault(const Constant('pending'))();

  /// A short machine kind saying why it was skipped, held or cancelled.
  TextColumn get stateReason => text().nullable()();

  /// The run it was delivered to. A value, not a key.
  TextColumn get deliveredRunId => text().nullable()();

  /// How many times it was claimed for a dispatch.
  IntColumn get attempt => integer().withDefault(const Constant(0))();

  /// When it was written.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When it was last claimed.
  DateTimeColumn get claimedAt => dateTime().nullable()();

  /// When it settled (retention deletes settled wakes by this).
  DateTimeColumn get settledAt => dateTime().nullable()();

  @override
  String get tableName => 'agent_wakes';

  @override
  Set<Column> get primaryKey => {id};

  // The entity's rules that cost nothing to keep here as well, so an import
  // or a hand edit cannot leave a wake no reader can map. SQLite counts
  // characters, so the length check never refuses a valid payload. Times are
  // whole seconds here, so the ordering allows equality.
  @override
  List<String> get customConstraints => [
    'CHECK (length(payload) <= 4000)',
    'CHECK (attempt >= 0)',
    'CHECK (expires_at IS NULL OR expires_at >= created_at)',
  ];
}

/// Wake rules (`WakeRule`): schedules and watches that produce wakes for one
/// agent in one conversation.
///
/// The trigger is stored flat in the `trigger_*` columns and a table check
/// keeps each kind's columns present, so every row maps to a `WakeTrigger`.
/// A rule goes with its conversation, its agent and the goal it is bound to
/// (`CASCADE`): a rule bound to a goal ends with it.
@TableIndex(
  name: 'idx_wake_rules_conversation_agent_status',
  columns: {#conversationId, #agentId, #status},
)
@TableIndex(name: 'idx_wake_rules_agent_status', columns: {#agentId, #status})
@TableIndex(
  name: 'idx_wake_rules_status_event_kind',
  columns: {#status, #eventKind},
)
@TableIndex(name: 'idx_wake_rules_goal', columns: {#goalId})
@TableIndex(name: 'idx_wake_rules_root_rule', columns: {#rootRuleId})
class WakeRulesTable extends Table {
  /// Unique rule id.
  TextColumn get id => text()();

  /// Owning workspace (this file's workspace).
  TextColumn get workspaceId => text()();

  /// Space of the target conversation. Not a key, as on `agent_wakes`.
  TextColumn get spaceId => text()();

  /// Target conversation. `CASCADE`.
  TextColumn get conversationId =>
      text().references(ConversationsTable, #id, onDelete: KeyAction.cascade)();

  /// Target agent. `CASCADE`.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The trigger's kind: `at`, `every`, `cron`, `self_paced` or `event`.
  TextColumn get triggerKind => text().check(
    // ignore: recursive_getters
    triggerKind.isIn(AgentsStoredValues.wakeTriggerKind),
  )();

  /// When a one-off (`at`) rule fires.
  DateTimeColumn get triggerAt => dateTime().nullable()();

  /// An `every` rule's interval, in seconds (60 or more).
  IntColumn get intervalSeconds => integer().nullable()();

  /// A `cron` rule's five-field expression.
  TextColumn get cronExpression => text().nullable()();

  /// A `cron` rule's IANA time zone.
  TextColumn get timeZone => text().nullable()();

  /// An `event` rule's watched event: a `WakeEventKind` wire name.
  TextColumn get eventKind =>
      text().nullable()
      // ignore: recursive_getters
      .check(eventKind.isIn(AgentsStoredValues.wakeEventKind))();

  /// The ticket or pipeline run a `ticket` or `pipeline_run` watch names. A
  /// value, not a key.
  TextColumn get eventTargetId => text().nullable()();

  /// What the agent's future self needs (at most 4,000 characters, checked
  /// by the entity).
  TextColumn get note => text()();

  /// The person who last changed [note]; null while it is the creator's
  /// words. No foreign key: users live in `global.db`.
  TextColumn get noteEditedByUserId => text().nullable()();

  /// The rule this one continues (the first of its line); null for a rule
  /// that is its own root. A value, not a key.
  TextColumn get rootRuleId => text().nullable()();

  /// `run` or `notify`: a `WakeDeliver` wire name.
  TextColumn get deliver => text()
      .check(
        // ignore: recursive_getters
        deliver.isIn(AgentsStoredValues.wakeDeliver),
      )
      .withDefault(const Constant('run'))();

  /// `skip` or `queue`: a `WakeWhenBusy` wire name.
  TextColumn get whenBusy => text()
      .check(
        // ignore: recursive_getters
        whenBusy.isIn(AgentsStoredValues.wakeWhenBusy),
      )
      .withDefault(const Constant('skip'))();

  /// The most runs it may start; null for no run cap.
  IntColumn get maxRuns => integer().nullable()();

  /// The total its runs may spend, in micro-dollars.
  IntColumn get costCapMicros => integer()();

  /// When it ends by itself.
  DateTimeColumn get expiresAt => dateTime()();

  /// Runs it started.
  IntColumn get runCount => integer().withDefault(const Constant(0))();

  /// Slots it skipped.
  IntColumn get skipCount => integer().withDefault(const Constant(0))();

  /// What its runs spent, in micro-dollars.
  IntColumn get costMicros => integer().withDefault(const Constant(0))();

  /// When it last fired.
  DateTimeColumn get lastFiredAt => dateTime().nullable()();

  /// When it fires next.
  DateTimeColumn get nextFireAt => dateTime().nullable()();

  /// The delay a self-paced rule's agent chose for its next fire, in
  /// seconds.
  IntColumn get nextDelaySeconds => integer().nullable()();

  /// The goal it is bound to. `CASCADE`: it ends with the goal.
  TextColumn get goalId => text().nullable().references(
    AgentGoalRunsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// `agent` or `person`: a `WakeRuleOrigin` wire name.
  TextColumn get origin => text().check(
    // ignore: recursive_getters
    origin.isIn(AgentsStoredValues.wakeRuleOrigin),
  )();

  /// The run in which an agent created it. A value, not a key.
  TextColumn get createdByRunId => text().nullable()();

  /// The person who created it. No key: users live in `global.db`.
  TextColumn get createdByUserId => text().nullable()();

  /// The accountable person, or null for the bot.
  TextColumn get requestedByUserId => text().nullable()();

  /// `active`, `paused` or `ended`: a `WakeRuleStatus` wire name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.wakeRuleStatus),
      )
      .withDefault(const Constant('active'))();

  /// Why it ended: a `WakeRuleEndReason` wire name, set exactly when it
  /// ended.
  TextColumn get endReason =>
      text().nullable()
      // ignore: recursive_getters
      .check(endReason.isIn(AgentsStoredValues.wakeRuleEndReason))();

  /// When it was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When it was last changed.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'wake_rules';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    // Each trigger kind carries its columns, so every row maps to a trigger.
    // One constraint, split for width: drift reads only literal strings here.
    // ignore: no_adjacent_strings_in_list
    "CHECK ((trigger_kind <> 'at' OR trigger_at IS NOT NULL) "
        "AND (trigger_kind <> 'every' OR interval_seconds >= 60) "
        "AND (trigger_kind <> 'cron' OR (cron_expression IS NOT NULL "
        'AND time_zone IS NOT NULL)) '
        "AND (trigger_kind <> 'event' OR event_kind IS NOT NULL) "
        "AND (event_kind NOT IN ('ticket', 'pipeline_run') "
        'OR event_target_id IS NOT NULL))',
    // An ended rule says why; no other rule has an end reason.
    "CHECK ((status = 'ended') = (end_reason IS NOT NULL))",
    // The entity's limits that cost nothing to keep here as well.
    'CHECK (length(note) <= 4000)',
    'CHECK (expires_at >= created_at)',
    'CHECK (run_count >= 0 AND skip_count >= 0 AND cost_micros >= 0)',
    'CHECK (cost_cap_micros > 0 AND (max_runs IS NULL OR max_runs > 0))',
  ];
}
