// What a model reads when the server fails under `repl` names the failure
// and what to do, never the exception's text: it can carry a host path.
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:test/test.dart';

const _secret = '/Users/someone/Library/Application Support/cc/data';

Never _fail() =>
    throw const FileSystemException('Cannot open file', '$_secret/x.db');

class _Throwing implements ToolReentry {
  @override
  Map<String, HarnessTool> get callable => const {};

  @override
  Future<ToolReentryOutcome> call(
    String name,
    Object? args, {
    CancellationToken? cancel,
    Duration? timeout,
    PersonWaitListener? onPersonWait,
    void Function(ToolGateVerdict verdict)? onToolStarted,
    ({int line, int column})? site,
  }) async => _fail();
}

class _ThrowingPort implements CodeExecutionPort {
  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.available();

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async => _fail();
}

void main() {
  test('a nested call whose gate throws fails with fixed text naming the '
      'tool', () async {
    final o = await callThroughReentry(
      _Throwing(),
      NestedCallRequest(
        sequence: 1,
        toolCallId: 'p/1',
        name: 'read',
        arguments: const {},
        origin: ScriptCallOrigin(parentToolCallId: 'p', executionId: 'e'),
        deadline: const Duration(seconds: 3),
        site: null,
      ),
    );
    expect(o.status, NestedCallStatus.failed);
    expect(o.errorMessage, contains('The call to read failed on the server'));
    expect(o.errorMessage, contains('may have taken effect'));
    expect(o.errorMessage, contains('check before repeating'));
    expect(o.errorMessage, isNot(contains('Users')));
    expect(o.errorMessage, isNot(contains('Cannot open')));
  });

  test('a repl call the service throws on says what to do, not what was '
      'thrown', () async {
    final tool = ReplTool(
      executor: _ThrowingPort(),
      run: ReplRunIdentity(
        readOnly: false,
        past: null,
        workspaceId: 'ws',
        runId: 'run-1',
        conversationId: 'conv',
        agentId: 'agent',
        spaceId: 'space',
        storeEnabled: false,
      ),
      callableTools: const [],
      directToolNames: const {},
      limits: CodeModeLimits(),
    );
    final result = await tool.execute(
      const {'code': 'return 1', 'description': 'one'},
      HarnessToolContext(
        workingDirectory: '/',
        toolCallId: 'call_1',
        reentry: _Throwing(),
      ),
    );
    expect(result.isError, isTrue);
    expect(result.content, contains('The script could not be run'));
    expect(result.content, contains('Call the tools directly'));
    expect(result.content, isNot(contains('Users')));
    expect(result.content, isNot(contains('Cannot open')));
  });
}
