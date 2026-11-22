import 'package:cc_persistence/database/tables/agent_run_logs.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// One `repl` call: the durable audit row of a script an agent ran in code
/// mode (`CodeExecution`).
///
/// Written when the host admits the script (status `running`) and finished
/// once when it ends; the next server start finishes a row a dead server
/// left running.
///
/// A part of its run: `run_id` is `CASCADE`, so executions go with their run
/// log, whether the retention sweep, an agent delete or an explicit delete
/// removes it. The space is `CASCADE` too: an execution's source, output and
/// call arguments are content of the space it was recorded in, so they go
/// wherever the space goes, by whichever path deletes it, and never outlive
/// it as a record with no space that every member could read. The
/// conversation and agent are `SET NULL` for the same reason as on
/// `agent_run_logs`: the record outlives them while its run is kept.
///
/// The row holds what lists, filters and counters read. The source, output
/// and console are in `code_execution_payloads`, which only the detail view
/// reads, and each nested call is a row of `code_execution_calls`.
///
/// Lists read newest first by `(started_at_ms, id)`. [startedAtMs] is epoch
/// milliseconds rather than a `dateTime()` column, which stores whole
/// seconds: several scripts in one second are normal, and their order must
/// survive. Each index a list filters on ends with those two columns, so the
/// order comes from the index.
@TableIndex(name: 'idx_code_executions_started', columns: {#startedAtMs, #id})
@TableIndex(
  name: 'idx_code_executions_run_started',
  columns: {#runId, #startedAtMs, #id},
)
@TableIndex(
  name: 'idx_code_executions_conversation_started',
  columns: {#conversationId, #startedAtMs, #id},
)
@TableIndex(
  name: 'idx_code_executions_agent_started',
  columns: {#agentId, #startedAtMs, #id},
)
@TableIndex(
  name: 'idx_code_executions_space_started',
  columns: {#spaceId, #startedAtMs, #id},
)
@TableIndex(
  name: 'idx_code_executions_status_started',
  columns: {#status, #startedAtMs, #id},
)
@TableIndex(
  name: 'idx_code_executions_tool_call_started',
  columns: {#toolCallId, #startedAtMs, #id},
)
@TableIndex(
  name: 'idx_code_executions_run_tool_call_suffix',
  columns: {#runId, #toolCallId, #idSuffix},
)
class CodeExecutionsTable extends Table {
  /// The execution id (`CodeExecution.id`).
  TextColumn get id => text()();

  /// The run (`agent_run_logs.id`) the script belongs to. `CASCADE`: an
  /// execution is part of its run and follows the run log's retention.
  TextColumn get runId =>
      text().references(AgentRunLogsTable, #id, onDelete: KeyAction.cascade)();

  /// The `repl` tool call's id. Not a row: a tool call id lives in the
  /// transcript.
  TextColumn get toolCallId => text()();

  /// Which execution of the `repl` call [toolCallId] in run [runId] this is:
  /// 1 for the id `<run>/<call>`, n for `<run>/<call>#<n>`. A tool call id can
  /// repeat within a run, so the next id is the highest suffix plus one, read
  /// from the index in one query.
  IntColumn get idSuffix => integer()();

  /// Which surface ran the script: a `CodeExecutionSurface` wire name.
  TextColumn get surface => text().check(
    // ignore: recursive_getters
    surface.isIn(AgentsStoredValues.codeExecutionSurface),
  )();

  /// The conversation, when the run has one. `SET NULL`: the record
  /// outlives the conversation while its run is kept.
  TextColumn get conversationId => text().nullable().references(
    ConversationsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The agent, when the run has one. `SET NULL` for the row's own sake; in
  /// practice deleting an agent deletes its runs, and these rows with them.
  TextColumn get agentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The space, when the run has one: what the read gate checks before
  /// showing source or output. `CASCADE`: the record is the space's content
  /// and is deleted with it.
  TextColumn get spaceId => text().nullable().references(
    SpacesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The one-line description the model gave the call, at most 200
  /// characters (`CodeExecution.boundDescription`).
  TextColumn get description => text().withDefault(const Constant(''))();

  /// When the host admitted the call, in epoch milliseconds (UTC).
  IntColumn get startedAtMs => integer()();

  /// Wall-clock milliseconds from admission to the result, waits included.
  /// Zero while running.
  IntColumn get durationMs => integer()();

  /// `running` until the script ends, then how it ended: a
  /// `CodeExecutionStatus` wire name.
  TextColumn get status => text().check(
    // ignore: recursive_getters
    status.isIn(AgentsStoredValues.codeExecutionStatus),
  )();

  /// Why a script that did not complete ended: a `CodeExecutionErrorKind`
  /// value, chosen by the host. The script's own error name is in the
  /// payload.
  TextColumn get errorKind =>
      text().nullable()
      // ignore: recursive_getters
      .check(errorKind.isIn(AgentsStoredValues.codeExecutionErrorKind))();

  /// SHA-256 of the source, lowercase hex: groups reruns of one script.
  TextColumn get sourceHash => text()();

  /// Size of the source in UTF-8 bytes.
  IntColumn get sourceBytes => integer()();

  /// Interpreter CPU milliseconds, when the runner reported them.
  IntColumn get cpuMs => integer().nullable()();

  /// Peak interpreter heap in bytes, when the runner reported it.
  IntColumn get peakHeapBytes => integer().nullable()();

  /// Nested calls that completed.
  IntColumn get callsCompleted => integer().withDefault(const Constant(0))();

  /// Nested calls whose tool returned an error.
  IntColumn get callsFailed => integer().withDefault(const Constant(0))();

  /// Nested calls the gate refused.
  IntColumn get callsDenied => integer().withDefault(const Constant(0))();

  /// Nested calls cancelled before they settled.
  IntColumn get callsCancelled => integer().withDefault(const Constant(0))();

  /// Nested calls whose own deadline ran out.
  IntColumn get callsTimedOut => integer().withDefault(const Constant(0))();

  /// Nested calls naming a tool outside the run's callable set.
  IntColumn get callsUnknownTool => integer().withDefault(const Constant(0))();

  /// Nested calls with unusable arguments.
  IntColumn get callsInvalidArgs => integer().withDefault(const Constant(0))();

  /// Questions the script asked a person.
  IntColumn get questionCount => integer().withDefault(const Constant(0))();

  /// Size of the script's output in UTF-8 bytes, before it was cut for the
  /// model.
  IntColumn get outputBytes => integer().withDefault(const Constant(0))();

  /// Whether the model read a head-and-tail cut of the output.
  BoolColumn get outputTruncated =>
      boolean().withDefault(const Constant(false))();

  /// The runner's engine and version, when it started. Open set: engine
  /// version strings.
  TextColumn get engineVersion => text().nullable()();

  /// The lockdown the runner reported in its first frame, as a JSON object.
  /// Null when no runner started.
  TextColumn get lockdownJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonObject(lockdownJson))();

  /// The limits the script ran under (`CodeModeLimits.toJson`), as a JSON
  /// object.
  TextColumn get limitsJson =>
      // ignore: recursive_getters
      text().check(isJsonObject(limitsJson))();

  @override
  String get tableName => 'code_executions';

  @override
  Set<Column> get primaryKey => {id};
}

/// The source, output and console of one execution
/// (`CodeExecutionPayload`), each bounded by the entity. Written with the
/// source when the script is admitted; the output, console and error name
/// are set once, when it ends.
///
/// A 1:1 side row of `code_executions`, kept apart because it is large, it
/// is space content that only the detail view reads behind the space read
/// gate, and a list must not drag it off disk.
class CodeExecutionPayloadsTable extends Table {
  /// The execution these belong to. `CASCADE`: part of the execution.
  TextColumn get executionId => text().references(
    CodeExecutionsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The script as the model wrote it.
  TextColumn get source => text()();

  /// The result text the model read.
  TextColumn get output => text().withDefault(const Constant(''))();

  /// The script's `console.*` lines, in order, one per line with its level.
  TextColumn get console => text().withDefault(const Constant(''))();

  /// The name of the error a failed script threw, as the script set it, cut
  /// to one line of 100 characters. Display text, never a filter.
  TextColumn get errorName => text().nullable()();

  @override
  String get tableName => 'code_execution_payloads';

  @override
  Set<Column> get primaryKey => {executionId};
}

/// One nested tool call a script made (`CodeExecutionCall`), in call order.
///
/// The key `(execution_id, sequence)` is the call's identity and the index
/// the detail view reads in order. The full result is not kept: it went to
/// the script, and the transcript row under the `repl` call holds what the
/// person saw.
class CodeExecutionCallsTable extends Table {
  /// The execution that made the call. `CASCADE`: part of the execution.
  TextColumn get executionId => text().references(
    CodeExecutionsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// One-based position in call order.
  IntColumn get sequence => integer()();

  /// The nested transcript id (`<replToolCallId>/<sequence>`). Not a row.
  TextColumn get toolCallId => text()();

  /// The tool's registered name. Open set: tool names.
  TextColumn get toolName => text()();

  /// Milliseconds from the script's start to this call's start.
  IntColumn get startOffsetMs => integer()();

  /// Milliseconds from start to settle, waits included.
  IntColumn get durationMs => integer()();

  /// How the call ended: a `NestedCallStatus` wire name.
  TextColumn get status => text().check(
    // ignore: recursive_getters
    status.isIn(AgentsStoredValues.nestedCallStatus),
  )();

  /// What the gate decided: a `NestedCallGateDecision` wire name. Null when
  /// the call never reached the gate.
  TextColumn get gateDecision =>
      text().nullable()
      // ignore: recursive_getters
      .check(gateDecision.isIn(AgentsStoredValues.nestedCallGateDecision))();

  /// Milliseconds spent waiting on a person, part of [durationMs].
  IntColumn get approvalWaitMs => integer().withDefault(const Constant(0))();

  /// Size of the arguments the script sent, in UTF-8 bytes, before
  /// redaction.
  IntColumn get argumentBytes => integer().withDefault(const Constant(0))();

  /// Size of the result handed back to the script, in UTF-8 bytes.
  IntColumn get resultBytes => integer().withDefault(const Constant(0))();

  /// The redacted arguments, at most 8 KiB.
  ///
  /// Display text, not a JSON column: arguments over the cap are cut with a
  /// marker (`CodeExecutionCall.boundArguments`), which leaves text that no
  /// longer parses, so the column carries no `json_valid` check and its name
  /// no `_json` suffix.
  TextColumn get arguments => text().withDefault(const Constant('{}'))();

  /// The error message of a call that did not complete, at most 500
  /// characters.
  TextColumn get error => text().nullable()();

  /// The 1-based line in the script the call was made from
  /// (`ScriptCallSite.line`), or null when the runner reported none.
  ///
  /// A display hint the runner reported: the runner executes model-written
  /// code, so nothing that decides reads it.
  IntColumn get siteLine => integer().nullable()();

  /// The 1-based column in the script the call was made from
  /// (`ScriptCallSite.column`), null exactly when [siteLine] is.
  IntColumn get siteColumn => integer().nullable()();

  @override
  String get tableName => 'code_execution_calls';

  @override
  Set<Column> get primaryKey => {executionId, sequence};

  /// A call site is a line and a column together, both 1-based, or neither.
  @override
  List<String> get customConstraints => [
    // One constraint, split for width: drift reads only literal strings here.
    // ignore: no_adjacent_strings_in_list
    'CHECK ((site_line IS NULL) = (site_column IS NULL) '
        'AND (site_line IS NULL OR (site_line >= 1 AND site_column >= 1)))',
  ];
}

/// What scripts kept with `store(key, value)`, per conversation and agent.
///
/// Values are JSON text, so the size caps (`CodeModeStoreRules`) count
/// exactly the bytes stored. Both owners are `CASCADE`: the values are the
/// agent's working state in that conversation and mean nothing once either
/// is gone, so they are removed with the conversation (directly, or with its
/// space) and with the agent. They are not tied to a run, so the run log's
/// retention leaves them alone.
@TableIndex(name: 'idx_code_mode_store_agent', columns: {#agentId})
class CodeModeStoreTable extends Table {
  /// The conversation the values belong to. `CASCADE`.
  TextColumn get conversationId =>
      text().references(ConversationsTable, #id, onDelete: KeyAction.cascade)();

  /// The agent the values belong to. `CASCADE`.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The key the script named.
  TextColumn get key => text()();

  /// The value as JSON text.
  TextColumn get valueJson =>
      // ignore: recursive_getters
      text().check(isJson(valueJson))();

  /// When the value was last written.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'code_mode_store';

  @override
  Set<Column> get primaryKey => {conversationId, agentId, key};
}
