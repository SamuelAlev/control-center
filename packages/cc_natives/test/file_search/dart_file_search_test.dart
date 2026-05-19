import 'dart:io';

import 'package:cc_natives/src/file_search/dart_file_search.dart';
import 'package:test/test.dart';

/// Regression tests for symlink traversal in [DartFileSearch].
///
/// The per-agent conversation overlay exposes shared repo worktrees via a
/// `repos → ../../repos` symlink. A `followLinks: false` walk returned that
/// symlink as an opaque `Link` and never descended into it, so `search_files`
/// found nothing ("couldn't search files"). These tests pin the fix: directory
/// symlinks are followed with logical relative paths and cyclic links
/// terminate.
void main() {
  late DartFileSearch search;
  late Directory tmp;

  setUp(() async {
    search = DartFileSearch();
    tmp = await Directory.systemTemp.createTemp('dart_file_search_');
  });

  tearDown(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  test(
    'descends into a directory symlink and returns logical relative paths',
    () async {
      // Real repo tree living OUTSIDE the search root — mirrors the shared
      // conversation worktrees the overlay's `repos → ../../repos` points at.
      final realRepo = Directory('${tmp.path}/real_repo');
      await realRepo.create(recursive: true);
      await Directory('${realRepo.path}/lib').create(recursive: true);
      await File('${realRepo.path}/lib/foo.dart').writeAsString('class Foo {}');

      // The search root mimics the per-agent overlay: a `repos` symlink whose
      // target sits elsewhere on disk.
      final root = Directory('${tmp.path}/overlay');
      await root.create(recursive: true);
      await Link('${root.path}/repos').create(realRepo.path);

      await search.warmUp([root.path]);

      final hits = await search
          .search(roots: [root.path], query: 'foo.dart')
          .first;
      final paths = hits.map((h) => h.relativePath).toList();

      expect(paths, contains('repos/lib/foo.dart'));
    },
  );

  test('terminates on a cyclic symlink without duplicates', () async {
    // `root` holds a file plus a symlink `loop → root` pointing back at itself.
    // Without the cycle guard the walk would recurse forever.
    final root = Directory('${tmp.path}/cyclic');
    await root.create(recursive: true);
    await File('${root.path}/marker.txt').writeAsString('x');
    await Link('${root.path}/loop').create(root.path);

    await search.warmUp([root.path]);

    final hits = await search
        .search(roots: [root.path], query: 'marker.txt')
        .first;
    final matches = hits
        .map((h) => h.relativePath)
        .where((p) => p.endsWith('marker.txt'))
        .toSet();

    // Found exactly once — the self-referential `loop` was pruned, not walked.
    expect(matches, hasLength(1));
  });

  test('skips a broken symlink without error', () async {
    final root = Directory('${tmp.path}/broken');
    await root.create(recursive: true);
    await File('${root.path}/present.dart').writeAsString('class A {}');
    await Link('${root.path}/dangling').create('${tmp.path}/does_not_exist');

    await search.warmUp([root.path]);

    final hits = await search
        .search(roots: [root.path], query: 'present.dart')
        .first;
    final paths = hits.map((h) => h.relativePath).toList();

    expect(paths, contains('present.dart'));
  });

  group('offset paging', () {
    test('consecutive pages are disjoint and cover the full result set',
        () async {
      final root = Directory('${tmp.path}/paged');
      await root.create(recursive: true);
      for (var i = 0; i < 10; i++) {
        await File('${root.path}/file_$i.dart').writeAsString('class A$i {}');
      }

      await search.warmUp([root.path]);

      final page0 = await search
          .search(roots: [root.path], query: 'file_', limit: 4, offset: 0)
          .first;
      final page1 = await search
          .search(roots: [root.path], query: 'file_', limit: 4, offset: 4)
          .first;
      final page2 = await search
          .search(roots: [root.path], query: 'file_', limit: 4, offset: 8)
          .first;

      expect(page0, hasLength(4));
      expect(page1, hasLength(4));
      // The final page holds only the remainder.
      expect(page2, hasLength(2));

      final all = [...page0, ...page1, ...page2];
      // Union of the pages = the un-paged result set, each entry exactly once.
      final unPaged = await search
          .search(roots: [root.path], query: 'file_', limit: 100)
          .first;
      expect(
        all.map((h) => h.relativePath).toSet(),
        equals(unPaged.map((h) => h.relativePath).toSet()),
      );
      // Disjoint: no path appears in two pages.
      final paths = all.map((h) => h.relativePath).toList();
      expect(paths.toSet(), hasLength(paths.length));
    });

    test('an offset past the end yields an empty page', () async {
      final root = Directory('${tmp.path}/past_end');
      await root.create(recursive: true);
      for (var i = 0; i < 3; i++) {
        await File('${root.path}/file_$i.dart').writeAsString('class A$i {}');
      }

      await search.warmUp([root.path]);

      final page = await search
          .search(roots: [root.path], query: 'file_', limit: 2, offset: 50)
          .first;
      expect(page, isEmpty);
    });
  });
}
