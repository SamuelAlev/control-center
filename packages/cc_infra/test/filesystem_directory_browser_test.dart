import 'dart:io';

import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FilesystemDirectoryBrowser', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('cc_dir_browser_test');
      // A plain folder, a git checkout (`.git` dir), a linked worktree
      // (`.git` file), and a hidden folder.
      Directory(p.join(root.path, 'plain')).createSync();
      final repo = Directory(p.join(root.path, 'my-app'))..createSync();
      Directory(p.join(repo.path, '.git')).createSync();
      final worktree = Directory(p.join(root.path, 'worktree'))..createSync();
      File(p.join(worktree.path, '.git')).writeAsStringSync('gitdir: ...');
      Directory(p.join(root.path, '.hidden')).createSync();
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('lists subfolders sorted, flags git repos, hides dot-folders',
        () async {
      final browser =
          FilesystemDirectoryBrowser(allowedRoots: [root.path]);

      final listing = await browser.browse();

      expect(listing.path, p.normalize(root.path));
      expect(listing.parent, isNull, reason: 'at a root, cannot go up');
      expect(listing.isGitRepo, isFalse);
      expect(listing.roots, [p.normalize(root.path)]);

      final names = listing.entries.map((e) => e.name).toList();
      expect(names, ['my-app', 'plain', 'worktree']);
      expect(names, isNot(contains('.hidden')));

      final byName = {for (final e in listing.entries) e.name: e};
      expect(byName['my-app']!.isGitRepo, isTrue, reason: '.git directory');
      expect(byName['worktree']!.isGitRepo, isTrue, reason: '.git file');
      expect(byName['plain']!.isGitRepo, isFalse);
    });

    test('navigating into a subfolder exposes the parent', () async {
      final browser =
          FilesystemDirectoryBrowser(allowedRoots: [root.path]);

      final listing =
          await browser.browse(path: p.join(root.path, 'my-app'));

      expect(listing.path, p.normalize(p.join(root.path, 'my-app')));
      expect(listing.parent, p.normalize(root.path));
      expect(listing.isGitRepo, isTrue);
    });

    test('refuses a path outside the allowed roots', () async {
      final browser =
          FilesystemDirectoryBrowser(allowedRoots: [root.path]);

      expect(
        () => browser.browse(path: Directory.systemTemp.path),
        throwsA(isA<DirectoryAccessException>()),
      );
    });

    test('refuses a `..` escape above a root', () async {
      final browser =
          FilesystemDirectoryBrowser(allowedRoots: [root.path]);

      expect(
        () => browser.browse(path: p.join(root.path, 'my-app', '..', '..')),
        throwsA(isA<DirectoryAccessException>()),
      );
    });

    test('refuses a non-existent folder within a root', () async {
      final browser =
          FilesystemDirectoryBrowser(allowedRoots: [root.path]);

      expect(
        () => browser.browse(path: p.join(root.path, 'does-not-exist')),
        throwsA(isA<DirectoryAccessException>()),
      );
    });

    test('refuses everything when no roots are configured', () async {
      final browser = FilesystemDirectoryBrowser(allowedRoots: const []);

      expect(
        () => browser.browse(path: root.path),
        throwsA(isA<DirectoryAccessException>()),
      );
    });

    test('forHome roots the browser at a single home directory', () {
      final browser = FilesystemDirectoryBrowser.forHome();
      // No exception constructing it; the home root is enforced like any other.
      expect(browser, isA<DirectoryBrowserPort>());
    });
  });
}
