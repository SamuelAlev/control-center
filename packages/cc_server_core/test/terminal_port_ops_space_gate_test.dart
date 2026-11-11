import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_ports_port.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/terminal_port_ops.dart';
import 'package:test/test.dart';

/// A space's terminal is the space's machine: its forwarded ports change only
/// for a caller the space gate admits.
void main() {
  RepoOpContext ctx(String userId) => RepoOpContext(
    args: const {'session_id': 'tty-1', 'space_id': 's-1', 'guest_port': 3000},
    workspaceId: 'ws1',
    deviceId: 'dev',
    userId: userId,
  );

  test('the space gate runs before any port changes', () async {
    final ports = _Ports();
    final op = buildTerminalPortOps(
      rigPorts: ports,
      terminals: const _Terminals({}),
      requireSpace: (ctx) async {
        if (ctx.userId != 'reader') {
          throw const AuthException('This space is not yours to read.');
        }
      },
    ).singleWhere((op) => op.name == 'terminal.addPort');

    await expectLater(
      op.handler(ctx('stranger')),
      throwsA(isA<AuthException>()),
    );
    expect(ports.added, isEmpty);

    expect(await op.handler(ctx('reader')), {'ok': true});
    expect(ports.added, [('tty-1', 's-1', 3000)]);
  });

  group('a terminal session a person opened', () {
    // Both callers are members the space admits; only `wanda` opened tty-1.
    const terminals = _Terminals({'tty-1': 'wanda'});
    late _Ports ports;
    late List<RepoOp> ops;
    setUp(() {
      ports = _Ports();
      ops = buildTerminalPortOps(
        rigPorts: ports,
        terminals: terminals,
        requireSpace: (_) async {},
      );
    });
    RepoOp op(String name) => ops.singleWhere((op) => op.name == name);

    test("answers anyone else's port ops exactly as a missing session "
        'does', () async {
      for (final name in [
        'terminal.setPortsAutoForward',
        'terminal.addPort',
        'terminal.removePort',
        'terminal.setPortLan',
        'terminal.setPortDomain',
      ]) {
        expect(
          await op(name).handler(
            const RepoOpContext(
              args: {
                'session_id': 'tty-1',
                'space_id': 's-1',
                'guest_port': 3000,
                'enabled': true,
                'exposed': true,
                'domain': 'web.test',
              },
              workspaceId: 'ws1',
              deviceId: 'dev',
              userId: 'fran',
            ),
          ),
          {'ok': false},
          reason: name,
        );
      }
      // Nothing reached the port service for the session.
      expect(ports.touched, isEmpty);

      // The same answer a session that does not exist gets.
      const missing = RepoOpContext(
        args: {'session_id': 'tty-none', 'space_id': 's-1', 'guest_port': 3000},
        workspaceId: 'ws1',
        deviceId: 'dev',
        userId: 'fran',
      );
      expect(await op('terminal.addPort').handler(missing), {'ok': false});
    });

    test('lets the person who opened it change its ports', () async {
      expect(await op('terminal.addPort').handler(ctx('wanda')), {'ok': true});
      expect(ports.added, [('tty-1', 's-1', 3000)]);
    });

    test('an owned session (no opener) stays with the space', () {
      expect(isOthersTerminal(terminals, 'tty-owned', 'fran'), isFalse);
      expect(isOthersTerminal(null, 'tty-1', 'fran'), isFalse);
      expect(isOthersTerminal(terminals, 'tty-1', 'fran'), isTrue);
      expect(isOthersTerminal(terminals, 'tty-1', 'wanda'), isFalse);
    });
  });
}

/// Who opened each person session; owned sessions and unknown ids have none.
class _Terminals implements TerminalSessionPort {
  const _Terminals(this.openers);
  final Map<String, String> openers;

  @override
  String? openerOf(String sessionId) => openers[sessionId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A port service that knows only [knownSessions], answering `false` for any
/// other id as the real one does. [touched] records every terminal call.
class _Ports implements RigPortsPort {
  final knownSessions = {'tty-1'};
  final added = <(String, String, int)>[];
  final touched = <String>[];

  @override
  Future<bool> addTerminalPortForward(
    String workspaceId,
    String sessionId, {
    required String spaceId,
    required int guestPort,
    int? hostPort,
  }) async {
    touched.add(sessionId);
    if (!knownSessions.contains(sessionId)) {
      return false;
    }
    added.add((sessionId, spaceId, guestPort));
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    touched.add('${invocation.memberName}');
    return Future.value(false);
  }
}
