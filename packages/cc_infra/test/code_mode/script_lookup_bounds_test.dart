// A script's lookups (searchTools, describeTool, describeNamespace) through
// the REAL runner (CC_CODEMODE_RUNNER): the host answers them on the isolate
// that serves every workspace, so it checks their sizes before any work and
// bounds how many one script makes and how much server time they take
// together, and how much the scripts of one workspace take together.
import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/code_mode/script_lookups.dart';
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

/// What a script runs first: `probe(f)` records each lookup's outcome in
/// `out`, `ok` or the rejection's message.
const _probe =
    'const out = [];\n'
    'async function probe(f) {\n'
    '  try { await f(); out.push("ok"); } catch (e) { out.push(String(e.message).slice(0, 90)); }\n'
    '}\n';

void main() {
  final runner = realRunnerPath();
  late CodeSandboxProcess process;
  late CodeExecutionService service;

  setUp(() async {
    process = CodeSandboxProcess(executable: runner);
    expect((await process.selfTest()).isAvailable, isTrue);
    service = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: MemoryStore(),
      serverProcessCap: 2,
    );
  });

  tearDown(() async {
    await service.dispose();
    expect(process.liveProcessCount, 0);
  });

  Future<List<Object?>> run(
    String body, {
    List<ScriptToolDescriptor>? tools,
  }) async {
    final r = await service.execute(
      CodeExecutionRequest(
        readOnly: false,
        past: null,
        workspaceId: 'ws-1',
        runId: 'run-1',
        parentToolCallId: 'call_1',
        surface: CodeExecutionSurface.harness,
        code: '$_probe$body\ntext("OUT" + JSON.stringify(out) + "END");',
        description: 'lookups',
        limits: CodeModeLimits(),
        tools: tools ?? _tools,
      ),
      callNested: (_) async => NestedCallOutcome(
        status: NestedCallStatus.completed,
        value: const {},
      ),
    );
    expect(
      r.execution.status,
      CodeExecutionStatus.completed,
      reason: r.result.text,
    );
    final match = RegExp('OUT(.*)END', dotAll: true).firstMatch(r.result.text);
    expect(match, isNotNull, reason: r.result.text);
    return (jsonDecode(match!.group(1)!) as List).cast<Object?>();
  }

  test('arguments over their size are refused before any work, naming the '
      'bound; those at it are answered', () async {
    const q = CodeModeLimits.maxLookupQueryUnits;
    const n = CodeModeLimits.maxLookupNameUnits;
    final out = await run('''
await probe(() => searchTools("r".repeat($q)));
await probe(() => searchTools("r".repeat(${q + 1})));
await probe(() => searchTools("é".repeat(${q + 1})));
await probe(() => describeTool("x".repeat(${n + 1})));
await probe(() => describeNamespace("x".repeat(${n + 1})));
await probe(() => searchTools("read", { namespace: "x".repeat(${n + 1}) }));
await probe(() => searchTools("read", { limit: 0 }));
await probe(() => searchTools("read", { limit: 50 }));
await probe(() => searchTools("read", { limit: 51 }));
await probe(() => searchTools("read", { limit: -1 }));
await probe(() => describeTool("read"));
''');
    expect(out[0], 'ok');
    expect(out[1], contains('${q + 1} characters; the limit is $q'));
    expect(out[2], contains('the limit is $q'));
    expect(out[3], contains('${n + 1} characters; the limit is $n'));
    expect(out[4], contains('the limit is $n'));
    expect(out[5], contains('namespace is ${n + 1} characters'));
    expect(out.sublist(6, 8), ['ok', 'ok']);
    expect(out[8], contains('limit must be 0 to 50'));
    expect(out[9], contains('limit must be 0 to 50'));
    expect(out[10], 'ok');
  });

  test('a script makes at most maxLookups lookups; later ones are refused '
      'without an answer', () async {
    const max = CodeModeLimits.maxLookups;
    final out = await run('''
for (let i = 0; i < ${max + 5}; i++) {
  await probe(i % 2 ? () => describeTool("read") : () => searchTools("read"));
}
''');
    expect(out.take(max).toSet(), {'ok'});
    expect(out.skip(max), hasLength(5));
    for (final refused in out.skip(max)) {
      expect(refused, contains('lookup budget used up'));
    }
  });

  test('once the lookups of one script have taken their server time '
      'together, nothing more is looked up', () async {
    // A budget the first lookup (which builds the search index) uses up.
    final tight = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: MemoryStore(),
      serverProcessCap: 2,
      lookupTimeBudget: const Duration(microseconds: 1),
    );
    final r = await tight.execute(
      CodeExecutionRequest(
        readOnly: false,
        past: null,
        workspaceId: 'ws-1',
        runId: 'run-2',
        parentToolCallId: 'call_1',
        surface: CodeExecutionSurface.harness,
        code:
            '$_probe'
            'for (let i = 0; i < 10; i++) await probe(() => searchTools("read"));\n'
            'text("OUT" + JSON.stringify(out) + "END");',
        description: 'lookups',
        limits: CodeModeLimits(),
        tools: _tools,
      ),
      callNested: (_) async => NestedCallOutcome(
        status: NestedCallStatus.completed,
        value: const {},
      ),
    );
    final match = RegExp('OUT(.*)END', dotAll: true).firstMatch(r.result.text);
    expect(match, isNotNull, reason: r.result.text);
    final out = jsonDecode(match!.group(1)!) as List;
    expect(out.first, 'ok');
    expect(out.skip(1), hasLength(9));
    for (final refused in out.skip(1)) {
      expect(refused, contains('lookup budget used up'));
    }
    await tight.dispose();
  });

  group('the workspace bucket', () {
    test('refills at its rate up to its capacity, goes below zero by one '
        'charge, and keeps workspaces apart', () {
      var now = 0;
      final buckets = WorkspaceLookupBuckets(nowMicros: () => now);
      expect(buckets.capacity, const Duration(milliseconds: 2000));
      expect(buckets.refillPerSecond, const Duration(milliseconds: 250));
      expect(buckets.hasTime('ws-1'), isTrue);
      // One lookup takes more than the bucket holds: it was answered, the
      // next is not.
      buckets.charge('ws-1', 2100 * 1000);
      expect(buckets.hasTime('ws-1'), isFalse);
      expect(buckets.hasTime('ws-2'), isTrue);
      now += 400 * 1000; // +100 ms: back to zero, still empty
      expect(buckets.hasTime('ws-1'), isFalse);
      now += 4000; // +1 ms
      expect(buckets.hasTime('ws-1'), isTrue);
      // Over time: a quarter of each second.
      var spent = 0;
      for (var second = 0; second < 60; second++) {
        while (buckets.hasTime('ws-1')) {
          buckets.charge('ws-1', 10 * 1000);
          spent += 10 * 1000;
        }
        now += 1000 * 1000;
      }
      expect(spent, lessThanOrEqualTo((2000 + 60 * 250 + 10) * 1000));
      // Never more than the capacity, however long it rests.
      now += 3600 * 1000 * 1000;
      var burst = 0;
      while (buckets.hasTime('ws-1')) {
        buckets.charge('ws-1', 1000);
        burst += 1000;
      }
      expect(burst, 2000 * 1000);
    });

    test('bounds the lookups of all of one workspace\'s scripts together, '
        'whatever each script has left', () async {
      var now = 0;
      final shared = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: MemoryStore(),
        serverProcessCap: 2,
        // A bucket the first lookup empties.
        lookupBuckets: WorkspaceLookupBuckets(
          capacity: const Duration(microseconds: 1),
          nowMicros: () => now,
        ),
      );
      Future<List<Object?>> lookups(String ws, String run) async {
        final r = await shared.execute(
          CodeExecutionRequest(
            readOnly: false,
            past: null,
            workspaceId: ws,
            runId: run,
            parentToolCallId: 'call_1',
            surface: CodeExecutionSurface.harness,
            code:
                '$_probe'
                'for (let i = 0; i < 3; i++) await probe(() => searchTools("read"));\n'
                'text("OUT" + JSON.stringify(out) + "END");',
            description: 'lookups',
            limits: CodeModeLimits(),
            tools: _tools,
          ),
          callNested: (_) async => NestedCallOutcome(
            status: NestedCallStatus.completed,
            value: const {},
          ),
        );
        final match = RegExp(
          'OUT(.*)END',
          dotAll: true,
        ).firstMatch(r.result.text);
        expect(match, isNotNull, reason: r.result.text);
        return jsonDecode(match!.group(1)!) as List;
      }

      final first = await lookups('ws-1', 'run-1');
      expect(first.first, 'ok');
      for (final refused in first.skip(1)) {
        expect(refused, contains('lookup budget of this workspace used up'));
      }
      // Another script of the workspace, its own budget untouched.
      final second = await lookups('ws-1', 'run-2');
      expect(second.first, contains('lookup budget of this workspace'));
      // Another workspace has its own bucket.
      expect((await lookups('ws-2', 'run-3')).first, 'ok');
      // The bucket refills with time.
      now += 1000 * 1000;
      expect((await lookups('ws-1', 'run-4')).first, 'ok');
      await shared.dispose();
    });
  });
}
