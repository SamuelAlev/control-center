import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_persistence/database/daos/code_mode_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/code_execution_mapper.dart';

const _mapper = CodeExecutionMapper();

/// Drift-backed [CodeExecutionRepository]: the audit record of `repl` calls
/// in each workspace's own database.
///
/// Holds the [WorkspaceDatabaseManager] and resolves the DAO per call: a
/// cached per-workspace DAO would answer every workspace from the first one.
/// The manager refuses an invalid or deleted workspace id before opening a
/// file.
///
/// An execution belongs to a run: [begin] refuses one whose run has no
/// `agent_run_logs` row in the workspace, because the row could neither be
/// kept with its run nor removed with it.
class DaoCodeExecutionRepository implements CodeExecutionRepository {
  /// Creates a [DaoCodeExecutionRepository] over the per-workspace databases.
  DaoCodeExecutionRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  CodeModeDao _dao(String workspaceId) => _dbs.of(workspaceId).codeModeDao;

  @override
  Future<void> begin(
    String workspaceId,
    CodeExecution execution, {
    required String source,
  }) async {
    if (execution.status != CodeExecutionStatus.running) {
      throw ArgumentError.value(
        execution.status.wire,
        'execution.status',
        'a record begins running',
      );
    }
    final result = await _dao(workspaceId).beginExecution(
      _mapper.toCompanion(execution),
      _mapper.payloadToCompanion(
        CodeExecutionPayload.bounded(executionId: execution.id, source: source),
      ),
    );
    switch (result) {
      case CodeExecutionBeginResult.begun:
        return;
      case CodeExecutionBeginResult.noRun:
        throw CodeExecutionBeginRefused(
          CodeExecutionBeginRefusal.noRun,
          execution.id,
        );
      case CodeExecutionBeginResult.idTaken:
        throw CodeExecutionBeginRefused(
          CodeExecutionBeginRefusal.idTaken,
          execution.id,
        );
      case CodeExecutionBeginResult.spaceGone:
        throw CodeExecutionBeginRefused(
          CodeExecutionBeginRefusal.spaceGone,
          execution.id,
        );
    }
  }

  @override
  Future<CodeExecutionAppendOutcome> appendCall(
    String workspaceId,
    CodeExecutionCall call,
  ) async {
    final result = await _dao(
      workspaceId,
    ).appendCall(_mapper.callToCompanion(call));
    return switch (result) {
      CodeExecutionAppendResult.appended => CodeExecutionAppendOutcome.appended,
      CodeExecutionAppendResult.notRunning =>
        CodeExecutionAppendOutcome.notRunning,
      CodeExecutionAppendResult.sequenceTaken =>
        CodeExecutionAppendOutcome.sequenceTaken,
    };
  }

  @override
  Future<CodeExecutionFinishResult> finish(
    String workspaceId,
    CodeExecution execution, {
    required CodeExecutionPayload payload,
    required List<CodeExecutionCall> calls,
  }) async {
    if (!execution.status.isTerminal) {
      throw ArgumentError.value(
        execution.status.wire,
        'execution.status',
        'a record is finished with how it ended',
      );
    }
    if (payload.executionId != execution.id) {
      throw ArgumentError.value(
        payload.executionId,
        'payload.executionId',
        'names another execution than ${execution.id}',
      );
    }
    final sequences = <int>{};
    for (final call in calls) {
      if (call.executionId != execution.id) {
        throw ArgumentError.value(
          call.executionId,
          'calls.executionId',
          'names another execution than ${execution.id}',
        );
      }
      if (!sequences.add(call.sequence)) {
        throw ArgumentError.value(
          call.sequence,
          'calls.sequence',
          'appears twice',
        );
      }
    }
    final outcome = await _dao(workspaceId).finishExecution(
      id: execution.id,
      terminal: _mapper.terminalCompanion(execution),
      output: payload.output,
      console: payload.console,
      errorName: payload.errorName,
      calls: [for (final call in calls) _mapper.callToCompanion(call)],
    );
    switch (outcome) {
      case CodeExecutionFinishOutcome.finished:
        return CodeExecutionFinishResult.finished;
      case CodeExecutionFinishOutcome.gone:
        return CodeExecutionFinishResult.gone;
      case CodeExecutionFinishOutcome.alreadyFinished:
        throw StateError(
          'Code execution ${execution.id} in workspace $workspaceId is '
          'already finished; a finished record never changes.',
        );
    }
  }

