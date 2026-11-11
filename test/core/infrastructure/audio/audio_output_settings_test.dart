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

    test('writing a choice stores it', () async {
      final prefs = AppPreferences.inMemory();
      final container = _container(prefs);

      await container
          .read(audioOutputDeviceProvider.notifier)
          .setDeviceName('coreaudio/new');

      expect(container.read(audioOutputDeviceProvider), 'coreaudio/new');
      expect(prefs.getString(audioOutputDeviceKey), 'coreaudio/new');
    });

    test('clearing the choice removes the stored device', () async {
      final prefs = AppPreferences.inMemory({
        audioOutputDeviceKey: 'coreaudio/new',
      });
      final container = _container(prefs);

      await container
          .read(audioOutputDeviceProvider.notifier)
          .setDeviceName(null);

      expect(container.read(audioOutputDeviceProvider), isNull);
      expect(prefs.containsKey(audioOutputDeviceKey), isFalse);
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

  group('audioOutputDevicesProvider', () {
    // A Linux desktop without libmpv: `Player()` throws there, and this list
    // is read by settings, onboarding and every rig tab. It must answer
    // without constructing one; a test process never initializes media_kit,
    // so constructing one here would surface as an AsyncError.
    test('is empty, not an error, without media playback', () async {
      final container = ProviderContainer(
        overrides: [mediaPlaybackAvailableProvider.overrideWithValue(false)],
      );
      addTearDown(container.dispose);

      expect(await container.read(audioOutputDevicesProvider.future), isEmpty);
    });
  });
}
