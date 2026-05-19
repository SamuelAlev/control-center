import 'dart:convert';

import 'package:cc_infra/src/sandboxing/violation_monitor.dart';
import 'package:test/test.dart';

/// Exercises the `@visibleForTesting` static helpers on [SandboxViolationMonitor]:
/// [SandboxViolationMonitor.parseLogLine] (the macOS `log stream` NDJSON →
/// [ParsedLine] decoder), [SandboxViolationMonitor.isNoise] (the
/// agent-process + action + path allowlist), and
/// [SandboxViolationMonitor.suggestCapability] (the action → capability
/// mapping).
void main() {
  /// Builds a macOS-style sandbox log NDJSON line carrying [message] in its
  /// `eventMessage` field.
  String logLine(String message) =>
      jsonEncode({'eventMessage': message, 'senderName': 'Sandbox'});

  group('parseLogLine', () {
    test('returns null for an empty string', () {
      expect(SandboxViolationMonitor.parseLogLine(''), isNull);
    });

    test('returns null for non-JSON input', () {
      expect(SandboxViolationMonitor.parseLogLine('not json'), isNull);
    });

    test('returns null when there is no deny(ies) marker', () {
      expect(
        SandboxViolationMonitor.parseLogLine(
          logLine('Sandbox: pi(1) something-else'),
        ),
        isNull,
      );
    });

    test('returns null when the deny marker has no trailing action', () {
      expect(
        SandboxViolationMonitor.parseLogLine(logLine('Sandbox: pi(1) deny(1)')),
        isNull,
      );
    });

    test('parses a file-read denial with process name', () {
      final parsed = SandboxViolationMonitor.parseLogLine(
        logLine('Sandbox: pi(123) deny(1) file-read-data /Library/foo'),
      );
      expect(parsed, isNotNull);
      expect(parsed!.processName, 'pi');
      expect(parsed.violation.action, 'file-read-data');
      expect(parsed.violation.target, '/Library/foo');
      expect(parsed.violation.raw, isNotNull);
    });

    test('parses a network denial and resolves the process name', () {
      final parsed = SandboxViolationMonitor.parseLogLine(
        logLine('Sandbox: node(42) deny network-outbound github.com'),
      );
      expect(parsed, isNotNull);
      expect(parsed!.processName, 'node');
      expect(parsed.violation.action, 'network-outbound');
      expect(parsed.violation.target, 'github.com');
    });

    test('returns a null processName when the proc matcher misses', () {
      final parsed = SandboxViolationMonitor.parseLogLine(
        logLine('deny file-write-create /Users/x'),
      );
      expect(parsed, isNotNull);
      expect(parsed!.processName, isNull);
      expect(parsed.violation.action, 'file-write-create');
    });

    test('joins a multi-word target', () {
      final parsed = SandboxViolationMonitor.parseLogLine(
        logLine('Sandbox: bash(1) deny(2) file-read-data /a /b /c'),
      );
      expect(parsed!.violation.target, '/a /b /c');
    });
  });

  group('suggestCapability', () {
    test('network → github.com resolves to canCallGitHubApi', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'network-outbound',
          'github.com',
        ),
        'canCallGitHubApi',
      );
    });

    test('network → other host resolves to canAccessNetwork', () {
      expect(
        SandboxViolationMonitor.suggestCapability(
          'network-outbound',
          'example.com',
        ),
        'canAccessNetwork',
      );
    });

    test('non-network action resolves to null', () {
      expect(
        SandboxViolationMonitor.suggestCapability('file-read-data', '/x'),
        isNull,
      );
    });
  });

  group('isNoise', () {
    ParsedLine parsed({
      String? processName = 'pi',
      required String action,
      required String target,
    }) {
      return ParsedLine(
        processName: processName,
        violation: SandboxViolationMonitor.parseLogLine(
          logLine('Sandbox: pi(1) deny(1) $action $target'),
        )!.violation,
      );
    }

    test('drops denials from non-agent processes', () {
      expect(
        SandboxViolationMonitor.isNoise(
          parsed(processName: 'Cursor', action: 'file-read-data', target: '/x'),
        ),
        isTrue,
      );
    });

    test('drops denials with no process name', () {
      expect(
        SandboxViolationMonitor.isNoise(
          parsed(processName: null, action: 'file-read-data', target: '/x'),
        ),
        isTrue,
      );
    });

    test('keeps a file-write from an agent process', () {
      expect(
        SandboxViolationMonitor.isNoise(
          parsed(action: 'file-write-create', target: '/Users/x'),
        ),
        isFalse,
      );
    });

    test('drops mach-lookup actions wholesale', () {
      expect(
        SandboxViolationMonitor.isNoise(
          parsed(action: 'mach-lookup', target: 'com.apple.xpc.foo'),
        ),
        isTrue,
      );
    });

    test('drops user-preference-write actions', () {
      expect(
        SandboxViolationMonitor.isNoise(
          parsed(action: 'user-preference-write', target: '/x'),
        ),
        isTrue,
      );
    });

    test('drops system-* actions', () {
      expect(
        SandboxViolationMonitor.isNoise(
          parsed(action: 'system-fsctl', target: '/x'),
        ),
        isTrue,
      );
    });

    test('drops file-read denials on noisy system paths', () {
      for (final path in [
        '/System/Library/foo',
        '/usr/lib/bar',
        '/usr/share/baz',
        '/usr/bin/git',
        '/Library/Fonts',
        '/Applications/Safari.app',
        '/private/etc/hosts',
      ]) {
        expect(
          SandboxViolationMonitor.isNoise(
            parsed(action: 'file-read-data', target: path),
          ),
          isTrue,
          reason: '$path should be filtered as framework noise',
        );
      }
    });

    test('keeps file-read denials on user paths', () {
      expect(
        SandboxViolationMonitor.isNoise(
          parsed(action: 'file-read-data', target: '/Users/me/proj/file.txt'),
        ),
        isFalse,
      );
    });

    test('drops file-read of paths starting with native-module suffixes', () {
      // The noisy-path matcher uses startsWith, so the suffix entries only
      // fire when the target literally begins with the suffix string.
      for (final suffix in ['.dylib', '.node', '.so']) {
        expect(
          SandboxViolationMonitor.isNoise(
            parsed(action: 'file-read-data', target: suffix),
          ),
          isTrue,
          reason: '$suffix should be filtered',
        );
      }
    });
  });

  group('visibleForTesting constants', () {
    test('agentProcesses covers common agent binaries', () {
      expect(SandboxViolationMonitor.agentProcesses, contains('pi'));
      expect(SandboxViolationMonitor.agentProcesses, contains('node'));
      expect(SandboxViolationMonitor.agentProcesses, contains('git'));
      expect(SandboxViolationMonitor.agentProcesses, contains('python3'));
    });

    test('noisyReadPaths covers system + native-module dirs', () {
      expect(SandboxViolationMonitor.noisyReadPaths, contains('/System/'));
      expect(SandboxViolationMonitor.noisyReadPaths, contains('.dylib'));
    });
  });
}
