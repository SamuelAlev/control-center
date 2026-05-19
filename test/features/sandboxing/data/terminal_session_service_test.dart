import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFs extends Fake implements WorkspaceFilesystemPort {}

/// A filesystem whose workspace dir is a REAL directory, so the guest-root
/// confinement can be exercised against actual paths.
class _RootedFs extends Fake implements WorkspaceFilesystemPort {
  _RootedFs(this.root);

  final String root;

  @override
  Future<String> workspaceDir(String workspaceId) async => root;

  @override
  Future<void> ensureWorkspaceDirs(String workspaceId) async {}

  @override
  Future<String> ensureSpaceDir(
    String workspaceId,
    String conversationId,
  ) async => root;
}

/// Rejection contract of [TerminalSessionService]: a session id the service does
/// not hold must fail as a TYPED domain exception, because the RPC layer
/// classifies those into stable error codes and the client's retry policy keys
/// off the code.
///
/// No PTY is spawned here — every case rejects before touching the sandbox or
/// the filesystem, which is exactly the path a stale client argument takes.
void main() {
  TerminalSessionService service() => TerminalSessionService(
    manager: SandboxManager.test(),
    filesystem: _FakeFs(),
  );

  group('TerminalSessionService rejections', () {
    test('output on an unknown session throws NotFoundException', () {
      // A bare StateError here mapped to the generic `internalError`, which the
      // client reads as TRANSIENT: a client still holding a session id from
      // before a cc_server restart then resubscribed against it at round-trip
      // speed. NotFoundException maps to `notFound` — unrecoverable — so the
      // client stops after one attempt.
      expect(
        () => service().output(workspaceId: 'ws-1', sessionId: 'tty1-gone'),
        throwsA(
          isA<NotFoundException>().having(
            (e) => e.message,
            'message',
            contains('tty1-gone'),
          ),
        ),
      );
    });

    test('titles on an unknown session throws NotFoundException', () {
      expect(
        () => service().titles(workspaceId: 'ws-1', sessionId: 'tty1-gone'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('resolveTerminalBackend', () {
    test('an unknown name is refused, never answered with the default', () {
      // Silently resolving a typo to the host default is the same silent
      // downgrade an explicit `microvm` on a rig-less host already refuses.
      expect(
        () => resolveTerminalBackend(
          requested: 'micovm',
          defaultBackend: SandboxBackend.native,
          hasVmShell: true,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            contains('micovm'),
          ),
        ),
      );
    });

    test('an EXPLICIT microvm on a rig-less host stays microvm', () {
      // So the PTY start fails loudly rather than opening a host shell wearing
      // an "Enclosed VM" badge.
      expect(
        resolveTerminalBackend(
          requested: 'microvm',
          defaultBackend: SandboxBackend.native,
          hasVmShell: false,
        ),
        SandboxBackend.microvm,
      );
    });

    test('an UNSPECIFIED microvm default steps down on a rig-less host', () {
      // The only degradation in the resolver, and the one latent path that
      // would weaken silently if a microvm default were ever wired.
      expect(
        resolveTerminalBackend(
          requested: null,
          defaultBackend: SandboxBackend.microvm,
          hasVmShell: false,
        ),
        SandboxBackend.native,
      );
    });

    test('an UNSPECIFIED microvm default is honoured when a rig service is '
        'wired', () {
      expect(
        resolveTerminalBackend(
          requested: null,
          defaultBackend: SandboxBackend.microvm,
          hasVmShell: true,
        ),
        SandboxBackend.microvm,
      );
    });
  });

  group('confineToGuestRoots', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('cc-term-confine');
    });

    tearDown(() {
      if (tmp.existsSync()) {
        tmp.deleteSync(recursive: true);
      }
    });

    test('a directory inside a root resolves', () {
      final root = Directory('${tmp.path}/ws')..createSync();
      final inside = Directory('${root.path}/conv/repo')
        ..createSync(recursive: true);
      expect(
        confineToGuestRoots(path: inside.path, roots: [root.path]),
        inside.resolveSymbolicLinksSync(),
      );
    });

    test('the root itself resolves', () {
      final root = Directory('${tmp.path}/ws')..createSync();
      expect(
        confineToGuestRoots(path: root.path, roots: [root.path]),
        root.resolveSymbolicLinksSync(),
      );
    });

    test('a directory outside every root is refused', () {
      final root = Directory('${tmp.path}/ws')..createSync();
      final outside = Directory('${tmp.path}/secrets')..createSync();
      expect(
        confineToGuestRoots(path: outside.path, roots: [root.path]),
        isNull,
      );
    });

    test('a symlink inside a root that points OUTSIDE it is refused', () {
      // The whole reason both sides are resolved: a path can sit inside an
      // allowed root by string and outside it by content, and it is the
      // content that gets tar'd into the guest.
      final root = Directory('${tmp.path}/ws')..createSync();
      final outside = Directory('${tmp.path}/dot-ssh')..createSync();
      final link = Link('${root.path}/escape')..createSync(outside.path);
      expect(confineToGuestRoots(path: link.path, roots: [root.path]), isNull);
    });

    test('a non-existent path is refused', () {
      final root = Directory('${tmp.path}/ws')..createSync();
      expect(
        confineToGuestRoots(path: '${root.path}/nope', roots: [root.path]),
        isNull,
      );
    });

    test('an empty root list confines everything', () {
      final dir = Directory('${tmp.path}/anywhere')..createSync();
      expect(confineToGuestRoots(path: dir.path, roots: const []), isNull);
    });

    test('a root that does not exist neither widens nor narrows', () {
      final root = Directory('${tmp.path}/ws')..createSync();
      final inside = Directory('${root.path}/x')..createSync();
      expect(
        confineToGuestRoots(
          path: inside.path,
          roots: ['${tmp.path}/gone', root.path],
        ),
        inside.resolveSymbolicLinksSync(),
      );
    });
  });

  group('microvm terminal cwd confinement', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('cc-term-spawn');
    });

    tearDown(() {
      if (tmp.existsSync()) {
        tmp.deleteSync(recursive: true);
      }
    });

    test('a cwd outside the workspace roots never reaches the rig', () async {
      // The bypass this guard closes: `terminal.spawn` forwarded `cwd`
      // verbatim into `RigSpec.exec(worktreePath: …)`, which tar-syncs the
      // directory into a VM the caller drives. `rig.open` refuses exactly this
      // by building its spec from a closed field set; the terminal path
      // reached the same primitive for the same principal class.
      final root = Directory('${tmp.path}/ws')..createSync();
      final secrets = Directory('${tmp.path}/dot-ssh')..createSync();
      var resolverCalls = 0;

      final service = TerminalSessionService(
        manager: SandboxManager.test(),
        filesystem: _RootedFs(root.path),
        vmShell:
            ({
              required String workspaceId,
              String? conversationId,
              String? worktreePath,
              String? actingUserId,
            }) async {
              resolverCalls++;
              return null;
            },
      );

      await expectLater(
        service.spawn(
          workspaceId: 'ws-1',
          rows: 24,
          cols: 80,
          spaceId: 'ch-1',
          cwd: secrets.path,
          backend: 'microvm',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('confined'),
          ),
        ),
      );
      expect(
        resolverCalls,
        0,
        reason: 'the rig resolver must not be reached at all',
      );
    });

    test('a cwd inside the workspace root reaches the rig resolver', () async {
      final root = Directory('${tmp.path}/ws')..createSync();
      final inside = Directory('${root.path}/conv/repo')
        ..createSync(recursive: true);
      String? seen;

      final service = TerminalSessionService(
        manager: SandboxManager.test(),
        filesystem: _RootedFs(root.path),
        vmShell:
            ({
              required String workspaceId,
              String? conversationId,
              String? worktreePath,
              String? actingUserId,
            }) async {
              seen = worktreePath;
              return null;
            },
      );

      // No rig comes back, so the spawn still fails — but AFTER the resolver
      // saw the confined path, which is what this pins.
      await expectLater(
        service.spawn(
          workspaceId: 'ws-1',
          rows: 24,
          cols: 80,
          spaceId: 'ch-1',
          cwd: inside.path,
          backend: 'microvm',
        ),
        throwsA(isA<StateError>()),
      );
      expect(seen, inside.resolveSymbolicLinksSync());
    });

    test('a cwd inside a REGISTERED repo checkout is allowed', () async {
      final root = Directory('${tmp.path}/ws')..createSync();
      final repo = Directory('${tmp.path}/checkouts/app')
        ..createSync(recursive: true);
      String? seen;

      final service = TerminalSessionService(
        manager: SandboxManager.test(),
        filesystem: _RootedFs(root.path),
        vmShell:
            ({
              required String workspaceId,
              String? conversationId,
              String? worktreePath,
              String? actingUserId,
            }) async {
              seen = worktreePath;
              return null;
            },
        guestRoots: (_) async => [repo.path],
      );

      await expectLater(
        service.spawn(
          workspaceId: 'ws-1',
          rows: 24,
          cols: 80,
          spaceId: 'ch-1',
          cwd: repo.path,
          backend: 'microvm',
        ),
        throwsA(isA<StateError>()),
      );
      expect(seen, repo.resolveSymbolicLinksSync());
    });
  });
}
