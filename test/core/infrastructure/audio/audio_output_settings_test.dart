import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderContainer _container(AppPreferences prefs) {
  final container = ProviderContainer(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('mediaKitVolume', () {
    // The bug this pins: notification chimes called `setVolume(volume)` with
    // the stored 0..1 preference, which libmpv read as 1% — the sound played
    // and could not be heard.
    test('scales a 0..1 preference onto media_kit\'s 0-100 range', () {
      expect(mediaKitVolume(1), 100.0);
      expect(mediaKitVolume(0.5), 50.0);
      expect(mediaKitVolume(0), 0.0);
    });

    test('clamps out-of-range input rather than passing it to mpv', () {
      expect(mediaKitVolume(1.5), 100.0);
      expect(mediaKitVolume(-1), 0.0);
    });
  });

  group('selectedAudioOutputDevice', () {
    test('maps null to mpv auto (the system default)', () {
      expect(selectedAudioOutputDevice(null).name, 'auto');
    });

    test('maps a stored name to that device', () {
      expect(selectedAudioOutputDevice('coreaudio/7').name, 'coreaudio/7');
    });
  });

  group('AudioOutputDeviceNotifier', () {
    test('reads the app-wide key', () {
      final prefs = AppPreferences.inMemory({
        audioOutputDeviceKey: 'coreaudio/7',
      });

      expect(_container(prefs).read(audioOutputDeviceProvider), 'coreaudio/7');
    });

    test('defaults to null (system default) with nothing stored', () {
      expect(
        _container(AppPreferences.inMemory()).read(audioOutputDeviceProvider),
        isNull,
      );
    });

    // Widening the setting from soundscape-only to app-wide must not silently
    // reset a selection someone already made.
    test('migrates a selection stored under the legacy soundscape key', () {
      final prefs = AppPreferences.inMemory({
        legacySoundscapeOutputDeviceKey: 'coreaudio/3',
      });

      expect(_container(prefs).read(audioOutputDeviceProvider), 'coreaudio/3');
    });

    test('prefers the app-wide key when both are present', () {
      final prefs = AppPreferences.inMemory({
        audioOutputDeviceKey: 'coreaudio/new',
        legacySoundscapeOutputDeviceKey: 'coreaudio/old',
      });

      expect(
        _container(prefs).read(audioOutputDeviceProvider),
        'coreaudio/new',
      );
    });

    test('writing a choice stores it and retires the legacy key', () async {
      final prefs = AppPreferences.inMemory({
        legacySoundscapeOutputDeviceKey: 'coreaudio/old',
      });
      final container = _container(prefs);

      await container
          .read(audioOutputDeviceProvider.notifier)
          .setDeviceName('coreaudio/new');

      expect(container.read(audioOutputDeviceProvider), 'coreaudio/new');
      expect(prefs.getString(audioOutputDeviceKey), 'coreaudio/new');
      expect(prefs.containsKey(legacySoundscapeOutputDeviceKey), isFalse);
    });

    // Otherwise "back to system default" would fall through to the legacy key
    // and resurrect the device the person just cleared.
    test('clearing the choice clears the legacy key too', () async {
      final prefs = AppPreferences.inMemory({
        audioOutputDeviceKey: 'coreaudio/new',
        legacySoundscapeOutputDeviceKey: 'coreaudio/old',
      });
      final container = _container(prefs);

      await container
          .read(audioOutputDeviceProvider.notifier)
          .setDeviceName(null);

      expect(container.read(audioOutputDeviceProvider), isNull);
      expect(prefs.containsKey(audioOutputDeviceKey), isFalse);
      expect(prefs.containsKey(legacySoundscapeOutputDeviceKey), isFalse);
    });

    test('treats mpv\'s "auto" as the system default, not a device', () async {
      final prefs = AppPreferences.inMemory();
      final container = _container(prefs);

      await container
          .read(audioOutputDeviceProvider.notifier)
          .setDeviceName('auto');

      expect(container.read(audioOutputDeviceProvider), isNull);
      expect(prefs.containsKey(audioOutputDeviceKey), isFalse);
    });
  });
}
