import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/backend_registry.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
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

    test('the built-in loop resolves to HarnessBackend', () {
      final harness = registry.backendFor('cc-harness');
      expect(harness, isA<HarnessBackend>());
      expect(harness!.transport, AdapterTransport.harness);
    });

    test('Claude resolves to ClaudeCliBackend', () {
      final claude = registry.backendFor('claude');
      expect(claude, isA<ClaudeCliBackend>());
      expect(claude!.transport, AdapterTransport.claudeCli);
    });

    test('Cursor is not a CLI adapter', () {
      expect(registry.backendFor('cursor-agent'), isNull);
      expect(registry.handles('cursor-agent'), isFalse);
    });

    test('unknown cliName resolves to null', () {
      expect(registry.backendFor('nope'), isNull);
      expect(registry.handles('nope'), isFalse);
    });
  });
}
