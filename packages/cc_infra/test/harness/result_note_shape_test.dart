import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/harness/ask_user_tool.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Each direct harness tool a script may call is held to its result note:
/// the test calls the tool and checks that what a script receives
/// ([scriptValueOf]) has the shape the note states, and that the note names
/// what the test checks, so neither can drift from the other.
/// What a script receives from [result]: [scriptValueOf], with a text that
/// looks like JSON decoded as the runner decodes it (a text that only starts
/// with `[` stays text).
Object? sees(HarnessToolResult result) =>
    jsonDecode(jsonEncode(scriptValueOf(result)));

void main() {
  late Directory root;
  late HarnessToolContext ctx;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_result_notes_');
    ctx = HarnessToolContext(
      workingDirectory: root.path,
      workspaceId: 'ws',
      conversationId: 'conv',
      agentId: 'agent',
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  void expectNamed(String? note, Iterable<String> parts) {
    expect(note, isNotNull);
    for (final part in parts) {
      expect(note, contains(part), reason: 'the note names $part');
    }
  }

  void expectKeys(Object? value, Set<String> keys) {
    expect(value, isA<Map<String, Object?>>());
    expect((value! as Map<String, Object?>).keys.toSet(), keys);
  }

  test(
    'read: an optional file line, numbered lines, then the window',
    () async {
      File(p.join(root.path, 'a.txt')).writeAsStringSync('alpha\nbeta\ngamma');
      final tool = ReadTool(hashOf: (_) => 'h1');
      final value = sees(
        await tool.execute({'path': 'a.txt', 'limit': 2}, ctx),
      );
      expect(value, isA<String>());
      expect(
        value,
        matches(
          RegExp(
            r'^\[file a\.txt hash=h1 lines=3\]\n1\talpha\n2\tbeta\n'
            r'\[showing lines 1-2 of 3; [^\]]*\]$',
          ),
        ),
      );
      // Without hashes there is no file line.
      final plain = sees(await ReadTool().execute({'path': 'a.txt'}, ctx));
      expect(plain, '1\talpha\n2\tbeta\n3\tgamma');
      expectNamed(tool.resultNote, [
        'maybe `[file <path> hash=H lines=N]`',
        '`<number><tab><line>` per line',
        'a partial read ends `[showing lines A-B of N; …]`',
      ]);
    },
  );

  test('write: Created or Updated, with the line count', () async {
    final tool = WriteTool();
    final created = sees(
      await tool.execute({'path': 'b.txt', 'content': 'one\ntwo'}, ctx),
    );
    final updated = sees(
      await tool.execute({'path': 'b.txt', 'content': 'one'}, ctx),
    );
    expect(created, 'Created b.txt (2 lines).');
    expect(updated, 'Updated b.txt (1 lines).');
    expectNamed(tool.resultNote, [
      '`Created <path> (N lines).`',
      '`Updated …`',
    ]);
  });

  test('edit: one file, or several with a count each', () async {
    File(p.join(root.path, 'c.txt')).writeAsStringSync('red green');
    File(p.join(root.path, 'd.txt')).writeAsStringSync('blue');
    final tool = EditTool();
    final one = sees(
      await tool.execute({
        'path': 'c.txt',
        'old_text': 'red',
        'new_text': 'pink',
      }, ctx),
    );
    expect(one, matches(RegExp(r'^Edited c\.txt \(1 changes?\)\.$')));
    final several = sees(
      await tool.execute({
        'edits': [
          {'path': 'c.txt', 'old_text': 'green', 'new_text': 'teal'},
          {'path': 'd.txt', 'old_text': 'blue', 'new_text': 'navy'},
        ],
      }, ctx),
    );
    expect(several, 'Edited 2 files: c.txt (1), d.txt (1).');
    expectNamed(tool.resultNote, [
      '`Edited <path> (N changes).`',
      '`Edited K files: <path> (N), ….`',
    ]);
  });

  test(
    'search: matches with path, line and text, total and truncated',
    () async {
      File(p.join(root.path, 'e.txt')).writeAsStringSync('needle\nhay\nneedle');
      final tool = SearchTool();
      final value = sees(await tool.execute({'pattern': 'needle'}, ctx));
      expectKeys(value, {'matches', 'total', 'truncated'});
      final map = value! as Map<String, Object?>;
      expect(map['total'], isA<int>());
      expect(map['truncated'], isA<bool>());
      final matches = map['matches']! as List;
      expect(matches, hasLength(2));
      for (final match in matches) {
        expectKeys(match, {'path', 'line', 'text'});
        final m = match as Map<String, Object?>;
        expect(m['path'], isA<String>());
        expect(m['line'], isA<int>());
        expect(m['text'], isA<String>());
      }
      expectNamed(tool.resultNote, [
        'matches: {path: string, line: number, text: string}[]',
        'total: number',
        'truncated: boolean',
      ]);
    },
  );

  test('find: files, total and truncated', () async {
    File(p.join(root.path, 'f.dart')).writeAsStringSync('');
    final tool = FindTool();
    final value = sees(await tool.execute({'pattern': '*.dart'}, ctx));
    expectKeys(value, {'files', 'total', 'truncated'});
    final map = value! as Map<String, Object?>;
    expect(map['files'], ['f.dart']);
    expect(map['total'], isA<int>());
    expect(map['truncated'], isA<bool>());
    expectNamed(tool.resultNote, [
      'files: string[]',
      'total: number',
      'truncated: boolean',
    ]);
  });

  test('bash: output, exit code 0 and no timeout; a failure is an error '
      'that starts with its exit code', () async {
    final ok = BashTool(
      const _Runner(
        HarnessCommandResult(exitCode: 0, stdout: 'hi', stderr: 'warn'),
      ),
    );
    final value = sees(
      await ok.execute({'command': 'x', 'description': 'Run x'}, ctx),
    );
    expect(value, {
      'output': 'hi\n[stderr]\nwarn',
      'exit_code': 0,
      'timed_out': false,
    });
    // A failed call rejects in a script; its message is the content.
    final failed = await BashTool(
      const _Runner(
        HarnessCommandResult(exitCode: 3, stdout: 'partial', stderr: ''),
      ),
    ).execute({'command': 'x', 'description': 'Run x'}, ctx);
    expect(failed.isError, isTrue);
    expect(failed.content, 'exit code 3\npartial');
    final timedOut = await BashTool(
      const _Runner(
        HarnessCommandResult(
          exitCode: 0,
          stdout: '',
          stderr: '',
          timedOut: true,
        ),
      ),
    ).execute({'command': 'x', 'description': 'Run x'}, ctx);
    expect(timedOut.isError, isTrue);
    expect(timedOut.content, startsWith('exit code 0\n'));
    expectNamed(ok.resultNote, [
      '{output: string, exit_code: 0, timed_out: false}',
      '`[stderr]`',
      'A nonzero exit or a timeout rejects with `exit code N`',
    ]);
  });

  test(
    'read_output: a header with the range, the text, then what remains',
    () async {
      final store = InMemoryToolOutputStore();
      final reference = (await store.put(
        ToolOutputWrite(
          scope: const ToolOutputScope(
            workspaceId: 'ws',
            conversationId: 'conv',
            agentId: 'agent',
          ),
          toolName: 'bash',
          content: 'x' * 50,
        ),
      ))!;
      final tool = ToolOutputReadTool(store);
      final value = sees(
        await tool.execute({'handle': reference.handle, 'limit': 20}, ctx),
      );
      expect(value, isA<String>());
      final lines = (value! as String).split('\n');
      expect(
        lines.first,
        matches(RegExp(r'^\[output \S+ \(bash\): chars 0-20 of 50\]')),
      );
      expect(lines[1], 'x' * 20);
      expect(lines.last, '[+30 chars remain; continue with offset=20]');
      expectNamed(tool.resultNote, [
        '`[output <handle> …: chars A-B of N]`',
        '`[+K chars remain; …]`',
      ]);
    },
  );

  test('ask_user: selected, text and skipped', () async {
    final tool = AskUserTool(
      port: const _Answers(
        AgentQuestionAnswer(selectedLabels: ['Blue'], freeText: ' red '),
      ),
      workspaceId: 'ws',
      spaceId: 'space',
      conversationId: 'conv',
    );
    final value = sees(await tool.execute({'question': 'Which colour?'}, ctx));
    expect(value, {
      'selected': ['Blue'],
      'text': 'red',
      'skipped': false,
    });
    expectNamed(tool.resultNote, [
      'selected: string[]',
      'text: string | null',
      'skipped: boolean',
    ]);
  });
}

class _Runner implements HarnessCommandRunner {
  const _Runner(this.result);

  final HarnessCommandResult result;

  @override
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
    PersonWaitListener? personWait,
    String? parentToolCallId,
    HarnessCommandObserver? observer,
  }) async => result;
}

class _Answers implements AgentQuestionPort {
  const _Answers(this.answer);

  final AgentQuestionAnswer answer;

  @override
  Future<AgentQuestionAnswer?> ask(
    AgentQuestionRequest request, {
    Future<void>? abandoned,
  }) async => answer;
}
