import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart' show PersonWaitListener;
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/dispatch/run_code_executions.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:test/test.dart';

/// A script's approval budget is held on the run's gateway lease from its
/// first nested call until it ends, so the cards the gateway raises for the
/// run while it runs count against it.
void main() {
  late _Relay relay;
  late _Service service;
  late RunScriptOrigins origins;

  setUp(() {
    relay = _Relay();
    service = _Service();
    origins = RunScriptOrigins(runId: 'run-1');
  });

  Future<CodeExecutionResult> start(RunCodeExecutions executions) => executions
      .forLoop(origins)
      .execute(
        CodeExecutionRequest(
          readOnly: false,
          past: null,
          workspaceId: 'ws-1',
          runId: 'run-1',
          parentToolCallId: 'call_repl',
          surface: CodeExecutionSurface.harness,
          code: 'await tools.read({})',
          description: 'reads',
          limits: CodeModeLimits(),
          tools: const [],
        ),
        callNested: (call) async =>
            NestedCallOutcome(status: NestedCallStatus.completed),
      );

  test('held from the first nested call to the script\'s end, once', () async {
    final executions = RunCodeExecutions(service, gateway: relay);
    final result = start(executions);
    await service.started.future;
    expect(relay.held, isEmpty, reason: 'nothing held before a call');

    await service.call(1);
    await service.call(2);
    expect(relay.held, hasLength(1));
    expect(relay.held.single, same(origins.approvalsOf('call_repl')));
    expect(relay.released, 0);

    service.end.complete();
    await expectLater(result, throwsStateError);
    expect(relay.released, 1);
  });

  test('a run with no gateway lease holds nothing', () async {
    final executions = RunCodeExecutions(service, gateway: null);
    final result = start(executions);
    await service.started.future;
    await service.call(1);
    service.end.complete();
    await expectLater(result, throwsStateError);
    expect(relay.held, isEmpty);
  });
}

/// Makes the nested calls the test asks for, then ends when [end] completes
/// (with an error: no record is built here).
class _Service implements CodeExecutionPort {
  final started = Completer<void>();
  final end = Completer<void>();
  late ScriptNestedCall _callNested;

  Future<void> call(int sequence) => _callNested(
    NestedCallRequest(
      sequence: sequence,
      toolCallId: 'call_repl/$sequence',
      name: 'read',
      arguments: const {},
      origin: ScriptCallOrigin(
        parentToolCallId: 'call_repl',
        executionId: 'run-1/call_repl',
      ),
      deadline: const Duration(seconds: 5),
      site: null,
    ),
  );

  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.unavailable('test');

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    _callNested = callNested;
    started.complete();
    await end.future;
    throw StateError('no record in this test');
  }
}

class _Relay implements CommandWaitRelay {
  final held = <ScriptApprovalBudget>[];
  int released = 0;

  @override
  CommandWait register(
    PersonWaitListener listener,
    Map<String, String> env, {
    required void Function(bool approved) decided,
  }) => throw StateError('no command in this test');

  @override
  void Function() holdScriptApprovals(ScriptApprovalBudget approvals) {
    held.add(approvals);
    return () => released++;
  }
}
