import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/services/redaction/sensitive_arguments.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// One nested tool call of a script and how it ended.
///
/// It keeps what the call's row and the script's result need, never a
/// result value, and its argument object only until the gate has it (a
/// question's until it settles): a script that makes thousands of calls
/// leaves a bounded row's worth of each on the server's heap.
class ScriptCall {
  /// Creates a call the script made; it has not started.
  ScriptCall({
    required this.replyId,
    required this.sequence,
    required this.toolCallId,
    required this.name,
    required Map<String, dynamic> arguments,
    required this.argumentBytes,
    required this.isQuestion,
    required this.parallel,
    required this.site,
  }) : _arguments = arguments,
       argumentsJson = CodeExecutionCall.boundArguments(
         jsonEncode(SensitiveArguments.redact(arguments)),
       );

  /// The runner's id for the call, which its reply names.
  final String replyId;

  /// One-based position in the script's call order.
  final int sequence;

  /// The nested transcript id.
  final String toolCallId;

  /// The tool's raw name.
  final String name;

  Map<String, dynamic>? _arguments;

  /// The argument object until [start] hands it to the gate (a question's
  /// until it settles), then null.
  Map<String, dynamic>? get arguments => _arguments;

  /// The redacted arguments as the row keeps them, at most
  /// [CodeExecutionCall.maxArgumentsBytes].
  final String argumentsJson;

  /// Size of the arguments in UTF-8 bytes.
  final int argumentBytes;

  /// Whether it asks a person a question.
  final bool isQuestion;

  /// Whether it may run beside other calls (a read with no effects).
  final bool parallel;

  /// Where in the script it was made, as the runner reported it; for the
  /// row only (see [CodeExecutionCall.site]).
  final ScriptCallSite? site;

  bool _started = false;

  /// Whether it was handed to the surface's gate.
  bool get started => _started;

  /// Marks the call handed to the gate and returns its arguments for the
  /// gate's request, which holds them from then on.
  Map<String, dynamic> start() {
    final arguments = _arguments;
    if (_started || arguments == null) {
      throw StateError('a call starts once');
    }
    _started = true;
    if (!isQuestion) {
      _arguments = null;
    }
    return arguments;
  }

  /// What the gate decided when it let the tool itself start, once the
  /// surface reported that ([NestedCallRequest.onToolStarted]).
  NestedCallGateDecision? toolStartedAfter;

  /// Whether the surface reported that the tool itself started.
  bool toolStarted = false;

  /// Milliseconds from the script's admission to the call's start.
  int startOffsetMs = 0;

  /// Milliseconds from start to settle.
  int durationMs = 0;

  /// Person waits of this call still open.
  int waitDepth = 0;

  NestedCallOutcome? _outcome;
  ScriptQuestionRecord? _question;

  /// How it ended, once it settled: without its value, with its error
  /// bounded to [CodeExecutionCall.maxErrorChars].
  NestedCallOutcome? get outcome => _outcome;

  /// What a started question asked and what the person answered (not
  /// answered until it settles); null for any other call.
  ScriptQuestionRecord? get questionRecord {
    if (!isQuestion || !_started) {
      return null;
    }
    return _question ??
        ScriptQuestionRecord.fromNestedCall(
          arguments: _arguments!,
          status: NestedCallStatus.cancelled,
        );
  }

  /// Settles the call with [outcome]. Keeps the status, sizes, durations,
  /// gate decision and a bounded error; the value goes to the script from
  /// the caller's hands, never from here.
  void settle(NestedCallOutcome outcome) {
    if (_outcome != null) {
      throw StateError('a call settles once');
    }
    final arguments = _arguments;
    if (isQuestion && arguments != null) {
      _question = ScriptQuestionRecord.fromNestedCall(
        arguments: arguments,
        status: outcome.status,
        value: outcome.value,
      );
      _arguments = null;
    }
    final error = outcome.errorMessage;
    _outcome = NestedCallOutcome(
      status: outcome.status,
      errorMessage: error == null ? null : CodeExecutionCall.boundError(error),
      gateDecision: outcome.gateDecision,
      durationMs: outcome.durationMs,
      approvalWaitMs: outcome.approvalWaitMs,
      resultBytes: outcome.resultBytes,
    );
  }

  /// [text] as it may appear in a server log line: one line, control and
  /// bidirectional characters replaced, at most
  /// [CodeExecutionCall.maxErrorChars] characters. Text a tool or a script
  /// chose reaches the log of a call that outlived its script only this way.
  static String lateOutcomeLabel(String text) =>
      oneLineLabel(text, CodeExecutionCall.maxErrorChars);

  /// The detail of a call whose tool was still running when its script
  /// stopped waiting for it, at the script's end or at the call's own
  /// deadline. The script reads it too, as the rejection of that call, so it
  /// must be true while the script is still running.
  static const String stillRunningDetail =
      'The tool was still running when the script stopped waiting for it; '
      'what it did afterwards is not in this record.';

