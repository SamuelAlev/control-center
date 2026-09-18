import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/synced_preferences.dart';
import 'package:control_center/features/rigs/providers/rig_clipboard_permissions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RigClipboardSessionGrants', () {
    test('scopes a ten-minute grant to one rig and direction', () {
      var now = DateTime.utc(2026, 1, 1, 12);
      final grants = RigClipboardSessionGrants(now: () => now);

      grants.allowForTenMinutes('rig-a', RigClipboardDirection.hostToRig);

      expect(grants.allows('rig-a', RigClipboardDirection.hostToRig), isTrue);
      expect(grants.allows('rig-a', RigClipboardDirection.rigToHost), isFalse);
      expect(grants.allows('rig-b', RigClipboardDirection.hostToRig), isFalse);

      now = now.add(const Duration(minutes: 9, seconds: 59));
      expect(grants.allows('rig-a', RigClipboardDirection.hostToRig), isTrue);
      now = now.add(const Duration(seconds: 1));
      expect(grants.allows('rig-a', RigClipboardDirection.hostToRig), isFalse);
    });
  });

  group('rigClipboardPreferencesProvider', () {
    test(
      'defaults paste on and copy out off, then persists overrides',
      () async {
        final preferences = AppPreferences.inMemory();
        final container = ProviderContainer(
          overrides: [appPreferencesProvider.overrideWithValue(preferences)],
        );
        addTearDown(container.dispose);

        final defaults = container.read(rigClipboardPreferencesProvider);
        expect(defaults.alwaysAllowHostToRig, isTrue);
        expect(defaults.alwaysAllowRigToHost, isFalse);

        await container
            .read(rigClipboardPreferencesProvider.notifier)
            .setAlwaysAllowed(RigClipboardDirection.hostToRig, allowed: false);
        await container
            .read(rigClipboardPreferencesProvider.notifier)
            .setAlwaysAllowed(RigClipboardDirection.rigToHost, allowed: true);

        final overridden = container.read(rigClipboardPreferencesProvider);
        expect(overridden.alwaysAllowHostToRig, isFalse);
        expect(overridden.alwaysAllowRigToHost, isTrue);
        expect(preferences.getBool(rigClipboardHostToRigAlwaysKey), isFalse);
        expect(preferences.getBool(rigClipboardRigToHostAlwaysKey), isTrue);
      },
    );

    test('registers durable choices for user preference sync', () {
      final syncedKeys = buildSyncedPreferences()
          .map((item) => item.key)
          .toSet();

      expect(syncedKeys, contains(rigClipboardHostToRigAlwaysKey));
      expect(syncedKeys, contains(rigClipboardRigToHostAlwaysKey));
    });
  });
}
