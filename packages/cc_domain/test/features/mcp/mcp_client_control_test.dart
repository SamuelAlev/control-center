import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:test/test.dart';

void main() {
  group('McpExternalServerInfo', () {
    test('round-trips through toJson/fromJson', () {
      const info = McpExternalServerInfo(
        name: 'github',
        transport: 'http',
        lifecycle: 'needs_auth',
        auth: 'oauth',
        toolCount: 3,
        resourceCount: 1,
        promptCount: 2,
        source: 'cursor',
        lastError: '401 unauthorized',
      );
      expect(McpExternalServerInfo.fromJson(info.toJson()), info);
    });

    test('defaults missing/optional fields safely', () {
      final info = McpExternalServerInfo.fromJson(const {'name': 'local'});
      expect(info.name, 'local');
      expect(info.transport, 'stdio');
      expect(info.lifecycle, 'disabled');
      expect(info.auth, 'none');
      expect(info.toolCount, 0);
      expect(info.source, isNull);
      expect(info.lastError, isNull);
    });

    test('convenience getters reflect lifecycle + auth', () {
      const connected = McpExternalServerInfo(
        name: 's',
        transport: 'stdio',
        lifecycle: 'connected',
        auth: 'none',
      );
      expect(connected.isConnected, isTrue);
      expect(connected.needsAuth, isFalse);
      expect(connected.usesOAuth, isFalse);

      const needsAuth = McpExternalServerInfo(
        name: 's',
        transport: 'http',
        lifecycle: 'needs_client_registration',
        auth: 'oauth',
      );
      expect(needsAuth.isConnected, isFalse);
      expect(needsAuth.needsAuth, isTrue);
      expect(needsAuth.usesOAuth, isTrue);
    });

    test('omits null source/lastError from the wire map', () {
      const info = McpExternalServerInfo(
        name: 's',
        transport: 'stdio',
        lifecycle: 'connected',
        auth: 'none',
      );
      final json = info.toJson();
      expect(json.containsKey('source'), isFalse);
      expect(json.containsKey('last_error'), isFalse);
    });
  });
}
