import 'dart:io';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/bash_tool.dart';
import 'package:cc_harness_runtime/src/tools/edit_tool.dart';
import 'package:cc_harness_runtime/src/tools/find_tool.dart';
import 'package:cc_harness_runtime/src/tools/read_tool.dart';
import 'package:cc_harness_runtime/src/tools/search_tool.dart';
import 'package:cc_harness_runtime/src/tools/write_tool.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _FakeCommandRunner implements HarnessCommandRunner {
  _FakeCommandRunner(this.result);

  final HarnessCommandResult result;
  String? lastCommand;

  @override
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
  }) async {
    lastCommand = command;
    return result;
  }
}

void main() {
  late Directory dir;
  late HarnessToolContext ctx;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('harness_tools_');
    ctx = HarnessToolContext(workingDirectory: dir.path);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('write then read round-trips with line numbers', () async {
    final write = await WriteTool().execute({
      'path': 'a.txt',
      'content': 'line1\nline2',
    }, ctx);
    expect(write.isError, isFalse);
    expect(File(p.join(dir.path, 'a.txt')).readAsStringSync(), 'line1\nline2');

    final read = await ReadTool().execute({'path': 'a.txt'}, ctx);
    expect(read.content, '1\tline1\n2\tline2');
  });

  test('read sel selects a line range', () async {
    File(p.join(dir.path, 'b.txt')).writeAsStringSync('a\nb\nc\nd\ne');
    final read = await ReadTool().execute({'path': 'b.txt', 'sel': '2-3'}, ctx);
    expect(read.content, '2\tb\n3\tc');
  });

  test('write refuses to escape the workspace', () async {
    final result = await WriteTool().execute({
      'path': '../escape.txt',
      'content': 'x',
    }, ctx);
    expect(result.isError, isTrue);
    expect(result.content, contains('outside the workspace'));
  });

  test('edit replaces a unique match and rejects ambiguous ones', () async {
    File(p.join(dir.path, 'c.txt')).writeAsStringSync('foo bar foo');
    final ambiguous = await EditTool().execute({
      'path': 'c.txt',
      'old_text': 'foo',
      'new_text': 'baz',
    }, ctx);
    expect(ambiguous.isError, isTrue);

    File(p.join(dir.path, 'c.txt')).writeAsStringSync('foo bar');
    final ok = await EditTool().execute({
      'path': 'c.txt',
      'old_text': 'bar',
      'new_text': 'qux',
    }, ctx);
    expect(ok.isError, isFalse);
    expect(File(p.join(dir.path, 'c.txt')).readAsStringSync(), 'foo qux');
  });

  test('search finds matching lines with file + line number', () async {
    File(
      p.join(dir.path, 'd.dart'),
    ).writeAsStringSync('void main() {}\n// TODO: x');
    final result = await SearchTool().execute({
      'pattern': 'TODO',
      'glob': '*.dart',
    }, ctx);
    expect(result.content, contains('d.dart:2'));
    expect(result.content, contains('TODO'));
  });

  test('find matches a glob and reports paths', () async {
    File(p.join(dir.path, 'one.dart')).writeAsStringSync('');
    Directory(p.join(dir.path, 'sub')).createSync();
    File(p.join(dir.path, 'sub', 'two.dart')).writeAsStringSync('');
    File(p.join(dir.path, 'note.md')).writeAsStringSync('');

    final result = await FindTool().execute({'pattern': '**/*.dart'}, ctx);
    expect(result.content, contains('one.dart'));
    expect(result.content, contains(p.join('sub', 'two.dart')));
    expect(result.content, isNot(contains('note.md')));
  });

  group('BashTool', () {
    test('reports command output and exit code', () async {
      final runner = _FakeCommandRunner(
        const HarnessCommandResult(exitCode: 0, stdout: 'hi', stderr: ''),
      );
      final result = await BashTool(
        runner,
      ).execute({'command': 'echo hi'}, ctx);
      expect(runner.lastCommand, 'echo hi');
      expect(result.isError, isFalse);
      expect(result.content, contains('hi'));
      expect(result.content, contains('exit code 0'));
    });

    test('surfaces a policy denial as an error', () async {
      final runner = _FakeCommandRunner(
        HarnessCommandResult.deny('denied by policy'),
      );
      final result = await BashTool(
        runner,
      ).execute({'command': 'rm -rf /'}, ctx);
      expect(result.isError, isTrue);
      expect(result.content, contains('denied by policy'));
    });

    test('marks a non-zero exit as an error', () async {
      final runner = _FakeCommandRunner(
        const HarnessCommandResult(exitCode: 1, stdout: '', stderr: 'boom'),
      );
      final result = await BashTool(runner).execute({'command': 'false'}, ctx);
      expect(result.isError, isTrue);
      expect(result.content, contains('boom'));
    });
  });
}
