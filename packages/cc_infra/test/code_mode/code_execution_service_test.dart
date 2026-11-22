// The execution service against the REAL runner (CC_CODEMODE_RUNNER or the
// development install). Nested calls go to a fake gate.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart' show ToolOutputReference;
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/code_execution_metrics.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

/// Counts runner starts, so a refusal can be shown to start none.
class CountingSandbox implements CodeSandboxPort {
  CountingSandbox(this.inner);

  final CodeSandboxProcess inner;
  int starts = 0;
  CodeSandboxStart? lastStart;

  @override
  CodeRunnerAvailability get availability => inner.availability;

  @override
  Future<CodeRunnerAvailability> selfTest() => inner.selfTest();

  @override
  Future<CodeSandboxSession> start(
    CodeSandboxStart request, {
    CancellationToken cancel = CancellationToken.none,
  }) {
    starts++;
    lastStart = request;
    return inner.start(request, cancel: cancel);
  }

  @override
  Future<void> dispose() => inner.dispose();
}

/// A gate double: records requests, tracks concurrency, answers per tool.
class FakeGate {
  final List<NestedCallRequest> requests = [];
  final Map<String, Future<NestedCallOutcome> Function(NestedCallRequest)>
  handlers = {};
  int inFlight = 0;
  int maxInFlight = 0;
  final Map<String, int> maxInFlightByTool = {};
  final Map<String, int> _byTool = {};

  Future<NestedCallOutcome> call(NestedCallRequest r) async {
    requests.add(r);
    inFlight++;
    maxInFlight = math.max(maxInFlight, inFlight);
    final n = (_byTool[r.name] ?? 0) + 1;
    _byTool[r.name] = n;
    maxInFlightByTool[r.name] = math.max(maxInFlightByTool[r.name] ?? 0, n);
    try {
      final handler = handlers[r.name];
      if (handler != null) {
        return await handler(r);
      }
      return NestedCallOutcome(
        status: NestedCallStatus.completed,
        value: {'tool': r.name, 'args': r.arguments},
        gateDecision: NestedCallGateDecision.allowed,
      );
    } finally {
      inFlight--;
      _byTool[r.name] = _byTool[r.name]! - 1;
    }
  }
}

class RecordingMetrics implements CodeExecutionMetrics {
  final List<CodeExecutionSample> samples = [];

  @override
  void recordExecution(CodeExecutionSample sample) => samples.add(sample);
}

final _tools = [
  ScriptToolDescriptor(
    name: 'read',
    namespace: ScriptToolNamespace.builtin,
    description: 'Read a file.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
      },
    },
  ),
  ScriptToolDescriptor(
    name: 'write',
    namespace: ScriptToolNamespace.builtin,
    description: 'Write a file to disk.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'path': {'type': 'string'},
        'content': {'type': 'string'},
      },
    },
    tier: ToolApprovalTier.write,
    effects: const {ActionClass.fileWriteOutsideWorktree},
  ),
  ScriptToolDescriptor(
    name: 'ask_user',
    namespace: ScriptToolNamespace.controlCenter,
    description: 'Ask the person a question.',
    inputSchema: const {'type': 'object'},
  ),
  ScriptToolDescriptor(
    name: 'mcp__github__list_issues',
    namespace: 'github',
    description: 'List issues.',
    inputSchema: const {'type': 'object'},
  ),
];

