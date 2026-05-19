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
class WorkersTable extends Table {
  @override
  String get tableName => 'workers';

  /// Unique worker id (UUID v4).
  TextColumn get id => text()();

  /// Operator-facing worker name (e.g. "mac-studio").
  TextColumn get name => text()();

  /// JSON-encoded `WorkerCapabilities` (OS, arch, cores, RAM, flutter SDK,
  /// sandbox backends, ML/GPU, always-on).
  TextColumn get capsJson => text().withDefault(const Constant('{}'))();

  /// Coarse platform string (`macos`/`linux`/`windows`) for quick display.
  TextColumn get platform => text().withDefault(const Constant('unknown'))();

  /// Reference to the paired-device credential (never the secret itself).
  TextColumn get credentialRef => text().nullable()();

  /// The paired-device row backing this worker (PRD 15), when paired.
  TextColumn get pairedDeviceId => text().nullable()();

  /// Wire protocol version the worker handshaked with. A mismatch marks the
  /// worker `incompatible` and withholds leases (spec Clarifications).
  IntColumn get protocolVersion => integer().withDefault(const Constant(0))();

  /// Lifecycle status: `online`/`draining`/`offline`/`incompatible`/`revoked`.
  TextColumn get status => text().withDefault(const Constant('offline'))();

  /// Last heartbeat time (server clock; workers never set server time).
  DateTimeColumn get lastHeartbeatAt => dateTime().nullable()();

  /// Principal (user id) that registered this worker.
  TextColumn get registeredBy => text().nullable()();

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
class JobsTable extends Table {
  @override
  String get tableName => 'jobs';

  /// Unique job id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Job kind wire name (`agentRun`/`pipelineStep`/`codeIndex`/`goldenRender`/
  /// `benchmark`/`evalBatch`).
  TextColumn get kind => text()();

  /// JSON-encoded `JobSpec` payload (kind-specific).
  TextColumn get specJson => text().withDefault(const Constant('{}'))();

  /// JSON array of required capability keys (must all be present on a worker).
  TextColumn get requiredCapsJson => text().withDefault(const Constant('[]'))();

  /// JSON array of preferred capability keys (break ties / prefer placement).
  TextColumn get preferredCapsJson =>
      text().withDefault(const Constant('[]'))();

  /// Status: `queued`/`leased`/`running`/`done`/`failed`/`reaped`/`cancelled`.
  TextColumn get status => text().withDefault(const Constant('queued'))();

  /// The worker currently holding the lease (null while queued).
  TextColumn get workerId => text().nullable()();

  /// An explicit pin: this job MUST run on this worker id (deterministic).
  TextColumn get pinnedWorkerId => text().nullable()();

  /// Lease expiry (server clock). A worker that vanishes has its lease reaped
  /// after this instant.
  DateTimeColumn get leaseExpiresAt => dateTime().nullable()();

  /// Scheduling priority (higher runs first within a workspace).
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Principal (user id) that submitted the job.
  TextColumn get submittedBy => text().nullable()();

  /// Metered worker cost in cents (token cost stays the billable cost).
  IntColumn get costCents => integer().withDefault(const Constant(0))();

  /// Attempt count (incremented on each lease → reap/retry cycle).
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Maximum attempts before the job is surfaced as failed.
  IntColumn get maxAttempts => integer().withDefault(const Constant(1))();

  /// Last event sequence the server acked from the worker (reconnect replay).
  IntColumn get lastAckedSeq => integer().withDefault(const Constant(0))();

  /// JSON-encoded result payload (artifact refs, branch, grade) when done.
  TextColumn get resultJson => text().nullable()();

  /// Failure reason when `failed`.
  TextColumn get error => text().nullable()();

  /// Correlated agent run / conversation this job drives, when applicable.
  TextColumn get agentId => text().nullable()();

  /// Correlated conversation (channel) id, when applicable.
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
class PlacementLogTable extends Table {
  @override
  String get tableName => 'placement_log';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope (matches the job).
  TextColumn get workspaceId => text()();

  /// The job this decision is about.
  TextColumn get jobId => text()();

  /// The chosen worker id, or null when the decision was "stay queued".
  TextColumn get workerId => text().nullable()();

  /// Machine-parseable decision code (`pinned`/`preferred`/`spill`/`queued`/
  /// `no_capable_worker`/`cache_warming`/`reaped`/`retried`).
  TextColumn get decision => text().withDefault(const Constant('queued'))();

  /// Human-readable explanation ("ran on mac-studio — required flutter;
  /// vps-1 lacked it").
  TextColumn get reason => text().withDefault(const Constant(''))();

  /// Decision time.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
