import 'dart:async';
import 'dart:io';

import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:control_center/features/sandboxing/data/runtime/http_proxy.dart';
import 'package:control_center/features/sandboxing/data/runtime/sandbox_config.dart';
import 'package:control_center/features/sandboxing/data/runtime/sandbox_manager.dart';
import 'package:control_center/features/sandboxing/data/runtime/socks_proxy.dart';
import 'package:control_center/features/sandboxing/data/runtime/violation_monitor.dart';
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
    profilesDir: profilesDir ?? Directory.systemTemp.createTempSync('sc_mgr_test_'),
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
      expect(() => mgr.httpProxy, throwsA(isA<TypeError>()));
      expect(() => mgr.socksProxy, throwsA(isA<TypeError>()));
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

      expect(mgr.httpProxy, same(http));
      expect(mgr.socksProxy, same(socks));
      expect(mgr.profilesDir, same(dir));
    });

    test('test constructor marks initialization as complete', () async {
      final mgr = _testManager();
      await mgr.ensureInitialized();
      expect(mgr.httpProxy, isNotNull);
      expect(mgr.socksProxy, isNotNull);
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

    test('with real manager, proxies are started (integration smoke test)',
        () async {
      final mgr = SandboxManager();
      try {
        await mgr.ensureInitialized();
        expect(mgr.httpProxy.port, greaterThan(0));
        expect(mgr.socksProxy.port, greaterThan(0));
        expect(mgr.profilesDir, isA<Directory>());
        expect(mgr.profilesDir.existsSync(), isTrue);
      } finally {
        await mgr.reset();
      }
    });
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
      expect(
        () => mgr.reportLinuxStderr('EPERM post-reset'),
        throwsStateError,
      );
      await sub.cancel();
    });
  });

  // =========================================================================
  // Lifecycle: wrap
  // =========================================================================
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

    test('sets proxy environment when network is restricted', () async {
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
        final result =
            await mgr.wrap(config: config, argv: ['curl', 'api.example.com']);
        expect(result.environment, isNotEmpty);
        expect(result.environment['HTTP_PROXY'], contains('127.0.0.1'));
        expect(result.environment['HTTPS_PROXY'], contains('127.0.0.1'));
        expect(result.environment['ALL_PROXY'], contains('socks5://127.0.0.1'));
        expect(result.environment['NO_PROXY'], 'localhost,127.0.0.1');
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
    });

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
        expect(result.executable, '/usr/bin/sandbox-exec');
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
    test('holds executable, argv, and environment', () {
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
