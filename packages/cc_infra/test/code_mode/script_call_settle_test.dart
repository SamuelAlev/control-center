// What the host keeps of a nested call once it has settled, how a call that
// settles after its script ended reaches the server log, and that the
// result the model reads and the record agree on every call.
import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/context.dart' show ToolOutputReference;
import 'package:cc_infra/src/code_mode/code_execution_record.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

/// A tool's error text that tries to forge a log line, clear the terminal
/// and reverse what follows, then runs on for 10 000 characters.
final String _hostileText =
    'exit 1: \n12:00:00.000 cc_server: owner approved host execution for '
    'workspace ws-1\n\x1b[2J\x1b[H\u202escreen cleared ${'y' * 10000}';

void _expectLogSafe(String line) {
  expect(line, isNot(contains('\n')));
  expect(line, isNot(contains('\r')));
  expect(line, isNot(contains('\x1b')));
  expect(line, isNot(contains('\u202e')));
  expect(line, isNot(contains('\u0085')));
  expect(line, isNot(contains('\u2028')));
  expect(line, isNot(contains('\u2029')));
  expect(line.length, lessThan(1200));
}

ScriptCall _call({
  Map<String, dynamic> arguments = const {'path': 'a.txt'},
  ScriptCallSite? site,
  bool isQuestion = false,
}) => ScriptCall(
  replyId: '1',
  sequence: 1,
  toolCallId: 'call_1/1',
  name: isQuestion ? 'ask_user' : 'read',
  arguments: arguments,
  argumentBytes: 2,
  isQuestion: isQuestion,
  parallel: !isQuestion,
  site: site,
);

