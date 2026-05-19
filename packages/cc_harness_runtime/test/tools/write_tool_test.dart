import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/write_tool.dart';
import 'package:test/test.dart';

HarnessToolContext _ctx(String dir) =>
    HarnessToolContext(workingDirectory: dir);

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('write_tool_test_');
  });

  tearDown(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  group('WriteTool', () {
    test('name/description/approvalTier/inputSchema', () {
      final tool = WriteTool();
      expect(tool.name, 'write');
      expect(tool.description, isNotEmpty);
      expect(tool.approvalTier, ToolApprovalTier.write);
      expect(tool.inputSchema['required'], ['path', 'content']);
    });

    test('errors when path is missing', () async {
      final tool = WriteTool();
      final result = await tool.execute({}, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, contains('path'));
    });

    test('errors when path is empty', () async {
      final tool = WriteTool();
      final result = await tool.execute({'path': ''}, _ctx(temp.path));
      expect(result.isError, isTrue);
    });

    test('errors when content is missing', () async {
      final tool = WriteTool();
      final result = await tool.execute({'path': 'a.txt'}, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, contains('content'));
    });

    test('errors when content is not a string', () async {
      final tool = WriteTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'content': 42,
      }, _ctx(temp.path));
      expect(result.isError, isTrue);
    });

    test('errors when path escapes the workspace', () async {
      final tool = WriteTool();
      final result = await tool.execute({
        'path': '../outside.txt',
        'content': 'x',
      }, _ctx(temp.path));
      expect(result.isError, isTrue);
      expect(result.content, contains('outside the workspace'));
    });

    test('creates a new file and reports the line count', () async {
      final tool = WriteTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'content': 'l1\nl2\nl3',
      }, _ctx(temp.path));
      expect(result.isError, isFalse);
      expect(result.content, contains('Created'));
      expect(result.content, contains('3 lines'));
      expect(File('${temp.path}/a.txt').readAsStringSync(), 'l1\nl2\nl3');
    });

    test('updates an existing file', () async {
      File('${temp.path}/a.txt').writeAsStringSync('old');
      final tool = WriteTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'content': 'new',
      }, _ctx(temp.path));
      expect(result.isError, isFalse);
      expect(result.content, contains('Updated'));
      expect(File('${temp.path}/a.txt').readAsStringSync(), 'new');
    });

    test('creates parent directories', () async {
      final tool = WriteTool();
      final result = await tool.execute({
        'path': 'nested/deep/file.txt',
        'content': 'x',
      }, _ctx(temp.path));
      expect(result.isError, isFalse);
      expect(File('${temp.path}/nested/deep/file.txt').existsSync(), isTrue);
    });

    test('counts a single line file as 1 line', () async {
      final tool = WriteTool();
      final result = await tool.execute({
        'path': 'a.txt',
        'content': 'only',
      }, _ctx(temp.path));
      expect(result.content, contains('1 lines'));
    });
  });
}
