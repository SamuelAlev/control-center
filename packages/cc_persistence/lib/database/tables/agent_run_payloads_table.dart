import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:drift/drift.dart';

/// The large values of one agent run: what only the run's detail view and the
/// runtime (output contract, pipeline harvest) read.
///
/// One row per run at most, keyed by the run id, and only once the run has a
/// value to keep here. They live beside `agent_run_logs` rather than in it
/// because every list, filter and counter write goes through the run-log row:
/// a status flip or a token count must not rewrite a prompt-context snapshot,
/// and a list of 200 runs must not drag 200 snapshots off disk. Lists read
/// `agent_run_logs` alone; the single-run reads join this table.
class AgentRunPayloadsTable extends Table {
  /// The run these values belong to. `CASCADE`: the payload is part of the
  /// run and goes with it (the retention sweep, an agent delete).
  TextColumn get runId =>
      text().references(AgentRunLogsTable, #id, onDelete: KeyAction.cascade)();

  /// Serialized prompt composition recorded when the run's session opened
  /// (mode, model, tool names, prompt size and hash), for debugging.
  TextColumn get contextSnapshotJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJson(contextSnapshotJson))();

  /// JSON schema the run's `submit_output` payload must conform to (the
  /// pipeline output contract): a JSON object. Null when the run has none.
  TextColumn get expectedOutputSchema =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(expectedOutputSchema))();

  /// JSON object the agent produced via `submit_output`, harvested into the
  /// pipeline step's state. Null until the agent submits.
  TextColumn get outputJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(outputJson))();

  /// Detail of the run's verification verdict (`RunVerification.toJson`: who
  /// verified, when, notes). The verdict itself is
  /// `agent_run_logs.verification_status`, which lists and metrics read; this
  /// detail is attached only while its own `status` matches that verdict.
  TextColumn get verificationJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(verificationJson))();

  @override
  String get tableName => 'agent_run_payloads';

  @override
  Set<Column> get primaryKey => {runId};
}
