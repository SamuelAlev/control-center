import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/backend_registry.dart';
import 'package:cc_infra/src/dispatch/backends/acp_backend.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:test/test.dart';

void main() {
  group('buildBackendRegistry', () {
    test('returns an empty registry for no adapters', () {
      final registry = buildBackendRegistry(adapters: const []);
      expect(registry.handles('cc-harness'), isFalse);
    });

    test('defaults to predefinedAdapters when none provided', () {
      final registry = buildBackendRegistry();
      // cc-harness is a harness-transport predefined adapter.
      expect(registry.handles('cc-harness'), isTrue);
      // claude is a claudeCli-transport predefined adapter.
      expect(registry.handles('claude'), isTrue);
      // Cursor is a harness LLM provider, not a CLI.
      expect(registry.handles('cursor-agent'), isFalse);
    });

    test('maps harness transport to HarnessBackend', () {
      final registry = buildBackendRegistry(
        adapters: [
          const Adapter(
            id: 'x',
            name: 'X',
            description: '',
            cliName: 'h',
            transport: AdapterTransport.harness,
          ),
        ],
      );
      final backend = registry.backendFor('h');
      expect(backend, isA<HarnessBackend>());
      expect((backend as HarnessBackend).cliName, 'h');
    });

    test('maps acp transport to AcpBackend', () {
      final registry = buildBackendRegistry(
        adapters: [
          const Adapter(
            id: 'x',
            name: 'X',
            description: '',
            cliName: 'opencode',
            transport: AdapterTransport.acp,
            acpArgs: 'acp',
          ),
        ],
      );
      final backend = registry.backendFor('opencode');
      expect(backend, isA<AcpBackend>());
      final acp = backend as AcpBackend;
      expect(acp.cliName, 'opencode');
      expect(acp.acpArgs, 'acp');
      // Non-goose ACP backend has no default env.
      expect(acp.defaultEnvironment, isEmpty);
    });

    test('ACP backends start with empty default env', () {
      final registry = buildBackendRegistry(
        adapters: [
          const Adapter(
            id: 'x',
            name: 'X',
            description: '',
            cliName: 'acp-test',
            transport: AdapterTransport.acp,
            acpArgs: 'acp',
          ),
        ],
      );
      final backend = registry.backendFor('acp-test') as AcpBackend;
      expect(backend.defaultEnvironment, isEmpty);
    });

    test('maps claudeCli to ClaudeCliBackend', () {
      final registry = buildBackendRegistry(
        adapters: [
          const Adapter(
            id: 'x',
            name: 'X',
            description: '',
            cliName: 'claude',
            transport: AdapterTransport.claudeCli,
          ),
        ],
      );
      expect(registry.backendFor('claude'), isA<ClaudeCliBackend>());
    });

    test('first adapter wins when cliName collides', () {
      final registry = buildBackendRegistry(
        adapters: [
          const Adapter(
            id: 'first',
            name: 'First',
            description: '',
            cliName: 'shared',
            transport: AdapterTransport.harness,
          ),
          const Adapter(
            id: 'second',
            name: 'Second',
            description: '',
            cliName: 'shared',
            transport: AdapterTransport.claudeCli,
          ),
        ],
      );
      // The harness backend was registered first.
      expect(registry.backendFor('shared'), isA<HarnessBackend>());
    });

    test('handles/backendFor return false/null for unknown cliName', () {
      final registry = buildBackendRegistry(adapters: const []);
      expect(registry.handles('nope'), isFalse);
      expect(registry.backendFor('nope'), isNull);
    });
  });
}
