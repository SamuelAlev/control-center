import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:test/test.dart';

void main() {
  group('StructuredCliBackend', () {
    test('declares the structuredCli transport and no acpArgs', () {
      const backend = StructuredCliBackend(cliName: 'pi');
      expect(backend.cliName, 'pi');
      expect(backend.transport.name, 'structuredCli');
      expect(backend.acpArgs, isNull);
    });

    test('defaultEnv is empty', () {
      const backend = StructuredCliBackend(cliName: 'pi');
      expect(backend.defaultEnv(), isEmpty);
    });

    test('buildArgs emits --mode json + system prompt constraint', () {
      const backend = StructuredCliBackend(cliName: 'pi');
      final args = backend.buildArgs();
      expect(args, contains('--mode'));
      expect(args, contains('json'));
      expect(args, contains('--append-system-prompt'));
      final constraintIndex = args.indexOf('--append-system-prompt');
      expect(args[constraintIndex + 1], contains('JSON'));
    });

    test('buildArgs appends --model when modelId provided', () {
      const backend = StructuredCliBackend(cliName: 'pi');
      final args = backend.buildArgs(modelId: 'gpt-4');
      final i = args.indexOf('--model');
      expect(args[i + 1], 'gpt-4');
    });

    test('buildArgs omits --model when modelId empty', () {
      const backend = StructuredCliBackend(cliName: 'pi');
      final args = backend.buildArgs(modelId: '');
      expect(args.indexOf('--model'), -1);
    });

    test('buildArgs appends --thinking when effortLevel provided', () {
      const backend = StructuredCliBackend(cliName: 'pi');
      final args = backend.buildArgs(effortLevel: 'high');
      final i = args.indexOf('--thinking');
      expect(args[i + 1], 'high');
    });

    test('buildArgs omits --thinking when effortLevel empty', () {
      const backend = StructuredCliBackend(cliName: 'pi');
      final args = backend.buildArgs(effortLevel: '');
      expect(args.indexOf('--thinking'), -1);
    });

    test('buildArgs honors a custom jsonModeConstraint', () {
      const backend = StructuredCliBackend(
        cliName: 'pi',
        jsonModeConstraint: 'Custom constraint',
      );
      final args = backend.buildArgs();
      expect(args, contains('Custom constraint'));
    });
  });

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
        expect(args, contains('--verbose'));
        expect(args, contains('--include-partial-messages'));
      });

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
  });
}
