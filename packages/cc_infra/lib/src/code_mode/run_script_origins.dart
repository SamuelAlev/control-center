import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';

/// The scripts running in one run right now, by the tool call that started
/// each: the one place a gate looks up which execution a nested call
/// belongs to, and what that script may still ask of a person.
///
/// A tool call id is not unique within a run (a provider can repeat one
/// across turns), so the execution service, not a derivation, decides an
/// execution's id: it starts from [CodeExecution.idFor] and takes `<id>#<n>`
/// when that id is taken. The approval card of a script's call, the form of
/// a script's question and the execution record must all name the same
/// execution, so the gates that build them ask here instead of deriving the
/// id again, which would name the wrong execution after a repeat.
///
/// One instance per loop: the top-level run and each subagent, at any depth,
/// has its own, created with the run id its scripts are recorded under, and
/// its gates (the approval callback bound for that loop, its `ask_user`, its
/// command runner) resolve against it alone. A child that reuses its
/// parent's tool call id (local models emit `call_0` every time) then never
/// names the parent's script, or the other way round.
final class RunScriptOrigins {
  /// Creates the registry for the run whose code executions are recorded
  /// under [runId]. Throws [ArgumentError] when [runId] is empty.
  RunScriptOrigins({required this.runId}) {
    if (runId.isEmpty) {
      throw ArgumentError.value(runId, 'runId', 'must not be empty');
    }
  }

  /// The run id this loop's executions are recorded under: the session's
  /// code mode run id for the top-level loop, the child's run id for a
  /// subagent. [CodeExecution.idFor] derives an execution's first id from it.
  final String runId;

  final Map<String, _Running> _running = {};

  /// Per-parent budgets for nested calls under a parent nothing registered.
  /// Kept for the run: never looser than a registered script's.
  final Map<String, ScriptApprovalBudget> _unregistered = {};

  /// Records that the script started by [parentToolCallId] runs as the
  /// execution [executionId], the id the execution service chose. Calling it
  /// again for the same call and execution keeps the registration (and what
  /// the script already asked); a different execution replaces it.
  void begin(String parentToolCallId, String executionId) {
    if (parentToolCallId.isEmpty || executionId.isEmpty) {
      throw ArgumentError('A running script needs both of its ids.');
    }
    if (_running[parentToolCallId]?.executionId == executionId) {
      return;
    }
    _running[parentToolCallId] = _Running(executionId);
  }

  /// Records that the script [executionId] started by [parentToolCallId]
  /// ended. Leaves a later script registered under the same call id alone,
  /// so one ending never takes another's id away.
  void end(String parentToolCallId, String executionId) {
    if (_running[parentToolCallId]?.executionId == executionId) {
      _running.remove(parentToolCallId);
    }
  }

  /// The origin of a call nested under [parentToolCallId]. It names an
  /// execution only when a script is registered for that call, with the id
  /// the service chose: a call nothing registered says it came from a script
  /// and links no record.
  ScriptCallOrigin originOf(String parentToolCallId) => ScriptCallOrigin(
    parentToolCallId: parentToolCallId,
    executionId: _running[parentToolCallId]?.executionId,
  );

  /// What the script running under [parentToolCallId] may still ask of a
  /// person. A parent nothing registered gets a budget kept for the rest of
  /// the run, so an unregistered caller is never bounded less than a script.
  ScriptApprovalBudget approvalsOf(String parentToolCallId) =>
      _running[parentToolCallId]?.approvals ??
      _unregistered.putIfAbsent(parentToolCallId, ScriptApprovalBudget.new);
}

/// One registration: a script with its execution id.
final class _Running {
  _Running(this.executionId);

  final String executionId;
  final ScriptApprovalBudget approvals = ScriptApprovalBudget();
}
