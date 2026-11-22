import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';

/// What one page of executions asks for. Newest first.
class CodeExecutionQuery {
  /// Creates a query. Throws [ArgumentError] when [limit] is outside
  /// 1..[maxLimit].
  CodeExecutionQuery({
    this.cursor,
    this.limit = 50,
    this.runId,
    this.conversationId,
    this.agentId,
    this.spaceId,
    this.toolCallId,
    this.hiddenSpaceIds = const {},
    this.statuses = const {},
    this.surface,
    this.since,
    this.until,
  }) {
    if (limit < 1 || limit > maxLimit) {
      throw ArgumentError.value(
        limit,
        'limit',
        'must be between 1 and $maxLimit',
      );
    }
  }

  /// The largest page.
  static const int maxLimit = 200;

  /// The [CodeExecutionPage.nextCursor] of the previous page, or null for the
  /// newest page. Opaque to callers.
  final String? cursor;

  /// Rows per page.
  final int limit;

  /// Only this run's executions.
  final String? runId;

  /// Only this conversation's executions.
  final String? conversationId;

  /// Only this agent's executions.
  final String? agentId;

  /// Only this space's executions.
  final String? spaceId;

  /// Only the executions of `repl` calls with this id: what one transcript
  /// row ran. Several can match (a provider can repeat an id across turns),
  /// newest first like every page.
  final String? toolCallId;

  /// Leaves out executions recorded in these spaces: the ones the reader may
  /// not read. Applied in the query, so a page, and the cursor to the next
  /// one, are made of rows the reader may see.
  final Set<String> hiddenSpaceIds;

  /// Only these statuses; empty reads all.
  final Set<CodeExecutionStatus> statuses;

  /// Only this surface.
  final CodeExecutionSurface? surface;

  /// Only executions started at or after this instant.
  final DateTime? since;

  /// Only executions started before this instant.
  final DateTime? until;
}

/// One page of executions, newest first.
class CodeExecutionPage {
  /// Creates a page.
  const CodeExecutionPage({required this.items, this.nextCursor});

  /// The executions.
  final List<CodeExecution> items;

  /// The cursor for the next (older) page, or null when this is the last.
  final String? nextCursor;
}

/// One execution with everything recorded about it.
class CodeExecutionDetail {
  /// Creates a detail.
  const CodeExecutionDetail({
    required this.execution,
    required this.calls,
    this.payload,
  });

  /// The execution.
  final CodeExecution execution;

  /// Its source and output, or null when retention already dropped them.
  final CodeExecutionPayload? payload;

  /// Its nested calls, by sequence.
  final List<CodeExecutionCall> calls;
}

/// Why [CodeExecutionRepository.begin] wrote nothing.
enum CodeExecutionBeginRefusal {
  /// The execution's run has no run log in the workspace, so the record
  /// could neither be kept with its run nor removed with it.
  noRun,

  /// An execution with this id is already recorded.
  idTaken,

  /// The execution names a space the workspace no longer has. Recorded with
  /// no space it would be readable by every member, whatever the space
  /// allowed, so it is not recorded at all.
  spaceGone,
}

/// [CodeExecutionRepository.begin] wrote nothing, for [reason].
class CodeExecutionBeginRefused implements Exception {
  /// Creates the refusal.
  const CodeExecutionBeginRefused(this.reason, this.executionId);

  /// Why.
  final CodeExecutionBeginRefusal reason;

  /// The execution that was not recorded.
  final String executionId;

  @override
  String toString() =>
      'CodeExecutionBeginRefused(${reason.name}, $executionId)';
}

/// What [CodeExecutionRepository.appendCall] did.
enum CodeExecutionAppendOutcome {
  /// The call row was written.
  appended,

  /// Nothing was written: the execution is no longer running (it was
  /// finished, or deleted with its run or space).
  notRunning,

  /// Nothing was written: the execution already has a call row with this
  /// sequence, and a call row is never replaced.
  sequenceTaken,
}

