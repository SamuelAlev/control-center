import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart'
    show CommandWaitRelay;
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The execution service as one dispatch session sees it: the server's one
/// [CodeExecutionPort], with the two things a run adds around each script.
///
/// - **Origins, per loop.** Each loop of the session (the top-level run and
///   every subagent, at any depth) has a [RunScriptOrigins] of its own and
///   runs its scripts through [forLoop] with it. Before the first nested
///   call of a script reaches the gate, the execution id the service chose
///   is registered in that loop's origins (`begin`), and removed when the
///   script ends (`end`). The approval card of a script's call, the form of
///   a script's question and a script's `bash` command then name the
///   execution the service records, including a `#<n>` id after a repeated
///   tool call id, and never another loop's script that happens to share
///   the parent tool call id (a provider can reuse `call_0` in a child).
/// - **Teardown, per session.** Every script of every loop is also bound to
///   the run's own end: [close] cancels whatever is still running and waits
///   until each script has ended, which is when the service has seen its
///   runner process exit. The session calls it before it reports itself
///   finished, whichever way the run ends (completion, error, a stop, a
///   shutdown).
/// - **Gateway cards, per session.** From a script's first nested call until
///   it ends, its approval budget is held on the run's gateway lease
///   ([CommandWaitRelay.holdScriptApprovals]), so an approval card the
///   gateway raises for the run (a push or an environment command one of the
///   run's commands makes) counts against it like a card for its own call.
///
/// - **Slots, per session.** Every script of every loop is sent as one run
///   tree's ([CodeExecutionRequest.runTree], a key of this instance), so
///   the run and its subagents together hold at most half of their
///   workspace's runner slots; past that their scripts wait in the same
///   queue as everyone's.
///
/// One instance per session, shared by its subagents' loops.
final class RunCodeExecutions {
  /// Wraps [_service] for one dispatch session whose gateway lease is
  /// `gateway` (null when the run has none).
  RunCodeExecutions(this._service, {required this._gateway});

  final CodeExecutionPort _service;
  final CommandWaitRelay? _gateway;
  final CancellationTokenSource _runEnd = CancellationTokenSource();
  final Set<Future<void>> _running = {};

  /// This session's run tree: unique in the process.
  final String _tree = 'session-${_sessions++}';
  static int _sessions = 0;

  /// How long [close] waits for the scripts it cancelled. A cancelled script
  /// ends within the runner's kill grace and the nested settle grace; this
  /// only bounds a stop against a service that never answers.
  static const Duration closeGrace = Duration(seconds: 30);

  /// Scripts of this run, of every loop, that have not ended yet.
  int get runningCount => _running.length;

  /// The service as the loop whose scripts register in [origins] sees it:
  /// that loop's `repl` binding. Its scripts end with [close] like every
  /// other script of the session.
  CodeExecutionPort forLoop(RunScriptOrigins origins) =>
      _LoopCodeExecutions(this, origins);

  Future<CodeExecutionResult> _execute(
    CodeExecutionRequest request,
    RunScriptOrigins origins, {
    required ScriptNestedCall callNested,
    required CancellationToken cancel,
  }) {
    final registered = <(String, String)>{};
    final holds = <void Function()>[];
    final result = _service.execute(
      request.inRunTree(_tree),
      callNested: (call) {
        final origin = call.origin;
        // The service names the execution on every call it makes.
        final executionId = origin.executionId;
        if (executionId != null &&
            registered.add((origin.parentToolCallId, executionId))) {
          origins.begin(origin.parentToolCallId, executionId);
          final gateway = _gateway;
          if (gateway != null) {
            holds.add(
              gateway.holdScriptApprovals(
                origins.approvalsOf(origin.parentToolCallId),
              ),
            );
          }
        }
        return callNested(call);
      },
      cancel: CancellationToken.any([cancel, _runEnd.token]),
    );
    late final Future<void> ended;
    ended = result.then<void>((_) {}, onError: (Object _) {}).whenComplete(() {
      for (final release in holds) {
        release();
      }
      for (final (parent, executionId) in registered) {
        origins.end(parent, executionId);
      }
      _running.remove(ended);
    });
    _running.add(ended);
    return result;
  }

  /// Cancels every script of this run (every loop's) that is still running
  /// and waits until each has ended. A script started afterwards starts
  /// already cancelled, so it never gets a runner.
  Future<void> close() async {
    _runEnd.cancel('The run ended.');
    if (_running.isEmpty) {
      return;
    }
    try {
      await Future.wait(_running.toList()).timeout(closeGrace);
    } on TimeoutException {
      CcInfraLog.error(
        'code mode: ${_running.length} script(s) did not end within '
        '${closeGrace.inSeconds} s of the run ending',
      );
    }
  }
}

/// One loop's view of the session's [RunCodeExecutions]: its scripts
/// register in that loop's own origins.
final class _LoopCodeExecutions implements CodeExecutionPort {
  _LoopCodeExecutions(this._run, this._origins);

  final RunCodeExecutions _run;
  final RunScriptOrigins _origins;

  @override
  CodeRunnerAvailability get availability => _run._service.availability;

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) =>
      _run._execute(request, _origins, callNested: callNested, cancel: cancel);
}
