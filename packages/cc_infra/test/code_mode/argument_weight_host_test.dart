// Call arguments are bounded as memory, not as JSON: the host weighs a frame
// before it decodes it, holds unanswered arguments by their decoded weight,
// refuses a call whose arguments hold too many values as an ordinary error
// for that call, and ends a runner that writes a frame heavier than any an
// honest runner writes. First against fake runners, then a script on the
// real runner within the default limits, with the server's memory measured.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/code_mode/runner_json.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'code_mode_test_support.dart';
import 'live_heap.dart';

const _done =
    '{"type":"done","ok":true,"stats":{"cpu_ms":0,"peak_heap_bytes":0,'
    '"calls":1,"output_chars":0,"output_items":0}}';

String _call(int id, Map<String, dynamic> args) => jsonEncode({
  'type': 'call',
  'id': id,
  'target': 'tool',
  'name': 'x',
  'args': args,
});

void main() {
  group('against fake runners', () {
    late Directory tmp;
    late FakeRunners fakes;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('codemode-weight-');
      fakes = FakeRunners(tmp);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    CodeSandboxStart start({int wallMs = 20000}) => CodeSandboxStart(
      code: 'return 1',
      limits: CodeModeLimits(wallClockMs: wallMs),
      returnBudgetChars: 30400,
      catalog: const [],
    );

    /// A fake that has read init and exec, writes [frames] (from a file),
    /// then runs [after].
    String writes(List<String> frames, String after) {
      final file = File(p.join(tmp.path, 'frames_${frames.length}'));
      file.writeAsStringSync(frames.map((f) => '$f\n').join());
      return fakes.script('''
printf '%s\\n' '$fakeReadyFull'
read -r init
read -r exec
/bin/cat ${file.path}
$after''');
    }

    test('unanswered arguments are held by what they take decoded: the host '
        'stops reading at the budget, not at 64 MiB of JSON', () async {
      // 200 calls of about 48 KiB of JSON each (9 MiB in all), each about
      // 5 MiB once decoded.
      final pad = {'pad': List.generate(16000, (_) => <String, dynamic>{})};
      final frames = [for (var i = 1; i <= 200; i++) _call(i, pad)];
      final weight = scanJsonFrame(utf8.encode(jsonEncode(pad))).shape.weight;
      final host = CodeSandboxProcess(
        executable: writes(frames, 'exec /bin/sleep 30'),
      );
      final session = await host.start(start());
      var calls = 0;
      session.events.listen((e) {
        if (e is CodeSandboxCall) {
          calls++;
        }
      });
      var last = -1;
      while (calls != last || calls == 0) {
        last = calls;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      expect(
        calls,
        lessThanOrEqualTo(
          CodeSandboxProcess.pendingArgumentBudgetBytes ~/ weight + 1,
        ),
      );
      session.terminate();
      await session.outcome;
    });

    test('a call whose arguments hold more values than a call takes is '
        'refused to the script, undecoded, and the script goes on', () async {
      final got = p.join(tmp.path, 'got');
      // About 1 MiB of JSON: 340,000 empty objects, about 80 MiB decoded.
      final pad = {'pad': List.generate(340000, (_) => <String, dynamic>{})};
      final frame = _call(1, pad);
      expect(
        utf8.encode(jsonEncode(pad)).length,
        lessThan(CodeModeLimits.maxCallArgumentBytes),
      );
      final host = CodeSandboxProcess(
        executable: writes(
          [frame],
          '''
read -r r1
printf "%s\\n" "\$r1" > $got
printf '%s\\n' '$_done'
''',
        ),
      );
      final session = await host.start(start());
      final calls = <CodeSandboxCall>[];
      session.events.listen((e) {
        if (e is CodeSandboxCall) {
          calls.add(e);
        }
      });
      final outcome = await session.outcome;
      expect(outcome.status, CodeExecutionStatus.completed);
      expect(calls, isEmpty);
      final reply = jsonDecode(File(got).readAsStringSync()) as Map;
      expect(reply['id'], 1);
      expect(reply['ok'], isFalse);
      expect(
        (reply['payload'] as Map)['status'],
        NestedCallStatus.invalidArgs.wire,
      );
      expect(
        (reply['payload'] as Map)['message'],
        allOf(
          contains('340003 values'),
          contains('${CodeModeLimits.maxCallArgumentItems}'),
          contains('Split the data across calls'),
        ),
      );
    });

    test('a string argument at the cap full of braces, brackets, commas and '
        'quotes is one value and reaches the tool intact', () async {
      const chunk = '{}[],:"\\';
      // Quotes and backslashes are escaped, so the JSON is 1.25 times this.
      final text = chunk * (800 * 1024 ~/ chunk.length);
      final args = {'s': text};
      expect(
        utf8.encode(jsonEncode(args)).length,
        lessThan(CodeModeLimits.maxCallArgumentBytes),
      );
      final host = CodeSandboxProcess(
        executable: writes(
          [_call(1, args)],
          '''
read -r r1
printf '%s\\n' '$_done'
''',
        ),
      );
      final session = await host.start(start());
      String? received;
      session.events.listen((e) {
        if (e is CodeSandboxCall) {
          received = e.arguments['s'] as String;
          session.reply(CodeSandboxReply.value(e.id, 1));
        }
      });
      final outcome = await session.outcome;
      expect(outcome.status, CodeExecutionStatus.completed);
      expect(received, text);
    });

    test('a stored value of 256 KiB of empty objects, the heaviest an honest '
        'runner stores, is accepted', () async {
      final value = List.generate(
        CodeModeLimits.maxStoreValueBytes ~/ 3 - 10,
        (_) => <String, dynamic>{},
      );
      final frame = jsonEncode({'type': 'store', 'key': 'k', 'value': value});
      final host = CodeSandboxProcess(
        executable: writes([frame], "printf '%s\\n' '$_done'"),
      );
      final session = await host.start(start());
      final writes0 = <CodeSandboxStoreWrite>[];
      session.events.listen((e) {
        if (e is CodeSandboxStoreWrite) {
          writes0.add(e);
        }
      });
      final outcome = await session.outcome;
      expect(outcome.status, CodeExecutionStatus.completed);
      expect(writes0.single.valueJson, jsonEncode(value));
    });

    test('a frame heavier than any an honest runner writes ends the session '
        'before it is decoded', () async {
      final frame = jsonEncode({
        'type': 'output',
        'kind': 'text',
        'text': 'x',
        'pad': List.generate(2000000, (_) => <String, dynamic>{}),
      });
      expect(utf8.encode(frame).length, lessThan(CodeModeLimits.maxFrameBytes));
      final host = CodeSandboxProcess(
        executable: writes([frame], 'exec /bin/sleep 30'),
      );
      final session = await host.start(start());
      session.events.listen((_) {});
      final outcome = await session.outcome;
      expect(outcome.status, CodeExecutionStatus.sandboxError);
      expect(outcome.errorKind, 'protocol');
      expect(outcome.detail, contains('once decoded'));
      expect(host.liveProcessCount, 0);
    });
  }, skip: fakeRunnersSkip);

  group('a script on the real runner', () {
    late CodeSandboxProcess process;

    setUp(() async {
      process = CodeSandboxProcess(executable: realRunnerPath());
      expect((await process.selfTest()).isAvailable, isTrue);
    });

    ScriptToolDescriptor tool(String name) => ScriptToolDescriptor(
      name: name,
      namespace: ScriptToolNamespace.builtin,
      description: name,
      inputSchema: const {'type': 'object'},
    );

    CodeExecutionRequest request(String code) => CodeExecutionRequest(
      readOnly: false,
      past: null,
      workspaceId: 'ws-1',
      runId: 'run-1',
      parentToolCallId: 'call_1',
      surface: CodeExecutionSurface.harness,
      code: code,
      description: 'arguments',
      limits: CodeModeLimits(wallClockMs: 60000),
      tools: [tool('noop'), tool('hold')],
    );

    CodeExecutionService build() {
      final service = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: MemoryStore(),
      );
      addTearDown(service.dispose);
      return service;
    }

    test('120 calls of 1 MiB of empty objects are each refused, and the '
        'server holds none of them', () async {
      final service = build();
      var reached = 0;
      // Resident memory belongs to the whole test process, and other test
      // files may run in it: a reading over the bound is taken once more.
      // Holding the arguments would cost gigabytes on every attempt (each
      // argument of 340,000 objects decodes to tens of MiB), so a second
      // clean reading still proves the server held none of them.
      var growth = 0;
      for (var attempt = 0; attempt < 2; attempt++) {
        final base = ProcessInfo.currentRss;
        final result = await service.execute(
          request('''
const pad = Array.from({ length: 340000 }, () => ({}));
let refused = 0;
let message = '';
for (let i = 0; i < 120; i++) {
  try {
    await tools.noop({ pad });
  } catch (e) {
    refused++;
    message = e.message;
  }
}
text(JSON.stringify({ refused, message }));
'''),
          callNested: (call) async {
            reached++;
            return NestedCallOutcome(status: NestedCallStatus.completed);
          },
        );
        growth = ProcessInfo.currentRss - base;
        // ignore: avoid_print
        print('REFUSED growth ${growth ~/ (1024 * 1024)} MiB');
        expect(result.execution.status, CodeExecutionStatus.completed);
        expect(result.result.text, contains('"refused":120'));
        // The whole message the script reads: the count, the limit, the fix.
        expect(
          result.result.text,
          contains(
            'The arguments to noop hold 340003 values; a call takes at most '
            '${CodeModeLimits.maxCallArgumentItems} (objects, arrays, members '
            'and other values together). Split the data across calls, or pass '
            'bulk data as one string where the tool takes text.',
          ),
        );
        expect(reached, 0);
        if (growth < 64 * 1024 * 1024) {
          break;
        }
      }
      expect(growth, lessThan(64 * 1024 * 1024));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('a large structured return value completes: past what a frame may '
        'take decoded it is kept as the text the runner wrote', () async {
      final service = build();
      final objects = await service.execute(
        request('return Array.from({ length: 300000 }, () => ({}));'),
        callNested: (call) async =>
            NestedCallOutcome(status: NestedCallStatus.completed),
      );
      expect(objects.execution.status, CodeExecutionStatus.completed);
      expect(objects.result.text, contains('[{},{},{}'));
      // Fewer values than a tool result may hold decoded, but more heap
      // than a frame may take decoded: still text, never a violation.
      final heavy = await service.execute(
        request('return Array.from({ length: 120000 }, () => ({}));'),
        callNested: (call) async =>
            NestedCallOutcome(status: NestedCallStatus.completed),
      );
      expect(heavy.execution.status, CodeExecutionStatus.completed);
      expect(heavy.result.text, contains('[{},{},{}'));
      final strings = await service.execute(
        request("return Array.from({ length: 200000 }, (_, i) => 's' + i);"),
        callNested: (call) async =>
            NestedCallOutcome(status: NestedCallStatus.completed),
      );
      expect(strings.execution.status, CodeExecutionStatus.completed);
      expect(strings.result.text, contains('"s199999"'));
      // A small value is still decoded and shown indented.
      final small = await service.execute(
        request('return { a: [1, 2] };'),
        callNested: (call) async =>
            NestedCallOutcome(status: NestedCallStatus.completed),
      );
      expect(small.result.text, contains('"a": ['));
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('a JSON text result just under the item limit arrives parsed and '
        'one at it arrives as its text', () async {
      final service = build();
      const limit = CodeModeLimits.maxNestedResultItems;
      final texts = [
        '[${List.filled(limit - 2, '{}').join(',')}]',
        '[${List.filled(limit, '{}').join(',')}]',
      ];
      var next = 0;
      final result = await service.execute(
        request('''
const under = await tools.noop({});
const at = await tools.noop({});
return {
  under: Array.isArray(under) ? under.length : typeof under,
  at: typeof at,
  parsed: JSON.parse(at).length,
};
'''),
        callNested: (call) async => NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: scriptResultOfText(texts[next++]),
        ),
      );
      expect(result.execution.status, CodeExecutionStatus.completed);
      expect(
        result.result.text,
        allOf(
          contains('"under": ${limit - 2}'),
          contains('"at": "string"'),
          contains('"parsed": $limit'),
        ),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('a result nested deeper than the runner reads fails, read from its '
        'encoded bytes', () async {
      final service = build();
      Object nested(int depth) {
        Object value = 1;
        for (var i = 0; i < depth; i++) {
          value = [value];
        }
        return value;
      }

      final values = [
        nested(kRunnerMaxJsonDepth - 2),
        scriptResultOfText(jsonEncode(nested(kRunnerMaxJsonDepth - 1))),
      ];
      var next = 0;
      final result = await service.execute(
        request('''
const seen = [];
for (let i = 0; i < 2; i++) {
  try {
    await tools.noop({});
    seen.push('ok');
  } catch (e) {
    seen.push(e.message);
  }
}
text(JSON.stringify(seen));
'''),
        callNested: (call) async => NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: values[next++],
        ),
      );
      expect(result.execution.status, CodeExecutionStatus.completed);
      expect(
        result.result.text,
        contains(
          '["ok","The result of noop is nested more than '
          '${kRunnerMaxJsonDepth - 2} levels deep',
        ),
      );
    });

    test('calls a tool has not answered take at most the pending budget and '
        'one call of server memory, measured', () async {
      final service = build();
      final release = Completer<void>();
      var reached = 0;
      // The live heap, not resident memory: see live_heap.dart.
      final heap = await LiveHeap.connect();
      addTearDown(heap.close);
      final base = await heap.bytes();
      final result = service.execute(
        request('''
const pad = Array.from({ length: 16000 }, () => ({}));
const sent = [];
for (let i = 0; i < 200; i++) sent.push(tools.hold({ pad }).catch(() => {}));
await Promise.all(sent);
return 'done';
'''),
        callNested: (call) async {
          reached++;
          await release.future;
          return NestedCallOutcome(status: NestedCallStatus.completed);
        },
      );
      // The runner sends all 200 within this; the host reads until the
      // budget is full and then stops.
      final clock = Stopwatch()..start();
      while (reached == 0 && clock.elapsed < const Duration(seconds: 20)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await Future<void>.delayed(const Duration(seconds: 4));
      final growth = await heap.bytes() - base;
      // ignore: avoid_print
      print('HELD growth ${growth ~/ (1024 * 1024)} MiB, reached $reached');
      release.complete();
      final done = await result;
      expect(done.execution.status, CodeExecutionStatus.completed);
      expect(reached, 200);
      expect(
        growth,
        lessThan(
          CodeSandboxProcess.pendingArgumentBudgetBytes +
              CodeSandboxProcess.maxCallWeightBytes,
        ),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
