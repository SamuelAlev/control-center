import 'package:cc_domain/features/mcp/domain/mcp_config.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/mcp/providers/mcp_config_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') {
          return null;
        }
        if (methodCall.method == 'read') {
          return null;
        }
        if (methodCall.method == 'delete') {
          return null;
        }
        return null;
      },
    );
  });

  group('McpConfigNotifier', () {
    test('build returns defaults when no stored prefs', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final config = container.read(mcpConfigProvider);
      expect(config.port, 9020);
      expect(config.token, '');
      expect(config.enabled, true);
    });

    test('build loads stored prefs', () async {
      final prefs = AppPreferences.inMemory({
        'mcp_port': 8080,
        'mcp_token': 'secret-token-123',
        'mcp_enabled': false,
      });
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final config = container.read(mcpConfigProvider);
      expect(config.port, 8080);
      expect(config.token, '');
      expect(config.enabled, false);
    });

    test('setPort updates state and persists', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(mcpConfigProvider.notifier).setPort(9090);

      final config = container.read(mcpConfigProvider);
      expect(config.port, 9090);
      expect(prefs.getInt('mcp_port'), 9090);
    });

    test('setToken with non-empty string updates state and persists', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(mcpConfigProvider.notifier)
          .setToken('new-secret-token');

      final config = container.read(mcpConfigProvider);
      expect(config.token, 'new-secret-token');
    });

    test('setToken with null removes stored value', () async {
      final prefs = AppPreferences.inMemory({'mcp_token': 'old-token'});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(mcpConfigProvider.notifier).setToken(null);

      final config = container.read(mcpConfigProvider);
      expect(config.token, null);
      expect(prefs.getString('mcp_token'), isNull);
    });

    test('setToken with empty string removes stored value', () async {
      final prefs = AppPreferences.inMemory({'mcp_token': 'old-token'});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(mcpConfigProvider.notifier).setToken('');

      final config = container.read(mcpConfigProvider);
      expect(config.token, '');
      expect(prefs.getString('mcp_token'), isNull);
    });

    test('setEnabled with true updates state and persists', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(mcpConfigProvider.notifier)
          .setEnabled(enabled: false);

      final config = container.read(mcpConfigProvider);
      expect(config.enabled, false);
      expect(prefs.getBool('mcp_enabled'), false);

      await container
          .read(mcpConfigProvider.notifier)
          .setEnabled(enabled: true);
      expect(container.read(mcpConfigProvider).enabled, true);
      expect(prefs.getBool('mcp_enabled'), true);
    });

    test('preserves other fields when updating one', () async {
      final prefs = AppPreferences.inMemory({
        'mcp_port': 9999,
        'mcp_token': 'keep-me',
        'mcp_enabled': true,
      });
      final container = ProviderContainer(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(mcpConfigProvider.notifier).setPort(7777);

      final config = container.read(mcpConfigProvider);
      expect(config.port, 7777);
      expect(config.token, '');
      expect(config.enabled, true);
    });
  });

  group('McpConfig', () {
    test('equality and hashCode', () {
      const a = McpConfig(port: 9020, token: 't', enabled: true);
      const b = McpConfig(port: 9020, token: 't', enabled: true);
      const c = McpConfig(port: 8080, token: 't', enabled: true);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