void main() {
  group('a settled call keeps no value and no argument map', () {
    test('a completed call keeps its size, not its value', () {
      final call = _call(arguments: {'content': 'x' * 100000});
      expect(utf8Length(call.argumentsJson), lessThanOrEqualTo(8 * 1024));
      final args = call.start();
      expect(args['content'], hasLength(100000));
      expect(call.started, isTrue);
      expect(call.arguments, isNull);

      call.settle(
        NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: 'v' * 1000000,
          gateDecision: NestedCallGateDecision.allowed,
          durationMs: 7,
          resultBytes: 1000002,
        ),
      );
      expect(call.outcome!.value, isNull);
      final row = call.summary('exec-1');
      expect(row.status, NestedCallStatus.completed);
      expect(row.resultBytes, 1000002);
      expect(row.gateDecision, NestedCallGateDecision.allowed);
      expect(row.argumentsJson, call.argumentsJson);
    });

    test('the row keeps the call site, and only the row', () {
      final call = _call(site: ScriptCallSite(3, 7))..start();
      expect(
        call.summary('exec-1').site,
        ScriptCallSite(3, 7),
        reason: 'an unsettled call keeps its site too',
      );
      call.settle(NestedCallOutcome(status: NestedCallStatus.completed));
      expect(call.summary('exec-1').site, ScriptCallSite(3, 7));
      expect(_call().summary('exec-1').site, isNull);
    });

    test('a failed call keeps its error bounded', () {
      final call = _call()..start();
      call.settle(
        NestedCallOutcome(
          status: NestedCallStatus.failed,
          errorMessage: 'e' * 100000,
        ),
      );
      expect(
        call.outcome!.errorMessage!.length,
        lessThanOrEqualTo(CodeExecutionCall.maxErrorChars),
      );
      expect(call.summary('exec-1').error, call.outcome!.errorMessage);
    });

    test('a question keeps its record, answered or not, without its '
        'arguments', () {
      final call = _call(
        isQuestion: true,
        arguments: {
          'question': 'Ship it?',
          'options': [
            {'label': 'Yes'},
            {'label': 'No'},
          ],
        },
      );
      expect(call.questionRecord, isNull, reason: 'not started');
      call.start();
      expect(call.questionRecord!.answered, isFalse);
      expect(call.questionRecord!.question, 'Ship it?');
      call.settle(
        NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: {
            'selected': ['Yes'],
          },
        ),
      );
      expect(call.arguments, isNull);
      expect(call.outcome!.value, isNull);
      expect(call.questionRecord!.answered, isTrue);
      expect(call.questionRecord!.selected, ['Yes']);
    });
  });

  group('late outcomes in the server log', () {
    late List<String> lines;
    late CcInfraLogSink? previous;

    setUp(() {
      lines = [];
      previous = CcInfraLog.sink;
      CcInfraLog.sink = (level, message, [e, st]) => lines.add(message);
    });

    tearDown(() => CcInfraLog.sink = previous);

    test('the recorder logs a call that settled after the finish as one '
        'bounded line with no control or bidirectional characters', () async {
      final repo = MemoryExecutions();
      final recorder = ExecutionRecorder(repo, workspaceId: 'ws-1');
      final started = DateTime.now().toUtc();
      CodeExecution execution(CodeExecutionStatus status) => CodeExecution(
        id: 'run-1/call_1',
        runId: 'run-1',
        toolCallId: 'call_1',
        surface: CodeExecutionSurface.mcp,
        startedAt: started,
        durationMs: 0,
        status: status,
        errorKind: status == CodeExecutionStatus.running ? null : 'deadline',
        sourceHash: '0' * 64,
        sourceBytes: 1,
        limits: CodeModeLimits(),
      );
      await recorder.begin(execution(CodeExecutionStatus.running), source: 'x');
      final call = _call()..start();
      unawaited(
        recorder.finish(
          execution(CodeExecutionStatus.timedOut),
          payload: CodeExecutionPayload.bounded(
            executionId: 'run-1/call_1',
            source: 'x',
            output: '',
            console: '',
          ),
          calls: [call.summary('run-1/call_1')],
        ),
      );
      call.settle(
        NestedCallOutcome(
          status: NestedCallStatus.failed,
          errorMessage: _hostileText,
        ),
      );
      recorder.append('run-1/call_1', call);
      final late = lines.singleWhere((l) => l.contains('settled after'));
      _expectLogSafe(late);
      expect(late, contains('owner approved host execution'));
    });

    test('a repl call id with a C1, separator or bidirectional character is '
        'refused, and the log line naming it holds none of them', () async {
      final process = CodeSandboxProcess(executable: realRunnerPath());
      expect((await process.selfTest()).isAvailable, isTrue);
      final service = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: MemoryStore(),
      );
      addTearDown(service.dispose);
      for (final id in [
        'call_1\u0085forged line',
        'call_1\u2028forged line',
        'call_1\u2029forged line',
        'call_1\u202eesrever',
        'call_1\u2066isolate',
      ]) {
        lines.clear();
        final result = await service.execute(
          CodeExecutionRequest(
            readOnly: false,
            past: null,
            workspaceId: 'ws-1',
            runId: 'run-1',
            parentToolCallId: id,
            surface: CodeExecutionSurface.mcp,
            code: 'return 1;',
            description: 'id',
            limits: CodeModeLimits(),
            tools: const [],
          ),
          callNested: (_) async => throw StateError('no call runs'),
        );
        expect(
          result.execution.errorKind,
          CodeExecutionErrorKind.invalidToolCallId,
        );
        expect(isOneLineLabel(result.execution.toolCallId, 256), isTrue);
        final refused = lines.singleWhere((l) => l.contains('refused'));
        _expectLogSafe(refused);
        expect(refused, contains('call call_1'));
      }
    });

    test('the shared label makes any text safe for a log line', () {
      _expectLogSafe(ScriptCall.lateOutcomeLabel(_hostileText));
      _expectLogSafe(ScriptCall.lateOutcomeLabel('a\u0085b\u2028c\u2029d'));
      expect(ScriptCall.lateOutcomeLabel('plain'), 'plain');
    });
  });

  test('a call that settles while the result is being shaped is reported to '
      'the model as it is recorded', () async {
    final process = CodeSandboxProcess(executable: realRunnerPath());
    expect((await process.selfTest()).isAvailable, isTrue);
    final executions = MemoryExecutions();
    final service = CodeExecutionService(
      sandbox: process,
      executions: executions,
      store: MemoryStore(),
    );
    addTearDown(service.dispose);
    final shapingBegan = Completer<void>();
    final readReturned = Completer<void>();
    // The order is set by the test, not by timing:
    // * the script awaits `stat`, which the host starts after `read` (calls
    //   start in sequence order), so `read` is running before the script
    //   ends. A call the script sends and does not await may otherwise
    //   reach the host after it has read the runner's `done`, and a call
    //   read after `done` never starts;
    // * `read` ignores the script's end and returns only once shaping the
    //   result has begun, after the settle grace;
    // * shaping waits until `read` has returned and settled.
    final result = await service
        .execute(
          CodeExecutionRequest(
            readOnly: false,
            past: null,
            workspaceId: 'ws-1',
            runId: 'run-1',
            parentToolCallId: 'call_1',
            surface: CodeExecutionSurface.harness,
            code:
                "tools.read({}); await tools.stat({}); return 'x'.repeat(20000);",
            description: 'shaped late',
            limits: CodeModeLimits(),
            maxOutputTokens: 100,
            tools: [
              for (final name in ['read', 'stat'])
                ScriptToolDescriptor(
                  name: name,
                  namespace: ScriptToolNamespace.builtin,
                  description: 'Read.',
                  inputSchema: const {'type': 'object'},
                ),
            ],
            fullOutputSink: (full) async {
              shapingBegan.complete();
              await readReturned.future;
              // Microtasks run before a timer: by then the returned call
              // has settled and been recorded.
              await Future<void>.delayed(Duration.zero);
              return ToolOutputReference(
                handle: 'h-1',
                toolName: 'repl',
                byteLength: full.length,
                charLength: full.length,
              );
            },
          ),
          callNested: (r) async {
            if (r.name == 'stat') {
              return NestedCallOutcome(
                status: NestedCallStatus.completed,
                value: 1,
              );
            }
            await r.cancel.whenCancelled;
            await shapingBegan.future;
            scheduleMicrotask(readReturned.complete);
            return NestedCallOutcome(
              status: NestedCallStatus.completed,
              value: 1,
            );
          },
        )
        .timeout(const Duration(seconds: 30));
    expect(readReturned.isCompleted, isTrue);
    final record = executions.rows[result.execution.id]!;
    expect(executions.finishes, contains(result.execution.id));
    final recorded = record.calls.singleWhere((c) => c.toolName == 'read');
    final told = result.calls.singleWhere((c) => c.toolName == 'read');
    expect(recorded.status, told.status);
    expect(recorded.error, told.error);
    expect(told.status, NestedCallStatus.cancelled);
    expect(
      result.calls.singleWhere((c) => c.toolName == 'stat').status,
      NestedCallStatus.completed,
    );
  }, timeout: const Timeout(Duration(minutes: 1)));
}
