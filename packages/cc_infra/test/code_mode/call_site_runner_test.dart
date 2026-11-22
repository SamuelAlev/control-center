// Call sites from the REAL runner (CC_CODEMODE_RUNNER) to the execution
// record: each call's row names the line and column of the script it was
// made from, and the site reaches nothing the gate sees.
import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

final _tools = [
  for (final name in ['read', 'list'])
    ScriptToolDescriptor(
      name: name,
      namespace: ScriptToolNamespace.builtin,
      description: 'A $name tool.',
      inputSchema: const {'type': 'object'},
    ),
];

/// The site of the first [needle] on 1-based [line] of [code] (ASCII lines).
ScriptCallSite _at(String code, int line, String needle) {
  final text = code.split('\n')[line - 1];
  final i = text.indexOf(needle);
  expect(i, isNonNegative, reason: '$needle on line $line');
  return ScriptCallSite(line, i + 1);
}

void main() {
  final runner = realRunnerPath();
  late CodeSandboxProcess process;
  late MemoryExecutions executions;
  late CodeExecutionService service;
  late List<NestedCallRequest> requests;

  setUp(() async {
    process = CodeSandboxProcess(executable: runner);
    final availability = await process.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
    executions = MemoryExecutions();
    service = CodeExecutionService(
      sandbox: process,
      executions: executions,
      store: MemoryStore(),
      serverProcessCap: 2,
    );
    requests = [];
  });

  tearDown(() async {
    await service.dispose();
    expect(process.liveProcessCount, 0);
  });

  Future<CodeExecutionResult> run(String code) => service.execute(
    CodeExecutionRequest(
      readOnly: false,
      past: null,
      workspaceId: 'ws-1',
      runId: 'run-1',
      parentToolCallId: 'call_1',
      surface: CodeExecutionSurface.harness,
      code: code,
      description: 'call sites',
      limits: CodeModeLimits(),
      tools: _tools,
    ),
    callNested: (r) async {
      requests.add(r);
      return NestedCallOutcome(
        status: NestedCallStatus.completed,
        value: {'ok': true},
        gateDecision: NestedCallGateDecision.allowed,
      );
    },
  );

  test('three calls on known lines are recorded with their sites', () async {
    const code =
        "const a = await tools.read({ path: 'a' });\n"
        '\n'
        'for (const p of [1]) {\n'
        "  await tools.list({ dir: 'b' });\n"
        '}\n'
        "const c = await tools.read({ path: 'c' });\n"
        'return 1;';
    final r = await run(code);
    expect(r.execution.status, CodeExecutionStatus.completed);
    final expected = [
      _at(code, 1, 'read'),
      _at(code, 4, 'list'),
      _at(code, 6, 'read'),
    ];
    expect(r.calls.map((c) => c.site), expected);
    final saved = executions.rows['run-1/call_1']!;
    expect(saved.calls.map((c) => c.site), expected);
    expect(saved.calls.map((c) => c.sequence), [1, 2, 3]);

    // What the gate is handed (and with it every guard decision, approval
    // card, audit entry and fingerprint the surface makes) is the script's
    // arguments, unchanged, and nothing of the site.
    expect(requests.map((q) => q.arguments), [
      {'path': 'a'},
      {'dir': 'b'},
      {'path': 'c'},
    ]);
    for (final row in saved.calls) {
      expect(row.argumentsJson, isNot(contains('"at"')));
    }
    expect(
      jsonEncode(saved.execution.toJson()),
      isNot(contains('"site"')),
      reason: 'the execution itself carries no site',
    );
  });

  test('a column counts UTF-16 units of the script', () async {
    const code = "const s = 'é😀'; await tools.read({});\nreturn 1;";
    final r = await run(code);
    expect(r.execution.status, CodeExecutionStatus.completed);
    // 11 units, é and the two units of 😀, then 15 more: column 30.
    expect(r.calls.single.site, ScriptCallSite(1, 30));
  });
}
