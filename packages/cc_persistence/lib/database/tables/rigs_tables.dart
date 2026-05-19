import 'package:drift/drift.dart';

/// Enclosure (rig) sessions: a disposable VM/microVM an agent or human drives.
///
/// Workspace-scoped. The rig itself is ephemeral — the machine is destroyed
/// and its disk overlay discarded — but the ROW outlives it, so a run can be
/// reviewed after the fact and a reaped session can say why it went.
@TableIndex(name: 'idx_rig_sessions_workspace', columns: {#workspaceId})
@TableIndex(
  name: 'idx_rig_sessions_phase',
  columns: {#workspaceId, #phase, #lastActivityAt},
)
@TableIndex(
  name: 'idx_rig_sessions_conversation',
  columns: {#workspaceId, #conversationId},
)
class RigSessionsTable extends Table {
  @override
  String get tableName => 'rig_sessions';

  /// Session id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// `computer` / `browser` / `mobile`.
  TextColumn get surface => text()();

  /// The `EnclosureBackend` wire name (`qemu-hvf`, `smolvm`, …).
  TextColumn get backend => text()();

  /// The `RigPhase` wire name.
  TextColumn get phase =>
      text().withDefault(const Constant('provisioning'))();

  /// Phase detail: the current boot step, or the failure message.
  TextColumn get statusDetail => text().nullable()();

  /// The `RigCloseReason` wire name, once closed.
  TextColumn get closeReason => text().nullable()();

  /// The full `RigSpec` as JSON. Stored whole rather than exploded into
  /// columns because it is read back as one object and never queried by its
  /// parts — a spec field is not a search key.
  TextColumn get specJson => text().withDefault(const Constant('{}'))();

  /// Guest display width in pixels, once the guest has a mode.
  IntColumn get displayWidth => integer().nullable()();

  /// Guest display height in pixels.
  IntColumn get displayHeight => integer().nullable()();

  /// The URL a browser rig's page is currently on. Tracked from the page's
  /// own navigation events so watchers see navigations pushed; null on the
  /// other surfaces and before the first navigation.
  TextColumn get currentUrl => text().nullable()();

  /// The conversation this rig belongs to, when opened from one.
  TextColumn get conversationId => text().nullable()();

  /// The agent driving it, when an agent opened it.
  TextColumn get agentId => text().nullable()();

  /// The fleet worker hosting it, when it is not local.
  TextColumn get workerId => text().nullable()();

  /// Wire-encoded `Principal` that opened it (`user:<id>` / `agent:<id>`).
  TextColumn get createdBy => text()();

  /// Wire-encoded `Principal` currently holding exclusive input control, or
  /// null when the owning agent is free to drive. This is the take-over lock.
  TextColumn get controller => text().nullable()();

  /// When [controller] took control.
  DateTimeColumn get controlHeldSince => dateTime().nullable()();

  /// Creation time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the guest first became reachable.
  DateTimeColumn get readyAt => dateTime().nullable()();

  /// Last action of any kind — what the idle reaper measures.
  DateTimeColumn get lastActivityAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// When it closed.
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Every input event sent to a rig, agent or human, with its principal.
///
/// The watch-lane frames are never persisted, so without this table a human
/// take-over leaves no trace once the stream ends. `seq` is the authority on
/// ordering — two actions can share a millisecond, and "who clicked first"
/// is exactly the question this table exists to answer.
@TableIndex(
  name: 'idx_rig_action_log_rig',
  columns: {#workspaceId, #rigId, #seq},
)
class RigActionLogTable extends Table {
  @override
  String get tableName => 'rig_action_log';

  /// Row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The rig acted upon.
  TextColumn get rigId => text()();

  /// Monotonic per-rig sequence.
  IntColumn get seq => integer()();

  /// The action verb.
  TextColumn get verb => text()();

  /// The action arguments as JSON.
  TextColumn get argsJson => text().withDefault(const Constant('{}'))();

  /// One-line human summary for the action feed.
  TextColumn get summary => text().withDefault(const Constant(''))();

  /// Wire-encoded `Principal` that sent it.
  TextColumn get actor => text()();

  /// Whether a human sent this while holding control.
  BoolColumn get isTakeOver => boolean().withDefault(const Constant(false))();

  /// Whether the action failed.
  BoolColumn get isError => boolean().withDefault(const Constant(false))();

  /// Truncated result text.
  TextColumn get resultText => text().nullable()();

  /// SHA-256 of the frame this action produced, joining to the run's retained
  /// agent-lane stills. The bytes are deliberately NOT here: an audit table
  /// that carries megabytes of base64 per row stops being queryable.
  TextColumn get imageHash => text().nullable()();

  /// How long the action took.
  IntColumn get durationMs => integer().nullable()();

  /// When it happened.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {rigId, seq},
  ];
}
