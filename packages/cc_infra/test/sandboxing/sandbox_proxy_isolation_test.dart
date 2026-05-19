@TestOn('mac-os')
library;

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// Egress rules must belong to ONE session.
///
/// They used to be process-wide: `wrap()` rewrote the shared HTTP/SOCKS proxy
/// config on every spawn, so a session with a restricted allow-list shared its
/// proxy with whatever wrapped next — after an unrestricted spawn, the
/// restricted agent's traffic was validated against `allowAll`, silently
/// voiding the per-capability egress gate. The old code acknowledged the race
/// and argued sessions serialize ("the chat UI only runs one at a time per
/// conversation"), which is not true of a server dispatching concurrent runs
/// across workspaces.
///
/// macOS-only: the Linux branch of `wrap` spawns `socat` bridges.
void main() {
  SandboxConfig configFor(String sessionId, NetworkConfig network) =>
      SandboxConfig(
        sessionId: sessionId,
        network: network,
        filesystem: const FilesystemConfig(),
      );

  const restrictedA = NetworkConfig(
    allowAll: false,
    allowedDomains: ['api.example.com'],
  );
  const restrictedB = NetworkConfig(
    allowAll: false,
    allowedDomains: ['other.example.com'],
  );

  test(
    'concurrent sessions get their own proxies on their own ports',
    () async {
      final manager = SandboxManager();
      addTearDown(manager.reset);

      await manager.wrap(
        config: configFor('sess-a', restrictedA),
        argv: ['true'],
      );
      await manager.wrap(
        config: configFor('sess-b', restrictedB),
        argv: ['true'],
      );

      final a = manager.proxiesForSession('sess-a');
      final b = manager.proxiesForSession('sess-b');

      expect(a.http, isNotNull);
      expect(b.http, isNotNull);
      expect(identical(a.http, b.http), isFalse);
      expect(identical(a.socks, b.socks), isFalse);
      expect(a.http!.port, isNot(b.http!.port));
      expect(a.socks!.port, isNot(b.socks!.port));
    },
  );

  test('an unrestricted spawn cannot relax a restricted session', () async {
    final manager = SandboxManager();
    addTearDown(manager.reset);

    await manager.wrap(
      config: configFor('sess-a', restrictedA),
      argv: ['true'],
    );
    final restrictedProxy = manager.proxiesForSession('sess-a').http!;
    final portBefore = restrictedProxy.port;

    // The exact interleaving that used to void the gate.
    await manager.wrap(
      config: configFor('sess-open', const NetworkConfig()),
      argv: ['true'],
    );

    // The restricted session still owns the same proxy, and the unrestricted
    // one was given none at all (it needs no proxy env).
    expect(
      identical(manager.proxiesForSession('sess-a').http, restrictedProxy),
      isTrue,
    );
    expect(manager.proxiesForSession('sess-a').http!.port, portBefore);
    expect(manager.proxiesForSession('sess-open').http, isNull);
  });

  test('disposing a session releases only its own proxies', () async {
    final manager = SandboxManager();
    addTearDown(manager.reset);

    await manager.wrap(
      config: configFor('sess-a', restrictedA),
      argv: ['true'],
    );
    await manager.wrap(
      config: configFor('sess-b', restrictedB),
      argv: ['true'],
    );
    final bPort = manager.proxiesForSession('sess-b').http!.port;

    await manager.disposeSession('sess-a');

    expect(manager.proxiesForSession('sess-a').http, isNull);
    expect(manager.proxiesForSession('sess-b').http?.port, bPort);
  });
}
