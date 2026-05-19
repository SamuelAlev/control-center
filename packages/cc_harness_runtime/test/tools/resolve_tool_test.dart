import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late StagedEditStore store;
  late ResolveTool tool;

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc_resolve');
    store = StagedEditStore();
    tool = ResolveTool(store);
  });
  tearDown(() => root.deleteSync(recursive: true));

  String write(String name, String content) {
    final path = p.join(root.path, name);
    File(path).writeAsStringSync(content);
    return path;
  }

  HarnessToolContext ctx() => HarnessToolContext(workingDirectory: root.path);

  StagedEdit stage(List<StagedFileEdit> files) =>
      store.stage(tool: 'ast_edit', summary: 'rewrite', files: files);

  test('accept writes every file at once', () async {
    final a = write('a.txt', 'old a');
    final b = write('b.txt', 'old b');
    final staged = stage([
      StagedFileEdit(path: a, before: 'old a', after: 'new a', replacements: 1),
      StagedFileEdit(path: b, before: 'old b', after: 'new b', replacements: 2),
    ]);

    final result = await tool.execute(
      {'edit_id': staged.id, 'action': 'accept'},
      ctx(),
    );
    expect(result.isError, isFalse);
    expect(result.content, contains('3 replacements across 2 files'));
    expect(File(a).readAsStringSync(), 'new a');
    expect(File(b).readAsStringSync(), 'new b');
  });

  test('discard writes nothing and drops the change', () async {
    final a = write('a.txt', 'old a');
    final staged = stage([
      StagedFileEdit(path: a, before: 'old a', after: 'new a', replacements: 1),
    ]);

    final result = await tool.execute(
      {'edit_id': staged.id, 'action': 'discard'},
      ctx(),
    );
    expect(result.isError, isFalse);
    expect(File(a).readAsStringSync(), 'old a');
    expect(store.peek(staged.id), isNull);
  });

  test('refuses when a file changed since staging', () async {
    // The safety property: committing anyway would silently discard the newer
    // work and the diff would look intentional.
    final a = write('a.txt', 'old a');
    final staged = stage([
      StagedFileEdit(path: a, before: 'old a', after: 'new a', replacements: 1),
    ]);
    File(a).writeAsStringSync('somebody else wrote this');

    final result = await tool.execute(
      {'edit_id': staged.id, 'action': 'accept'},
      ctx(),
    );
    expect(result.isError, isTrue);
    expect(result.content, contains('changed since'));
    expect(File(a).readAsStringSync(), 'somebody else wrote this');
    expect(
      store.peek(staged.id),
      isNull,
      reason: 'a refused change is dropped, not left to be retried blindly',
    );
  });

  test('a stale sibling refuses the whole change, not just that file', () async {
    final a = write('a.txt', 'old a');
    final b = write('b.txt', 'old b');
    final staged = stage([
      StagedFileEdit(path: a, before: 'old a', after: 'new a', replacements: 1),
      StagedFileEdit(path: b, before: 'old b', after: 'new b', replacements: 1),
    ]);
    File(b).writeAsStringSync('moved');

    final result = await tool.execute(
      {'edit_id': staged.id, 'action': 'accept'},
      ctx(),
    );
    expect(result.isError, isTrue);
    expect(
      File(a).readAsStringSync(),
      'old a',
      reason: 'a partly-applied structural rewrite compiles under neither shape',
    );
  });

  test('a second accept fails rather than writing twice', () async {
    final a = write('a.txt', 'old a');
    final staged = stage([
      StagedFileEdit(path: a, before: 'old a', after: 'new a', replacements: 1),
    ]);
    await tool.execute({'edit_id': staged.id, 'action': 'accept'}, ctx());

    final again = await tool.execute(
      {'edit_id': staged.id, 'action': 'accept'},
      ctx(),
    );
    expect(again.isError, isTrue);
    expect(again.content, contains('No staged change'));
  });

  test('an unknown id lists what is actually pending', () async {
    final staged = stage([]);
    final result = await tool.execute(
      {'edit_id': 'edit_99', 'action': 'accept'},
      ctx(),
    );
    expect(result.isError, isTrue);
    expect(result.content, contains(staged.id));
  });

  test('rejects a bad action instead of guessing', () async {
    final staged = stage([]);
    final result = await tool.execute(
      {'edit_id': staged.id, 'action': 'maybe'},
      ctx(),
    );
    expect(result.isError, isTrue);
    expect(store.peek(staged.id), isNotNull);
  });

  test('is write tier, so read-only surfaces never see it', () {
    expect(tool.approvalTier, ToolApprovalTier.write);
  });
}
