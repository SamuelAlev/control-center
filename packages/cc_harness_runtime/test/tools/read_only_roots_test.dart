import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A read-only root is refused by every file-changing tool, with the refusal
/// data the caller gave it, and reading or writing elsewhere is unchanged.
void main() {
  late Directory root;
  late String locked;
  late String open;
  const refusal = {'kind': 'repo_grant_required', 'level': 'write'};

  setUp(() {
    root = Directory(
      Directory.systemTemp
          .createTempSync('cc_ro_roots')
          .resolveSymbolicLinksSync(),
    );
    locked = p.join(root.path, 'repos', 'locked');
    open = p.join(root.path, 'repos', 'open');
    for (final dir in [locked, open]) {
      File(p.join(dir, 'README'))
        ..createSync(recursive: true)
        ..writeAsStringSync('original\n');
    }
  });
  tearDown(() => root.deleteSync(recursive: true));

  HarnessToolContext ctx() => HarnessToolContext(
    workingDirectory: root.path,
    readOnlyRoots: [
      ReadOnlyRoot(
        path: locked,
        reason: 'locked is read-only',
        refusal: refusal,
      ),
    ],
  );

  void expectRefused(HarnessToolResult result) {
    expect(result.isError, isTrue);
    expect(result.refusal, refusal);
    expect(result.content, contains('locked is read-only'));
  }

  String readme(String dir) => File(p.join(dir, 'README')).readAsStringSync();

  test('write refuses a file in the root, and a new one', () async {
    final tool = WriteTool();
    expectRefused(
      await tool.execute({
        'path': p.join(locked, 'README'),
        'content': 'changed',
      }, ctx()),
    );
    expectRefused(
      await tool.execute({
        'path': 'repos/locked/sub/new.txt',
        'content': 'changed',
      }, ctx()),
    );
    expect(readme(locked), 'original\n');
    expect(Directory(p.join(locked, 'sub')).existsSync(), isFalse);
  });

  test('write elsewhere is unchanged', () async {
    final result = await WriteTool().execute({
      'path': p.join(open, 'README'),
      'content': 'changed\n',
    }, ctx());
    expect(result.isError, isFalse);
    expect(result.refusal, isNull);
    expect(readme(open), 'changed\n');
  });

  test('a link the agent made cannot carry a write into the root', () async {
    Link(p.join(root.path, 'via')).createSync(locked);
    Link(p.join(root.path, 'file-link')).createSync(p.join(locked, 'README'));
    final tool = WriteTool();
    expectRefused(
      await tool.execute({'path': 'via/README', 'content': 'x'}, ctx()),
    );
    expectRefused(
      await tool.execute({'path': 'file-link', 'content': 'x'}, ctx()),
    );
    expect(readme(locked), 'original\n');
  });

  test('edit refuses the whole batch when one file is in the root', () async {
    final result = await EditTool().execute({
      'edits': [
        {
          'path': p.join(open, 'README'),
          'old_text': 'original',
          'new_text': 'changed',
        },
        {
          'path': p.join(locked, 'README'),
          'old_text': 'original',
          'new_text': 'changed',
        },
      ],
    }, ctx());
    expectRefused(result);
    expect(readme(open), 'original\n');
    expect(readme(locked), 'original\n');
  });

  test('resolve refuses a staged change that touches the root', () async {
    final store = StagedEditStore();
    final staged = store.stage(
      tool: 'ast_edit',
      summary: 'rewrite',
      files: [
        StagedFileEdit(
          path: p.join(open, 'README'),
          before: 'original\n',
          after: 'changed\n',
          replacements: 1,
        ),
        StagedFileEdit(
          path: p.join(locked, 'README'),
          before: 'original\n',
          after: 'changed\n',
          replacements: 1,
        ),
      ],
    );
    final result = await ResolveTool(
      store,
    ).execute({'edit_id': staged.id, 'action': 'accept'}, ctx());
    expectRefused(result);
    expect(readme(open), 'original\n');
    expect(readme(locked), 'original\n');
  });

  test('reading the root is unchanged', () async {
    final result = await ReadTool().execute({
      'path': p.join(locked, 'README'),
    }, ctx());
    expect(result.isError, isFalse);
    expect(result.content, contains('original'));
  });
}
