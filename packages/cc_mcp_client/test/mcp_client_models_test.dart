import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

void main() {
  group('McpServerLifecycle', () {
    test('wire <-> fromWire round-trips every value', () {
      for (final v in McpServerLifecycle.values) {
        expect(McpServerLifecycle.fromWire(v.wire), v, reason: v.name);
      }
    });

    test('fromWire defaults unknown to disabled', () {
      expect(McpServerLifecycle.fromWire(null), McpServerLifecycle.disabled);
      expect(McpServerLifecycle.fromWire('nonsense'), McpServerLifecycle.disabled);
    });
  });

  group('McpServerStatusSnapshot', () {
    test('round-trips through toJson/fromJson incl. auth', () {
      const snap = McpServerStatusSnapshot(
        name: 'sentry',
        transport: 'sse',
        lifecycle: McpServerLifecycle.connected,
        auth: 'oauth',
        toolCount: 5,
        resourceCount: 2,
        promptCount: 0,
        source: 'vscode',
        lastError: null,
      );
      final back = McpServerStatusSnapshot.fromJson(snap.toJson());
      expect(back.name, snap.name);
      expect(back.transport, snap.transport);
      expect(back.lifecycle, snap.lifecycle);
      expect(back.auth, snap.auth);
      expect(back.toolCount, snap.toolCount);
      expect(back.resourceCount, snap.resourceCount);
      expect(back.promptCount, snap.promptCount);
      expect(back.source, snap.source);
    });

    test('auth defaults to none', () {
      const snap = McpServerStatusSnapshot(
        name: 's',
        transport: 'stdio',
        lifecycle: McpServerLifecycle.disabled,
        toolCount: 0,
        resourceCount: 0,
        promptCount: 0,
      );
      expect(snap.auth, 'none');
      expect(snap.toJson()['auth'], 'none');
    });
  });
}
