import 'dart:io';

import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [resolveInsideWorkspace] — the jail guard shared by the read/
/// write/edit/search/find tools. Proves: relative resolution, absolute inputs
/// accepted only when inside the workspace, traversal (`..`) refusal, and
/// symlink-escape refusal.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('ws_paths_'));
  tearDown(() => root.deleteSync(recursive: true));

  group('resolveInsideWorkspace — relative inputs', () {
    test('resolves a simple relative path inside the workspace', () {
      final resolved = resolveInsideWorkspace(root.path, 'a/b.txt');
      expect(resolved, p.normalize(p.join(root.path, 'a/b.txt')));
    });

    test('normalizes redundant separators / dots', () {
      final resolved = resolveInsideWorkspace(root.path, 'a/./b//c.txt');
      expect(resolved, p.normalize(p.join(root.path, 'a/b/c.txt')));
    });

    test("'.' resolves to the workspace root itself", () {
      expect(resolveInsideWorkspace(root.path, '.'), root.path);
    });
  });

  group('resolveInsideWorkspace — absolute inputs', () {
    test('accepts an absolute path already inside the workspace', () {
      final abs = p.join(root.path, 'src', 'main.dart');
      expect(resolveInsideWorkspace(root.path, abs), p.normalize(abs));
    });

    test('rejects an absolute path outside the workspace', () {
      expect(resolveInsideWorkspace(root.path, '/etc/passwd'), isNull);
      expect(resolveInsideWorkspace(root.path, '/usr/local/bin'), isNull);
    });
  });

  group('resolveInsideWorkspace — traversal', () {
    test("rejects '..' escape", () {
      expect(resolveInsideWorkspace(root.path, '../escape.txt'), isNull);
      expect(resolveInsideWorkspace(root.path, 'a/../../escape.txt'), isNull);
    });

    test('a path that escapes and re-enters still resolves if inside', () {
      // a/../b.txt → b.txt (inside workspace).
      final resolved = resolveInsideWorkspace(root.path, 'a/../b.txt');
      expect(resolved, p.join(root.path, 'b.txt'));
    });
  });

  group('resolveInsideWorkspace — symlink hardening', () {
    test('refuses a symlink that escapes the workspace', () {
      // Create an outside target + a symlink inside pointing to it.
      final outside = Directory.systemTemp.createTempSync('ws_paths_out_');
      addTearDown(() => outside.deleteSync(recursive: true));
      final target = File(p.join(outside.path, 'secret.txt'))
        ..writeAsStringSync('x');
      final link = Link(p.join(root.path, 'escape.link'));
      link.createSync(target.path);

      expect(resolveInsideWorkspace(root.path, 'escape.link'), isNull);
    });

    test('accepts a symlink whose target is inside the workspace', () {
      final real = File(p.join(root.path, 'real.txt'))..writeAsStringSync('x');
      final link = Link(p.join(root.path, 'inner.link'));
      link.createSync(real.path);

      final resolved = resolveInsideWorkspace(root.path, 'inner.link');
      // The returned path is the requested path (or its real target) and must
      // be within root.
      expect(resolved, isNotNull);
      expect(
        p.isWithin(root.path, resolved!) || p.equals(resolved, root.path),
        isTrue,
      );
    });
  });

  group('resolveInsideWorkspace — shared roots (conversation repos/)', () {
    // Mirrors the provisioner layout: the cwd is a per-agent overlay
    // (<conv>/agents/<slug>) whose `repos` symlink points at the shared
    // sibling worktrees dir (<conv>/repos).
    late Directory conv;
    late Directory overlay;
    late Directory sharedRepos;

    setUp(() {
      conv = Directory(p.join(root.path, 'conversations', 'conv-1'))
        ..createSync(recursive: true);
      overlay = Directory(p.join(conv.path, 'agents', 'dev'))
        ..createSync(recursive: true);
      sharedRepos = Directory(p.join(conv.path, 'repos'))
        ..createSync(recursive: true);
      Directory(p.join(sharedRepos.path, 'app')).createSync();
      File(p.join(sharedRepos.path, 'app', 'main.dart')).writeAsStringSync('x');
      Link(p.join(overlay.path, 'repos')).createSync('../../repos');
    });

    test('accepts the shared root by its real absolute path', () {
      final abs = p.join(sharedRepos.path, 'app', 'main.dart');
      final resolved = resolveInsideWorkspace(
        overlay.path,
        abs,
        sharedRoots: [sharedRepos.path],
      );
      expect(resolved, p.normalize(abs));
    });

    test('without sharedRoots the same real path is refused (regression)', () {
      final abs = p.join(sharedRepos.path, 'app', 'main.dart');
      expect(resolveInsideWorkspace(overlay.path, abs), isNull);
    });

    test('accepts the overlay `repos` symlink itself', () {
      final resolved = resolveInsideWorkspace(
        overlay.path,
        'repos',
        sharedRoots: [sharedRepos.path],
      );
      expect(resolved, isNotNull);
    });

    test('accepts relative paths through the `repos` symlink', () {
      final resolved = resolveInsideWorkspace(
        overlay.path,
        'repos/app/main.dart',
        sharedRoots: [sharedRepos.path],
      );
      expect(resolved, isNotNull);
    });

    test('still refuses escapes outside cwd + shared roots', () {
      expect(
        resolveInsideWorkspace(
          overlay.path,
          '/etc/passwd',
          sharedRoots: [sharedRepos.path],
        ),
        isNull,
      );
      // A sibling agent overlay is NOT covered by the shared root.
      final sibling = Directory(p.join(conv.path, 'agents', 'other'))
        ..createSync(recursive: true);
      expect(
        resolveInsideWorkspace(
          overlay.path,
          p.join(sibling.path, '.mcp.json'),
          sharedRoots: [sharedRepos.path],
        ),
        isNull,
      );
    });

    test('still refuses a symlink escaping cwd + shared roots', () {
      final outside = Directory.systemTemp.createTempSync('ws_paths_out2_');
      addTearDown(() => outside.deleteSync(recursive: true));
      Link(p.join(overlay.path, 'sneaky')).createSync(outside.path);
      expect(
        resolveInsideWorkspace(
          overlay.path,
          'sneaky',
          sharedRoots: [sharedRepos.path],
        ),
        isNull,
      );
    });
  });

  group('listWorkspaceTree', () {
    test('expands a trusted direct-child symlink into the shared root', () {
      final conv = Directory(p.join(root.path, 'c'))..createSync();
      final overlay = Directory(p.join(conv.path, 'agents', 'dev'))
        ..createSync(recursive: true);
      final shared = Directory(p.join(conv.path, 'repos'))..createSync();
      File(p.join(shared.path, 'a.dart')).writeAsStringSync('x');
      Link(p.join(overlay.path, 'repos')).createSync('../../repos');
      File(p.join(overlay.path, 'notes.md')).writeAsStringSync('n');

      final entities = listWorkspaceTree(
        overlay.path,
        workspaceRoot: overlay.path,
        sharedRoots: [shared.path],
      );
      final paths = entities.map((e) => e.path).toList();
      expect(paths, contains(p.join(overlay.path, 'notes.md')));
      // The repo file is reachable via the symlinked prefix.
      expect(paths, contains(p.join(overlay.path, 'repos', 'a.dart')));
    });

    test('does not expand an untrusted symlink (target outside roots)', () {
      final outside = Directory.systemTemp.createTempSync('ws_tree_out_');
      addTearDown(() => outside.deleteSync(recursive: true));
      File(p.join(outside.path, 'secret.txt')).writeAsStringSync('s');
      final cwd = Directory(p.join(root.path, 'cwd'))..createSync();
      Link(p.join(cwd.path, 'leak')).createSync(outside.path);

      final entities = listWorkspaceTree(cwd.path, workspaceRoot: cwd.path);
      expect(
        entities.map((e) => e.path),
        isNot(contains(p.join(cwd.path, 'leak', 'secret.txt'))),
      );
    });
  });

  group('outsideWorkspaceMessage', () {
    test('names the accessible roots and steers to repos/ when shared', () {
      final message = outsideWorkspaceMessage(
        'read',
        '/original/checkout',
        workspaceRoot: '/conv/agents/dev',
        sharedRoots: ['/conv/repos'],
      );
      expect(message, contains('/conv/agents/dev'));
      expect(message, contains('/conv/repos'));
      expect(message, contains('never operate on an original checkout'));
    });

    test('omits the repos/ hint when there is no shared root', () {
      final message = outsideWorkspaceMessage(
        'write',
        '/x',
        workspaceRoot: '/w',
      );
      expect(message, isNot(contains('repos/')));
    });
  });
}
