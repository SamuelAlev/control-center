import 'package:drift/drift.dart';

@TableIndex(name: 'idx_remembered_decisions_workspace', columns: {#workspaceId})
/// Remembers per-workspace (or per-agent) user decisions for command-policy
/// prompts, so a non-destructive consentable command doesn't re-prompt on
/// every invocation.
///
/// Workspace-scoped per AGENTS.md isolation rules — decisions from one
/// workspace MUST NEVER surface in another. The [workspaceId] column is
/// required and indexed.
class RememberedDecisionsTable extends Table {
  /// Unique decision id.
  TextColumn get id => text()();

  /// Workspace this decision belongs to (required — never null).
  TextColumn get workspaceId => text()();

  /// Agent this decision is scoped to, when scoped to a single agent.
  TextColumn get agentId => text().nullable()();

  /// Canonical fingerprint of the matched command (exact token sequence).
  TextColumn get fingerprint => text()();

  /// The remembered decision: `allow` or `deny`.
  TextColumn get decision => text()();

  /// Scope: `session` (in-memory only, not persisted), `workspace`, or
  /// `agent`.
  TextColumn get scope => text()();

  /// When the decision was made.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
