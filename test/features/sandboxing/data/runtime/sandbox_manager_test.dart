import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_infra/src/sandboxing/http_proxy.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/socks_proxy.dart';
import 'package:cc_infra/src/sandboxing/violation_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Manual fakes — avoid Mockito's `when()` stubbing context that leaks
// between tests when the same test file mixes stubbed and unstubbed mocks.
// ---------------------------------------------------------------------------

class FakeHttpProxy implements SandboxHttpProxy {
  int _closeCallCount = 0;
  int get closeCallCount => _closeCallCount;
  NetworkConfig? lastNetworkConfig;
  String? lastParentProxy;

  @override
  int get port => 9999;

  @override
  Future<void> close() async {
    _closeCallCount++;
  }

  @override
  void updateConfig({required NetworkConfig network, String? parentProxy}) {
    lastNetworkConfig = network;
    lastParentProxy = parentProxy;
  }
}

class FakeSocksProxy implements SandboxSocksProxy {
  int _closeCallCount = 0;
  int get closeCallCount => _closeCallCount;
  NetworkConfig? lastNetworkConfig;

  @override
  int get port => 8888;

  @override
  Future<void> close() async {
    _closeCallCount++;
  }

  @override
  void updateConfig({required NetworkConfig network}) {
    lastNetworkConfig = network;
  }
}

class FakeViolationMonitor implements SandboxViolationMonitor {
  int _closeCallCount = 0;
  int get closeCallCount => _closeCallCount;

  final StreamController<SandboxViolation> _streamController =
      StreamController<SandboxViolation>.broadcast();

  @override
  Stream<SandboxViolation> get stream => _streamController.stream;

  @override
  Future<void> close() async {
    _closeCallCount++;
    await _streamController.close();
  }
}

