import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_infra/src/sandboxing/violation_monitor.dart';
import 'package:flutter_test/flutter_test.dart';
// ---------------------------------------------------------------------------
// parseLogLine — parses macOS `log stream --style ndjson` output
// ---------------------------------------------------------------------------

void main() {
  group('parseLogLine', () {
    test('returns null for empty line', () {
      expect(SandboxViolationMonitor.parseLogLine(''), isNull);
    });

    test('returns null for invalid JSON', () {
      expect(SandboxViolationMonitor.parseLogLine('not json{{'), isNull);
    });

    test('returns null when eventMessage has no "deny" keyword', () {
      const line =
          '{"eventMessage":"Sandbox: bash(12345) allow file-read-data /tmp/foo"}';
      expect(SandboxViolationMonitor.parseLogLine(line), isNull);
    });

    test('returns null when eventMessage is missing', () {
      const line = '{"someOtherKey":"value"}';
      expect(SandboxViolationMonitor.parseLogLine(line), isNull);
    });

    test('parses deny(1) with error code and extracts action + target', () {
      const line =
          '{"eventMessage":"Sandbox: bash(12345) deny(1) file-read-data /tmp/secret"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.processName, 'bash');
      expect(result.violation.action, 'file-read-data');
      expect(result.violation.target, '/tmp/secret');
      expect(result.violation.raw, line);
      expect(result.violation.suggestedCapability, isNull);
    });

    test('parses deny without error code', () {
      const line =
          '{"eventMessage":"Sandbox: python3(99999) deny file-write-create /Users/me/output.txt"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.processName, 'python3');
      expect(result.violation.action, 'file-write-create');
      expect(result.violation.target, '/Users/me/output.txt');
    });

    test('parses deny with multi-digit error code', () {
      const line =
          '{"eventMessage":"Sandbox: node(42) deny(42) network-outbound /private/var/run/mDNSResponder"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.processName, 'node');
      expect(result.violation.action, 'network-outbound');
    });

    test('parses mach-lookup actions', () {
      const line =
          '{"eventMessage":"Sandbox: pi(7777) deny(1) mach-lookup com.apple.CoreDisplay.Notification"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.violation.action, 'mach-lookup');
      expect(
          result.violation.target, 'com.apple.CoreDisplay.Notification');
    });

    test('parses network-outbound with host target', () {
      const line =
          '{"eventMessage":"Sandbox: curl(111) deny(1) network-outbound github.com:443"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.violation.action, 'network-outbound');
      expect(result.violation.target, 'github.com:443');
      expect(result.violation.suggestedCapability, 'canCallGitHubApi');
    });

    test('parses network-outbound to non-github host and suggests generic capability', () {
      const line =
          '{"eventMessage":"Sandbox: curl(111) deny(1) network-outbound api.example.com:443"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.violation.suggestedCapability, 'canAccessNetwork');
    });

    test('handles eventMessage without process info gracefully', () {
      const line = '{"eventMessage":" deny(1) file-read-data /tmp/x"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.processName, isNull);
      expect(result.violation.action, 'file-read-data');
      expect(result.violation.target, '/tmp/x');
    });

    test('parses Unix socket target', () {
      const line =
          '{"eventMessage":"Sandbox: node(555) deny(1) file-read-data /tmp/.X11-unix/X0"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.violation.action, 'file-read-data');
      expect(result.violation.target, '/tmp/.X11-unix/X0');
    });

    test('handles extra whitespace in the deny tail', () {
      const line =
          '{"eventMessage":"Sandbox: git(888) deny(1)  file-read-data   /some/path  "}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result, isNotNull);
      expect(result!.violation.action, 'file-read-data');
      expect(result.violation.target, '/some/path');
    });

    test('sets raw to the original log line', () {
      const line =
          '{"eventMessage":"Sandbox: bash(1) deny(1) file-write-unlink /tmp/f"}';
      final result = SandboxViolationMonitor.parseLogLine(line);
      expect(result!.violation.raw, line);
    });
  });

  // -------------------------------------------------------------------------
  // isNoise — filters the macOS sandbox firehose down to actionable denials
  // -------------------------------------------------------------------------

  group('isNoise', () {
    // Helper to create a ParsedLine for testing
    ParsedLine makeParsed({
      String? processName,
      String action = 'file-read-data',
      String target = '/tmp/test',
      String? suggestedCapability,
    }) {
      return ParsedLine(
        processName: processName,
        violation: SandboxViolation(
          action: action,
          target: target,
          suggestedCapability: suggestedCapability,
        ),
      );
    }

    group('process-name filtering', () {
      test('null process name → noise', () {
        final p = makeParsed(processName: null);
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('non-agent process (Spotlight) → noise', () {
        final p = makeParsed(processName: 'mdworker');
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('non-agent process (Cursor) → noise', () {
        final p = makeParsed(processName: 'Cursor');
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      // Every process in agentProcesses should pass the allowlist
      for (final proc in SandboxViolationMonitor.agentProcesses) {
        test('agent process "$proc" with benign action → NOT noise', () {
          final p = makeParsed(
            processName: proc,
            action: 'file-read-data',
            target: '/tmp/not-system',
          );
          expect(SandboxViolationMonitor.isNoise(p), isFalse,
              reason: '$proc should not be noise for file-read-data on /tmp');
        });
      }

      test('process-name check is case-insensitive', () {
        final p = makeParsed(processName: 'BASH');
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });
    });

    group('action-based filtering', () {
      test('mach-lookup → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'mach-lookup',
          target: 'com.apple.securityd',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('mach-lookup with suffix → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'mach-lookup-global',
          target: 'com.apple.windowserver',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('user-preference-write → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'user-preference-write',
          target: 'com.apple.Terminal',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('system-* action (system-fsctl) → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'system-fsctl',
          target: '/dev/disk0',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('system-* action (system-privilege) → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'system-privilege',
          target: '',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });
    });

    group('file-read path filtering', () {
      test('file-read on /System/ → noise', () {
        final p = makeParsed(
          processName: 'node',
          action: 'file-read-data',
          target: '/System/Library/Frameworks/CoreFoundation.framework',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /Library/ → noise', () {
        final p = makeParsed(
          processName: 'python3',
          action: 'file-read-data',
          target: '/Library/Preferences/com.apple.security.plist',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /Applications/ → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-read-data',
          target: '/Applications/Xcode.app/Contents/Info.plist',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /usr/lib/ → noise', () {
        final p = makeParsed(
          processName: 'pi',
          action: 'file-read-data',
          target: '/usr/lib/libSystem.B.dylib',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /usr/share/ → noise', () {
        final p = makeParsed(
          processName: 'pi',
          action: 'file-read-data',
          target: '/usr/share/zoneinfo/UTC',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /usr/bin/ → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-read-data',
          target: '/usr/bin/true',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /private/etc/ → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-read-data',
          target: '/private/etc/hosts',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /private/var/db/ → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-read-data',
          target: '/private/var/db/dyld/dyld_shared_cache_x86_64',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /private/var/folders/ → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-read-data',
          target: '/private/var/folders/zz/zyxvpxvq6csfxvn_n00000sm00006d/C',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on /.fseventsd → noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-read-data',
          target: '/.fseventsd/0000000000000001',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on target starting with .node → noise', () {
        final p = makeParsed(
          processName: 'node',
          action: 'file-read-data',
          target: '.node_cache/module.node',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on target containing .node but not at start → NOT noise '
          '(startsWith semantics)', () {
        final p = makeParsed(
          processName: 'node',
          action: 'file-read-data',
          target: '/Users/me/project/node_modules/pkg/foo.node',
        );
        // The noisyReadPaths check uses startsWith, so this does NOT match
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });

      test('file-read on target starting with .dylib → noise', () {
        final p = makeParsed(
          processName: 'python3',
          action: 'file-read-data',
          target: '.dylib_cache/libffi.8.dylib',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on target starting with .so → noise', () {
        final p = makeParsed(
          processName: 'python3',
          action: 'file-read-data',
          target: '.so_cache/_ctypes.cpython-312-darwin.so',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('file-read on user project path → NOT noise', () {
        final p = makeParsed(
          processName: 'python3',
          action: 'file-read-data',
          target: '/Users/me/projects/myapp/config.json',
        );
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });

      test('file-read on /tmp → NOT noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-read-data',
          target: '/tmp/my-data.txt',
        );
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });
    });

    group('non-file-read actions on noisy paths are not filtered', () {
      test('file-write-create on /System/ → NOT noise (action is not file-read)', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-write-create',
          target: '/System/Library/Something',
        );
        // Path filtering only applies to file-read actions
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });

      test('network-outbound on any target → NOT noise (for agent process)', () {
        final p = makeParsed(
          processName: 'curl',
          action: 'network-outbound',
          target: '/System/Library',
        );
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });

      test('file-write-unlink on /Library/ → NOT noise', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'file-write-unlink',
          target: '/Library/Caches/com.apple.SoftwareUpdate',
        );
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });
    });

    group('combined filters', () {
      test('agent process with actionable action and path → NOT noise', () {
        final p = makeParsed(
          processName: 'node',
          action: 'file-write-create',
          target: '/Users/me/output.json',
        );
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });

      test('agent process reading dotfile in user dir → NOT noise', () {
        final p = makeParsed(
          processName: 'git',
          action: 'file-read-data',
          target: '/Users/me/.gitconfig',
        );
        expect(SandboxViolationMonitor.isNoise(p), isFalse);
      });

      test('non-agent process even with actionable path → noise', () {
        final p = makeParsed(
          processName: 'Spotlight',
          action: 'file-write-create',
          target: '/tmp/important',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });

      test('agent process with mach-lookup on user path → still noise (action wins)', () {
        final p = makeParsed(
          processName: 'bash',
          action: 'mach-lookup',
          target: '/Users/me/something',
        );
        expect(SandboxViolationMonitor.isNoise(p), isTrue);
      });
    });
  });

  // -------------------------------------------------------------------------
  // suggestCapability — maps violations to agent capability flags
  // -------------------------------------------------------------------------

  group('suggestCapability', () {
    test('network action targeting github.com → canCallGitHubApi', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'network-outbound',
          'github.com:443',
        ),
        'canCallGitHubApi',
      );
    });

    test('network action targeting api.github.com → canCallGitHubApi', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'network-outbound',
          'api.github.com:443',
        ),
        'canCallGitHubApi',
      );
    });

    test('network action targeting non-github host → canAccessNetwork', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'network-outbound',
          'api.example.com:443',
        ),
        'canAccessNetwork',
      );
    });

    test('network-inbound → canAccessNetwork', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'network-inbound',
          '0.0.0.0:3000',
        ),
        'canAccessNetwork',
      );
    });

    test('file-read-data → null (no capability suggested)', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'file-read-data',
          '/tmp/secret',
        ),
        isNull,
      );
    });

    test('file-write-create → null', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'file-write-create',
          '/tmp/output.txt',
        ),
        isNull,
      );
    });

    test('mach-lookup → null', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'mach-lookup',
          'com.apple.audio',
        ),
        isNull,
      );
    });

    test('user-preference-write → null', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'user-preference-write',
          'com.apple.Terminal',
        ),
        isNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  // agentProcesses — the process-name allowlist
  // -------------------------------------------------------------------------

  group('agentProcesses', () {
    test('contains expected shell interpreters', () {
      const procs = SandboxViolationMonitor.agentProcesses;
      expect(procs, contains('bash'));
      expect(procs, contains('zsh'));
      expect(procs, contains('sh'));
    });

    test('contains expected runtime interpreters', () {
      const procs = SandboxViolationMonitor.agentProcesses;
      expect(procs, contains('node'));
      expect(procs, contains('python3'));
      expect(procs, contains('python'));
    });

    test('contains expected CLI tools', () {
      const procs = SandboxViolationMonitor.agentProcesses;
      expect(procs, contains('git'));
      expect(procs, contains('gh'));
      expect(procs, contains('curl'));
      expect(procs, contains('wget'));
    });

    test('contains sandbox-specific processes', () {
      const procs = SandboxViolationMonitor.agentProcesses;
      expect(procs, contains('pi'));
      expect(procs, contains('sandbox-exec'));
    });

    test('all entries are lowercase', () {
      for (final proc in SandboxViolationMonitor.agentProcesses) {
        expect(proc, equals(proc.toLowerCase()),
            reason: '"$proc" should be lowercase');
      }
    });
  });

  // -------------------------------------------------------------------------
  // noisyReadPaths — paths whose deny logs are always irrelevant
  // -------------------------------------------------------------------------

  group('noisyReadPaths', () {
    test('contains system framework paths', () {
      const paths = SandboxViolationMonitor.noisyReadPaths;
      expect(paths, contains('/System/'));
      expect(paths, contains('/Library/'));
      expect(paths, contains('/Applications/'));
    });

    test('contains Unix system paths', () {
      const paths = SandboxViolationMonitor.noisyReadPaths;
      expect(paths, contains('/usr/lib/'));
      expect(paths, contains('/usr/share/'));
      expect(paths, contains('/usr/bin/'));
    });

    test('contains private system paths', () {
      const paths = SandboxViolationMonitor.noisyReadPaths;
      expect(paths, contains('/private/etc/'));
      expect(paths, contains('/private/var/db/'));
      expect(paths, contains('/private/var/folders/'));
    });

    test('contains native module extension filters', () {
      const paths = SandboxViolationMonitor.noisyReadPaths;
      expect(paths, contains('.node'));
      expect(paths, contains('.dylib'));
      expect(paths, contains('.so'));
    });

    test('contains fsevents noise', () {
      expect(
        SandboxViolationMonitor.noisyReadPaths,
        contains('/.fseventsd'),
      );
    });
  });
}
