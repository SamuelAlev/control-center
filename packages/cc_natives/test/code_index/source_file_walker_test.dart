import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// These tests exercise real filesystem + git behaviour, so they spawn `git`.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('source_file_walker_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  Future<void> write(String relativePath, String contents) async {
    final file = File(p.join(tmp.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  Future<ProcessResult> git(List<String> args) =>
      Process.run('git', args, workingDirectory: tmp.path);

  Set<String> rels(List<SourceFile> files) =>
      files.map((f) => p.split(f.relativePath).join('/')).toSet();

  group('SourceFileWalker in a git work tree', () {
    setUp(() async {
      await git(['init']);
      await git(['config', 'user.email', 'test@example.com']);
      await git(['config', 'user.name', 'Test']);
    });

    test('excludes paths matched by .gitignore', () async {
      await write('.gitignore', 'node_modules/\nbuild/\n*.log\n');
      await write('lib/main.dart', 'void main() {}');
      await write('lib/widget.dart', 'class W {}');
      // Ignored trees / files — these must NOT be indexed.
      await write('node_modules/pkg/index.js', 'module.exports = {};');
      await write('build/generated.dart', 'class Gen {}');
      await write('debug.log', 'noise');

      final files = await const SourceFileWalker().walk(tmp.path);
      final paths = rels(files);

      expect(paths, containsAll(<String>['lib/main.dart', 'lib/widget.dart']));
      expect(
        paths.any((path) => path.startsWith('node_modules/')),
        isFalse,
        reason: 'gitignored node_modules must be excluded',
      );
      expect(paths, isNot(contains('build/generated.dart')));
    });

    test('honours a nested .gitignore', () async {
      await write('.gitignore', '');
      await write('lib/keep.dart', 'class Keep {}');
      await write('lib/sub/.gitignore', 'secret.dart\n');
      await write('lib/sub/visible.dart', 'class Visible {}');
      await write('lib/sub/secret.dart', 'class Secret {}');

      final paths = rels(await const SourceFileWalker().walk(tmp.path));

      expect(paths, contains('lib/sub/visible.dart'));
      expect(paths, isNot(contains('lib/sub/secret.dart')));
    });

    test('still excludes generated Dart even when committed', () async {
      await write('.gitignore', '');
      await write('lib/model.dart', 'class Model {}');
      // Generated files are typically committed (not gitignored) but should
      // never reach the graph.
      await write('lib/model.g.dart', '// GENERATED');
      await write('lib/model.freezed.dart', '// GENERATED');
      await git(['add', '-A']);

      final paths = rels(await const SourceFileWalker().walk(tmp.path));

      expect(paths, contains('lib/model.dart'));
      expect(paths, isNot(contains('lib/model.g.dart')));
      expect(paths, isNot(contains('lib/model.freezed.dart')));
    });

    test('includes untracked-but-not-ignored files', () async {
      await write('.gitignore', 'node_modules/\n');
      await write('lib/tracked.dart', 'class T {}');
      await git(['add', 'lib/tracked.dart']);
      await git(['commit', '-m', 'init']);
      // Brand new, never staged — git ls-files --others must still surface it.
      await write('lib/fresh.dart', 'class F {}');
      await write('node_modules/dep/index.js', 'x');

      final paths = rels(await const SourceFileWalker().walk(tmp.path));

      expect(paths, containsAll(<String>['lib/tracked.dart', 'lib/fresh.dart']));
      expect(paths.any((path) => path.startsWith('node_modules/')), isFalse);
    });

    test('filters by extension override', () async {
      await write('.gitignore', '');
      await write('a.dart', '');
      await write('b.py', '');
      await write('c.ts', '');

      final paths = rels(
        await const SourceFileWalker(extensions: {'dart'}).walk(tmp.path),
      );

      expect(paths, contains('a.dart'));
      expect(paths, isNot(contains('b.py')));
      expect(paths, isNot(contains('c.ts')));
    });
  });

  group('SourceFileWalker fallback (non-git directory)', () {
    test('falls back to the hardcoded skip set', () async {
      // No `git init` — not a work tree, so the manual walk runs.
      await write('lib/main.dart', 'void main() {}');
      await write('node_modules/pkg/index.js', 'x');
      await write('.dart_tool/cache.dart', 'class C {}');

      final paths = rels(await const SourceFileWalker().walk(tmp.path));

      expect(paths, contains('lib/main.dart'));
      expect(paths.any((path) => path.startsWith('node_modules/')), isFalse);
      expect(paths.any((path) => path.startsWith('.dart_tool/')), isFalse);
    });
  });
}