/// Creates a [SandboxManager] with fake proxies and a temp profiles dir.
SandboxManager _testManager({
  FakeHttpProxy? httpProxy,
  FakeSocksProxy? socksProxy,
  FakeViolationMonitor? violationMonitor,
  Directory? profilesDir,
}) {
  return SandboxManager.test(
    httpProxy: httpProxy ?? FakeHttpProxy(),
    socksProxy: socksProxy ?? FakeSocksProxy(),
    violationMonitor: violationMonitor ?? FakeViolationMonitor(),
    profilesDir:
        profilesDir ?? Directory.systemTemp.createTempSync('sc_mgr_test_'),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // Construction
  // =========================================================================
  group('SandboxManager construction', () {
    test('default constructor is cheap (no resources acquired)', () {
      final mgr = SandboxManager();
      // Egress proxies are PER SESSION now (see the `wrap` group), so an
      // un-wrapped manager owns none at all — not even a process-wide pair.
      expect(mgr.proxiesForSession('anything').http, isNull);
      expect(mgr.proxiesForSession('anything').socks, isNull);
      expect(() => mgr.profilesDir, throwsA(isA<TypeError>()));
    });

    test('test constructor accepts injected dependencies', () {
      final http = FakeHttpProxy();
      final socks = FakeSocksProxy();
      final mon = FakeViolationMonitor();
      final dir = Directory.systemTemp.createTempSync('test_ctor_');

      final mgr = SandboxManager.test(
        httpProxy: http,
        socksProxy: socks,
        violationMonitor: mon,
        profilesDir: dir,
      );

      // Injected proxies are ADOPTED by a restricted session rather than
      // started fresh (and are not closed by it — the test owns them).
      expect(mgr.profilesDir, same(dir));
      expect(http.closeCallCount, 0);
      expect(socks.closeCallCount, 0);
    });

    test('test constructor marks initialization as complete', () async {
      final mgr = _testManager();
      await mgr.ensureInitialized();
      // Initialization no longer binds listeners; it only prepares the
      // profiles dir + violation monitor.
      expect(mgr.profilesDir.existsSync(), isTrue);
    });
  });

  // =========================================================================
  // Lifecycle: ensureInitialized
  // =========================================================================
  group('ensureInitialized', () {
    test('is idempotent — second call returns same future', () async {
      final mgr = _testManager();
      final f1 = mgr.ensureInitialized();
      final f2 = mgr.ensureInitialized();
      expect(identical(f1, f2), isTrue);
      await f1;
      await f2;
    });

    test(
      'with real manager, init prepares the profiles dir (smoke test)',
      () async {
        final mgr = SandboxManager();
        try {
          await mgr.ensureInitialized();
          expect(mgr.profilesDir, isA<Directory>());
          expect(mgr.profilesDir.existsSync(), isTrue);
          // No process-wide proxies: binding two listeners nobody routes
          // through was pure waste, and SHARING them was the egress-policy
          // race this suite now guards against below.
          expect(mgr.proxiesForSession('unused').http, isNull);
        } finally {
          await mgr.reset();
        }
      },
    );
  });

  // =========================================================================
  // Lifecycle: disposeSession
  // =========================================================================
  group('disposeSession', () {
    test('no-ops for unknown session id', () async {
      final mgr = _testManager();
      await mgr.disposeSession('nonexistent');
    });

    test('is idempotent — safe to call multiple times', () async {
      final mgr = _testManager();
      await mgr.disposeSession('s1');
      await mgr.disposeSession('s1');
    });
  });

  // =========================================================================
  // Lifecycle: reset
  // =========================================================================
  group('reset', () {
    test('closes proxies and monitor, clears state', () async {
      final http = FakeHttpProxy();
      final socks = FakeSocksProxy();
      final mon = FakeViolationMonitor();

      final mgr = SandboxManager.test(
        httpProxy: http,
        socksProxy: socks,
        violationMonitor: mon,
      );

      await mgr.reset();

      expect(http.closeCallCount, 1);
      expect(socks.closeCallCount, 1);
      expect(mon.closeCallCount, 1);
    });

    test('handles null proxies gracefully (no-op reset)', () async {
      final mgr = SandboxManager.test();
      await mgr.reset();
    });

    test('resets initialization future so re-init works', () async {
      final mgr = SandboxManager.test(
        httpProxy: FakeHttpProxy(),
        socksProxy: FakeSocksProxy(),
      );
      await mgr.ensureInitialized();
      await mgr.reset();
      final f = mgr.ensureInitialized();
      await f;
    });

    test('closes violations stream', () async {
      final mgr = _testManager();
      final violations = <SandboxViolation>[];
      final sub = mgr.violations.listen(violations.add);
      await mgr.reset();
      // After reset the stream is closed; adding events throws.
      expect(() => mgr.reportLinuxStderr('EPERM post-reset'), throwsStateError);
      await sub.cancel();
    });
  });

  // =========================================================================
  // Lifecycle: wrap
  // =========================================================================
  group('wrap — per-session egress isolation', () {
    // THE regression guard for the original defect: `wrap()` used to rewrite a
    // process-wide proxy's rules on every spawn, so a session with a
    // restricted allow-list shared its proxy with whatever wrapped next —
    // after an unrestricted spawn, the restricted agent's traffic was
    // validated against `allowAll`. The old assertions in this file (a single
    // `mgr.httpProxy` pair) were exactly the shape that could not see it.
    const restrictedA = SandboxConfig(
      sessionId: 'sess-a',
      network: NetworkConfig(allowAll: false, allowedDomains: ['a.example']),
      filesystem: FilesystemConfig(),
    );
    const restrictedB = SandboxConfig(
      sessionId: 'sess-b',
      network: NetworkConfig(allowAll: false, allowedDomains: ['b.example']),
      filesystem: FilesystemConfig(),
    );
    const unrestricted = SandboxConfig(
      sessionId: 'sess-open',
      network: NetworkConfig(),
      filesystem: FilesystemConfig(),
    );

    test('two restricted sessions never share a proxy', () async {
      final mgr = SandboxManager();
      try {
        await mgr.wrap(config: restrictedA, argv: ['true']);
        await mgr.wrap(config: restrictedB, argv: ['true']);

        final a = mgr.proxiesForSession('sess-a');
        final b = mgr.proxiesForSession('sess-b');
        expect(a.http, isNotNull);
        expect(b.http, isNotNull);
        expect(identical(a.http, b.http), isFalse);
        expect(a.http!.port, isNot(b.http!.port));
        expect(a.socks!.port, isNot(b.socks!.port));
      } finally {
        await mgr.reset();
      }
    });

    test('an unrestricted spawn cannot relax a restricted session', () async {
      final mgr = SandboxManager();
      try {
        await mgr.wrap(config: restrictedA, argv: ['true']);
        final before = mgr.proxiesForSession('sess-a').http;

        await mgr.wrap(config: unrestricted, argv: ['true']);

        expect(identical(mgr.proxiesForSession('sess-a').http, before), isTrue);
        // An unrestricted session needs no proxy at all, so it allocates none.
        expect(mgr.proxiesForSession('sess-open').http, isNull);
      } finally {
        await mgr.reset();
      }
    });

    test('disposeSession releases only that session\'s proxies', () async {
      final mgr = SandboxManager();
      try {
        await mgr.wrap(config: restrictedA, argv: ['true']);
        await mgr.wrap(config: restrictedB, argv: ['true']);
        final bPort = mgr.proxiesForSession('sess-b').http!.port;

        await mgr.disposeSession('sess-a');

        expect(mgr.proxiesForSession('sess-a').http, isNull);
        expect(mgr.proxiesForSession('sess-b').http?.port, bPort);
      } finally {
        await mgr.reset();
      }
    });
  });

  group('wrap', () {
    test('calls ensureInitialized before wrapping', () async {
      final mgr = SandboxManager();
      try {
        const config = SandboxConfig(
          sessionId: 'wrap_test',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        );
        final result = await mgr.wrap(config: config, argv: ['echo', 'hi']);
        expect(result.executable, isNotEmpty);
        expect(result.argv, isNotEmpty);
        expect(result.environment, isEmpty);
      } finally {
        await mgr.reset();
      }
    });

    test(
      'sets proxy environment when network is restricted',
      () async {
        final mgr = SandboxManager();
        try {
          const config = SandboxConfig(
            sessionId: 'wrap_restricted',
            network: NetworkConfig(
              allowAll: false,
              allowedDomains: ['api.example.com'],
            ),
            filesystem: FilesystemConfig(),
          );
          final result = await mgr.wrap(
            config: config,
            argv: ['curl', 'api.example.com'],
          );
          expect(result.environment, isNotEmpty);
          expect(result.environment['HTTP_PROXY'], contains('127.0.0.1'));
          expect(result.environment['HTTPS_PROXY'], contains('127.0.0.1'));
          expect(
            result.environment['ALL_PROXY'],
            contains('socks5://127.0.0.1'),
          );
          expect(
            result.environment['NO_PROXY'],
            'localhost,127.0.0.1,::1,*.local,.local,'
            '169.254.0.0/16,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16',
          );
          expect(
            result.environment['http_proxy'],
            result.environment['HTTP_PROXY'],
          );
          expect(
            result.environment['https_proxy'],
            result.environment['HTTPS_PROXY'],
          );
          expect(
            result.environment['all_proxy'],
            result.environment['ALL_PROXY'],
          );
          expect(
            result.environment['no_proxy'],
            result.environment['NO_PROXY'],
          );
        } finally {
          await mgr.reset();
        }
      },
      // On Linux a restricted-network wrap spawns real `socat` bridge
      // processes (LinuxSandbox.startBridges), which aren't guaranteed on a
      // CI runner and would leak child processes. The macOS path shares the
      // host loopback, so the proxy-env contract is deterministic there.
      skip: Platform.isMacOS
          ? null
          : 'restricted-network wrap needs host socat bridges (macOS-only)',
    );

    test('does NOT set proxy vars when network is fully open', () async {
      final mgr = SandboxManager();
      try {
        const config = SandboxConfig(
          sessionId: 'wrap_open',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        );
        final result = await mgr.wrap(config: config, argv: ['echo', 'hi']);
        expect(result.environment, isEmpty);
      } finally {
        await mgr.reset();
      }
    });

    test('wrap result contains executable and argv', () async {
      final mgr = SandboxManager();
      try {
        const config = SandboxConfig(
          sessionId: 'wrap_result',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(),
        );
        final result = await mgr.wrap(config: config, argv: ['ls', '-la']);
        // The sandbox executable is host-specific: macOS Seatbelt uses
        // `/usr/bin/sandbox-exec`; Linux uses bubblewrap (`bwrap`).
        if (Platform.isMacOS) {
          expect(result.executable, '/usr/bin/sandbox-exec');
        } else {
          expect(result.executable, isNotEmpty);
        }
        expect(result.argv, isNotEmpty);
        expect(result.environment, isA<Map<String, String>>());
      } finally {
        await mgr.reset();
      }
    });
  });

  // =========================================================================
  // Isolation: reportLinuxStderr
  // =========================================================================
  group('reportLinuxStderr', () {
    /// Pumps pending microtasks so broadcast stream listeners fire.
    Future<void> pump() => Future.microtask(() {});

    test('detects "Operation not permitted"', () async {
      final mgr = _testManager();
      final captured = <SandboxViolation>[];
      mgr.violations.listen(captured.add);
      mgr.reportLinuxStderr('bash: /usr/bin/curl: Operation not permitted');
      await pump();
      expect(captured, hasLength(1));
      expect(captured.first.action, 'unknown');
      expect(captured.first.target, contains('Operation not permitted'));
      expect(captured.first.raw, contains('Operation not permitted'));
    });

    test('detects "EPERM"', () async {
      final mgr = _testManager();
      final captured = <SandboxViolation>[];
      mgr.violations.listen(captured.add);
      mgr.reportLinuxStderr('openat(AT_FDCWD, "/etc/shadow") = -1 EPERM');
      await pump();
      expect(captured, hasLength(1));
      expect(captured.first.target, contains('EPERM'));
    });

    test('detects "Permission denied"', () async {
      final mgr = _testManager();
      final captured = <SandboxViolation>[];
      mgr.violations.listen(captured.add);
      mgr.reportLinuxStderr('/bin/sh: /root/.bashrc: Permission denied');
      await pump();
      expect(captured, hasLength(1));
      expect(captured.first.target, contains('Permission denied'));
    });

    test('ignores normal stdout/stderr lines', () async {
      final mgr = _testManager();
      final captured = <SandboxViolation>[];
      mgr.violations.listen(captured.add);
      mgr.reportLinuxStderr('Hello, world!');
      mgr.reportLinuxStderr('');
      mgr.reportLinuxStderr('compilation finished successfully');
      await pump();
      expect(captured, isEmpty);
    });

    test('trims target to the line content', () async {
      final mgr = _testManager();
      final captured = <SandboxViolation>[];
      mgr.violations.listen(captured.add);
      mgr.reportLinuxStderr('  EPERM: access denied  ');
      await pump();
      expect(captured.single.target, 'EPERM: access denied');
    });

    test('multiple violations all emitted', () async {
      final mgr = _testManager();
      final captured = <SandboxViolation>[];
      mgr.violations.listen(captured.add);
      mgr.reportLinuxStderr('Error: EPERM on file A');
      await pump();
      mgr.reportLinuxStderr('Error: Operation not permitted on file B');
      await pump();
      expect(captured, hasLength(2));
    });
  });

  // =========================================================================
  // Isolation: violations broadcast stream
  // =========================================================================
  group('violations stream', () {
    test('is a broadcast stream', () {
      final mgr = _testManager();
      final sub1 = mgr.violations.listen((_) {});
      final sub2 = mgr.violations.listen((_) {});
      sub1.cancel();
      sub2.cancel();
    });

    test('delivers violations from reportLinuxStderr', () async {
      final mgr = _testManager();
      final c = Completer<SandboxViolation>();
      mgr.violations.listen(c.complete);
      mgr.reportLinuxStderr('EPERM access');
      final v = await c.future.timeout(const Duration(seconds: 1));
      expect(v.action, 'unknown');
      expect(v.target, contains('EPERM'));
    });

    test('multiple listeners all receive the same violation', () async {
      final mgr = _testManager();
      final c1 = Completer<SandboxViolation>();
      final c2 = Completer<SandboxViolation>();
      mgr.violations.listen(c1.complete);
      mgr.violations.listen(c2.complete);
      mgr.reportLinuxStderr('Permission denied: /secret');
      final v1 = await c1.future.timeout(const Duration(seconds: 1));
      final v2 = await c2.future.timeout(const Duration(seconds: 1));
      expect(v1.target, v2.target);
      expect(v1.raw, v2.raw);
    });
  });

  // =========================================================================
  // Resource limits: SandboxWrapResult
  // =========================================================================
  group('SandboxWrapResult', () {
    test('holds executable, argv and environment', () {
      const result = SandboxWrapResult(
        executable: '/bin/echo',
        argv: ['hello'],
        environment: {'FOO': 'bar'},
      );
      expect(result.executable, '/bin/echo');
      expect(result.argv, ['hello']);
      expect(result.environment, {'FOO': 'bar'});
    });

    test('const constructor works', () {
      const result = SandboxWrapResult(
        executable: 'x',
        argv: [],
        environment: {},
      );
      expect(result, isA<SandboxWrapResult>());
    });
  });
}
