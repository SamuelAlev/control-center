// A call already running when a person wait opens goes on, within the time
// the script had left when the call started: the paused script clock does not
// extend it. Against the real runner and the real loop's gate, which is what
// enforces a nested call's deadline on the harness.
import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/harness/repl_tool.dart' show callThroughReentry;
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

class _Tool extends HarnessTool {
  _Tool(this.name, this.body, {this.waitsOnPerson = false});

  @override
  final String name;
  final Future<HarnessToolResult> Function() body;
  @override
  final bool waitsOnPerson;

  @override
  String get description => name;
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get parallelSafe => true;
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) => body();
}

class _Parent extends HarnessTool {
  _Parent(this.body);
  final Future<void> Function(HarnessToolContext context) body;
  @override
  String get name => 'parent';
  @override
  String get description => 'Runs a script.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get selfGuards => true;
  @override
  bool get parallelSafe => false;
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    await body(context);
    return HarnessToolResult.success('script finished');
  }
}

class _Provider extends LlmProviderPort {
  int calls = 0;
  @override
  String get displayName => 'in flight';
  @override
  String get defaultModel => 'controlled';
  @override
  Future<List<ProviderModel>> listModels() async => const [];
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (calls++ == 0) {
      yield const LlmToolUseDelta(
        id: 'call_1',
        name: 'parent',
        argumentsJson: '{}',
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

ScriptToolDescriptor _descriptor(String name) => ScriptToolDescriptor(
  name: name,
  namespace: ScriptToolNamespace.builtin,
  description: name,
  inputSchema: const {'type': 'object'},
);

void main() {
  test('a call started before a question opens ends at the time the script had '
      'left, not later, while the question is open; a call sent after the '
      'question opened never starts', () async {
    final process = CodeSandboxProcess(executable: realRunnerPath());
    expect((await process.selfTest()).isAvailable, isTrue);
    final service = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: MemoryStore(),
    );
    addTearDown(service.dispose);

    final answer = Completer<HarnessToolResult>();
    var reads = 0;
    final slow = _Tool(
      'slow',
      () => Future.delayed(
        const Duration(seconds: 5),
        () => HarnessToolResult.success('slow'),
      ),
    );
    final ask = _Tool('ask_user', () => answer.future, waitsOnPerson: true);
    final read = _Tool('read', () async {
      reads++;
      return HarnessToolResult.success('read');
    });
    // `slow` is sent first, so it is running before the question's wait
    // opens. The script waits out the slow call's time without awaiting it
    // (a parked script receives no reply until it holds a slot again), then
    // sends `read` with the wait still open.
    const code = '''
tools.slow({}).catch(() => {});
tools.ask_user({}).catch(() => {});
await sleep(3500);
tools.read({}).catch(() => {});
return 'sent';
''';
    final executed = Completer<CodeExecutionResult>();
    final parent = _Parent((context) async {
      executed.complete(
        await service.execute(
          CodeExecutionRequest(
            readOnly: false,
            past: null,
            workspaceId: 'ws-1',
            runId: 'run-1',
            parentToolCallId: 'call_1',
            surface: CodeExecutionSurface.harness,
            code: code,
            description: 'in flight',
            limits: CodeModeLimits(wallClockMs: 2000),
            tools: [
              _descriptor('slow'),
              _descriptor('ask_user'),
              _descriptor('read'),
            ],
          ),
          callNested: (call) => callThroughReentry(context.reentry!, call),
        ),
      );
    });
    final cwd = Directory.systemTemp.createTempSync('cc_in_flight_');
    addTearDown(() => cwd.deleteSync(recursive: true));
    final run = const AgentLoopRunner()
        .run(
          history: <HarnessMessage>[],
          userMessage: 'Run.',
          tools: [parent, slow, ask, read],
          provider: _Provider(),
          context: HarnessToolContext(workingDirectory: cwd.path),
        )
        .drain<void>();
    final result = await executed.future.timeout(const Duration(seconds: 30));
    final questionOpenAtEnd = !answer.isCompleted;
    answer.complete(HarnessToolResult.success('late'));
    await run;

    CodeExecutionCall row(String name) =>
        result.calls.singleWhere((c) => c.toolName == name);
    expect(result.execution.status, CodeExecutionStatus.completed);
    expect(questionOpenAtEnd, isTrue);

    final slowRow = row('slow');
    expect(slowRow.status, NestedCallStatus.timedOut);
    // It had about 2 s left when it started: it ends near 2 s, not at 5 s,
    // although the script's own clock stood still during the question.
    expect(slowRow.durationMs, inInclusiveRange(1500, 3500));
    expect(slowRow.startOffsetMs, lessThan(row('ask_user').startOffsetMs + 1));

    // Still open when the slow call gave up, so settled only at the end.
    final askRow = row('ask_user');
    expect(
      askRow.startOffsetMs + askRow.durationMs,
      greaterThan(slowRow.startOffsetMs + slowRow.durationMs),
    );
    expect(askRow.status, NestedCallStatus.cancelled);

    final readRow = row('read');
    expect(readRow.status, NestedCallStatus.cancelled);
    expect(readRow.error, contains('ended before the call started'));
    expect(reads, 0);
  }, timeout: const Timeout(Duration(minutes: 1)));
}
