import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_discovery.dart';
import 'package:control_center/core/server/server_startup_status.dart';
import 'package:control_center/shared/widgets/connection_error_alert.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoServerDiscovery extends ServerDiscovery {
  const _NoServerDiscovery();

  @override
  Stream<List<DiscoveredServer>> watch({
    Duration timeout = const Duration(seconds: 3),
  }) => const Stream.empty();
}

void main() {
  setUp(() => serverStartupStatus.value = null);
  tearDown(() => serverStartupStatus.value = null);

  for (final mode in ServerConnectionMode.values) {
    testWidgets('switching away from $mode clears its connection error', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = ServerConnectionStore(
        AppPreferences.inMemory(),
        SecureStore.inMemory(),
      );
      await store.setMode(mode);
      await tester.pumpWidget(
        ProviderScope(
          child: ServerSetupApp(
            store: store,
            initialError: const UserFacingMessage('Earlier attempt failed'),
            previousSessionClosed: null,
            onResolved: (_) => fail('Selecting a mode must not connect'),
            discovery: const _NoServerDiscovery(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Earlier attempt failed'), findsOneWidget);

      final selectedLabel = mode == ServerConnectionMode.local
          ? 'Run in this app'
          : 'Connect to a remote instance';
      final otherLabel = mode == ServerConnectionMode.local
          ? 'Connect to a remote instance'
          : 'Run in this app';
      await tester.tap(find.text(selectedLabel).first);
      await tester.pump();
      expect(find.text('Earlier attempt failed'), findsOneWidget);

      await tester.tap(find.text(otherLabel).first);
      await tester.pump();
      expect(find.byType(ConnectionErrorAlert), findsNothing);

      await tester.tap(find.text(selectedLabel).first);
      await tester.pump();
      expect(find.byType(ConnectionErrorAlert), findsNothing);
      expect(store.readMode(), mode, reason: 'A selection is not a connection');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('setup keeps connection failures in the callout, not activity', (
    tester,
  ) async {
    final store = ServerConnectionStore(
      AppPreferences.inMemory(),
      SecureStore.inMemory(),
    );
    await store.setMode(ServerConnectionMode.remote);
    const failure = UserFacingMessage('Remote server unavailable');
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.failed,
      error: failure,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: ServerSetupApp(
          store: store,
          initialError: failure,
          previousSessionClosed: null,
          onResolved: (_) => fail('No connection attempted'),
          discovery: const _NoServerDiscovery(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionErrorAlert), findsOneWidget);
    expect(find.text('Remote server unavailable'), findsOneWidget);
    expect(find.text('Server activity'), findsNothing);

    await tester.tap(find.text('Run in this app').first);
    await tester.pump();
    expect(serverStartupStatus.value, isNull);
    expect(find.byType(ConnectionErrorAlert), findsNothing);
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.starting,
    );
    await tester.pump();
    expect(find.text('Starting local server…'), findsOneWidget);
    serverStartupStatus.value = const ServerStartupStatus(
      phase: ServerStartupPhase.ready,
    );
    await tester.pump();
    expect(find.text('Server activity'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
