import 'dart:convert';
import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart' show workspaceDirPath;
import 'package:cc_server_core/src/fs_confinement.dart';
import 'package:cc_server_core/src/run_log_reader.dart';
import 'package:cc_server_core/src/workspaces/workspace_logo.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A host path a caller names stays inside the directory it is confined to
/// once symlinks are resolved, for writes through a linked parent and for the
/// run viewer's and the logo route's reads.
void main() {
  late Directory tmp;
  late String root;
  late String outside;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('fs_confinement_');
    root = p.join(tmp.path, 'root');
    Directory(root).createSync(recursive: true);
    outside = p.join(tmp.path, 'outside');
    Directory(outside).createSync();
    File(p.join(outside, 'secret.txt')).writeAsStringSync('secret');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  group('confinedRealPath', () {
    test('keeps a path inside the root, existing or not', () {
      File(p.join(root, 'a.txt')).writeAsStringSync('a');
      final real = Directory(root).resolveSymbolicLinksSync();
      expect(
        confinedRealPath(root, p.join(root, 'a.txt')),
        p.join(real, 'a.txt'),
      );
      expect(
        confinedRealPath(root, p.join(root, 'new', 'b.txt')),
        p.join(real, 'new', 'b.txt'),
      );
      expect(confinedRealPath(root, root), real);
    });

    test('refuses traversal', () {
      expect(confinedRealPath(root, p.join(root, '..', 'outside')), isNull);
      expect(confinedRealPath(root, '/'), isNull);
    });

    test('refuses a symlink that leaves the root, for a read and for a '
        'write through it', () {
      Link(p.join(root, 'link')).createSync(outside);
      expect(
        confinedRealPath(root, p.join(root, 'link', 'secret.txt')),
        isNull,
      );
      expect(confinedRealPath(root, p.join(root, 'link', 'new.txt')), isNull);
      Link(p.join(root, 'file-link')).createSync(p.join(outside, 'secret.txt'));
      expect(confinedRealPath(root, p.join(root, 'file-link')), isNull);
    });

    test('refuses a dangling link, which a write would follow out', () {
      Link(p.join(root, 'dangling')).createSync(p.join(outside, 'later.txt'));
      expect(confinedRealPath(root, p.join(root, 'dangling')), isNull);
    });

    test('allows a symlink that stays inside the root', () {
      Directory(p.join(root, 'real')).createSync();
      File(p.join(root, 'real', 'x.txt')).writeAsStringSync('x');
      Link(p.join(root, 'alias')).createSync(p.join(root, 'real'));
      expect(
        confinedRealPath(root, p.join(root, 'alias', 'x.txt')),
        p.join(Directory(root).resolveSymbolicLinksSync(), 'real', 'x.txt'),
      );
    });
  });

  group('RunLogReader', () {
    late String dataDir;
    late RunLogReader reader;

    setUp(() {
      dataDir = p.join(tmp.path, 'data');
      Directory(workspaceDirPath(dataDir, 'ws-1')).createSync(recursive: true);
      Directory(workspaceDirPath(dataDir, 'ws-2')).createSync(recursive: true);
      reader = RunLogReader(dataDir: dataDir);
    });

    String writeLog(String dir, String name) {
      final file = File(p.join(dir, 'runs', name))
        ..createSync(recursive: true)
        ..writeAsStringSync('${jsonEncode({'type': 'start'})}\n');
      return file.path;
    }

    test("reads a run log inside the run's own workspace", () async {
      final log = writeLog(workspaceDirPath(dataDir, 'ws-1'), 'r.ndjson');
      final read = await reader.readRunLogEvents(log, workspaceId: 'ws-1');
      expect(read.events, [
        {'type': 'start'},
      ]);
    });

    test("never opens another workspace's log, the data dir's files, or a "
        'file reached through a link', () async {
      final foreign = writeLog(workspaceDirPath(dataDir, 'ws-2'), 'r.ndjson');
      File(p.join(dataDir, 'secrets.ndjson')).writeAsStringSync('{"k":1}\n');
      Link(
        p.join(workspaceDirPath(dataDir, 'ws-1'), 'runs.ndjson'),
      ).createSync(foreign);
      for (final path in [
        foreign,
        p.join(dataDir, 'secrets.ndjson'),
        p.join(workspaceDirPath(dataDir, 'ws-1'), 'runs.ndjson'),
        p.join(outside, 'secret.txt'),
        'runs/r.ndjson',
      ]) {
        final read = await reader.readRunLogEvents(path, workspaceId: 'ws-1');
        expect(read.events, isEmpty, reason: path);
      }
    });
  });

  group('isWorkspaceLogoPath', () {
    test('is only the logo file the persist ops write', () {
      expect(isWorkspaceLogoPath(root, p.join(root, 'logo.png')), isTrue);
      expect(isWorkspaceLogoPath(root, p.join(root, 'logo')), isTrue);
      for (final path in [
        p.join(root, 'workspace.db'),
        p.join(root, 'logo.db'),
        p.join(root, 'agents', 'logo.png'),
        p.join(outside, 'logo.png'),
        p.join(outside, 'secret.txt'),
      ]) {
        expect(isWorkspaceLogoPath(root, path), isFalse, reason: path);
      }
    });

    test('a logo that is a link out of the workspace is refused', () {
      Link(p.join(root, 'logo.png')).createSync(p.join(outside, 'secret.txt'));
      expect(isWorkspaceLogoPath(root, p.join(root, 'logo.png')), isFalse);
    });
  });
}
