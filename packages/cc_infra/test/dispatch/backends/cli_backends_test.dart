import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:test/test.dart';

void main() {
  group('ClaudeCliBackend', () {
    test('defaults cliName to "claude"', () {
      const backend = ClaudeCliBackend();
      expect(backend.cliName, 'claude');
    });

    test('declares the claudeCli transport and no acpArgs', () {
      const backend = ClaudeCliBackend(cliName: 'my-claude');
      expect(backend.transport.name, 'claudeCli');
      expect(backend.acpArgs, isNull);
    });

    test('defaultEnv is empty', () {
      const backend = ClaudeCliBackend();
      expect(backend.defaultEnv(), isEmpty);
    });

    group('buildClaudeArgs', () {
      test('includes the core stream-json flags', () {
        final args = ClaudeCliBackend.buildClaudeArgs();
        expect(args, contains('-p'));
        expect(args, contains('--output-format'));
        final i = args.indexOf('--output-format');
        expect(args[i + 1], 'stream-json');
        // Stdin is the steering lane, so input is stream-json too.
        final j = args.indexOf('--input-format');
        expect(args[j + 1], 'stream-json');
        expect(args, contains('--verbose'));
        expect(args, contains('--include-partial-messages'));
      });

      // The session preflights the joined argv as a shell line, so the
      // appended prose must not parse into a denied or prompted command.
      for (final mcpConfigPath in [null, '/control-center.mcp.json']) {
        test('the argv passes preflight with MCP config $mcpConfigPath', () {
          final line = [
            'claude',
            ...ClaudeCliBackend.buildClaudeArgs(mcpConfigPath: mcpConfigPath),
          ].join(' ');
          for (final mode in Mode.values) {
            expect(
              commandPolicyForMode(mode).evaluate(line),
              CommandDecision.allow,
              reason: mode.name,
            );
          }
        });
      }

      test('adds --dangerously-skip-permissions by default', () {
        final args = ClaudeCliBackend.buildClaudeArgs();
        expect(args, contains('--dangerously-skip-permissions'));
      });

      test(
        'omits --dangerously-skip-permissions when skipPermissions=false',
        () {
          final args = ClaudeCliBackend.buildClaudeArgs(skipPermissions: false);
          expect(args, isNot(contains('--dangerously-skip-permissions')));
        },
      );

      test('passes the policy hooks as --settings', () {
        final args = ClaudeCliBackend.buildClaudeArgs(settingsJson: '{"a":1}');
        final i = args.indexOf('--settings');
        expect(args[i + 1], '{"a":1}');
      });

      test('omits --settings without hooks', () {
        expect(
          ClaudeCliBackend.buildClaudeArgs(),
          isNot(contains('--settings')),
        );
      });

      test('adds --model when modelId provided', () {
        final args = ClaudeCliBackend.buildClaudeArgs(modelId: 'opus');
        final i = args.indexOf('--model');
        expect(args[i + 1], 'opus');
      });

      test('omits --model when modelId empty', () {
        final args = ClaudeCliBackend.buildClaudeArgs(modelId: '');
        expect(args.indexOf('--model'), -1);
      });

      test('adds --permission-mode when provided', () {
        final args = ClaudeCliBackend.buildClaudeArgs(permissionMode: 'plan');
        final i = args.indexOf('--permission-mode');
        expect(args[i + 1], 'plan');
      });

      test('omits --permission-mode when empty', () {
        final args = ClaudeCliBackend.buildClaudeArgs(permissionMode: '');
        expect(args.indexOf('--permission-mode'), -1);
      });

      test('adds --mcp-config and --strict-mcp-config when path provided', () {
        final args = ClaudeCliBackend.buildClaudeArgs(mcpConfigPath: '/x.json');
        final i = args.indexOf('--mcp-config');
        expect(args[i + 1], '/x.json');
        expect(args, contains('--strict-mcp-config'));
      });

      test('omits --mcp-config when path empty', () {
        final args = ClaudeCliBackend.buildClaudeArgs(mcpConfigPath: '');
        expect(args.indexOf('--mcp-config'), -1);
        expect(args.indexOf('--strict-mcp-config'), -1);
      });

      test('combines all flags in order', () {
        final args = ClaudeCliBackend.buildClaudeArgs(
          modelId: 'sonnet',
          permissionMode: 'default',
          mcpConfigPath: '/mcp.json',
          skipPermissions: true,
        );
        expect(args.first, '-p');
        expect(args.last, '--dangerously-skip-permissions');
        expect(args, contains('--model'));
        expect(args, contains('--permission-mode'));
        expect(args, contains('--mcp-config'));
      });
    });

    group('buildArgs (instance)', () {
      test('adds --model when modelId provided', () {
        const backend = ClaudeCliBackend();
        final args = backend.buildArgs(modelId: 'opus');
        final i = args.indexOf('--model');
        expect(args[i + 1], 'opus');
      });

      test('adds --effort when effortLevel provided', () {
        const backend = ClaudeCliBackend();
        final args = backend.buildArgs(effortLevel: 'high');
        final i = args.indexOf('--effort');
        expect(args[i + 1], 'high');
      });

      test('returns empty when nothing provided', () {
        const backend = ClaudeCliBackend();
        expect(backend.buildArgs(), isEmpty);
      });
    });

    group('buildClaudeArgs effort', () {
      test('omits --effort when no effort is configured', () {
        expect(ClaudeCliBackend.buildClaudeArgs(), isNot(contains('--effort')));
      });

      test('passes a supported explicit effort through', () {
        final args = ClaudeCliBackend.buildClaudeArgs(effortLevel: 'high');
        final i = args.indexOf('--effort');
        expect(args[i + 1], 'high');
      });

      test('maps minimal up to the CLI floor (low)', () {
        final args = ClaudeCliBackend.buildClaudeArgs(effortLevel: 'minimal');
        final i = args.indexOf('--effort');
        expect(args[i + 1], 'low');
      });

      test('maps xhigh through', () {
        final args = ClaudeCliBackend.buildClaudeArgs(effortLevel: 'xhigh');
        expect(args[args.indexOf('--effort') + 1], 'xhigh');
      });

      test('omits an unrecognized effort rather than failing the launch', () {
        expect(
          ClaudeCliBackend.buildClaudeArgs(effortLevel: 'ludicrous'),
          isNot(contains('--effort')),
        );
      });

      test('omits --effort on a binary that does not advertise it', () {
        final args = ClaudeCliBackend.buildClaudeArgs(
          effortLevel: 'high',
          capabilities: ClaudeCliCapabilities.minimal,
        );
        expect(args, isNot(contains('--effort')));
      });

      test('omits a level the binary does not advertise', () {
        final args = ClaudeCliBackend.buildClaudeArgs(
          effortLevel: 'xhigh',
          capabilities: const ClaudeCliCapabilities(
            supportsEffort: true,
            supportsResume: true,
            supportsSessionId: true,
            effortValues: {'low', 'medium', 'high'},
          ),
        );
        expect(args, isNot(contains('--effort')));
      });
    });

    group('buildClaudeArgs resume', () {
      test('resumes with an EXPLICIT session id, never --continue', () {
        final args = ClaudeCliBackend.buildClaudeArgs(
          resumeSessionId: 'sess-abc',
        );
        final i = args.indexOf('--resume');
        expect(args[i + 1], 'sess-abc');
        expect(args, isNot(contains('--continue')));
        expect(args, isNot(contains('-c')));
      });

      test('never resumes without an id', () {
        final args = ClaudeCliBackend.buildClaudeArgs();
        expect(args, isNot(contains('--resume')));
        expect(args, isNot(contains('--continue')));
      });

      test('omits --resume on a binary that does not support it', () {
        final args = ClaudeCliBackend.buildClaudeArgs(
          resumeSessionId: 'sess-abc',
          capabilities: ClaudeCliCapabilities.minimal,
        );
        expect(args, isNot(contains('--resume')));
      });

      test('never adds --bare, --continue or --fork-session', () {
        // `--bare` skips hooks and the subscription login the PreToolUse
        // enforcement depends on; `--continue` picks "the latest session in
        // this directory", which is unsafe with two conversations; nothing
        // here forks or rewrites Claude's own history.
        final args = ClaudeCliBackend.buildClaudeArgs(
          resumeSessionId: 'sess-abc',
        );
        expect(args, isNot(contains('--bare')));
        expect(args, isNot(contains('--continue')));
        expect(args, isNot(contains('--fork-session')));
      });
    });

    group('claudeEffortValue', () {
      test('maps every platform effort id to a Claude value', () {
        expect(ClaudeCliBackend.claudeEffortValue('minimal'), 'low');
        expect(ClaudeCliBackend.claudeEffortValue('low'), 'low');
        expect(ClaudeCliBackend.claudeEffortValue('medium'), 'medium');
        expect(ClaudeCliBackend.claudeEffortValue('high'), 'high');
        expect(ClaudeCliBackend.claudeEffortValue('xhigh'), 'xhigh');
        expect(ClaudeCliBackend.claudeEffortValue('max'), 'max');
      });

      test('accepts aliases', () {
        expect(ClaudeCliBackend.claudeEffortValue('none'), 'low');
        expect(ClaudeCliBackend.claudeEffortValue('mid'), 'medium');
        expect(ClaudeCliBackend.claudeEffortValue('extra-high'), 'xhigh');
      });

      test('is case/whitespace tolerant', () {
        expect(ClaudeCliBackend.claudeEffortValue('  HIGH '), 'high');
      });

      test('returns null for null or unknown input', () {
        expect(ClaudeCliBackend.claudeEffortValue(null), isNull);
        expect(ClaudeCliBackend.claudeEffortValue(''), isNull);
        expect(ClaudeCliBackend.claudeEffortValue('nope'), isNull);
      });

      test('returns null when the binary has no --effort at all', () {
        expect(
          ClaudeCliBackend.claudeEffortValue(
            'high',
            ClaudeCliCapabilities.minimal,
          ),
          isNull,
        );
      });
    });

    group('ClaudeCliCapabilities.fromHelp', () {
      // The real 2.1.293 help lines (trimmed).
      const realHelp = '''
  --effort <level>                      Effort level for the current session
                                        (low, medium, high, xhigh, max)
  -r, --resume [value]                  Resume a conversation by session ID
  --session-id <uuid>                   Use a specific session ID
  --output-format <format>              Output format
''';

      test('reads the flags and the advertised effort levels', () {
        final caps = ClaudeCliCapabilities.fromHelp(realHelp)!;
        expect(caps.supportsEffort, isTrue);
        expect(caps.supportsResume, isTrue);
        expect(caps.supportsSessionId, isTrue);
        expect(caps.effortValues, {'low', 'medium', 'high', 'xhigh', 'max'});
      });

      test('an older help without --effort reads as effort-unsupported', () {
        final caps = ClaudeCliCapabilities.fromHelp('''
  --output-format <format>   Output format
  --permission-mode <mode>   Permission mode
''')!;
        expect(caps.supportsEffort, isFalse);
        expect(caps.effortValues, isEmpty);
      });

      test('unrecognized output is not read as "supports nothing"', () {
        expect(ClaudeCliCapabilities.fromHelp('--help'), isNull);
        expect(ClaudeCliCapabilities.fromHelp(''), isNull);
        expect(
          ClaudeCliCapabilities.fromHelp('zsh: command not found'),
          isNull,
        );
      });

      test('reads the choices when they wrap onto the next line', () {
        // A NARROWER advertised list than the baseline: if the wrapped line were
        // not read, the parser would substitute every baseline value and let an
        // unsupported `xhigh` through.
        const wrapped = '''
  --effort <level>                      Effort level for the current session
                                        (low, medium, high)
  --output-format <format>              Output format
''';
        final caps = ClaudeCliCapabilities.fromHelp(wrapped)!;
        expect(caps.effortValues, {'low', 'medium', 'high'});
        expect(caps.supportsEffortValue('xhigh'), isFalse);
        expect(
          ClaudeCliBackend.buildClaudeArgs(
            effortLevel: 'xhigh',
            capabilities: caps,
          ),
          isNot(contains('--effort')),
        );
        // A supported level in the same narrow list still goes through.
        expect(
          ClaudeCliBackend.buildClaudeArgs(
            effortLevel: 'high',
            capabilities: caps,
          ),
          contains('--effort'),
        );
      });

      test('stops the choices search at the next option', () {
        // A later option's parentheses must not be mistaken for the effort
        // list, which would widen the capability set.
        const help = '''
  --effort <level>                      Effort level for the current session
  --output-format <format>              Output format (text, json, stream-json)
''';
        expect(ClaudeCliCapabilities.fromHelp(help)!.effortValues, {
          'low',
          'medium',
          'high',
          'xhigh',
          'max',
        });
      });

      test('session totals require a separate 2.1.277+ version probe', () {
        const help = '''
  --effort <level>                      Effort level (low, medium, high)
  --resume [value]                      Resume a conversation
  --output-format <format>              Output format
''';
        // Help proves the resume FLAG only, even if a wrapper happens to echo
        // version text there. Only a successful --version probe proves totals.
        expect(ClaudeCliCapabilities.fromHelp(help)!.supportsResume, isTrue);
        expect(
          ClaudeCliCapabilities.fromHelp(
            '2.1.293 (Claude Code)\n$help',
          )!.restoresSessionTotals,
          isFalse,
        );
        expect(
          ClaudeCliCapabilities.restoresSessionTotalsForVersion(
            ClaudeCliCapabilities.versionOf('2.1.276 (Claude Code)'),
          ),
          isFalse,
        );
        expect(
          ClaudeCliCapabilities.restoresSessionTotalsForVersion(
            ClaudeCliCapabilities.versionOf('2.1.277 (Claude Code)'),
          ),
          isTrue,
        );
        expect(
          ClaudeCliCapabilities.restoresSessionTotalsForVersion(
            ClaudeCliCapabilities.versionOf('2.1.293 (Claude Code)'),
          ),
          isTrue,
        );
        expect(
          ClaudeCliCapabilities.restoresSessionTotalsForVersion(null),
          isFalse,
        );
      });

      test('baseline is the documented pinned-CLI set', () {
        expect(ClaudeCliCapabilities.baseline.supportsEffort, isTrue);
        expect(ClaudeCliCapabilities.baseline.supportsResume, isTrue);
        expect(
          ClaudeCliCapabilities.baseline.supportsEffortValue('xhigh'),
          isTrue,
        );
      });
    });
  });
}
