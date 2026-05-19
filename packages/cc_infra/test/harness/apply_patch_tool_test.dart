import 'dart:io';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/edit/file_edit_service.dart';
import 'package:cc_infra/src/harness/tools/apply_patch_tool.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late HarnessToolContext ctx;
  late FileEditService service;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('patch_');
    ctx = HarnessToolContext(workingDirectory: dir.path);
    service = FileEditService();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('replaces a line range anchored by the file hash', () async {
    final path = p.join(dir.path, 'a.txt');
    const content = 'line1\nline2\nline3\n';
    File(path).writeAsStringSync(content);
    final hash = service.computeHashFor(content);

    final r = await ApplyPatchTool(service).execute({
      'edits': [
        {
          'path': path,
          'file_hash': hash,
          'start_line': 2,
          'end_line': 2,
          'replacement': 'LINE-TWO',
        },
      ],
    }, ctx);

    expect(r.isError, isFalse);
    expect(File(path).readAsStringSync(), 'line1\nLINE-TWO\nline3\n');
  });

  test('rejects a stale hash and writes nothing', () async {
    final path = p.join(dir.path, 'a.txt');
    File(path).writeAsStringSync('line1\nline2\n');
    final r = await ApplyPatchTool(service).execute({
      'edits': [
        {
          'path': path,
          'file_hash': 'dead',
          'start_line': 1,
          'end_line': 1,
          'replacement': 'X',
        },
      ],
    }, ctx);
    expect(r.isError, isTrue);
    expect(File(path).readAsStringSync(), 'line1\nline2\n'); // untouched
  });

  test('empty replacement deletes the range', () async {
    final path = p.join(dir.path, 'a.txt');
    const content = 'keep1\ndrop\nkeep2\n';
    File(path).writeAsStringSync(content);
    final hash = service.computeHashFor(content);
    final r = await ApplyPatchTool(service).execute({
      'edits': [
        {
          'path': path,
          'file_hash': hash,
          'start_line': 2,
          'end_line': 2,
          'replacement': '',
        },
      ],
    }, ctx);
    expect(r.isError, isFalse);
    expect(File(path).readAsStringSync(), 'keep1\nkeep2\n');
  });
}
