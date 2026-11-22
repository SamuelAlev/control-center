// The call site a runner's `call` frame carries (`at`): read against the
// script's own lines, absent is fine, anything malformed ends the script like
// every other malformed frame. Fake runners only; the real runner's sites are
// in call_site_runner_test.dart.
import 'dart:io';

import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/code_mode/runner_frames.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

void main() {
  group('ScriptLines', () {
    test('splits at LF, CRLF and a lone CR and counts UTF-16 units', () {
      final lines = ScriptLines('a();\r\n  b();\rc😀d();\n\ne();');
      expect(lines.siteOf([1, 1]), ScriptCallSite(1, 1));
      expect(lines.siteOf([2, 3]), ScriptCallSite(2, 3));
      // 😀 is two units: `d` is unit 4 of line 3.
      expect(lines.siteOf([3, 4]), ScriptCallSite(3, 4));
      expect(lines.siteOf([5, 1]), ScriptCallSite(5, 1));
    });

    test('refuses anything that is not a character of the script', () {
      final lines = ScriptLines('a😀b();\n\nc();');
      for (final at in <Object?>[
        [1],
        [1, 1, 1],
        ['1', '1'],
        [1.0, 1],
        [1, 1.5],
        [0, 1],
        [1, 0],
        [-1, 1],
        [4, 1],
        [1, 8],
        // The second unit of 😀.
        [1, 3],
        // An empty line has no character.
        [2, 1],
        {'line': 1, 'column': 1},
        '1:1',
        1,
        null,
      ]) {
        expect(() => lines.siteOf(at), throwsFormatException, reason: '$at');
      }
    });
  });

  group('a fake runner', () {
    late Directory tmp;
    late FakeRunners fakes;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('codemode-site-');
      fakes = FakeRunners(tmp);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    const code = 'const r = await tools.x({});\nreturn r;';

    CodeSandboxStart start() => CodeSandboxStart(
      code: code,
      limits: CodeModeLimits(wallClockMs: 5000, maxNestedCalls: 1),
      returnBudgetChars: 30400,
      catalog: const [],
    );

    /// A fake that writes [callFrame] after init and exec, then exits
    /// cleanly once it has its result.
    String fake(String callFrame) => fakes.script('''
printf '%s\\n' '$fakeReadyFull'
read -r init
read -r exec
printf '%s\\n' '$callFrame'
read -r result
printf '%s\\n' '{"type":"done","ok":true,"stats":{"cpu_ms":0,"peak_heap_bytes":0,"calls":1,"output_chars":0,"output_items":0}}'
''');

    Future<(CodeSandboxOutcome, List<CodeSandboxCall>)> drive(
      String path,
    ) async {
      final host = CodeSandboxProcess(executable: path);
      final calls = <CodeSandboxCall>[];
      final session = await host.start(start());
      session.events.listen((e) {
        if (e is CodeSandboxCall) {
          calls.add(e);
          session.reply(CodeSandboxReply(id: e.id, ok: true, payload: 1));
        }
      });
      final outcome = await session.outcome;
      await host.dispose();
      expect(host.liveProcessCount, 0);
      return (outcome, calls);
    }

    String call(String at) =>
        '{"type":"call","id":1,"target":"tool","name":"x","args":{}$at}';

    test('passes a site on a line of the script to the call', () async {
      final (outcome, calls) = await drive(fake(call(',"at":[1,17]')));
      expect(outcome.status, CodeExecutionStatus.completed, reason: '$outcome');
      expect(calls.single.site, ScriptCallSite(1, 17));
    });

    test('takes a call without a site', () async {
      final (outcome, calls) = await drive(fake(call('')));
      expect(outcome.status, CodeExecutionStatus.completed, reason: '$outcome');
      expect(calls.single.site, isNull);
    });

    for (final (label, at) in [
      ('a list of one', ',"at":[1]'),
      ('strings', ',"at":["1","17"]'),
      ('a fraction', ',"at":[1,1.5]'),
      ('null', ',"at":null'),
      ('a line past the script', ',"at":[3,1]'),
      ('a column past the line', ',"at":[2,10]'),
      ('an object', ',"at":{"line":1,"column":1}'),
    ]) {
      test('ends the script on a site that is $label', () async {
        final (outcome, calls) = await drive(fake(call(at)));
        expect(outcome.status, CodeExecutionStatus.sandboxError);
        expect(outcome.errorKind, 'protocol');
        expect(outcome.detail, contains('malformed call site'));
        expect(calls, isEmpty, reason: 'the call never reaches the host');
      });
    }
  });
}
