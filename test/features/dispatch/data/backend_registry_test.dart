import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/backend_registry.dart';
import 'package:cc_infra/src/dispatch/backends/acp_backend.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendRegistry', () {
    final registry = buildBackendRegistry();

    test('maps every predefined cliName to a backend', () {
      for (final adapter in predefinedAdapters) {
        expect(
          registry.backendFor(adapter.cliName),
          isNotNull,
          reason: 'no backend for cliName "${adapter.cliName}"',
        );
      }
    });

    test('ACP adapters resolve to AcpBackend', () {
      expect(registry.backendFor('opencode'), isA<AcpBackend>());
      expect(registry.backendFor('gemini'), isA<AcpBackend>());
      expect(registry.backendFor('goose'), isA<AcpBackend>());
      expect(registry.backendFor('cursor-agent'), isA<AcpBackend>());
      expect(registry.backendFor('codex'), isA<AcpBackend>());
    });

    test('Pi resolves to StructuredCliBackend', () {
      final pi = registry.backendFor('pi');
      expect(pi, isA<StructuredCliBackend>());
      expect(pi!.transport, AdapterTransport.structuredCli);
    });

    test('Claude resolves to RelayBackend', () {
      final claude = registry.backendFor('claude');
      expect(claude, isA<RelayBackend>());
      expect(claude!.transport, AdapterTransport.relay);
    });

    test('unknown cliName resolves to null', () {
      expect(registry.backendFor('nope'), isNull);
      expect(registry.handles('nope'), isFalse);
    });

    test('AcpBackend carries its acpArgs', () {
      expect((registry.backendFor('opencode')! as AcpBackend).acpArgs, 'acp');
      expect((registry.backendFor('gemini')! as AcpBackend).acpArgs, '--acp');
    });

    test('Goose backend contributes GOOSE_MODE env by default', () {
      final goose = registry.backendFor('goose')! as AcpBackend;
      expect(goose.defaultEnv()['GOOSE_MODE'], 'auto');
    });

    test('Pi backend builds the --mode json argv', () {
      final pi = registry.backendFor('pi')! as StructuredCliBackend;
      final args = pi.buildArgs(modelId: 'anthropic/claude-opus-4-7');
      expect(args, contains('--mode'));
      expect(args, contains('json'));
      expect(args, contains('--model'));
      expect(args, contains('anthropic/claude-opus-4-7'));
    });
  });
}