  /// The call row. A call still unsettled when the script ended is recorded
  /// as cancelled, saying how far it got: not started, at its gate, or with
  /// its tool still running (then with the gate decision it passed). Its
  /// duration then runs to [endedAtMs], the script's end, when given.
  CodeExecutionCall summary(String executionId, {int? endedAtMs}) {
    final o = outcome;
    final status = o?.status ?? NestedCallStatus.cancelled;
    final String? error;
    var duration = durationMs;
    if (o == null) {
      error = !started
          ? 'The script ended before the call started.'
          : toolStarted
          ? stillRunningDetail
          : 'The script ended before the gate reported that the tool '
                'started.';
      if (started && endedAtMs != null && endedAtMs > startOffsetMs) {
        duration = endedAtMs - startOffsetMs;
      }
    } else {
      error = o.errorMessage;
    }
    return CodeExecutionCall(
      executionId: executionId,
      sequence: sequence,
      toolCallId: toolCallId,
      toolName: name,
      startOffsetMs: startOffsetMs,
      durationMs: duration,
      status: status,
      gateDecision: o?.gateDecision ?? (toolStarted ? toolStartedAfter : null),
      approvalWaitMs: o?.approvalWaitMs ?? 0,
      argumentBytes: argumentBytes,
      resultBytes: o?.resultBytes ?? 0,
      argumentsJson: argumentsJson,
      error: error == null || status == NestedCallStatus.completed
          ? null
          : CodeExecutionCall.boundError(error),
      site: site,
    );
  }
}

/// Every write of one execution's record, in one ordered queue: [begin],
/// then an [append] per settled call, then one [finish].
///
/// Each write starts only after the one before it has ended, so the finish
/// sees every append that was accepted and writes only the call rows still
/// missing; a call that settles after the finish was queued is a late event
/// that goes to the server log, since a finished record never changes. An
/// append the store refuses is logged with why. A finish that fails is
/// followed by [CodeExecutionRepository.close], so the record does not stay
/// running while the server lives.
class ExecutionRecorder {
  /// Creates the recorder of one execution in [workspaceId].
  ExecutionRecorder(this._executions, {required this.workspaceId});

  final CodeExecutionRepository _executions;

  /// The execution's workspace.
  final String workspaceId;

  Future<void> _tail = Future.value();
  bool _finishing = false;
  final Set<int> _recorded = {};

  /// Whether the finish is queued: later calls are late events.
  bool get finishing => _finishing;

  /// Takes no more appends: a call that settles from now on is a late event,
  /// logged and not recorded. The service calls it before it takes the
  /// call rows its result and its finish both state.
  void stopAppends() => _finishing = true;

  Future<T> _queued<T>(Future<T> Function() write) {
    final result = _tail.then((_) => write());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Records [running] and its [source]. Throws what the repository throws.
  Future<void> begin(CodeExecution running, {required String source}) =>
      _queued(() => _executions.begin(workspaceId, running, source: source));

  /// Records [call], which has settled, on the running record [executionId];
  /// after the finish was queued, logs its outcome instead.
  void append(String executionId, ScriptCall call) {
    if (_finishing) {
      final o = call.outcome;
      CcInfraLog.info(
        'code mode: call ${call.sequence} (${call.name}) of $executionId in '
        'workspace $workspaceId settled after its script ended, as '
        '${o?.status.wire ?? 'unknown'}'
        '${o?.errorMessage == null ? '' : ': ${ScriptCall.lateOutcomeLabel(o!.errorMessage!)}'}'
        '; its record is closed and does not hold this.',
      );
      return;
    }
    final row = call.summary(executionId);
    unawaited(
      _queued(() async {
        try {
          final outcome = await _executions.appendCall(workspaceId, row);
          switch (outcome) {
            case CodeExecutionAppendOutcome.appended:
              _recorded.add(call.sequence);
            case CodeExecutionAppendOutcome.notRunning:
              CcInfraLog.warning(
                'code mode: call ${call.sequence} of $executionId was not '
                'recorded: the record is no longer running (finished, or '
                'deleted with its run or space).',
              );
            case CodeExecutionAppendOutcome.sequenceTaken:
              _recorded.add(call.sequence);
              CcInfraLog.warning(
                'code mode: call ${call.sequence} of $executionId was not '
                'recorded again: a row with its sequence is already there.',
              );
          }
        } on Object catch (e, st) {
          CcInfraLog.error(
            'code mode: recording call ${call.sequence} of $executionId '
            'failed; it is written with the finished record',
            e,
            st,
          );
        }
      }),
    );
  }

  /// Finishes the record once, after every queued append: [ended]'s terminal
  /// fields, [payload], and the rows of [calls] (taken now, as the result
  /// states them) that no append recorded. Returns what the repository did,
  /// or null when the finish failed; the record is then closed as a
  /// sandbox error by the smallest write, and both are logged.
  Future<CodeExecutionFinishResult?> finish(
    CodeExecution ended, {
    required CodeExecutionPayload payload,
    required List<CodeExecutionCall> calls,
  }) {
    _finishing = true;
    return _queued(() async {
      try {
        return await _executions.finish(
          workspaceId,
          ended,
          payload: payload,
          calls: [
            for (final c in calls)
              if (!_recorded.contains(c.sequence)) c,
          ],
        );
      } on Object catch (e, st) {
        CcInfraLog.error(
          'code mode: the record of ${ended.id} was not finished',
          e,
          st,
        );
        await _close(ended);
        return null;
      }
    });
  }

  Future<void> _close(CodeExecution ended) async {
    try {
      final closed = await _executions.close(
        workspaceId,
        ended.id,
        status: CodeExecutionStatus.sandboxError,
        errorKind: CodeExecutionErrorKind.hostError,
        durationMs: ended.durationMs,
      );
      CcInfraLog.warning(
        closed
            ? 'code mode: the record of ${ended.id} was closed as '
                  'sandbox_error/host_error, without its output and '
                  'remaining call rows, after its finish failed.'
            : 'code mode: the record of ${ended.id} was no longer running '
                  'when it was to be closed after its finish failed.',
      );
    } on Object catch (e, st) {
      CcInfraLog.error(
        'code mode: the record of ${ended.id} could not be closed either; '
        'the next server start finishes it as server_stopped',
        e,
        st,
      );
    }
  }
}
