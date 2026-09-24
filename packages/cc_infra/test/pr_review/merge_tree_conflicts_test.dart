import 'dart:io';

import 'package:cc_infra/src/pr_review/pr_clone_manager.dart';
import 'package:test/test.dart';

void main() {
  group('parseMergeTreeConflicts', () {
    test('drops the tree OID and dedupes multi-stage paths', () {
      const out = 'e118fa270925\x00a.txt\x00a.txt\x00dir/b c.txt\x00';
      expect(parseMergeTreeConflicts(out), ['a.txt', 'dir/b c.txt']);
    });

    test('a clean merge is only the OID', () {
      expect(parseMergeTreeConflicts('e118fa270925\x00'), isEmpty);
      expect(parseMergeTreeConflicts('e118fa270925\n'), isEmpty);
    });
  });

  // Pins the argv shape against a real git: `-z --name-only --no-messages`
  // is what the parser above assumes.
  test('parses what git merge-tree really prints', () async {
    final dir = await Directory.systemTemp.createTemp('merge_tree_');
    addTearDown(() => dir.delete(recursive: true));
    Future<ProcessResult> git(List<String> args) => Process.run(
      'git',
      ['-c', 'user.email=t@t', '-c', 'user.name=t', ...args],
      workingDirectory: dir.path,
    );
    void write(String name, String body) =>
        File('${dir.path}/$name').writeAsStringSync(body);

    await git(['init', '-q', '-b', 'main']);
    write('f.txt', 'a\n');
    write('same.txt', 'a\n');
    await git(['add', '.']);
    await git(['commit', '-qm', 'init']);
    await git(['checkout', '-qb', 'pr']);
    write('f.txt', 'pr\n');
    write('new file.txt', 'pr\n');
    await git(['add', '.']);
    await git(['commit', '-qm', 'pr']);
    await git(['checkout', '-q', 'main']);
    write('f.txt', 'main\n');
    write('new file.txt', 'main\n');
    await git(['add', '.']);
    await git(['commit', '-qm', 'main']);

    final result = await git([
      'merge-tree',
      '--write-tree',
      '--name-only',
      '--no-messages',
      '-z',
      'main',
      'pr',
    ]);
    expect(result.exitCode, 1);
    expect(parseMergeTreeConflicts(result.stdout as String), [
      'f.txt',
      'new file.txt',
    ]);
  });
}
