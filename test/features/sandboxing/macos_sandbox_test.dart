import 'dart:io';

import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateSeatbeltProfile', () {
    test('includes version + allow-default for a baseline config', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, contains('(version 1)'));
      expect(profile, contains('(allow default)'));
      // No network rule when not restricted.
      expect(profile, isNot(contains('(deny network*)')));
    });

    test('emits deny file-read* for each denyRead path', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyRead: ['/Users/me/.ssh', '/Users/me/.aws'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, contains('(deny file-read* (subpath "/Users/me/.ssh"))'));
      expect(profile, contains('(deny file-read* (subpath "/Users/me/.aws"))'));
    });

    test('restricts network to proxy ports when an allowlist is set', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(allowAll: false, allowedDomains: ['github.com']),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(
        config,
        httpProxyPort: 1234,
        socksProxyPort: 5678,
      );
      expect(profile, contains('(deny network*)'));
      expect(
        profile,
        contains('(allow network* (remote tcp "localhost:1234"))'),
      );
      expect(
        profile,
        contains('(allow network* (remote tcp "localhost:5678"))'),
      );
    });

    test('write rules go from blanket deny to per-subpath allow', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(allowWrite: ['/Users/me/work']),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      // The blanket deny must come *before* the subpath allow to take effect.
      final denyIdx = profile.indexOf('(deny file-write*)');
      final allowIdx = profile.indexOf(
        '(allow file-write* (subpath "/Users/me/work"))',
      );
      expect(denyIdx, isNonNegative);
      expect(allowIdx, isNonNegative);
      expect(denyIdx, lessThan(allowIdx));
    });

    test('emits allow file-read* for each allowRead path', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(allowRead: ['/Users/me/documents']),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains('(allow file-read* (subpath "/Users/me/documents"))'),
      );
    });

    test('emits deny file-write* for explicit denyWrite paths', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(denyWrite: ['/etc/hosts']),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, contains('(deny file-write* (literal "/etc/hosts"))'));
    });

    test('denyRead paths appear before allowRead paths in output', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyRead: ['/Users/me/.ssh'],
          allowRead: ['/Users/me/docs'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      final denyIdx = profile.indexOf('(deny file-read*');
      final allowIdx = profile.indexOf('(allow file-read*');
      expect(denyIdx, isNonNegative);
      expect(allowIdx, isNonNegative);
      expect(denyIdx, lessThan(allowIdx));
    });

    test(
      'denyWrite rules come after blanket deny + before mandatory denies',
      () {
        const config = SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(
            allowWrite: ['/Users/me/work'],
            denyWrite: ['/Users/me/work/.env'],
          ),
        );
        final profile = MacosSandbox.generateSeatbeltProfile(config);
        final blanketDenyIdx = profile.indexOf('(deny file-write*)');
        final denyEnvIdx = profile.indexOf(
          '(deny file-write* (subpath "/Users/me/work/.env"))',
        );
        expect(blanketDenyIdx, isNonNegative);
        expect(denyEnvIdx, isNonNegative);
        expect(blanketDenyIdx, lessThan(denyEnvIdx));
      },
    );

    test('includes standby write paths when allowWrite is present', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(allowWrite: ['/Users/me/work']),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      // Standby paths that macOS processes need.
      expect(profile, contains('(allow file-write* (subpath "/private/tmp"))'));
      expect(
        profile,
        contains('(allow file-write* (subpath "/private/var/folders"))'),
      );
      expect(profile, contains('(allow file-write* (literal "/dev/null"))'));
      expect(profile, contains('(allow file-write* (literal "/dev/stdout"))'));
      expect(profile, contains('(allow file-write* (literal "/dev/stderr"))'));
    });

    test('no write section when allowWrite and denyWrite are both empty', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, isNot(contains('file-write')));
    });

    test('no network section when network is fully open', () {
      // Default NetworkConfig: allowAll=true, no domains.
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, isNot(contains('(deny network*)')));
      expect(profile, isNot(contains('(allow network*)')));
    });

    test('network restricted — deny-all with local-ip + DNS, sockets denied', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(
          allowAll: false,
          allowedDomains: ['api.example.com'],
        ),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(profile, contains('(deny network*)'));
      // Local IP binding is allowed (ephemeral local port for outbound setup),
      // but loopback egress is NOT blanket-allowed and unix-sockets are NOT
      // allowed — egress is gated by explicit (remote ...) proxy-port rules.
      expect(profile, contains('(allow network* (local ip))'));
      expect(profile, isNot(contains('(allow network* (remote ip "localhost')));
      expect(
        profile,
        isNot(contains('(allow network-outbound (remote unix-socket))')),
      );
      // DNS resolution via macOS mDNSResponder.
      expect(
        profile,
        contains(
          '(allow network-outbound (literal "/private/var/run/mDNSResponder"))',
        ),
      );
      // Container/runtime sockets are explicitly denied (belt-and-suspenders).
      expect(
        profile,
        contains('(deny network-outbound (literal "/var/run/docker.sock"))'),
      );
    });

    test('network restricted without proxy ports — no TCP port rules', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(allowAll: false, allowedDomains: ['github.com']),
        filesystem: FilesystemConfig(),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      // Should not contain any TCP port-specific rules.
      expect(profile, isNot(contains('(allow network* (remote tcp ')));
    });

    test('multiple allowWrite — all appear in profile', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowWrite: ['/Users/me/work', '/Users/me/tmp'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains('(allow file-write* (subpath "/Users/me/work"))'),
      );
      expect(
        profile,
        contains('(allow file-write* (subpath "/Users/me/tmp"))'),
      );
    });

    test('generateSeatbeltProfile — denying and allowing same path', () {
      // denyRead should still emit deny even if same path appears in allowRead.
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          denyRead: ['/Users/me/shared'],
          allowRead: ['/Users/me/shared', '/Users/me/docs'],
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      final denyIdx = profile.indexOf(
        '(deny file-read* (subpath "/Users/me/shared"))',
      );
      final allowIdx = profile.indexOf(
        '(allow file-read* (subpath "/Users/me/shared"))',
      );
      expect(denyIdx, isNonNegative);
      expect(allowIdx, isNonNegative);
      // Deny comes before allow, so deny takes precedence.
      expect(denyIdx, lessThan(allowIdx));
    });

    test('escape — backslashes and quotes in paths are escaped', () {
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(denyRead: [r'/Users/me/weird\"path']),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains(r'(deny file-read* (subpath "/Users/me/weird\\\"path"))'),
      );
    });

    test('mandatory deny paths within allowWrite regions', () {
      // Mandatory-deny expansion (.git/hooks, .git/config, .npmrc inside
      // writable roots) now lives in `SandboxConfigBuilder`, which scans the
      // writable roots and folds the dangerous paths into `denyWrite`.
      // `generateSeatbeltProfile` renders that resolved `denyWrite` list into
      // file-write* deny rules — this asserts the generator emits a deny-write
      // rule for each mandatory-deny path the builder hands it.
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(
          allowWrite: ['/Users/me/project'],
          denyWrite: [
            '/Users/me/project/.git/hooks',
            '/Users/me/project/.git/config',
            '/Users/me/project/.npmrc',
          ],
        ),
        skipMandatoryHomeRcDenies: true,
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      expect(
        profile,
        contains('(deny file-write* (subpath "/Users/me/project/.git/hooks"))'),
      );
      expect(
        profile,
        contains(
          '(deny file-write* (subpath "/Users/me/project/.git/config"))',
        ),
      );
      expect(
        profile,
        contains('(deny file-write* (subpath "/Users/me/project/.npmrc"))'),
      );
    });

    test(
      'read-only mounts are denied for write AFTER the \$HOME allowance',
      () {
        // In review/plan/orchestrate modes the worktree bind mounts are
        // read-only. They live under `$HOME`, which IS writable, so the deny
        // must be emitted after the allow — Seatbelt is last-match-wins.
        // Before this, plan mode's read-only guarantee did not exist on macOS
        // for spawned commands at all (readOnlyMounts was Linux-only).
        const config = SandboxConfig(
          sessionId: 't',
          network: NetworkConfig(),
          filesystem: FilesystemConfig(allowWrite: ['/Users/me', '/tmp']),
          skipMandatoryHomeRcDenies: true,
          policy: SandboxPolicySpec(
            sessionId: 't',
            denyRead: [],
            allowWrite: ['/Users/me', '/tmp'],
            denyWrite: [],
            denyExecutables: [],
            allowedDomains: [],
            deniedDomains: [],
            networkOn: false,
            readOnlyMounts: ['/Users/me/worktrees/feature-x'],
            homeDir: '/Users/me',
          ),
        );
        final profile = MacosSandbox.generateSeatbeltProfile(config);
        final allowHome = profile.indexOf(
          '(allow file-write* (subpath "/Users/me"))',
        );
        final denyMount = profile.indexOf(
          '(deny file-write* (subpath "/Users/me/worktrees/feature-x"))',
        );
        expect(allowHome, greaterThanOrEqualTo(0));
        expect(denyMount, greaterThanOrEqualTo(0));
        expect(
          denyMount,
          greaterThan(allowHome),
          reason: 'Seatbelt is last-match-wins: the deny must come after.',
        );
      },
    );

    test('runDir stays writable even inside a read-only mount', () {
      // The run dir is `<agentDir>/.cc-runs/<id>` — inside a bind mount the
      // read-only pass just denied. It is the sanctioned scratch space in
      // read-only modes, so it is re-allowed last.
      const runDir = '/Users/me/agents/ceo/.cc-runs/session-1';
      const config = SandboxConfig(
        sessionId: 't',
        network: NetworkConfig(),
        filesystem: FilesystemConfig(allowWrite: ['/Users/me', runDir]),
        skipMandatoryHomeRcDenies: true,
        policy: SandboxPolicySpec(
          sessionId: 't',
          denyRead: [],
          allowWrite: ['/Users/me', runDir],
          denyWrite: [],
          denyExecutables: [],
          allowedDomains: [],
          deniedDomains: [],
          networkOn: false,
          readOnlyMounts: ['/Users/me/agents/ceo'],
          homeDir: '/Users/me',
          runDir: runDir,
        ),
      );
      final profile = MacosSandbox.generateSeatbeltProfile(config);
      final denyMount = profile.indexOf(
        '(deny file-write* (subpath "/Users/me/agents/ceo"))',
      );
      final allowRunDir = profile.lastIndexOf(
        '(allow file-write* (subpath "$runDir"))',
      );
      expect(denyMount, greaterThanOrEqualTo(0));
      expect(allowRunDir, greaterThan(denyMount));
    });

    group('exec-deny symlink resolution', () {
      late Directory tmp;
      late String root;

      setUp(() {
        tmp = Directory.systemTemp.createTempSync('sb-exec-');
        // macOS temp dirs live under /var → /private/var. The kernel matches
        // resolved paths, so the expectations must use the resolved spelling.
        root = tmp.resolveSymbolicLinksSync();
        Directory('$root/bin').createSync(recursive: true);
      });

      tearDown(() => tmp.deleteSync(recursive: true));

      SandboxConfig configDenying(List<String> paths) => SandboxConfig(
        sessionId: 't',
        network: const NetworkConfig(),
        filesystem: const FilesystemConfig(),
        denyExecutables: paths,
      );

      test(
        'skips the realpath deny for a multi-call binary, so its other '
        'applets stay runnable',
        () {
          // Nix ships coreutils 9.x as ONE binary dispatching on argv[0], with
          // a symlink per applet. `rm`, `dd` and `chroot` all resolve to it, so
          // denying the realpath blocked every applet the package ships — `cat`,
          // `echo`, `env`, `dirname`, `chmod` — about a hundred commands, to
          // deny three. Seatbelt has no argv[0] predicate, so on such a build
          // the exec layer genuinely cannot tell `dd` from `cat`.
          File('$root/bin/coreutils').writeAsStringSync('#!/bin/sh\n');
          for (final applet in ['rm', 'dd', 'chroot', 'cat', 'echo']) {
            Link('$root/bin/$applet').createSync('$root/bin/coreutils');
          }

          final profile = MacosSandbox.generateSeatbeltProfile(
            configDenying(['$root/bin/rm']),
          );

          expect(
            profile,
            isNot(contains('(deny process-exec (literal "$root/bin/coreutils")')),
            reason: 'denying the multiplexer takes out every applet with it',
          );
          expect(
            profile,
            contains(';; skipped realpath deny for $root/bin/rm'),
            reason: 'the skip must be visible in the profile, not silent',
          );
        },
      );

      test('still denies the realpath of an ordinary symlink farm', () {
        // Same basename on both ends: `/usr/bin/rm` → `/opt/…/bin/rm` is one
        // binary reached through a link, not a multiplexer. The realpath deny
        // is the rule that actually fires, so it must survive.
        Directory('$root/real').createSync();
        File('$root/real/rm').writeAsStringSync('#!/bin/sh\n');
        Link('$root/bin/rm').createSync('$root/real/rm');

        final profile = MacosSandbox.generateSeatbeltProfile(
          configDenying(['$root/bin/rm']),
        );

        expect(
          profile,
          contains('(deny process-exec (literal "$root/real/rm"))'),
        );
      });

      test('an exec grant is allowed AFTER the writable-dir denies', () {
        final profile = MacosSandbox.generateSeatbeltProfile(
          SandboxConfig(
            sessionId: 't',
            network: const NetworkConfig(),
            filesystem: const FilesystemConfig(),
            allowedExecRoots: ['$root/worktree'],
            policy: SandboxPolicySpec(
              sessionId: 't',
              denyRead: const [],
              allowWrite: const [],
              denyWrite: const [],
              denyExecutables: const [],
              allowedDomains: const [],
              deniedDomains: const [],
              networkOn: false,
              homeDir: root,
              execGrantRoots: ['$root/worktree'],
            ),
          ),
        );
        final denyHome = profile.indexOf(
          '(deny process-exec (subpath "$root"))',
        );
        final allowGrant = profile.indexOf(
          '(allow process-exec (subpath "$root/worktree"))',
        );
        expect(denyHome, greaterThanOrEqualTo(0));
        expect(allowGrant, greaterThanOrEqualTo(0));
        expect(
          allowGrant,
          greaterThan(denyHome),
          reason: 'Seatbelt is last-match-wins: the grant must come after '
              'the \$HOME block it is re-opening.',
        );
      });

      test('with no grant, the writable-dir deny still blocks the worktree', () {
        final profile = MacosSandbox.generateSeatbeltProfile(
          SandboxConfig(
            sessionId: 't',
            network: const NetworkConfig(),
            filesystem: const FilesystemConfig(),
            policy: SandboxPolicySpec(
              sessionId: 't',
              denyRead: const [],
              allowWrite: const [],
              denyWrite: const [],
              denyExecutables: const [],
              allowedDomains: const [],
              deniedDomains: const [],
              networkOn: false,
              homeDir: root,
            ),
          ),
        );
        expect(profile, contains('(deny process-exec (subpath "$root"))'));
        expect(profile, isNot(contains('(allow process-exec (subpath ')));
      });

      test(
        'the kernel honours a grant: a worktree binary runs only once granted',
        () async {
          // The rule ordering above is necessary but not sufficient — this is
          // the claim that matters, checked against the real Seatbelt
          // evaluator rather than against our own idea of it.
          Directory('$root/worktree/node_modules/.bin').createSync(
            recursive: true,
          );
          final tool = File('$root/worktree/node_modules/.bin/is-ci')
            ..writeAsStringSync('#!/bin/sh\necho TOOL_RAN\n');
          Process.runSync('chmod', ['+x', tool.path]);

          SandboxPolicySpec policyWith(List<String> grants) =>
              SandboxPolicySpec(
                sessionId: 't',
                denyRead: const [],
                allowWrite: const [],
                denyWrite: const [],
                denyExecutables: const [],
                allowedDomains: const [],
                deniedDomains: const [],
                networkOn: false,
                homeDir: root,
                execGrantRoots: grants,
              );

          Future<String> run(List<String> grants) async {
            final wrap = MacosSandbox.wrapCommand(
              config: SandboxConfig(
                sessionId: 't',
                network: const NetworkConfig(),
                filesystem: const FilesystemConfig(),
                allowedExecRoots: grants,
                policy: policyWith(grants),
              ),
              // Through a shell, NOT as argv.first: `wrapCommand` explicitly
              // allows the command it wraps, and the real case is a NESTED
              // exec — npm spawning husky, which nothing allowlisted.
              argv: ['/bin/sh', '-c', tool.path],
              profilesDir: Directory('$root/profiles'),
            );
            final r = await Process.run(wrap.executable, wrap.argv);
            return '${r.stdout}${r.stderr}';
          }

          expect(
            await run(const []),
            isNot(contains('TOOL_RAN')),
            reason: 'ungranted: the \$HOME exec block must still bite',
          );
          expect(
            await run(['$root/worktree']),
            contains('TOOL_RAN'),
            reason: 'granted: the subpath allow must re-open exec',
          );
        },
        skip: !Platform.isMacOS ? 'Seatbelt is macOS-only' : false,
      );

      test('still denies a renamed single binary with no sibling aliases', () {
        // Homebrew's GNU coreutils installs `grm` as its own executable — the
        // basename differs but nothing else links to it, so it is not a
        // multiplexer and denying it costs nothing else.
        Directory('$root/real').createSync();
        File('$root/real/grm').writeAsStringSync('#!/bin/sh\n');
        Link('$root/bin/rm').createSync('$root/real/grm');

        final profile = MacosSandbox.generateSeatbeltProfile(
          configDenying(['$root/bin/rm']),
        );

        expect(
          profile,
          contains('(deny process-exec (literal "$root/real/grm"))'),
        );
      });
    });
  });

  group('wrapCommand', () {
    test('builds sandbox-exec argv with profile file', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['ls', '-la'],
          profilesDir: tempDir,
        );
        expect(result.executable, '/usr/bin/sandbox-exec');
        expect(result.argv[0], '-f');
        expect(result.argv[1], result.profilePath);
        expect(result.argv[2], '/bin/bash');
        expect(result.argv[3], '-c');
        expect(result.argv[4], 'ls -la');
        // Profile file was created.
        expect(File(result.profilePath).existsSync(), isTrue);
        expect(result.profilePath, contains('sandbox-s1.sb'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('wrapCommand with workingDirectory prepends cd', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['ls', '-la'],
          profilesDir: tempDir,
          workingDirectory: '/Users/me/work',
        );
        // Last arg should be: cd /Users/me/work && ls -la
        final inner = result.argv.last;
        expect(inner, contains('cd'));
        expect(inner, contains('/Users/me/work'));
        expect(inner, contains('&&'));
        expect(inner, contains('ls -la'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('custom binShell', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['echo', 'hi'],
          profilesDir: tempDir,
          binShell: '/bin/zsh',
        );
        expect(result.argv[2], '/bin/zsh');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('with proxy ports adds them to profile', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(
              allowAll: false,
              allowedDomains: ['github.com'],
            ),
            filesystem: FilesystemConfig(),
          ),
          argv: ['curl', 'https://github.com'],
          profilesDir: tempDir,
          httpProxyPort: 8080,
          socksProxyPort: 1080,
        );
        // Profile file should contain proxy rules.
        final profile = File(result.profilePath).readAsStringSync();
        expect(
          profile,
          contains('(allow network* (remote tcp "localhost:8080"))'),
        );
        expect(
          profile,
          contains('(allow network* (remote tcp "localhost:1080"))'),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('shell quoting — args with special chars', () {
      final tempDir = Directory.systemTemp.createTempSync('sb-test-');
      try {
        final result = MacosSandbox.wrapCommand(
          config: const SandboxConfig(
            sessionId: 's1',
            network: NetworkConfig(),
            filesystem: FilesystemConfig(),
          ),
          argv: ['bash', '-c', 'echo "hello world"'],
          profilesDir: tempDir,
        );
        // The inner command in the -c arg should quote the "$" properly.
        expect(result.argv.last, contains('"hello world"'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
