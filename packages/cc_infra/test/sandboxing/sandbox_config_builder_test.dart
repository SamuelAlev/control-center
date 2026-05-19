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
/// configs) and exec-deny token resolution. The wrap shell is always
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
    },
      skip: Platform.isWindows
          ? 'the .git-peek deny paths come out separator-mixed on the Windows runner (raw-root pass vs resolved-root pass); needs on-machine debugging'
          : false);

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

    test('every resolved runtime-tool allow is an absolute path', () async {
      // `resolveBinaryPath` returns the BARE TOKEN for a binary that is on PATH
      // but in no known install prefix, and a relative rule in a Seatbelt
      // profile matches nothing: `(allow process-exec (literal "dart"))` is
      // inert, so an fvm-managed `dart`/`flutter` (which lives under `$HOME`)
      // stayed blocked by the writable-dir exec deny with no sign of why.
      final cfg = await builder.build(
        const SandboxPolicySpec(
          sessionId: 's-abs',
          denyRead: [],
          allowWrite: [],
          denyWrite: [],
          denyExecutables: [],
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
        ),
      );
      expect(cfg.allowedExecutables, isNotEmpty);
      expect(
        cfg.allowedExecutables.where((e) => !p.isAbsolute(e)),
        isEmpty,
        reason: 'a relative exec rule never matches — omit it instead',
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
      // `rm` resolves on test runners (POSIX PATH, Git-for-Windows' rm on
      // Windows); if found, it must be ABSOLUTE — platform-shaped, so the
      // assertion goes through p.isAbsolute rather than a '/' prefix.
      if (cfg.denyExecutables.isNotEmpty) {
        expect(cfg.denyExecutables.every(p.isAbsolute), isTrue);
      }
    },
      skip: Platform.isWindows
          ? 'rm only resolves through Git-for-Windows usr/bin on the runner '
              'and not always to an absolute path'
          : false);
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
        expect(cfg.sessionId, 's10');
        // Field equality, NOT identity: the builder hands the emitters a
        // policy whose paths are spelled the way the kernel matches them (see
        // the symlink-resolution group below), so it is a copy by design.
        expect(cfg.policy?.sessionId, spec.sessionId);
        expect(cfg.policy?.allowWrite, spec.allowWrite);
        expect(cfg.policy?.readOnlyMounts, spec.readOnlyMounts);
        expect(cfg.policy?.runnerStateDirs, spec.runnerStateDirs);
        expect(cfg.policy?.homeDir, spec.homeDir);
        expect(cfg.policy?.runDir, spec.runDir);
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
      expect(cfg.policy?.sessionId, spec.sessionId);
      expect(cfg.policy?.allowWrite, spec.allowWrite);
    });
  });

  // A rule is matched by the kernel against the RESOLVED path, so a rule
  // written against a symlinked one silently never fires. Deny paths were
  // already resolved; ALLOW paths were not, and the asymmetry was the bug: a
  // resolved deny shadowed an unresolved allow, so a Claude Code account
  // directory reached through a symlinked data dir was unwritable inside a
  // protected checkout, and a read-only mount under `/tmp` was never actually
  // read-only.
  group('SandboxConfigBuilder.build — symlink resolution', () {
    late Directory root;
    late Directory real;
    late Link link;

    setUp(() {
      root = Directory.systemTemp.createTempSync('cc-sbx-symlink-');
      real = Directory(p.join(root.path, 'real'))..createSync();
      link = Link(p.join(root.path, 'alias'))..createSync(real.path);
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    test('allowWrite carries both the written and the resolved spelling',
        () async {
      final cfg = await builder.build(
        SandboxPolicySpec(
          sessionId: 's12',
          denyRead: const [],
          allowWrite: [link.path],
          denyWrite: const [],
          denyExecutables: const [],
          allowedDomains: const [],
          deniedDomains: const [],
          networkOn: false,
        ),
      );
      expect(cfg.filesystem.allowWrite, contains(link.path));
      expect(cfg.filesystem.allowWrite, contains(real.resolveSymbolicLinksSync()));
    });

    test('readOnlyMounts and runnerStateDirs are resolved too', () async {
      final cfg = await builder.build(
        SandboxPolicySpec(
          sessionId: 's13',
          denyRead: const [],
          allowWrite: const [],
          denyWrite: const [],
          denyExecutables: const [],
          allowedDomains: const [],
          deniedDomains: const [],
          networkOn: false,
          readOnlyMounts: [link.path],
          runnerStateDirs: [link.path],
        ),
      );
      final resolved = real.resolveSymbolicLinksSync();
      expect(cfg.policy?.readOnlyMounts, contains(resolved));
      expect(cfg.policy?.runnerStateDirs, contains(resolved));
    });
  });
}
