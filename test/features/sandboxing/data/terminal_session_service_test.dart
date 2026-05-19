import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFs extends Fake implements WorkspaceFilesystemPort {}

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
}
