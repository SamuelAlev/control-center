import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/dispatch/run_code_executions.dart';
import 'package:test/test.dart';

/// Every script of a session, whichever loop runs it (the run or a
/// subagent), is sent as one run tree's, and two sessions are two trees: the
/// slots a run and its subagents hold together are bounded by that key.
void main() {
  CodeExecutionRequest request(String runId) => CodeExecutionRequest(
    readOnly: false,
    past: null,
    workspaceId: 'ws-1',
    runId: runId,
    parentToolCallId: 'call_repl',
    surface: CodeExecutionSurface.harness,
    code: 'return 1',
    description: 'one',
    limits: CodeModeLimits(),
    tools: const [],
  );

  test('a session\'s loops share one run tree; sessions do not', () async {
    final service = _Service();
    final first = RunCodeExecutions(service, gateway: null);
    final second = RunCodeExecutions(service, gateway: null);
    for (final (executions, run) in [
      (first, 'parent'),
      (first, 'subagent'),
      (second, 'other'),
    ]) {
      await expectLater(
        executions
            .forLoop(RunScriptOrigins(runId: run))
            .execute(request(run), callNested: (_) => throw StateError('x')),
        throwsStateError,
      );
    }
    final trees = [for (final r in service.requests) r.runTree];
    expect(trees.every((t) => t != null && t.isNotEmpty), isTrue);
    expect(trees[0], trees[1]);
    expect(trees[2], isNot(trees[0]));
    expect(
      [for (final r in service.requests) r.runId],
      ['parent', 'subagent', 'other'],
    );
  });
}

class _Service implements CodeExecutionPort {
  final List<CodeExecutionRequest> requests = [];

  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    requests.add(request);
    throw StateError('no record is built here');
  }
}
