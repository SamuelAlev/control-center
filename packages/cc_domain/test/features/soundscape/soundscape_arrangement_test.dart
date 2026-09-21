import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_domain/features/soundscape/domain/value_objects/soundscape_arrangement.dart';
import 'package:test/test.dart';

SoundscapeContext _context({
  SoundscapeMood mood = SoundscapeMood.focus,
  SoundscapeDaypart daypart = SoundscapeDaypart.day,
  SoundscapeWeather weather = SoundscapeWeather.clear,
  bool isDay = true,
  double temperatureCelsius = 20.0,
  double dayLengthHours = 12.0,
}) => SoundscapeContext(
  mood: mood,
  daypart: daypart,
  weather: weather,
  isDay: isDay,
  temperatureCelsius: temperatureCelsius,
  dayLengthHours: dayLengthHours,
);

void main() {
  group('SoundscapeArrangement', () {
    test('is a pure function of the context', () {
      final ctx = _context(weather: SoundscapeWeather.rain);
      expect(
        SoundscapeTargets.fromContext(ctx),
        equals(SoundscapeTargets.fromContext(ctx)),
      );
    });

    test('fromContext matches resolve()', () {
      final ctx = _context();
      expect(
        SoundscapeTargets.fromContext(ctx),
        equals(const SoundscapeArrangement().resolve(ctx)),
      );
    });

    test('storm has a louder noise bed than clear (same mood/daypart)', () {
      final clear = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.clear),
      );
      final storm = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.storm),
      );
      expect(storm.noiseGain, greaterThan(clear.noiseGain));
    });

    test('rain is brighter (higher cutoff) than storm', () {
      final rain = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.rain),
      );
      final storm = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.storm),
      );
      expect(rain.noiseCutoffHz, greaterThan(storm.noiseCutoffHz));
    });

    test('wind gusts harder than clear skies', () {
      final clear = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.clear),
      );
      final wind = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.wind),
      );
      expect(wind.gustDepthDb, greaterThan(clear.gustDepthDb));
    });

    test('sleep silences the motifs entirely', () {
      final sleep = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.sleep),
      );
      expect(sleep.motifNotesPerMinute, closeTo(0.0, 1e-9));
      expect(sleep.motifGain, closeTo(0.0, 1e-9));
    });

    test('focus (day) plays sparse motifs — a handful per minute', () {
      final focus = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.focus, daypart: SoundscapeDaypart.day),
      );
      expect(focus.motifNotesPerMinute, greaterThan(0.0));
      expect(focus.motifNotesPerMinute, lessThanOrEqualTo(12.0));
    });

    test('rise (day) is denser than focus but still sparse', () {
      final focus = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.focus, daypart: SoundscapeDaypart.day),
      );
      final rise = SoundscapeTargets.fromContext(
        _context(
          mood: SoundscapeMood.rise,
          daypart: SoundscapeDaypart.day,
        ),
      );
      expect(
        rise.motifNotesPerMinute,
        greaterThan(focus.motifNotesPerMinute),
      );
      expect(rise.motifNotesPerMinute, lessThanOrEqualTo(20.0));
      expect(rise.pulseGain, greaterThan(0.0));
      expect(rise.pulseGain, lessThan(focus.pulseGain));
    });

    test('motif onsets are soft in every mood (no percussive attacks)', () {
      for (final mood in SoundscapeMood.values) {
        final t = SoundscapeTargets.fromContext(_context(mood: mood));
        expect(
          t.motifAttackSeconds,
          greaterThanOrEqualTo(0.15),
          reason: '${mood.name} attack must not be percussive',
        );
        expect(t.motifReleaseSeconds, greaterThanOrEqualTo(2.0));
      }
    });

    test('AM depth is strongest for focus, gentlest for sleep', () {
      final focus = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.focus),
      );
      final rise = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.rise),
      );
      final relax = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.relax),
      );
      final sleep = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.sleep),
      );
      expect(focus.amDepth, greaterThan(rise.amDepth));
      expect(rise.amDepth, greaterThan(relax.amDepth));
      expect(relax.amDepth, greaterThan(sleep.amDepth));
      expect(sleep.amDepth, greaterThan(0.0));
    });

    test('focus is drier than rise, which is drier than relax', () {
      final focus = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.focus),
      );
      final rise = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.rise),
      );
      final relax = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.relax),
      );
      final sleep = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.sleep),
      );
      expect(focus.reverbWet, lessThan(rise.reverbWet));
      expect(rise.reverbWet, lessThan(relax.reverbWet));
      expect(relax.reverbWet, lessThan(sleep.reverbWet));
      expect(sleep.reverbDecay, greaterThan(focus.reverbDecay));
    });

    test('sleep grounds hardest (strongest sub, darkest pad)', () {
      final focus = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.focus),
      );
      final sleep = SoundscapeTargets.fromContext(
        _context(mood: SoundscapeMood.sleep),
      );
      expect(sleep.subGain, greaterThan(focus.subGain));
      expect(sleep.padCutoffHz, lessThan(focus.padCutoffHz));
    });

    test('rain pulls the pad down relative to clear', () {
      final clear = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.clear),
      );
      final rain = SoundscapeTargets.fromContext(
        _context(weather: SoundscapeWeather.rain),
      );
      expect(rain.padGain, lessThan(clear.padGain));
    });

    test('night thins the motifs relative to day (same mood)', () {
      final day = SoundscapeTargets.fromContext(
        _context(daypart: SoundscapeDaypart.day, isDay: true),
      );
      final night = SoundscapeTargets.fromContext(
        _context(daypart: SoundscapeDaypart.night, isDay: false),
      );
      expect(night.motifNotesPerMinute, lessThan(day.motifNotesPerMinute));
    });

    test(
      'short day eases rise night darkening and leaves focus alone',
      () {
        final focusLong = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.focus,
            daypart: SoundscapeDaypart.night,
            isDay: false,
            dayLengthHours: 16.0,
          ),
        );
        final focusShort = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.focus,
            daypart: SoundscapeDaypart.night,
            isDay: false,
            dayLengthHours: 8.0,
          ),
        );
        expect(focusShort.motifNotesPerMinute, focusLong.motifNotesPerMinute);
        expect(focusShort.noiseCutoffHz, focusLong.noiseCutoffHz);
        expect(focusShort.amDepth, focusLong.amDepth);

        final riseDay = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.day,
            isDay: true,
            dayLengthHours: 8.0,
          ),
        );
        final riseLongNight = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.night,
            isDay: false,
            dayLengthHours: 16.0,
          ),
        );
        final riseShortNight = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.night,
            isDay: false,
            dayLengthHours: 8.0,
          ),
        );
        final risePolarNight = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.night,
            isDay: false,
            dayLengthHours: 0.0,
          ),
        );
        final riseMidNight = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.night,
            isDay: false,
            dayLengthHours: 11.0,
          ),
        );
        final riseLongDusk = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.dusk,
            isDay: true,
            dayLengthHours: 16.0,
          ),
        );
        final riseShortDusk = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.dusk,
            isDay: true,
            dayLengthHours: 8.0,
          ),
        );
        final riseShortStormNight = SoundscapeTargets.fromContext(
          _context(
            mood: SoundscapeMood.rise,
            daypart: SoundscapeDaypart.night,
            isDay: false,
            weather: SoundscapeWeather.storm,
            dayLengthHours: 8.0,
          ),
        );

        expect(
          riseShortNight.motifNotesPerMinute,
          closeTo(riseDay.motifNotesPerMinute, 1e-9),
        );
        expect(
          risePolarNight.motifNotesPerMinute,
          closeTo(riseDay.motifNotesPerMinute, 1e-9),
        );
        expect(
          riseShortNight.noiseCutoffHz,
          closeTo(riseDay.noiseCutoffHz, 1e-9),
        );
        expect(riseShortNight.amDepth, closeTo(riseDay.amDepth, 1e-9));
        expect(
          riseLongNight.motifNotesPerMinute,
          closeTo(riseDay.motifNotesPerMinute * 0.4 * 0.85, 1e-9),
        );
        expect(
          riseMidNight.motifNotesPerMinute,
          closeTo(riseDay.motifNotesPerMinute * 0.7 * 0.925, 1e-9),
        );
        expect(
          riseShortDusk.motifNotesPerMinute,
          closeTo(riseDay.motifNotesPerMinute, 1e-9),
        );
        expect(
          riseLongDusk.motifNotesPerMinute,
          closeTo(riseDay.motifNotesPerMinute * 0.7, 1e-9),
        );
        expect(
          riseShortStormNight.motifNotesPerMinute,
          closeTo(riseDay.motifNotesPerMinute * 0.4, 1e-9),
        );
        expect(
          riseShortStormNight.motifNotesPerMinute,
          lessThan(riseShortNight.motifNotesPerMinute),
        );
      },
    );

    test('all target values are finite and inside their ranges', () {
      for (final mood in SoundscapeMood.values) {
        for (final weather in SoundscapeWeather.values) {
          for (final daypart in SoundscapeDaypart.values) {
            final t = SoundscapeTargets.fromContext(
              _context(mood: mood, weather: weather, daypart: daypart),
            );
            expect(t.noiseGain, inInclusiveRange(0.0, 0.6));
            expect(t.noiseColor, inInclusiveRange(0.0, 1.0));
            expect(t.noiseCutoffHz, inInclusiveRange(200.0, 16000.0));
            expect(t.gustDepthDb, inInclusiveRange(0.0, 4.0));
            expect(t.padGain, inInclusiveRange(0.0, 0.5));
            expect(t.padCutoffHz, inInclusiveRange(120.0, 6000.0));
            expect(t.padDetuneCents, inInclusiveRange(3.0, 12.0));
            expect(t.motifGain, inInclusiveRange(0.0, 0.5));
            expect(t.motifNotesPerMinute, inInclusiveRange(0.0, 20.0));
            expect(t.motifAttackSeconds, greaterThan(0.0));
            expect(t.motifReleaseSeconds, greaterThan(0.0));
            expect(t.subGain, inInclusiveRange(0.0, 0.3));
            expect(t.amDepth, inInclusiveRange(0.0, 0.5));
            expect(t.reverbWet, inInclusiveRange(0.0, 0.6));
            expect(t.reverbDecay, inInclusiveRange(0.0, 0.95));
            expect(t.reverbDamp, inInclusiveRange(0.0, 1.0));
            expect(t.preDelayMs, inInclusiveRange(0.0, 110.0));
            expect(t.wetHighPassHz, inInclusiveRange(20.0, 1000.0));
          }
        }
      }
    });
  });
}
