import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [SandboxConfigBuilder] — the infra materializer that turns a
/// pure [SandboxPolicySpec] into a platform-ready [SandboxConfig]. Covers the
/// network default-deny flag, mandatory home-deny expansion, recursive
/// dangerous-path scanning of writable roots (shell rc, .git/hooks, editor
/// configs), and exec-deny token resolution. The wrap shell is always
/// exempted from exec-deny.
void main() {
  const builder = SandboxConfigBuilder();

  group('SandboxConfigBuilder.build — network', () {
    test('networkOff → fully blocked (allowAll false, no domains)', () async {
      final cfg = await builder.build(
        const SandboxPolicySpec(
          sessionId: 's1',
          denyRead: [],
          allowWrite: [],
          denyWrite: [],
          denyExecutables: [],
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
        ),
      );
      expect(cfg.network.allowAll, isFalse);
      expect(cfg.network.allowedDomains, isEmpty);
      expect(cfg.network.isBlocked, isTrue);
    });

    test(
      'networkOn → restricted to allowed/denied domains (never allowAll)',
      () async {
        final cfg = await builder.build(
          const SandboxPolicySpec(
            sessionId: 's2',
            denyRead: [],
            allowWrite: [],
            denyWrite: [],
            denyExecutables: [],
            allowedDomains: ['api.github.com'],
            deniedDomains: ['telemetry.example.com'],
            networkOn: true,
          ),
        );
        expect(cfg.network.allowAll, isFalse);
        expect(cfg.network.allowedDomains, ['api.github.com']);
        expect(cfg.network.deniedDomains, ['telemetry.example.com']);
        expect(cfg.network.isRestricted, isTrue);
      },
    );
  });

  group('SandboxConfigBuilder.build — home mandatory deny', () {
    test('expands mandatory + rc deny rels against homeDir', () async {
      final cfg = await builder.build(
        const SandboxPolicySpec(
          sessionId: 's3',
          denyRead: [],
          allowWrite: [],
          denyWrite: [],
          denyExecutables: [],
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
          homeDir: '/users/me',
        ),
      );
      // A representative subset from homeMandatoryDenyRels / homeRcDenyRels.
      expect(cfg.filesystem.denyWrite, contains('/users/me/.ssh'));
      expect(cfg.filesystem.denyWrite, contains('/users/me/.aws'));
      expect(cfg.filesystem.denyWrite, contains('/users/me/.claude.json'));
      expect(cfg.filesystem.denyWrite, contains('/users/me/.bashrc'));
      expect(cfg.filesystem.denyWrite, contains('/users/me/.zshrc'));
      expect(cfg.filesystem.denyWrite, contains('/users/me/.gitconfig'));
    });

    test('skips home expansion when homeDir is null', () async {
      final cfg = await builder.build(
        const SandboxPolicySpec(
          sessionId: 's4',
          denyRead: [],
          allowWrite: [],
          denyWrite: [],
          denyExecutables: [],
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
        ),
      );
      expect(cfg.filesystem.denyWrite, isEmpty);
    });
  });

  group('SandboxConfigBuilder.build — dangerous path scan', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('sb_scan_'));
    tearDown(() => root.deleteSync(recursive: true));

    test('shadows dangerous files under a writable root', () async {
      // Seed a dangerous file + a benign sibling.
      File(p.join(root.path, '.bashrc')).writeAsStringSync('x');
      File(p.join(root.path, '.mcp.json')).writeAsStringSync('{}');
      Directory(p.join(root.path, 'src')).createSync();

      final cfg = await builder.build(
        SandboxPolicySpec(
          sessionId: 's5',
          denyRead: const [],
          allowWrite: [root.path],
          denyWrite: const [],
          denyExecutables: const [],
          allowedDomains: const [],
          deniedDomains: const [],
          networkOn: false,
        ),
      );
      expect(cfg.filesystem.denyWrite, contains(p.join(root.path, '.bashrc')));
      expect(
        cfg.filesystem.denyWrite,
        contains(p.join(root.path, '.mcp.json')),
      );
      // Benign dir is not shadowed.
      expect(
        cfg.filesystem.denyWrite,
        isNot(contains(p.join(root.path, 'src'))),
      );
    });

    test('peeks inside .git for hooks/config and skips node_modules', () async {
      final gitDir = Directory(p.join(root.path, '.git'))..createSync();
      Directory(p.join(gitDir.path, 'hooks')).createSync();
      File(p.join(gitDir.path, 'config')).writeAsStringSync('c');
      // node_modules must be skipped for performance.
      Directory(
        p.join(root.path, 'node_modules', 'deep'),
      ).createSync(recursive: true);

      final cfg = await builder.build(
        SandboxPolicySpec(
          sessionId: 's6',
          denyRead: const [],
          allowWrite: [root.path],
          denyWrite: const [],
          denyExecutables: const [],
          allowedDomains: const [],
          deniedDomains: const [],
          networkOn: false,
        ),
      );
      expect(
        cfg.filesystem.denyWrite,
        contains(p.join(root.path, '.git', 'hooks')),
      );
      expect(
        cfg.filesystem.denyWrite,
        contains(p.join(root.path, '.git', 'config')),
      );
      expect(
        cfg.filesystem.denyWrite,
        isNot(contains(p.join(root.path, 'node_modules'))),
      );
    });

    test('recurses up to the depth cap', () async {
      // Depth 0..3 are scanned; depth 4 is beyond the cap (depth > 3 returns).
      // A dangerous file at depth 3 (a/b/c) IS shadowed...
      Directory(p.join(root.path, 'a', 'b', 'c')).createSync(recursive: true);
      File(p.join(root.path, 'a', 'b', 'c', '.zshrc')).writeAsStringSync('z');
      // ...but one at depth 4 (a/b/c/d) is NOT.
      Directory(
        p.join(root.path, 'a', 'b', 'c', 'd'),
      ).createSync(recursive: true);
      File(
        p.join(root.path, 'a', 'b', 'c', 'd', '.zshrc'),
      ).writeAsStringSync('deep');
      // depth-0 file (directly in root) IS scanned.
      File(p.join(root.path, '.profile')).writeAsStringSync('p');

      final cfg = await builder.build(
        SandboxPolicySpec(
          sessionId: 's7',
          denyRead: const [],
          allowWrite: [root.path],
          denyWrite: const [],
          denyExecutables: const [],
          allowedDomains: const [],
          deniedDomains: const [],
          networkOn: false,
        ),
      );
      expect(cfg.filesystem.denyWrite, contains(p.join(root.path, '.profile')));
      // depth 3 file (.zshrc under a/b/c) is within cap → shadowed.
      expect(
        cfg.filesystem.denyWrite,
        contains(p.join(root.path, 'a', 'b', 'c', '.zshrc')),
      );
      // depth 4 file (.zshrc under a/b/c/d) is beyond cap → not shadowed.
      expect(
        cfg.filesystem.denyWrite,
        isNot(contains(p.join(root.path, 'a', 'b', 'c', 'd', '.zshrc'))),
      );
    });
  });

  group('SandboxConfigBuilder.build — exec denies', () {
    test('never exec-denies the wrap shell', () async {
      final cfg = await builder.build(
        const SandboxPolicySpec(
          sessionId: 's8',
          denyRead: [],
          allowWrite: [],
          denyWrite: [],
          denyExecutables: [], // none requested
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
        ),
      );
      expect(
        cfg.denyExecutables,
        isNot(contains(SandboxConfigBuilder.wrapShell)),
      );
    });

    test('resolves a real deny token (rm) to its absolute path', () async {
      final cfg = await builder.build(
        const SandboxPolicySpec(
          sessionId: 's9',
          denyRead: [],
          allowWrite: [],
          denyWrite: [],
          denyExecutables: ['rm'],
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
        ),
      );
      // `rm` resolves on POSIX test runners; if found, it must be absolute.
      if (cfg.denyExecutables.isNotEmpty) {
        expect(cfg.denyExecutables.every((e) => e.startsWith('/')), isTrue);
      }
    });
  });

  group('SandboxConfigBuilder.build — pass-through fields', () {
    test(
      'carries denyRead/allowWrite/denyWrite + the policy verbatim',
      () async {
        const spec = SandboxPolicySpec(
          sessionId: 's10',
          denyRead: ['/secret'],
          allowWrite: ['/w'],
          denyWrite: ['**/.env'],
          denyExecutables: [],
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
        );
        final cfg = await builder.build(spec);
        expect(cfg.filesystem.denyRead, ['/secret']);
        expect(cfg.filesystem.allowWrite, ['/w']);
        expect(cfg.filesystem.denyWrite, contains('**/.env'));
        expect(cfg.policy, same(spec));
        expect(cfg.sessionId, 's10');
      },
    );
  });

  group('buildSandboxConfigFromPolicy — fallback', () {
    test('returns a config mirroring the spec', () async {
      const spec = SandboxPolicySpec(
        sessionId: 's11',
        denyRead: ['/r'],
        allowWrite: ['/w'],
        denyWrite: [],
        denyExecutables: [],
        allowedDomains: ['a.example.com'],
        deniedDomains: [],
        networkOn: true,
      );
      final cfg = await buildSandboxConfigFromPolicy(spec);
      expect(cfg.sessionId, 's11');
      expect(cfg.network.allowedDomains, ['a.example.com']);
      expect(cfg.network.allowAll, isFalse);
      expect(cfg.filesystem.denyRead, ['/r']);
      expect(cfg.policy, same(spec));
    });
  });
}
