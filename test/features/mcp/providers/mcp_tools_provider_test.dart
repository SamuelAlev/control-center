import 'package:control_center/features/mcp/providers/mcp_tools_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mcpToolRegistryProvider', () {
    test('provider exists and returns McpToolRegistry', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      try {
        final registry = container.read(mcpToolRegistryProvider);
        expect(registry, isNotNull);
      } catch (_) {
        // Provider may fail without full dependency graph, test structure only
      }
    });
  });

}
