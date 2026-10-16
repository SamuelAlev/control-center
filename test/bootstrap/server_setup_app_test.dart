import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:control_center/core/server/server_discovery.dart';
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
}
