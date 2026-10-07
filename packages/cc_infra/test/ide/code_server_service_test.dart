import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_infra/src/ide/code_server_service.dart';
import 'package:test/test.dart';

void main() {
  group('CodeServerService workspace isolation', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('cc_code_server_test');
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    test('rejects a foreign space/repo with no worktree (no fallback)', () async {
      // Workspace A has a worktree for (wsA, chA, repoA); workspace B does NOT.
      final repo = _FakeIsolatedRepoRepo(
        worktrees: {
          'wsA:chA:repoA': _worktree(
            workspaceId: 'wsA',
            spaceId: 'chA',
            repoId: 'repoA',
          ),
        },
      );
      final service = CodeServerService(
        isolatedRepos: repo,
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );

      // A foreign (workspace/space/repo) yields NO worktree → ensureSession
      // throws loudly rather than falling back to a raw checkout.
      await expectLater(
        service.ensureSession(
          workspaceId: 'wsB',
          spaceId: 'chB',
          repoId: 'repoB',
          deviceId: 'device-b',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('empty repoId resolves the space\'s first worktree', () async {
      // The PR "open editor" / ⌘T path opens a code-server tab without naming a
      // repo (repoId == ''); ensureSession must resolve the space's first
      // provisioned worktree rather than requiring an exact repo id.
      final worktreeDir = Directory('${tmp.path}/wsA-chA-repoA')
        ..createSync(recursive: true);
      addTearDown(() => worktreeDir.deleteSync(recursive: true));
      final repo = _FakeIsolatedRepoRepo(
        worktrees: {
          'wsA:chA:repoA': _worktree(
            workspaceId: 'wsA',
            spaceId: 'chA',
            repoId: 'repoA',
            path: worktreeDir.path,
          ),
        },
      );
      final service = CodeServerService(
        isolatedRepos: repo,
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );

      // Resolves the worktree (no throw); code-server isn't installed in the
      // test env so the session is `unavailable`, but it carries the resolved
      // worktree path — proof the empty repoId matched the space's worktree.
      final session = await service.ensureSession(
        workspaceId: 'wsA',
        spaceId: 'chA',
        repoId: '',
        deviceId: 'device-a',
      );
      expect(session.folderPath, worktreeDir.path);
      expect(session.status, CodeServerStatus.unavailable);
    });

    test('empty repoId with no space worktrees still throws', () async {
      final service = CodeServerService(
        isolatedRepos: _FakeIsolatedRepoRepo(worktrees: const {}),
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );

      await expectLater(
        service.ensureSession(
          workspaceId: 'wsA',
          spaceId: 'chA',
          repoId: '',
          deviceId: 'device-a',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('lookup returns null for an unknown capability', () async {
      final service = CodeServerService(
        isolatedRepos: _FakeIsolatedRepoRepo(worktrees: const {}),
        dataRoot: tmp.path,
      );
      expect(service.lookup('never-minted'), isNull);
    });

    test('closeSession on a non-existent session is a safe no-op', () async {
      final service = CodeServerService(
        isolatedRepos: _FakeIsolatedRepoRepo(worktrees: const {}),
        dataRoot: tmp.path,
      );
      // No throw — idempotent.
      await service.closeSession(workspaceId: 'wsA', sessionId: 'nope');
    });

    test('reportDirty for an unknown session emits nothing', () async {
      final service = CodeServerService(
        isolatedRepos: _FakeIsolatedRepoRepo(worktrees: const {}),
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );
      final events = <CodeServerDirtyEvent>[];
      final sub = service.watchDirtyState('wsA').listen(events.add);
      // Unknown / expired capability → ignored, never throws, never emits.
      service.reportDirty(sessionId: 'nope', absPath: '/x/y.dart', dirty: true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, isEmpty);
      await sub.cancel();
    });

    test('commandStream for an unknown session is empty', () async {
      final service = CodeServerService(
        isolatedRepos: _FakeIsolatedRepoRepo(worktrees: const {}),
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );
      expect(await service.commandStream('nope').isEmpty, isTrue);
    });

    test('saveFile returns false when there is no running session', () async {
      // A worktree resolves, but code-server isn't installed in the test env, so
      // no instance is registered → nothing to relay a save to → false (never
      // throws).
      final worktreeDir = Directory('${tmp.path}/wsA-chA-repoA')
        ..createSync(recursive: true);
      addTearDown(() => worktreeDir.deleteSync(recursive: true));
      final service = CodeServerService(
        isolatedRepos: _FakeIsolatedRepoRepo(
          worktrees: {
            'wsA:chA:repoA': _worktree(
              workspaceId: 'wsA',
              spaceId: 'chA',
              repoId: 'repoA',
              path: worktreeDir.path,
            ),
          },
        ),
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );
      final saved = await service.saveFile(
        workspaceId: 'wsA',
        spaceId: 'chA',
        repoId: 'repoA',
        path: 'lib/main.dart',
      );
      expect(saved, isFalse);
    });

    test('saveFile returns false for an unresolvable worktree', () async {
      final service = CodeServerService(
        isolatedRepos: _FakeIsolatedRepoRepo(worktrees: const {}),
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );
      final saved = await service.saveFile(
        workspaceId: 'wsA',
        spaceId: 'chNope',
        repoId: 'repoNope',
        path: 'lib/main.dart',
      );
      expect(saved, isFalse);
    });

    group(
      'with a running instance',
      () {
        late Directory worktreeDir;
        late CodeServerService service;
        late String sessionId;

        setUp(() async {
          // A stand-in `code-server` in the managed install dir: it accepts the
          // bridge install, then prints the startup banner and idles, which is
          // all the service needs to register a running instance.
          final os = Platform.isMacOS ? 'darwin' : 'linux';
          final uname = Process.runSync('uname', ['-m']).stdout as String;
          final arch = uname.contains('arm64') || uname.contains('aarch64')
              ? 'arm64'
              : 'x64';
          final bin = File('${tmp.path}/code-server/$os-$arch/bin/code-server')
            ..createSync(recursive: true)
            ..writeAsStringSync(
              '#!/bin/sh\n'
              'case "\$*" in *--install-extension*) exit 0;; esac\n'
              'echo "HTTP server listening on http://127.0.0.1:45678/"\n'
              'exec sleep 60\n',
            );
          Process.runSync('chmod', ['755', bin.path]);
          for (final ext in codeServerCuratedExtensions) {
            Directory(
              '${tmp.path}/code-server/extensions/'
              '${ext.publisher}.${ext.name}-${ext.version}',
            ).createSync(recursive: true);
          }
          worktreeDir = Directory('${tmp.path}/wsA-chA-repoA')
            ..createSync(recursive: true);
          service = CodeServerService(
            isolatedRepos: _FakeIsolatedRepoRepo(
              worktrees: {
                'wsA:chA:repoA': _worktree(
                  workspaceId: 'wsA',
                  spaceId: 'chA',
                  repoId: 'repoA',
                  path: worktreeDir.path,
                ),
              },
            ),
            dataRoot: tmp.path,
            attemptManagedDownload: false,
          );
          final session = await service.ensureSession(
            workspaceId: 'wsA',
            spaceId: 'chA',
            repoId: 'repoA',
            deviceId: 'device-a',
          );
          expect(session.status, CodeServerStatus.ready);
          sessionId = session.sessionId;
        });

        tearDown(() => service.disposeAll());

        test('openFile addresses one window with the absolute path', () async {
          final commands = <Map<String, Object?>>[];
          final sub = service.commandStream(sessionId).listen(commands.add);
          addTearDown(sub.cancel);

          final sent = await service.openFile(
            workspaceId: 'wsA',
            spaceId: 'chA',
            repoId: 'repoA',
            windowId: 'w1',
            path: 'lib/main.dart',
            line: 12,
          );
          await Future<void>.delayed(Duration.zero);

          expect(sent, isTrue);
          expect(commands, [
            {
              'cmd': 'open',
              'window': 'w1',
              'path': '${worktreeDir.path}/lib/main.dart',
              'line': 12,
            },
          ]);
        });

        test(
          'closeFile broadcasts the close, with revert when asked',
          () async {
            final commands = <Map<String, Object?>>[];
            final sub = service.commandStream(sessionId).listen(commands.add);
            addTearDown(sub.cancel);

            await service.closeFile(
              workspaceId: 'wsA',
              spaceId: 'chA',
              repoId: 'repoA',
              path: 'lib/main.dart',
              revert: true,
            );
            await Future<void>.delayed(Duration.zero);

            expect(commands, [
              {
                'cmd': 'close',
                'path': '${worktreeDir.path}/lib/main.dart',
                'revert': true,
              },
            ]);
          },
        );

        test('a path escaping the worktree is refused', () async {
          final commands = <Map<String, Object?>>[];
          final sub = service.commandStream(sessionId).listen(commands.add);
          addTearDown(sub.cancel);

          expect(
            await service.openFile(
              workspaceId: 'wsA',
              spaceId: 'chA',
              repoId: 'repoA',
              windowId: 'w1',
              path: '../outside.dart',
            ),
            isFalse,
          );
          expect(
            await service.closeFile(
              workspaceId: 'wsA',
              spaceId: 'chA',
              repoId: 'repoA',
              path: '../outside.dart',
            ),
            isFalse,
          );
          await Future<void>.delayed(Duration.zero);
          expect(commands, isEmpty);
        });

        test('another workspace cannot reach the instance', () async {
          expect(
            await service.openFile(
              workspaceId: 'wsB',
              spaceId: 'chA',
              repoId: 'repoA',
              windowId: 'w1',
              path: 'lib/main.dart',
            ),
            isFalse,
          );
        });
      },
      skip: Platform.isWindows
          ? 'the code-server stand-in is a POSIX shell script'
          : null,
    );

    test(
      'lookup rejects an unknown capability even after a session was minted elsewhere',
      () async {
        // code-server is not installed in the test env, so ensureSession returns
        // an `unavailable` session WITHOUT entering the proxy table (port 0 →
        // nothing to proxy). A later lookup of that capability must therefore be
        // null: the proxy must never authorize a session with no bound port.
        // The worktree directory must exist on disk — ensureSession validates it
        // (a GC'd worktree throws an actionable StateError before spawning).
        final worktreeDir = Directory('${tmp.path}/wsA-chA-repoA')
          ..createSync(recursive: true);
        addTearDown(() => worktreeDir.deleteSync(recursive: true));
        final repo = _FakeIsolatedRepoRepo(
          worktrees: {
            'wsA:chA:repoA': _worktree(
              workspaceId: 'wsA',
              spaceId: 'chA',
              repoId: 'repoA',
              path: worktreeDir.path,
            ),
          },
        );
        final service = CodeServerService(
          isolatedRepos: repo,
          dataRoot: tmp.path,
          attemptManagedDownload: false,
        );
        final session = await service.ensureSession(
          workspaceId: 'wsA',
          spaceId: 'chA',
          repoId: 'repoA',
          deviceId: 'device-a',
        );
        expect(session.status, CodeServerStatus.unavailable);
        // An unavailable session is NOT live in the proxy table.
        expect(service.lookup(session.sessionId), isNull);
      },
    );
  });
}

IsolatedRepo _worktree({
  required String workspaceId,
  required String spaceId,
  required String repoId,
  String? path,
}) {
  return IsolatedRepo(
    id: '$workspaceId-$spaceId-$repoId',
    workspaceId: workspaceId,
    spaceId: spaceId,
    repoId: repoId,
    path: path ?? '/tmp/fake-$workspaceId-$spaceId-$repoId',
    branch: 'main',
    backend: RepoIsolationBackend.rift,
    sourcePath: '/tmp/source-$repoId',
    createdAt: DateTime.utc(2024, 1, 1),
  );
}

/// Minimal fake: resolves a worktree only for a known `(ws, space, repo)`.
class _FakeIsolatedRepoRepo implements IsolatedRepoRepository {
  _FakeIsolatedRepoRepo({required this.worktrees});

  final Map<String, IsolatedRepo> worktrees;

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) => Future.value(worktrees['$workspaceId:$spaceId:$repoId']);

  @override
  Future<List<IsolatedRepo>> forSpace(String workspaceId, String spaceId) =>
      Future.value([
        for (final e in worktrees.entries)
          if (e.key.startsWith('$workspaceId:$spaceId:')) e.value,
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
