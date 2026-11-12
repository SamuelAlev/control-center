import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/paired_devices.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Registered fleet workers (PRD 20 §1).
///
/// A worker is a paired, principal-adjacent device that executes leased jobs
/// and holds **no durable state**. This table is **CROSS-WORKSPACE BY DESIGN**:
/// a worker serves every workspace (jobs are workspace-scoped, workers are
/// not), so it carries no `workspaceId`. Registration rides the PRD 15 pairing
/// flow; the `credentialRef` points at the paired-device credential the server
/// minted, never a secret value.
@TableIndex(name: 'idx_workers_status', columns: {#status})
@TableIndex(name: 'idx_workers_paired_device', columns: {#pairedDeviceId})
@TableIndex(name: 'idx_workers_registered_by', columns: {#registeredBy})
class WorkersTable extends Table {
  @override
  String get tableName => 'workers';

  /// Unique worker id (UUID v4).
  TextColumn get id => text()();

  /// Operator-facing worker name (e.g. "mac-studio").
  TextColumn get name => text()();

  /// JSON-encoded `WorkerCapabilities` (OS, arch, cores, RAM, flutter SDK,
  /// sandbox backends, ML/GPU, always-on): a JSON object.
  TextColumn get capsJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(capsJson))
      .withDefault(const Constant('{}'))();

  /// Coarse platform string (`macos`/`linux`/`windows`) for quick display.
  /// An open set: whatever the worker reports.
  TextColumn get platform => text().withDefault(const Constant('unknown'))();

  /// Reference to the paired-device credential (never the secret itself).
  TextColumn get credentialRef => text().nullable()();

  /// The paired-device row backing this worker (PRD 15), when paired. Cleared
  /// when the device goes: the worker then authenticates as nothing.
  TextColumn get pairedDeviceId => text().nullable().references(
    PairedDevicesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Wire protocol version the worker handshaked with. A mismatch marks the
  /// worker `incompatible` and withholds leases (spec Clarifications).
  IntColumn get protocolVersion => integer().withDefault(const Constant(0))();

  /// Lifecycle status: a `WorkerStatus` wire name.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(PlatformStoredValues.workerStatus))
      .withDefault(const Constant('offline'))();

  /// Last heartbeat time (server clock; workers never set server time).
  DateTimeColumn get lastHeartbeatAt => dateTime().nullable()();

  /// Principal (user id) that registered this worker. History: cleared if
  /// the user row goes.
  TextColumn get registeredBy => text().nullable().references(
    UsersTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// When the operator put the worker into drain (finish current, take no new).
  DateTimeColumn get drainedAt => dateTime().nullable()();

  /// When the worker was revoked (its live session must terminate; no leases).
  DateTimeColumn get revokedAt => dateTime().nullable()();

  /// Last error surfaced by/about the worker (for the fleet panel).
  TextColumn get lastError => text().nullable()();

  /// Registration time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Executable jobs the scheduler leases to workers (PRD 20 §2).
///
/// Everything executable (agent run, pipeline step, code index, golden render,
/// benchmark, eval batch) becomes a typed, serialized `JobSpec` row.
/// Workspace-scoped (jobs belong to a workspace even though workers do not).
@TableIndex(name: 'idx_jobs_workspace_status', columns: {#workspaceId, #status})
@TableIndex(name: 'idx_jobs_worker_status', columns: {#workerId, #status})
@TableIndex(name: 'idx_jobs_lease_expiry', columns: {#leaseExpiresAt})
// The scheduler's queue (`status = 'queued'`) and the retention sweep of
// terminal jobs by finish time.
@TableIndex(name: 'idx_jobs_status_finished', columns: {#status, #finishedAt})
@TableIndex(name: 'idx_jobs_submitted_by', columns: {#submittedBy})
class JobsTable extends Table {
  @override
  String get tableName => 'jobs';

  /// Unique job id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope; a job is part of its workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// Job kind: a `JobKind` wire name.
  TextColumn get kind =>
      // ignore: recursive_getters
      text().check(kind.isIn(PlatformStoredValues.jobKind))();

  /// JSON-encoded `JobSpec` payload (kind-specific): a JSON object.
  TextColumn get specJson => text()
      // ignore: recursive_getters
      .check(isJsonObject(specJson))
      .withDefault(const Constant('{}'))();

  /// JSON array of required capability keys (must all be present on a worker).
  TextColumn get requiredCapsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(requiredCapsJson))
      .withDefault(const Constant('[]'))();

  /// JSON array of preferred capability keys (break ties / prefer placement).
  TextColumn get preferredCapsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(preferredCapsJson))
      .withDefault(const Constant('[]'))();

  /// Status: a `JobStatus` wire name.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(PlatformStoredValues.jobStatus))
      .withDefault(const Constant('queued'))();

  /// The worker currently holding the lease (null while queued). Cleared if
  /// the worker row goes: the reaper then sees a lease nobody holds.
  TextColumn get workerId => text().nullable().references(
    WorkersTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// An explicit pin: this job MUST run on this worker id (deterministic).
  /// No foreign key: a pin may name a worker that is not registered (yet, or
  /// any more); the scheduler then reports it unavailable.
  TextColumn get pinnedWorkerId => text().nullable()();

  /// Lease expiry (server clock). A worker that vanishes has its lease reaped
  /// after this instant.
  DateTimeColumn get leaseExpiresAt => dateTime().nullable()();

  /// Scheduling priority (higher runs first within a workspace).
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Principal (user id) that submitted the job. History: cleared if the user
  /// row goes.
  TextColumn get submittedBy => text().nullable().references(
    UsersTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Metered worker cost in micro-dollars (token cost stays the billable
  /// cost).
  IntColumn get costMicros => integer().withDefault(const Constant(0))();

  /// Attempt count (incremented on each lease → reap/retry cycle).
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Maximum attempts before the job is surfaced as failed.
  IntColumn get maxAttempts => integer().withDefault(const Constant(1))();

  /// Last event sequence the server acked from the worker (reconnect replay).
  IntColumn get lastAckedSeq => integer().withDefault(const Constant(0))();

  /// JSON-encoded result payload (artifact refs, branch, grade) when done.
  // ignore: recursive_getters
  TextColumn get resultJson => text().nullable().check(isJson(resultJson))();

  /// Failure reason when `failed`.
  TextColumn get error => text().nullable()();

  /// Correlated agent run / conversation this job drives, when applicable.
  /// No foreign key: agents live in the workspace's own database.
  TextColumn get agentId => text().nullable()();

  /// Correlated conversation (space) id, when applicable. No foreign key:
  /// conversations live in the workspace's own database.
  TextColumn get conversationId => text().nullable()();

  /// Submission time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the job was leased to a worker.
  DateTimeColumn get leasedAt => dateTime().nullable()();

  /// When the worker reported it started executing.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// When the job reached a terminal state.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Explainable placement decisions (PRD 20 §2, §7).
///
/// One row per scheduling decision so "why is this queued / why did it run
/// there?" always has an answer. Workspace-scoped (mirrors the owning job).
@TableIndex(name: 'idx_placement_log_job', columns: {#jobId})
@TableIndex(name: 'idx_placement_log_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_placement_log_worker', columns: {#workerId})
// The retention sweep's age cutoff.
@TableIndex(name: 'idx_placement_log_created', columns: {#createdAt})
class PlacementLogTable extends Table {
  @override
  String get tableName => 'placement_log';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope (matches the job); goes with its workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// The job this decision is about; a decision about a job that is gone is
  /// history of nothing, so it goes with the job.
  TextColumn get jobId =>
      text().references(JobsTable, #id, onDelete: KeyAction.cascade)();

  /// The chosen worker id, or null when the decision was "stay queued".
  /// History: cleared if the worker row goes.
  TextColumn get workerId => text().nullable().references(
    WorkersTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Machine-parseable decision code: a `PlacementCode` wire name.
  TextColumn get decision => text()
      // ignore: recursive_getters
      .check(decision.isIn(PlatformStoredValues.placementCode))
      .withDefault(const Constant('queued'))();

  /// Human-readable explanation ("ran on mac-studio — required flutter;
  /// vps-1 lacked it").
  TextColumn get reason => text().withDefault(const Constant(''))();

  /// Decision time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
