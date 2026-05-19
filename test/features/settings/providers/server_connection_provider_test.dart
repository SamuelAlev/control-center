import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/features/settings/providers/server_connection_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ServerConnectionStore _storeOf(ProviderContainer container) =>
    ServerConnectionStore(
      container.read(appPreferencesProvider),
      container.read(secureStoreProvider),
    );

ServerEntry _entry(String serverId) => ServerEntry(
  descriptor: ConnectionDescriptor(
    serverId: serverId,
    serverName: 'Test $serverId',
    fingerprint: 'fp-$serverId',
    paths: [const LanPath(host: '192.168.1.10', port: 9030, tls: false)],
  ),
  deviceId: 'device-1',
);

void main() {
  group('ServerListNotifier.switchTo', () {
    test('succeeds when the switch replaces its own container', () async {
      // What both bootstraps do on a successful switch: adopt the new session
      // and rebuild the app around it, which disposes the container this
      // notifier (and the settings screen that called it) lives in. Anything
      // the notifier touches on `state` afterwards throws a "Ref used after
      // dispose" StateError — which the settings UI reported as
      // "Could not switch server" even though the switch had succeeded.
      late ProviderContainer container;
      var switched = 0;
      container = ProviderContainer(
        overrides: [
          serverSwitchHandlerProvider.overrideWithValue((serverId) async {
            switched++;
            container.dispose();
          }),
        ],
      );

      await container.read(serverListProvider.notifier).switchTo('local');

      expect(switched, 1);
    });

    test('clears the busy flag when the switch fails', () async {
      final container = ProviderContainer(
        overrides: [
          serverSwitchHandlerProvider.overrideWithValue(
            (serverId) async => throw StateError('unreachable'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(serverListProvider.notifier);

      await expectLater(notifier.switchTo('srv-a'), throwsStateError);

      expect(container.read(serverListProvider).busy, isFalse);
    });

    test('re-reads the choice the switch handler persisted', () async {
      // The handler owns persistence (desktop: `resolveServerBackend`, web:
      // the connect gate's `_switchTo`); the notifier only reflects it.
      late ProviderContainer container;
      container = ProviderContainer(
        overrides: [
          serverSwitchHandlerProvider.overrideWithValue((serverId) async {
            final store = _storeOf(container);
            await store.setMode(ServerConnectionMode.remote);
            await store.setActiveServer(serverId);
          }),
        ],
      );
      addTearDown(container.dispose);
      await _storeOf(container).upsertEntry(_entry('srv-a'));

      await container.read(serverListProvider.notifier).switchTo('srv-a');

      final state = container.read(serverListProvider);
      expect(state.currentServerId, 'srv-a');
      expect(state.busy, isFalse);
    });
  });
}
