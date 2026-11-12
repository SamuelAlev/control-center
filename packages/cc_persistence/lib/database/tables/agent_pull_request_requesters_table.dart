import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:drift/drift.dart';

/// Who asked an agent for a pull request it opened (or is opening), one row
/// per person: they may not approve it.
///
/// Server-wide, in the global database: a pull request belongs to the forge,
/// not to a workspace, so a row carries no workspace and outlives the
/// workspace it was written through (its deletion, or a restore of an older
/// copy of its file). Keys are forge identities, never a workspace's repo id:
/// the same forge repository linked in two workspaces is one pull request.
///
/// Kept for as long as the pull request can be approved, so never pruned by
/// age; a pending row the forge never opened is dropped by the store's
/// reconcile.
@TableIndex(name: 'idx_agent_pull_request_requesters_user', columns: {#userId})
class AgentPullRequestRequestersTable extends Table {
  @override
  String get tableName => 'agent_pull_request_requesters';

  /// `opened` (keyed by number) or `pending` (keyed by head branch): an
  /// `AgentPullRequestRecordState` wire name.
  TextColumn get state => text().check(
    // ignore: recursive_getters
    state.isIn(PlatformStoredValues.agentPullRequestRecordState),
  )();

  /// The pull request's forge key.
  TextColumn get prKey => text()();

  /// A person who may not approve it; the refusal is theirs and goes with
  /// them.
  TextColumn get userId =>
      text().references(UsersTable, #id, onDelete: KeyAction.cascade)();

  /// When this person was last recorded on it.
  DateTimeColumn get recordedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {state, prKey, userId};
}
