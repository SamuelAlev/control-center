import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_rpc_client.dart';

/// Fixes the active workspace so [MyPresenceNotifier] always has somewhere to
/// publish to, without depending on the real Drift-backed bootstrap stream.
class _FixedActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

/// The clock/timer seam: every cadence is shortened to millisecond scale so
/// these tests exercise real timers without waiting out the real 10s
/// heartbeat / 5-minute idle timeout / 5s typing-clear window.
class _FastMyPresenceNotifier extends MyPresenceNotifier {
  @override
  Duration get heartbeatInterval => const Duration(milliseconds: 30);

  @override
  Duration get idleTimeout => const Duration(milliseconds: 60);

  @override
  Duration get typingClearDelay => const Duration(milliseconds: 40);

  @override
  Duration get coalesceWindow => const Duration(milliseconds: 5);
}

void main() {
  late FakeRpcHost host;
  late List<Map<String, dynamic>> publishedArgs;

  ProviderContainer makeContainer() {
    host = FakeRpcHost()
      ..onCall = (op, args) {
        if (op == 'presence.update') {
          publishedArgs.add(args);
        }
        return <String, dynamic>{};
      };
    final container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWithValue(host.client()),
        activeWorkspaceIdProvider.overrideWith(_FixedActiveWorkspaceId.new),
        appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
        myPresenceProvider.overrideWith(_FastMyPresenceNotifier.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    publishedArgs = [];
  });

  test('publishes on init and heartbeats on the configured cadence', () async {
    final container = makeContainer();
    container.read(myPresenceProvider); // Drives build().
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(publishedArgs, isNotEmpty, reason: 'initial publish should land');
    final afterInit = publishedArgs.length;
    expect(
      (publishedArgs.last['presence'] as Map)['a'],
      'online',
      reason: 'default availability is online',
    );

    // 100ms at a 30ms heartbeat interval should tick several more times.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(publishedArgs.length, greaterThan(afterInit));
  });

  test(
    'do-not-disturb publishes offline once and suspends the heartbeat',
    () async {
      final container = makeContainer();
      container.read(myPresenceProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      publishedArgs.clear();

      await container.read(myPresenceProvider.notifier).setDnd(true);
      expect(publishedArgs, hasLength(1));
      expect(publishedArgs.single['presence'], {'a': 'offline'});
      expect(container.read(myPresenceProvider).dnd, isTrue);

      // No further heartbeats while DND is on, even after several intervals.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(publishedArgs, hasLength(1));

      // Re-enabling resumes publishing.
      await container.read(myPresenceProvider.notifier).setDnd(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(publishedArgs.length, greaterThan(1));
      expect(container.read(myPresenceProvider).dnd, isFalse);
    },
  );

  test('typing clears itself after the inactivity window', () async {
    final container = makeContainer();
    container.read(myPresenceProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    container.read(myPresenceProvider.notifier).setTyping('chan-1');
    expect(container.read(myPresenceProvider).typingSpaceId, 'chan-1');

    // Still typing shortly before the 40ms clear delay elapses.
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(container.read(myPresenceProvider).typingSpaceId, 'chan-1');

    // Cleared automatically once the inactivity window passes.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(container.read(myPresenceProvider).typingSpaceId, isNull);
  });

  test(
    'setTyping(null) clears immediately without waiting for the timer',
    () async {
      final container = makeContainer();
      container.read(myPresenceProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      container.read(myPresenceProvider.notifier).setTyping('chan-1');
      expect(container.read(myPresenceProvider).typingSpaceId, 'chan-1');

      container.read(myPresenceProvider.notifier).setTyping(null);
      expect(container.read(myPresenceProvider).typingSpaceId, isNull);
    },
  );
}