/// What [CodeExecutionRepository.finish] did.
enum CodeExecutionFinishResult {
  /// The running record was finished.
  finished,

  /// No record was left to finish: it was deleted with its run or its space
  /// while the script ran. Nothing was written, and nothing should be.
  gone,
}

/// The durable record of code executions, in the workspace database.
///
/// A record is written in three steps, so it survives a server that dies
/// mid-script: [begin] when the host admits the script (status `running`,
/// with the source), [appendCall] as each nested call settles, and [finish]
/// once at the end, which sets the terminal fields of a record that is still
/// running and nothing else. A finished record and a call row are never
/// changed or replaced. Records a dead server left running are finished by
/// the next start (`server_stopped`). [close] is the last resort when a
/// finish fails: it ends the record with the least it can write.
///
/// Every method takes the workspace explicitly and resolves its database per
/// call; nothing here caches a workspace's DAO. Rows are deleted with their
/// run, and with the space they were recorded in.
abstract interface class CodeExecutionRepository {
  /// Records an admitted script: [execution], whose status is
  /// [CodeExecutionStatus.running], and its [source].
  ///
  /// A conversation or agent the execution names that no longer exists in
  /// the workspace is recorded as none: who may read a record is decided by
  /// its space alone. A space that no longer exists is refused instead,
  /// because a record without one is readable by every member.
  ///
  /// Throws [CodeExecutionBeginRefused] when the run has no run log, the id
  /// is taken or the space is gone, and [ArgumentError] when [execution] is
  /// not running. Nothing is written in any of those cases.
  Future<void> begin(
    String workspaceId,
    CodeExecution execution, {
    required String source,
  });

  /// Records one settled nested call of a running execution, or writes
  /// nothing and says why: the execution is no longer running (it was
  /// finished, or deleted with its run or space), or it already has a call
  /// row with this sequence (a call row is written once).
  Future<CodeExecutionAppendOutcome> appendCall(
    String workspaceId,
    CodeExecutionCall call,
  );

  /// Finishes the running record [execution].id with [execution]'s terminal
  /// fields (status, error kind, duration, counts, sizes, runner details),
  /// [payload]'s output, console and error name, and those of [calls] whose
  /// sequence has no row yet, in one transaction that only a running record
  /// passes. A call row already recorded is kept as it is, so a call
  /// appended while the finish was on its way cannot fail the finish.
  ///
  /// The conversation, agent, space, description, start time and source
  /// recorded at [begin] are not touched. Throws [StateError] when the record
  /// is already finished (a finished record never changes), and
  /// [ArgumentError] when [execution] is still running or [payload] or a
  /// call names another execution.
  Future<CodeExecutionFinishResult> finish(
    String workspaceId,
    CodeExecution execution, {
    required CodeExecutionPayload payload,
    required List<CodeExecutionCall> calls,
  });

  /// Ends the running record [executionId] with [status], [errorKind] and
  /// [durationMs] and nothing else: no payload, no call rows. For a record
  /// whose [finish] failed, so it does not stay running while the server
  /// lives. Returns false, writing nothing, when the record is not running
  /// (finished meanwhile, or gone).
  Future<bool> close(
    String workspaceId,
    String executionId, {
    required CodeExecutionStatus status,
    required String errorKind,
    required int durationMs,
  });

  /// The highest `#<n>` suffix among the recorded ids of [runId]'s `repl`
  /// call [toolCallId] in one read: 0 when none is recorded, 1 when only the
  /// plain id ([CodeExecution.idFor]) is, else the largest n.
  Future<int> highestIdSuffix(
    String workspaceId, {
    required String runId,
    required String toolCallId,
  });

  /// One page of [workspaceId]'s executions matching [query].
  Future<CodeExecutionPage> list(String workspaceId, CodeExecutionQuery query);

  /// The execution [executionId] of [workspaceId] with its payload and calls,
  /// or null when the workspace has no such execution.
  Future<CodeExecutionDetail?> get(String workspaceId, String executionId);
}
