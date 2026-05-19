import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/edit_tool.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('EditTool', () {
    late Directory dir;
    late HarnessToolContext ctx;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('edit_');
      ctx = HarnessToolContext(workingDirectory: dir.path);
    });
    tearDown(() => dir.deleteSync(recursive: true));

    File write(String name, String content) =>
        File(p.join(dir.path, name))..writeAsStringSync(content);

    test('single edit replaces a unique section', () async {
      write('a.txt', 'hello world');
      final r = await EditTool().execute({
        'path': 'a.txt',
        'old_text': 'world',
        'new_text': 'there',
      }, ctx);
      expect(r.isError, isFalse);
      expect(File(p.join(dir.path, 'a.txt')).readAsStringSync(), 'hello there');
    });

    test('batch edits across two files apply atomically', () async {
      write('a.txt', 'aaa');
      write('b.txt', 'bbb');
      final r = await EditTool().execute({
        'edits': [
          {'path': 'a.txt', 'old_text': 'aaa', 'new_text': 'AAA'},
          {'path': 'b.txt', 'old_text': 'bbb', 'new_text': 'BBB'},
        ],
      }, ctx);
      expect(r.isError, isFalse);
      expect(File(p.join(dir.path, 'a.txt')).readAsStringSync(), 'AAA');
      expect(File(p.join(dir.path, 'b.txt')).readAsStringSync(), 'BBB');
    });

    test('a failing edit in a batch writes nothing (atomic)', () async {
      write('a.txt', 'aaa');
      write('b.txt', 'bbb');
      final r = await EditTool().execute({
        'edits': [
          {'path': 'a.txt', 'old_text': 'aaa', 'new_text': 'AAA'},
          {'path': 'b.txt', 'old_text': 'nope', 'new_text': 'X'},
        ],
      }, ctx);
      expect(r.isError, isTrue);
      // a.txt must be untouched because the batch failed.
      expect(File(p.join(dir.path, 'a.txt')).readAsStringSync(), 'aaa');
    });

    test('ambiguous match without replace_all errors', () async {
      write('a.txt', 'x x x');
      final r = await EditTool().execute({
        'path': 'a.txt',
        'old_text': 'x',
        'new_text': 'y',
      }, ctx);
      expect(r.isError, isTrue);
    });

    test('replace_all replaces every occurrence', () async {
      write('a.txt', 'x x x');
      final r = await EditTool().execute({
        'path': 'a.txt',
        'old_text': 'x',
        'new_text': 'y',
        'replace_all': true,
      }, ctx);
      expect(r.isError, isFalse);
      expect(File(p.join(dir.path, 'a.txt')).readAsStringSync(), 'y y y');
    });
  });

  // The former ephemeral `TodoTool` has been replaced by the persisted MCP
  // `TodoWriteTool` (see cc_mcp `todo_write_tool_test.dart`), which is bridged
  // into the harness rather than registered as a native built-in.
}
