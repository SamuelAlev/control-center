import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:drift/drift.dart';

/// Reviewer identities a forge once flagged as code owners of a pull request.
///
/// The forge drops the flag once the request is satisfied, so this is the
/// only memory of it. Grows only.
class PrCodeOwnerReviewersTable extends Table {
  @override
  String get tableName => 'pr_code_owner_reviewers';

  /// `owner/repo`, or `u:<member>|owner/repo` for one member's rows.
  TextColumn get repoKey => text()();

  /// The pull request number.
  IntColumn get prNumber => integer()();

  /// The reviewer identity (a login or a team slug).
  TextColumn get identity => text()();

  @override
  Set<Column> get primaryKey => {repoKey, prNumber, identity};
}

/// The reply an agent run owes a pull-request conversation, written when the
/// run is dispatched and consumed when it completes. Goes with its run.
class PendingPrRepliesTable extends Table {
  @override
  String get tableName => 'pending_pr_replies';

  /// The run that will produce the reply.
  TextColumn get runLogId =>
      text().references(AgentRunLogsTable, #id, onDelete: KeyAction.cascade)();

  /// Where and how to reply, as a JSON object.
  // ignore: recursive_getters
  TextColumn get replyJson => text().check(isJsonObject(replyJson))();

  /// When the run was dispatched.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {runLogId};
}
