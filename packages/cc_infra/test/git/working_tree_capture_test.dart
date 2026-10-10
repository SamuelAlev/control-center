import 'dart:io';

import 'package:cc_infra/src/git/working_tree_capture.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future<void> _git(List<String> args, String dir) async {
  final r = await Process.run('git', args, workingDirectory: dir);
  if (r.exitCode != 0) {
    fail('git ${args.join(' ')}: ${r.stderr}');
  }
}

void main() {
  late Directory repo;
  late File index;

  setUp(() async {
    repo = Directory.systemTemp.createTempSync('cc_capture_repo');
    await _git(['init', '-q'], repo.path);
    await _git(['config', 'user.email', 'test@example.com'], repo.path);
    await _git(['config', 'user.name', 'Test'], repo.path);
    await _git(['config', 'commit.gpgsign', 'false'], repo.path);
    File(p.join(repo.path, 'a.txt')).writeAsStringSync('a\n');
    await _git(['add', '-A'], repo.path);
    await _git(['commit', '-q', '-m', 'init'], repo.path);
    index = File(workingTreeCaptureIndexPath(repo.path));
  });

  tearDown(() async {
    await discardWorkingTreeCapture(repo.path);
    repo.deleteSync(recursive: true);
  });

  test('a capture leaves its warm index for the next one', () async {
    expect(await captureWorkingTree(repo.path), isNotNull);
    expect(index.existsSync(), isTrue);
  });

  test('discard deletes the index', () async {
    await captureWorkingTree(repo.path);

    await discardWorkingTreeCapture(repo.path);

    expect(index.existsSync(), isFalse);
  });

  test('discard waits for a capture already running', () async {
    final capture = captureWorkingTree(repo.path);

    await discardWorkingTreeCapture(repo.path);

    expect(await capture, isNotNull);
    expect(index.existsSync(), isFalse);
  });

  test('prune deletes an idle index and keeps a recent one', () async {
    final other = Directory.systemTemp.createTempSync('cc_capture_other');
    addTearDown(() async {
      await discardWorkingTreeCapture(other.path);
      other.deleteSync(recursive: true);
    });
    await _git(['init', '-q'], other.path);
    await captureWorkingTree(repo.path);
    await captureWorkingTree(other.path);
    final recent = File(workingTreeCaptureIndexPath(other.path));
    index.setLastModifiedSync(
      DateTime.now().subtract(const Duration(days: 30)),
    );

    final pruned = pruneWorkingTreeCaptures(olderThan: const Duration(days: 7));

    expect(pruned, greaterThanOrEqualTo(1));
    expect(index.existsSync(), isFalse);
    expect(recent.existsSync(), isTrue);
  });
}
