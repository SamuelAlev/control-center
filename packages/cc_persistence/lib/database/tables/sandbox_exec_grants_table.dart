import 'package:drift/drift.dart';

/// Operator decisions about executing binaries from inside a writable
/// directory tree — the exception to the sandbox's writable-dir exec block.
///
/// The macOS Seatbelt profile denies `process-exec` across all of `$HOME`, so
/// an agent's CoW worktree (which lives under `$HOME`) cannot run the tools a
/// checked-out repo installs for itself (`node_modules/.bin/…`, `.venv/bin/…`).
/// A row here records that the operator was asked about one tree and what they
/// answered; an ABSENT row means "not asked yet", which is why `deny` is stored
/// rather than simply omitted.
///
/// Workspace-scoped: the same checkout registered in two workspaces is two
/// independent decisions. `path` is stored symlink-resolved, because that is
/// the spelling the kernel matches an exec rule against.
@TableIndex(name: 'idx_sandbox_exec_grants_workspace', columns: {#workspaceId})
class SandboxExecGrantsTable extends Table {
  @override
  String get tableName => 'sandbox_exec_grants';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// The absolute, symlink-resolved directory tree the decision covers.
  TextColumn get path => text()();

  /// The decision: `allow` / `deny`.
  TextColumn get decision => text().withDefault(const Constant('deny'))();

  /// Principal that made the decision.
  TextColumn get createdBy => text().nullable()();

  /// When the decision was made.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  /// One decision per tree per workspace — a second answer replaces the first
  /// rather than accumulating rows the resolver would have to disambiguate.
  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, path},
  ];
}
