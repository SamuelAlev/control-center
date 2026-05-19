import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_tune.dart';
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_domain/features/weather/domain/repositories/weather_repository.dart';
import 'package:cc_infra/cc_infra.dart' show SoundscapeHub;
import 'package:test/test.dart';

/// A weather repository that never has data and never errors — enough for the
/// hub's scene stream, which is what carries the tune to clients.
class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<WeatherSnapshot?> getCurrent(String workspaceId) async => null;

  @override
  Stream<WeatherSnapshot?> watchCurrent(String workspaceId) =>
      Stream<WeatherSnapshot?>.value(null);

  @override
  Future<void> refreshNow(String workspaceId) async {}

  @override
  Future<void> setManualLocation(
    String workspaceId, {
    required double latitude,
    required double longitude,
    String? label,
  }) async {}

  @override
  Future<void> clearManualLocation(String workspaceId) async {}
}

void main() {
  group('SoundscapeHub tune', () {
    test('scene reports the neutral tune before any setTune', () async {
      final hub = SoundscapeHub(weather: _FakeWeatherRepository());
      final scene = await hub
          .watchScene(workspaceId: 'ws-1', mood: 'focus')
          .first;
      expect(scene['tune_energy'], SoundscapeTune.neutral.energy);
      expect(scene['tune_brightness'], SoundscapeTune.neutral.brightness);
      await hub.dispose();
    });

    test(
      'setTune is stored per (workspace, mood) and surfaces in the scene',
      () async {
        final hub = SoundscapeHub(weather: _FakeWeatherRepository())
          ..setTune(
            workspaceId: 'ws-1',
            mood: 'focus',
            tune: SoundscapeTune(energy: 0.8, brightness: 0.3),
          );

        final focus = await hub
            .watchScene(workspaceId: 'ws-1', mood: 'focus')
            .first;
        expect(focus['tune_energy'], 0.8);
        expect(focus['tune_brightness'], 0.3);

        // Other moods and workspaces stay neutral.
        final relax = await hub
            .watchScene(workspaceId: 'ws-1', mood: 'relax')
            .first;
        expect(relax['tune_energy'], SoundscapeTune.neutral.energy);
        final otherWs = await hub
            .watchScene(workspaceId: 'ws-2', mood: 'focus')
            .first;
        expect(otherWs['tune_energy'], SoundscapeTune.neutral.energy);
        await hub.dispose();
      },
    );
  });
}