  @override
  Future<bool> close(
    String workspaceId,
    String executionId, {
    required CodeExecutionStatus status,
    required String errorKind,
    required int durationMs,
  }) {
    if (!status.isTerminal) {
      throw ArgumentError.value(
        status.wire,
        'status',
        'a record is closed with how it ended',
      );
    }
    return _dao(workspaceId).closeRunning(
      id: executionId,
      status: status.wire,
      errorKind: errorKind,
      durationMs: durationMs,
    );
  }

  @override
  Future<int> highestIdSuffix(
    String workspaceId, {
    required String runId,
    required String toolCallId,
  }) async => _dao(workspaceId).highestIdSuffix(runId, toolCallId);

  @override
  Future<CodeExecutionPage> list(
    String workspaceId,
    CodeExecutionQuery query,
  ) async {
    final after = _decodeCursor(query.cursor);
    // One row past the page says whether an older page exists without a
    // second query.
    final rows = await _dao(workspaceId).page(
      limit: query.limit + 1,
      after: after,
      runId: query.runId,
      conversationId: query.conversationId,
      agentId: query.agentId,
      spaceId: query.spaceId,
      toolCallId: query.toolCallId,
      hiddenSpaceIds: query.hiddenSpaceIds,
      statuses: {for (final s in query.statuses) s.wire},
      surface: query.surface?.wire,
      sinceMs: query.since?.millisecondsSinceEpoch,
      untilMs: query.until?.millisecondsSinceEpoch,
    );
    final more = rows.length > query.limit;
    final page = more ? rows.sublist(0, query.limit) : rows;
    return CodeExecutionPage(
      items: [for (final row in page) _mapper.fromRow(row)],
      nextCursor: more
          ? _encodeCursor((
              startedAtMs: page.last.startedAtMs,
              id: page.last.id,
            ))
          : null,
    );
  }

  @override
  Future<CodeExecutionDetail?> get(
    String workspaceId,
    String executionId,
  ) async {
    final dao = _dao(workspaceId);
    final row = await dao.executionById(executionId);
    if (row == null) {
      return null;
    }
    final payload = await dao.payloadOf(executionId);
    final calls = await dao.callsOf(executionId);
    return CodeExecutionDetail(
      execution: _mapper.fromRow(row),
      payload: payload == null ? null : _mapper.payloadFromRow(payload),
      calls: [for (final call in calls) _mapper.callFromRow(call)],
    );
  }

  /// The cursor is base64url JSON of the last row's position, so callers
  /// treat it as opaque.
  static String _encodeCursor(CodeExecutionPosition position) =>
      base64Url.encode(
        utf8.encode(jsonEncode({'t': position.startedAtMs, 'i': position.id})),
      );

  /// Decodes [cursor], or null for the newest page.
  ///
  /// A cursor this repository did not write is refused with a
  /// [ValidationException] rather than read as "start again": a pager that
  /// restarts from the newest page on a bad cursor never ends.
  static CodeExecutionPosition? _decodeCursor(String? cursor) {
    if (cursor == null || cursor.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(cursor)));
      if (decoded case {
        't': final int t,
        'i': final String i,
      } when i.isNotEmpty) {
        return (startedAtMs: t, id: i);
      }
    } on FormatException {
      // Falls through to the refusal below.
    }
    throw const ValidationException(
      'The cursor is not one this list returned.',
      code: 'invalid_cursor',
    );
  }
}
