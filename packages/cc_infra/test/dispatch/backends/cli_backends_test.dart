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