void main() {
  final runner = realRunnerPath();
  late CodeSandboxProcess process;
  late CountingSandbox sandbox;
  late MemoryExecutions executions;
  late MemoryStore store;
  late FakeGate gate;
  late RecordingMetrics metrics;
  late CodeExecutionService service;

  CodeExecutionService build({
    int cap = 4,
    FakeEmbeddings? embeddings,
    ScriptAdmission? admission,
  }) => CodeExecutionService(
    sandbox: sandbox,
    executions: executions,
    store: store,
    embeddings: embeddings,
    serverProcessCap: cap,
    metrics: metrics,
    admission: admission,
  );

  setUp(() async {
    process = CodeSandboxProcess(executable: runner);
    final availability = await process.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
    sandbox = CountingSandbox(process);
    executions = MemoryExecutions();
    store = MemoryStore();
    gate = FakeGate();
    metrics = RecordingMetrics();
    service = build();
  });

  tearDown(() async {
    await service.dispose();
    expect(process.liveProcessCount, 0);
  });

  CodeExecutionRequest request(
    String code, {
    String workspaceId = 'ws-1',
    String runId = 'run-1',
    String callId = 'call_1',
    CodeModeLimits? limits,
    String? conversationId = 'conv-1',
    String? agentId = 'agent-1',
    int? maxOutputTokens,
    Future<ToolOutputReference?> Function(String)? sink,
  }) => CodeExecutionRequest(
    readOnly: false,
    past: null,
    workspaceId: workspaceId,
    runId: runId,
    parentToolCallId: callId,
    surface: CodeExecutionSurface.harness,
    code: code,
    description: 'test script',
    limits: limits ?? CodeModeLimits(),
    tools: _tools,
    conversationId: conversationId,
    agentId: agentId,
    spaceId: 'space-1',
    maxOutputTokens: maxOutputTokens,
    fullOutputSink: sink,
  );

  Future<CodeExecutionResult> run(
    String code, {
    String workspaceId = 'ws-1',
    String runId = 'run-1',
    String callId = 'call_1',
    CodeModeLimits? limits,
    String? conversationId = 'conv-1',
    String? agentId = 'agent-1',
    int? maxOutputTokens,
    CancellationToken cancel = CancellationToken.none,
    Future<ToolOutputReference?> Function(String)? sink,
  }) => service.execute(
    request(
      code,
      workspaceId: workspaceId,
      runId: runId,
      callId: callId,
      limits: limits,
      conversationId: conversationId,
      agentId: agentId,
      maxOutputTokens: maxOutputTokens,
      sink: sink,
    ),
    callNested: gate.call,
    cancel: cancel,
  );

  /// Waits until [condition] holds, failing after [within].
  Future<void> until(
    bool Function() condition, {
    Duration within = const Duration(seconds: 15),
  }) async {
    final clock = Stopwatch()..start();
    while (!condition()) {
      if (clock.elapsed > within) {
        fail('timed out waiting');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  String runOf(NestedCallRequest r) => r.origin.executionId!.split('/').first;

  // A fast deadline for the tests that hit it; CPU well above it, so the
  // host's kill is what ends the script.
  final short = CodeModeLimits(wallClockMs: 1000, cpuMs: 30000);

  group('running a script', () {
    test('returns a value, keeping output in order', () async {
      final r = await run(
        "console.log('one'); text('two'); console.warn('three'); "
        'return {x: 1};',
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(r.result.isError, isFalse);
      final text = r.result.text;
      expect(text, startsWith('Script completed in'));
      final one = text.indexOf('one');
      final two = text.indexOf('two');
      final three = text.indexOf('[warn] three');
      final value = text.indexOf('"x": 1');
      expect([one, two, three, value].every((i) => i > 0), isTrue);
      expect(one < two && two < three && three < value, isTrue);
    });

    test('partial output survives a failure', () async {
      final r = await run(
        "console.log('before'); throw new TypeError('boom');",
      );
      expect(r.execution.status, CodeExecutionStatus.failed);
      // The kind is the host's fixed vocabulary; the script's own error
      // name is kept apart, in the payload.
      expect(r.execution.errorKind, CodeExecutionErrorKind.scriptError);
      expect(executions.rows[r.execution.id]!.payload?.errorName, 'TypeError');
      expect(r.result.isError, isTrue);
      expect(r.result.text, contains('before'));
      expect(r.result.text, contains('TypeError: boom'));
    });

    test(
      'a busy loop is ended at the deadline and the process is gone',
      () async {
        final clock = Stopwatch()..start();
        final r = await run('while (true) {}', limits: short);
        expect(r.execution.status, CodeExecutionStatus.timedOut);
        expect(r.execution.errorKind, 'deadline');
        expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
        expect(process.liveProcessCount, 0);
      },
    );

    test('a microtask loop is ended at the deadline', () async {
      final r = await run('while (true) await null;', limits: short);
      expect(r.execution.status, CodeExecutionStatus.timedOut);
      expect(process.liveProcessCount, 0);
    });

    test('a promise that can never settle fails at once', () async {
      final clock = Stopwatch()..start();
      final r = await run('await new Promise(() => {}); return 1;');
      expect(r.execution.status, CodeExecutionStatus.failed);
      expect(r.execution.errorKind, 'stalled');
      expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('heap exhaustion is reported as memory', () async {
      final r = await run(
        'const a = []; while (true) a.push(new Array(100000).fill(1));',
        limits: CodeModeLimits(heapBytes: 16 * 1024 * 1024),
      );
      expect(r.execution.status, CodeExecutionStatus.memoryExceeded);
      expect(r.result.text, contains('out of memory'));
    });

    test('an output flood ends the script even when it is caught', () async {
      final r = await run(
        "try { while (true) text('x'.repeat(1000000)); } catch (e) {} "
        'return 1;',
      );
      expect(r.execution.status, CodeExecutionStatus.outputExceeded);
      expect(r.result.truncated, isTrue);
    });

    test('a source over 256 KiB is refused before a runner starts', () async {
      final r = await run('// ${'x' * (300 * 1024)}');
      expect(r.execution.status, CodeExecutionStatus.refused);
      expect(r.execution.errorKind, 'source_too_large');
      expect(sandbox.starts, 0);
      // A refusal ran nothing, so it is not recorded; it is counted.
      expect(executions.rows, isEmpty);
      expect(metrics.samples.single.admitted, isFalse);
    });

    test('full output over the budget is stored and referenced', () async {
      String? stored;
      final r = await run(
        "for (let i = 0; i < 2000; i++) text('line ' + i);",
        maxOutputTokens: 100,
        sink: (full) async {
          stored = full;
          return ToolOutputReference(
            handle: 'h-1',
            toolName: 'repl',
            byteLength: full.length,
            charLength: full.length,
          );
        },
      );
      expect(r.result.truncated, isTrue);
      expect(stored, contains('line 1999'));
      expect(r.result.text, contains('read_output(handle: "h-1"'));
      expect(r.execution.outputTruncated, isTrue);
    });
  });

  group('nested calls', () {
    test('Promise.all runs read calls in parallel up to the limit and gated '
        'calls one at a time, in call order', () async {
      for (final name in ['read', 'write']) {
        gate.handlers[name] = (r) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return NestedCallOutcome(
            status: NestedCallStatus.completed,
            value: r.sequence,
          );
        };
      }
      final r = await run(
        'const reads = await Promise.all([1,2,3,4,5,6].map(i => '
        'tools.read({path: String(i)}))); '
        'const writes = await Promise.all([1,2,3].map(i => '
        'tools.write({path: String(i)}))); return [reads, writes];',
        limits: CodeModeLimits(maxInFlightCalls: 4),
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(gate.maxInFlightByTool['read'], 4);
      expect(gate.maxInFlightByTool['write'], 1);
      expect(
        [for (final q in gate.requests) q.sequence],
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
      );
      expect(
        [for (final q in gate.requests) q.toolCallId],
        [for (var i = 1; i <= 9; i++) 'call_1/$i'],
      );
      expect(r.execution.callCounts.completed, 9);
    });

    test(
      'a denied call rejects in the script with the message and status',
      () async {
        gate.handlers['write'] = (_) async => NestedCallOutcome(
          status: NestedCallStatus.denied,
          errorMessage: 'policy said no',
          gateDecision: NestedCallGateDecision.denied,
        );
        final r = await run(
          "try { await tools.write({path: 'x'}); return 'ran'; } "
          'catch (e) { return [e.message, e.status]; }',
        );
        expect(r.execution.status, CodeExecutionStatus.completed);
        expect(r.result.text, contains('"policy said no"'));
        expect(r.result.text, contains('"denied"'));
        expect(r.calls.single.status, NestedCallStatus.denied);
        expect(r.calls.single.gateDecision, NestedCallGateDecision.denied);
        expect(r.execution.callCounts.denied, 1);
      },
    );

    test('calls past the cap are refused without reaching the gate', () async {
      final r = await run(
        'const out = []; for (let i = 0; i < 3; i++) { '
        'try { await tools.read({}); out.push("ok"); } '
        'catch (e) { out.push(e.status); } } return out;',
        limits: CodeModeLimits(maxNestedCalls: 2),
      );
      expect(gate.requests, hasLength(2));
      expect(r.result.text, contains('"limit_exceeded"'));
      expect(r.calls, hasLength(2));
    });

    test('arguments over the cap are refused in the script', () async {
      final r = await run(
        "try { await tools.read({a: 'x'.repeat(1100000)}); return 'sent'; } "
        'catch (e) { return e.name; }',
      );
      expect(r.result.text, contains('RangeError'));
      expect(gate.requests, isEmpty);
    });

    test('an unknown tool rejects in the script and reaches no gate', () async {
      final r = await run(
        "try { await tools['nope']({}); } catch (e) { return e.message; }",
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(gate.requests, isEmpty);
    });

    test('a wait on a person longer than the deadline does not time the '
        'script out, and frees its runner slot', () async {
      service = build(cap: 1);
      int? slotsDuringWait;
      gate.handlers['ask_user'] = (r) async {
        r.onPersonWait!(true);
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        slotsDuringWait = service.slotsInUse;
        await Future<void>.delayed(const Duration(milliseconds: 1300));
        r.onPersonWait!(false);
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: {
            'selected': ['yes'],
            'text': null,
            'skipped': false,
          },
          approvalWaitMs: 2500,
        );
      };
      final r = await run(
        "const a = await tools.ask_user({question: 'Go?', options: "
        "[{label: 'yes'}, {label: 'no'}]}); return a.selected[0];",
        limits: short,
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(r.result.text, contains('yes'));
      expect(slotsDuringWait, 0);
      expect(r.calls.single.approvalWaitMs, 2500);
      expect(service.slotsInUse, 0);
    });

    test('a nested call that simply hangs times the script out and is '
        'recorded as cancelled', () async {
      gate.handlers['read'] = (r) async {
        await r.cancel.whenCancelled;
        return NestedCallOutcome(
          status: NestedCallStatus.cancelled,
          errorMessage: 'cancelled',
        );
      };
      final r = await run('await tools.read({}); return 1;', limits: short);
      expect(r.execution.status, CodeExecutionStatus.timedOut);
      expect(r.calls.single.status, NestedCallStatus.cancelled);
      expect(gate.requests.single.deadline.inMilliseconds, lessThan(1001));
    });

    test('the eleventh question is refused; answers appear even when the '
        'script returns nothing', () async {
      gate.handlers['ask_user'] = (r) async => NestedCallOutcome(
        status: NestedCallStatus.completed,
        value: {
          'selected': <String>[],
          'text': 'answer ${r.sequence}',
          'skipped': false,
        },
      );
      final r = await run(
        'for (let i = 1; i <= 11; i++) { try { '
        "await tools.ask_user({question: 'Q' + i}); } catch (e) { "
        "text(e.status + ': ' + e.message); } }",
      );
      expect(gate.requests, hasLength(10));
      expect(r.execution.questionCount, 10);
      expect(r.result.text, contains('limit_exceeded'));
      expect(r.result.text, contains('Question 10: Q10'));
      expect(r.result.text, contains('Wrote: answer 10'));
      expect(r.result.text, isNot(contains('Question 11')));
    });

    test(
      'cancellation mid-script settles in-flight calls and records them',
      () async {
        gate.handlers['read'] = (r) async {
          await r.cancel.whenCancelled;
          return NestedCallOutcome(
            status: NestedCallStatus.cancelled,
            errorMessage: 'The script ended.',
          );
        };
        final source = CancellationTokenSource();
        Timer(const Duration(milliseconds: 300), source.cancel);
        final r = await run(
          'await Promise.all([tools.read({}), tools.read({})]);',
          cancel: source.token,
        );
        expect(r.execution.status, CodeExecutionStatus.cancelled);
        expect(r.calls, hasLength(2));
        expect(
          r.calls.map((c) => c.status),
          everyElement(NestedCallStatus.cancelled),
        );
        expect(process.liveProcessCount, 0);
      },
    );

    test('the origin names the execution', () async {
      await run('await tools.read({});');
      final origin = gate.requests.single.origin;
      expect(
        origin,
        ScriptCallOrigin(
          parentToolCallId: 'call_1',
          executionId: 'run-1/call_1',
        ),
      );
    });
  });

  group('host calls', () {
    test('discovery answers from the catalog', () async {
      final r = await run(
        "const hits = await searchTools('write file'); "
        "const d = await describeTool('read'); "
        "const ns = await describeNamespace('builtin'); "
        'let unknown; try { await describeTool("nope"); } '
        'catch (e) { unknown = e.status; } '
        'return { all: ALL_TOOLS.map(t => t.name), first: hits[0].name, '
        'tier: d.tier, decl: d.declaration, ns: ns.tools.length, unknown };',
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      final value =
          jsonDecode(r.result.text.substring(r.result.text.indexOf('{')))
              as Map<String, dynamic>;
      expect(value['all'], [
        'read',
        'write',
        'ask_user',
        'mcp__github__list_issues',
      ]);
      expect(value['first'], 'write');
      expect(value['tier'], 'read');
      expect(value['decl'], contains('declare const tools'));
      expect(value['ns'], 2);
      expect(value['unknown'], 'unknown_tool');
    });

    test('models.* use the embedding port', () async {
      service = build(embeddings: FakeEmbeddings());
      final r = await run(
        "const e = await models.embed(['apple', 'banana']); "
        "const k = await models.rank('apricot', ['banana', 'avocado']); "
        "const c = await models.classify(['blueberry'], ['a-fruit', "
        "'b-fruit']); return { dims: e[0].length, top: k[0].text, "
        'label: c[0].label };',
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(r.result.text, contains('"dims": 3'));
      expect(r.result.text, contains('"top": "avocado"'));
      expect(r.result.text, contains('"label": "b-fruit"'));
    });

    test('a text over the per-text cap is refused in the script', () async {
      service = build(embeddings: FakeEmbeddings());
      final r = await run(
        "try { await models.embed(['x'.repeat(9000)]); } "
        'catch (e) { return e.message; }',
      );
      expect(r.result.text, contains('at most 8 KiB'));
    });

    test('a script stops at its embedding byte budget', () async {
      final embeddings = FakeEmbeddings();
      service = build(embeddings: embeddings);
      // 200 texts of 4,000 bytes is 800,000 bytes a batch: five fit in
      // 4 MiB, the sixth does not.
      final r = await run(
        "const batch = Array(200).fill('x'.repeat(4000)); let ok = 0; "
        'for (let i = 0; i < 6; i++) { try { await models.embed(batch); ok++; '
        "} catch (e) { return ok + ': ' + e.message; } } return ok;",
      );
      expect(r.result.text, contains('5: This script has sent the embedding'));
      expect(embeddings.calls, 5 * 200);
    });

    test('the server embeds at most two script batches at once', () async {
      final embeddings = FakeEmbeddings(
        batchDelay: const Duration(milliseconds: 300),
      );
      service = build(embeddings: embeddings);
      final results = await Future.wait([
        for (var i = 0; i < 4; i++)
          run("await models.embed(['a']); return 1;", runId: 'run-$i'),
      ]);
      for (final r in results) {
        expect(r.execution.status, CodeExecutionStatus.completed);
      }
      expect(
        embeddings.maxBatchesInFlight,
        CodeModeLimits.maxServerModelBatches,
      );
    });

    test(
      'models.* without an embedding model says it is not installed',
      () async {
        final r = await run(
          "try { await models.embed(['a']); } catch (e) { return e.message; }",
        );
        expect(r.result.text, contains('embedding model is not installed'));
      },
    );
  });

  // What a script gets from each of its own functions is what
  // ScriptGlobals says it gets. `image` and the error paths are held by
  // reading; the rest run here.
  group('script functions', () {
    Map<String, dynamic> valueOf(CodeExecutionResult r) =>
        jsonDecode(r.result.text.substring(r.result.text.indexOf('{')))
            as Map<String, dynamic>;

    test(
      'limits() returns the five numbers its signature names, at once',
      () async {
        final r = await run(
          'const l = limits(); '
          'return { keys: Object.keys(l).sort(), sync: !(l instanceof Promise), '
          "numbers: Object.values(l).every(v => typeof v === 'number') };",
        );
        expect(r.execution.status, CodeExecutionStatus.completed);
        final documented =
            RegExp(r'(\w+): number')
                .allMatches(ScriptGlobals.byName('limits')!.signature)
                .map((m) => m.group(1)!)
                .toList()
              ..sort();
        final value = valueOf(r);
        expect(value['keys'], documented);
        expect(value['sync'], isTrue);
        expect(value['numbers'], isTrue);
      },
    );

    test('sleep resolves with undefined; setTimeout returns a number id and '
        'clearTimeout nothing; text returns nothing', () async {
      final r = await run(
        'const slept = await sleep(5); const id = setTimeout(() => {}, 50); '
        "const cleared = clearTimeout(id); const t = text('x'); "
        'return { slept: slept === undefined, id: typeof id, '
        'cleared: cleared === undefined, text: t === undefined };',
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(valueOf(r), {
        'slept': true,
        'id': 'number',
        'cleared': true,
        'text': true,
      });
    });

    test('load returns a fresh copy (not a promise), undefined for a missing '
        'key, and store(key, undefined) deletes', () async {
      final r = await run(
        "store('k', {a: 1}); const first = load('k'); first.a = 2; "
        "const again = load('k'); store('k', undefined); "
        'return { copy: again.a, sync: !(first instanceof Promise), '
        "missing: load('nope') === undefined, deleted: load('k') === undefined };",
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(valueOf(r), {
        'copy': 1,
        'sync': true,
        'missing': true,
        'deleted': true,
      });
    });

    test('exit ends the script as completed with no value, keeping what it '
        'output', () async {
      final r = await run("text('kept'); exit(); return 'never';");
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(r.result.text, contains('kept'));
      expect(r.result.text, isNot(contains('never')));
    });

    test(
      'models.rank and models.classify return the documented fields',
      () async {
        service = build(embeddings: FakeEmbeddings());
        final r = await run(
          "const k = await models.rank('apricot', ['banana', 'avocado'], "
          "{ top: 1 }); const c = await models.classify(['blueberry'], "
          "['a-fruit', 'b-fruit']); const e = await models.embed(['a', 'b']); "
          'return { rank: Object.keys(k[0]).sort(), ranked: k.length, '
          'classify: Object.keys(c[0]).sort(), vectors: e.length, '
          "numbers: e[0].every(x => typeof x === 'number') };",
        );
        expect(r.execution.status, CodeExecutionStatus.completed);
        expect(valueOf(r), {
          'rank': ['index', 'score', 'text'],
          'ranked': 1,
          'classify': ['index', 'label', 'score'],
          'vectors': 2,
          'numbers': true,
        });
      },
    );

    test('a script looks a global up as one, and tools.<global> is still '
        'refused before the gate', () async {
      final r = await run(
        "const d = await describeTool('store'); "
        "const ns = await describeNamespace('script'); "
        "const hits = await searchTools('wait milliseconds'); "
        'let refused; try { await tools.store({}); } '
        'catch (e) { refused = e.message; } '
        'return { kind: d.kind, ns: d.namespace, id: d.id === undefined, '
        'globals: ns.globals.length, '
        "sleep: hits.some(h => h.name === 'sleep' && h.namespace === 'script'), "
        "inAll: ALL_TOOLS.some(t => t.name === 'store'), refused };",
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      final value = valueOf(r);
      expect(value['kind'], 'global');
      expect(value['ns'], 'script');
      expect(value['id'], isTrue);
      expect(value['globals'], ScriptGlobals.all.length);
      expect(value['sleep'], isTrue);
      expect(value['inAll'], isFalse);
      // The runner builds this message; it does not yet say `store` is a
      // script function.
      expect(value['refused'], startsWith('Unknown tool "store".'));
      expect(gate.requests, isEmpty);
    });
  });

  group('store', () {
    test('values round-trip across two executions', () async {
      final first = await run("store('k', {a: 1}); return 'saved';");
      expect(first.execution.status, CodeExecutionStatus.completed);
      final second = await run("return load('k');", callId: 'call_2');
      expect(second.result.text, contains('"a": 1'));
    });

    test('values are not committed when the script fails', () async {
      final r = await run("store('z', 1); throw new Error('no');");
      expect(r.execution.status, CodeExecutionStatus.failed);
      expect(store.commits, 0);
      expect(r.result.text, contains('were not saved'));
    });

    test('caps are enforced', () async {
      // The runner enforces the same caps as the store rules (512-byte
      // keys, the per-value budget), so both writes throw inside the script
      // and neither reaches the host.
      final r = await run(
        "try { store('${'k' * 600}', 1); } "
        "catch (e) { text('key:' + e.name); } "
        "try { store('big', 'x'.repeat(300 * 1024)); } "
        "catch (e) { text('value:' + e.name); } store('ok', 2);",
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(r.result.text, contains('key:RangeError'));
      expect(r.result.text, contains('value:RangeError'));
      expect(store.values['conv-1|agent-1'], {'ok': '2'});
    });

    test(
      'without a conversation, store() throws and the result says why',
      () async {
        final r = await run(
          "try { store('k', 1); } catch (e) { return e.name; }",
          conversationId: null,
        );
        expect(r.result.text, contains('RangeError'));
        expect(r.result.text, contains('store() is unavailable in this run'));
        expect(store.commits, 0);
      },
    );

    test('stored values are charged at their compact JSON from the start, '
        'so a script may fill the store exactly to its total however the '
        'saved text is spaced', () async {
      // Four arrays saved with a space after each comma: half again larger
      // as text than as the compact JSON both sides charge.
      const n = 102400;
      final compact = jsonEncode(List.filled(n, 0));
      final spaced = '[${List.filled(n, '0').join(', ')}]';
      expect(spaced.length - compact.length, n - 1);
      store.values['conv-1|agent-1'] = {
        for (var i = 0; i < 4; i++) 'a$i': spaced,
      };
      final loaded = 4 * compact.length;
      // One more stored byte is refused by the runner; exactly the total is
      // accepted by the runner and by the host.
      final fill = CodeModeLimits.maxStoreTotalBytes - loaded - 2;
      final r = await run(
        "try { store('e', 'v'.repeat(${fill + 1})); } "
        "catch (e) { text('over:' + e.name); } "
        "store('e', 'v'.repeat($fill)); return 'filled';",
      );
      expect(
        r.execution.status,
        CodeExecutionStatus.completed,
        reason: '${r.execution.errorKind}: ${r.result.text}',
      );
      expect(r.result.text, contains('over:RangeError'));
      expect(r.result.text, contains('filled'));
    });

    test('a commit that fails leaves the completed script completed', () async {
      store.failCommitWith = ArgumentError('no such conversation');
      final r = await run("store('k', 1); return 1;");
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(r.result.isError, isFalse);
      expect(r.result.text, contains('were not saved'));
    });
  });

  group('the audit record', () {
    test('records the execution, redacted call rows and counts', () async {
      gate.handlers['write'] = (_) async => NestedCallOutcome(
        status: NestedCallStatus.failed,
        errorMessage: 'disk full',
        gateDecision: NestedCallGateDecision.approved,
      );
      final r = await run(
        "await tools.read({path: 'a', token: 'abc', nested: [{password: 'p'}]}); "
        "try { await tools.write({path: 'b', content: 'secret text'}); } "
        'catch (e) {} return 1;',
      );
      final saved = executions.rows['run-1/call_1']!;
      final e = saved.execution;
      expect(e, r.execution);
      expect(e.status, CodeExecutionStatus.completed);
      expect(e.surface, CodeExecutionSurface.harness);
      expect(e.conversationId, 'conv-1');
      expect(e.spaceId, 'space-1');
      expect(e.description, 'test script');
      expect(e.sourceHash, hasLength(64));
      expect(e.engineVersion, startsWith('quickjs-ng'));
      expect(e.lockdown?['level'], 'full');
      expect(e.cpuMs, isNotNull);
      expect(e.callCounts.completed, 1);
      expect(e.callCounts.failed, 1);
      expect(saved.payload?.source, contains('tools.read'));
      expect(saved.calls, hasLength(2));
      final read = saved.calls[0];
      expect(read.toolCallId, 'call_1/1');
      expect(read.argumentsJson, contains('"path":"a"'));
      expect(read.argumentsJson, isNot(contains('abc')));
      expect(read.argumentsJson, isNot(contains('"p"')));
      final write = saved.calls[1];
      expect(write.status, NestedCallStatus.failed);
      expect(write.error, 'disk full');
      expect(write.gateDecision, NestedCallGateDecision.approved);
      expect(write.argumentsJson, isNot(contains('secret text')));
      expect(metrics.samples.single.calls.total, 2);
    });

    test('a status for each ending is recorded', () async {
      await run('return 1;', callId: 'a');
      await run('throw new Error()', callId: 'b');
      await run('while (true) {}', callId: 'c', limits: short);
      expect(
        [
          for (final id in ['a', 'b', 'c'])
            executions.rows['run-1/$id']!.execution.status,
        ],
        [
          CodeExecutionStatus.completed,
          CodeExecutionStatus.failed,
          CodeExecutionStatus.timedOut,
        ],
      );
    });

    test('the record is begun running before the runner starts, and '
        'finished once', () async {
      final startsAtBegin = <int>[];
      executions.onBegin = (e) {
        expect(e.status, CodeExecutionStatus.running);
        startsAtBegin.add(sandbox.starts);
      };
      int? appendedBeforeSecond;
      gate.handlers['read'] = (r) async {
        // A settled call is appended while the script still runs, so a
        // server that dies mid-script keeps it.
        if (r.sequence == 2) {
          appendedBeforeSecond = executions.rows['run-1/call_1']!.calls.length;
        }
        return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
      };
      final r = await run(
        'await tools.read({}); await tools.read({}); return 1;',
      );
      expect(startsAtBegin, [0]);
      expect(executions.begins, ['run-1/call_1']);
      expect(executions.finishes, ['run-1/call_1']);
      final saved = executions.rows['run-1/call_1']!;
      expect(saved.execution.status, CodeExecutionStatus.completed);
      expect(saved.execution, r.execution);
      expect(saved.calls.map((c) => c.sequence), [1, 2]);
      expect(appendedBeforeSecond, 1);
      expect(metrics.samples.single.admitted, isTrue);
    });

    test('a failed finish is loud but the result stands', () async {
      executions.failFinishWith = StateError('database closed');
      final r = await run('return 1;');
      expect(r.execution.status, CodeExecutionStatus.completed);
      expect(r.result.isError, isFalse);
      expect(r.result.text, contains('audit record of this script could not'));
    });

    test(
      'a record that cannot be begun is refused, and nothing runs',
      () async {
        executions.failBeginWith = StateError('database closed');
        final r = await run('return 1;');
        expect(r.execution.status, CodeExecutionStatus.refused);
        expect(r.execution.errorKind, CodeExecutionErrorKind.auditUnavailable);
        expect(sandbox.starts, 0);
      },
    );

    test('a run with no run log gets no script: refused, nothing saved, '
        'nothing run', () async {
      executions.runsWithoutLog.add('run-1');
      final r = await run('return 1;');
      expect(r.execution.status, CodeExecutionStatus.refused);
      expect(r.execution.errorKind, CodeExecutionErrorKind.noRunLog);
      expect(executions.rows, isEmpty);
      expect(sandbox.starts, 0);
    });

    test(
      'a repeated call id gets its own record; the first is untouched',
      () async {
        final first = await run('await tools.read({}); return 1;');
        final before = executions.rows['run-1/call_1']!;
        final second = await run('return 2;');
        expect(first.execution.id, 'run-1/call_1');
        expect(second.execution.id, 'run-1/call_1#2');
        final after = executions.rows['run-1/call_1']!;
        expect(identical(after, before), isTrue);
        expect(after.calls, hasLength(1));
        expect(executions.rows['run-1/call_1#2']!.payload?.source, 'return 2;');
        expect(gate.requests.single.origin.executionId, 'run-1/call_1');
      },
    );

    test('a second script of the same run is refused while the first '
        'runs', () async {
      gate.handlers['read'] = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
      };
      final a = run('await tools.read({}); return 1;');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final b = await run('return 2;');
      final first = await a;
      expect(first.execution.id, 'run-1/call_1');
      // Same run: the second is refused while the first runs, before any
      // id is taken, and is not recorded.
      expect(b.execution.status, CodeExecutionStatus.refused);
      expect(b.execution.errorKind, 'run_busy');
      expect(executions.rows.keys, ['run-1/call_1']);
      expect(
        executions.rows['run-1/call_1']!.execution.status,
        CodeExecutionStatus.completed,
      );
    });

    test('an over-long or control-character call id is refused before the '
        'runner starts', () async {
      final long = await run('return 1;', callId: 'x' * 300);
      final control = await run('return 1;', callId: 'call\n1');
      for (final r in [long, control]) {
        expect(r.execution.status, CodeExecutionStatus.refused);
        expect(r.execution.errorKind, 'invalid_tool_call_id');
        expect(r.result.isError, isTrue);
      }
      expect(sandbox.starts, 0);
      expect(executions.rows, isEmpty);
    });
  });

  group('admission', () {
    test('no script is admitted, or recorded, before its workspace has been '
        'swept, and a cancel ends the wait', () async {
      final sweep = Completer<String?>();
      final asked = <String>[];
      service = build(
        admission: (ws) {
          asked.add(ws);
          return sweep.future;
        },
      );
      final waiting = run('return 1;');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(executions.begins, isEmpty);
      expect(service.slotsInUse, 0);
      final cancel = CancellationTokenSource();
      final cancelled = service.execute(
        request('return 2;', runId: 'run-2'),
        callNested: gate.call,
        cancel: cancel.token,
      );
      cancel.cancel();
      final c = await cancelled.timeout(const Duration(seconds: 5));
      expect(c.execution.status, CodeExecutionStatus.cancelled);
      expect(executions.begins, isEmpty);
      sweep.complete(null);
      expect((await waiting).execution.status, CodeExecutionStatus.completed);
      expect(executions.begins, hasLength(1));
      expect(asked, everyElement('ws-1'));
    });

    test('a workspace whose sweep failed admits no script: it is refused '
        'audit_unavailable with the reason, unrecorded', () async {
      service = build(
        admission: (ws) async => 'the records could not be closed: disk full',
      );
      final r = await run('return 1;');
      expect(r.execution.status, CodeExecutionStatus.refused);
      expect(r.execution.errorKind, CodeExecutionErrorKind.auditUnavailable);
      expect(r.result.text, contains('disk full'));
      expect(sandbox.starts, 0);
      expect(executions.begins, isEmpty);
    });

    test('a sweep that does not finish within the wall clock ends in the '
        'busy refusal', () async {
      service = build(admission: (ws) => Completer<String?>().future);
      final clock = Stopwatch()..start();
      final r = await run(
        'return 1;',
        limits: CodeModeLimits(wallClockMs: 1000),
      );
      expect(r.execution.status, CodeExecutionStatus.refused);
      expect(r.execution.errorKind, CodeExecutionErrorKind.serverBusy);
      expect(r.result.text, contains('previous process'));
      expect(clock.elapsedMilliseconds, lessThan(5000));
      expect(sandbox.starts, 0);
      expect(executions.begins, isEmpty);
    });

    test('a script at the shortest wall clock is not refused for the time '
        'its admission took: it runs with the whole floor', () async {
      // The first script of a workspace waits for its sweep; a script whose
      // `timeout` clamps to the 1 s floor used to be refused as busy (no
      // runner free) for any wait, here 50 ms with every slot free.
      service = build(
        admission: (ws) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return null;
        },
      );
      final r = await run('return 1;', limits: short);
      expect(
        r.execution.status,
        CodeExecutionStatus.completed,
        reason: '${r.execution.errorKind}: ${r.result.text}',
      );
      expect(
        sandbox.lastStart!.limits.wallClockMs,
        CodeModeLimits.wallClock.floor,
      );
    });

    test('a longer wall clock is charged the admission wait', () async {
      service = build(
        admission: (ws) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return null;
        },
      );
      final r = await run(
        'return 1;',
        limits: CodeModeLimits(wallClockMs: 5000, cpuMs: 30000),
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      final given = sandbox.lastStart!.limits.wallClockMs;
      expect(given, lessThanOrEqualTo(5000 - 50));
      expect(given, greaterThanOrEqualTo(CodeModeLimits.wallClock.floor));
    });

    test('the server cap queues a script until a slot frees', () async {
      service = build(cap: 1);
      gate.handlers['read'] = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
      };
      final a = run('await tools.read({}); return 1;', runId: 'run-a');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final b = await run('return 2;', runId: 'run-b');
      expect((await a).execution.status, CodeExecutionStatus.completed);
      expect(b.execution.status, CodeExecutionStatus.completed);
    });

    test('a slot that does not free within the deadline is refused, naming '
        'the cap', () async {
      service = build(cap: 1);
      gate.handlers['read'] = (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 2500));
        return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
      };
      final a = run('await tools.read({}); return 1;', runId: 'run-a');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final b = await run('return 2;', runId: 'run-b', limits: short);
      expect(b.execution.status, CodeExecutionStatus.refused);
      expect(b.execution.errorKind, 'server_busy');
      expect(b.result.text, contains('at most 1 script at once'));
      await a;
    });

    test('the parked pool is bounded: of six scripts waiting on a person, '
        'four park and one keeps its slot, so live runners never exceed '
        'the cap plus the pool', () async {
      service = build(cap: 1);
      expect(service.parkedCap, 4);
      final answered = Completer<void>();
      gate.handlers['ask_user'] = (r) async {
        r.onPersonWait!(true);
        await answered.future;
        r.onPersonWait!(false);
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: {'selected': <String>[], 'text': 'ok', 'skipped': false},
        );
      };
      // Two workspaces, so neither reaches its share of the pool (three).
      final runs = <Future<CodeExecutionResult>>[];
      for (var i = 0; i < 6; i++) {
        runs.add(
          run(
            "await tools.ask_user({question: 'wait'}); return 'r$i';",
            runId: 'run-$i',
            workspaceId: i.isEven ? 'ws-1' : 'ws-2',
          ),
        );
        await until(() => gate.requests.length == math.min(i + 1, 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(gate.requests, hasLength(5), reason: 'the sixth waits');
      expect(service.parkedRunners, 4);
      expect(service.slotsInUse, 1);
      expect(process.liveProcessCount, 5);
      final refused = await run('return 7;', runId: 'run-7', limits: short);
      expect(refused.execution.errorKind, 'server_busy');
      answered.complete();
      for (final r in await Future.wait(runs)) {
        expect(r.execution.status, CodeExecutionStatus.completed);
      }
      expect(service.parkedRunners, 0);
      expect(service.slotsInUse, 0);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('one workspace parks at most its share of the pool; the rest of the '
        'pool stays for other workspaces', () async {
      service = build(cap: 2);
      expect(service.parkedCap, 8);
      expect(service.parkedShare, 6);
      expect(service.workspaceShare, 1);
      final answered = Completer<void>();
      gate.handlers['ask_user'] = (r) async {
        r.onPersonWait!(true);
        await answered.future;
        r.onPersonWait!(false);
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: {'selected': <String>[], 'text': 'ok', 'skipped': false},
        );
      };
      Future<CodeExecutionResult> asking(String ws, String runId) => run(
        "await tools.ask_user({question: 'wait'}); return 1;",
        runId: runId,
        workspaceId: ws,
      );
      final runs = <Future<CodeExecutionResult>>[];
      for (var i = 0; i < 7; i++) {
        runs.add(asking('ws-1', 'a$i'));
        await until(() => gate.requests.length == i + 1);
      }
      await until(() => service.parkedRunnersOf('ws-1') == 6);
      // The seventh keeps its slot: ws-1 holds its share of the pool.
      expect(service.slotsHeldBy('ws-1'), 1);
      expect(service.parkedRunners, 6);
      runs.add(asking('ws-2', 'b0'));
      await until(() => service.parkedRunnersOf('ws-2') == 1);
      expect(service.parkedRunners, 7);
      answered.complete();
      for (final r in await Future.wait(runs)) {
        expect(r.execution.status, CodeExecutionStatus.completed);
      }
      expect(service.parkedRunners, 0);
      expect(service.slotsInUse, 0);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('one workspace holds at most its share of the slots, so another '
        'workspace still runs', () async {
      service = build(cap: 4);
      expect(service.workspaceShare, 3);
      final release = Completer<void>();
      gate.handlers['read'] = (_) async {
        await release.future;
        return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
      };
      final busy = [
        for (var i = 0; i < 4; i++)
          run('await tools.read({}); return 1;', runId: 'a$i'),
      ];
      await until(() => gate.requests.length == 3);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(gate.requests, hasLength(3));
      expect(service.slotsInUse, 3);
      final other = await run(
        'return 2;',
        workspaceId: 'ws-2',
        runId: 'b0',
        limits: short,
      );
      expect(other.execution.status, CodeExecutionStatus.completed);
      release.complete();
      for (final r in await Future.wait(busy)) {
        expect(r.execution.status, CodeExecutionStatus.completed);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('waiting scripts are admitted round-robin across workspaces, not in '
        'arrival order', () async {
      service = build(cap: 1);
      final gates = <String, Completer<void>>{};
      gate.handlers['read'] = (r) async {
        await gates.putIfAbsent(runOf(r), Completer.new).future;
        return NestedCallOutcome(status: NestedCallStatus.completed, value: 1);
      };
      final all = <Future<CodeExecutionResult>>[];
      Future<void> start(String workspaceId, String runId) async {
        all.add(
          run(
            'await tools.read({}); return 1;',
            workspaceId: workspaceId,
            runId: runId,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      List<String> admitted() => [for (final r in gate.requests) runOf(r)];
      await start('ws-z', 'z1');
      await until(() => admitted().length == 1);
      await start('ws-a', 'a1');
      await start('ws-a', 'a2');
      await start('ws-b', 'b1');
      for (final (release, next) in [('z1', 2), ('a1', 3), ('b1', 4)]) {
        gates.putIfAbsent(release, Completer.new).complete();
        await until(() => admitted().length == next);
      }
      gates.putIfAbsent('a2', Completer.new).complete();
      await Future.wait(all);
      // FIFO would have run a2 before b1.
      expect(admitted(), ['z1', 'a1', 'b1', 'a2']);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('a script parked on a person frees its slot for another', () async {
      service = build(cap: 1);
      final answered = Completer<void>();
      gate.handlers['ask_user'] = (r) async {
        r.onPersonWait!(true);
        await answered.future;
        r.onPersonWait!(false);
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: {'selected': <String>[], 'text': 'ok', 'skipped': false},
        );
      };
      final a = run(
        "await tools.ask_user({question: 'wait'}); return 'a';",
        runId: 'run-a',
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final b = await run("return 'b';", runId: 'run-b', limits: short);
      expect(b.execution.status, CodeExecutionStatus.completed);
      answered.complete();
      expect((await a).execution.status, CodeExecutionStatus.completed);
      expect(service.slotsInUse, 0);
    });
  });
}
