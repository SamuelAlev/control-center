import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:test/test.dart';

/// A shared timestamp so the snapshot test cases are consistent.
final observedAt = DateTime.utc(2025, 6, 1, 12);

/// Covers construction, copyWith preservation, equality, and the
/// WeatherCondition parse/fallback factories.
void main() {
  group('WeatherSnapshot construction', () {
    test('round-trips every field through the constructor', () {
      final at = DateTime.utc(2025, 6, 1, 12);
      final sunrise = DateTime.utc(2025, 6, 1, 6);
      final sunset = DateTime.utc(2025, 6, 1, 20);

      final snapshot = WeatherSnapshot(
        latitude: 40.0,
        longitude: -73.9,
        locationLabel: 'NYC',
        condition: WeatherCondition.clear,
        isDay: true,
        temperatureCelsius: 21.5,
        windSpeedKmh: 12.0,
        sunrise: sunrise,
        sunset: sunset,
        observedAt: at,
      );

      expect(snapshot.latitude, 40.0);
      expect(snapshot.longitude, -73.9);
      expect(snapshot.locationLabel, 'NYC');
      expect(snapshot.condition, WeatherCondition.clear);
      expect(snapshot.isDay, isTrue);
      expect(snapshot.temperatureCelsius, 21.5);
      expect(snapshot.windSpeedKmh, 12.0);
      expect(snapshot.sunrise, sunrise);
      expect(snapshot.sunset, sunset);
      expect(snapshot.observedAt, at);
    });

    test('leaves optional fields null', () {
      final snapshot = WeatherSnapshot(
        latitude: 0,
        longitude: 0,
        condition: WeatherCondition.clouds,
        isDay: false,
        temperatureCelsius: 0,
        windSpeedKmh: 0,
        observedAt: observedAt,
      );
      expect(snapshot.locationLabel, isNull);
      expect(snapshot.sunrise, isNull);
      expect(snapshot.sunset, isNull);
    });
  });

  group('WeatherSnapshot equality', () {
    final a = WeatherSnapshot(
      latitude: 1,
      longitude: 2,
      locationLabel: 'x',
      condition: WeatherCondition.rain,
      isDay: true,
      temperatureCelsius: 5,
      windSpeedKmh: 9,
      observedAt: observedAt,
    );

    test('equal instances match by value and hashCode', () {
      expect(a, a);
      final b = WeatherSnapshot(
        latitude: 1,
        longitude: 2,
        locationLabel: 'x',
        condition: WeatherCondition.rain,
        isDay: true,
        temperatureCelsius: 5,
        windSpeedKmh: 9,
        observedAt: observedAt,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing fields break equality', () {
      WeatherSnapshot tweak(Object field, Object value) => WeatherSnapshot(
        latitude: 1,
        longitude: 2,
        locationLabel: 'x',
        condition: field == 'condition'
            ? value as WeatherCondition
            : WeatherCondition.rain,
        isDay: field == 'isDay' ? value as bool : true,
        temperatureCelsius: field == 'temperatureCelsius' ? value as double : 5,
        windSpeedKmh: 9,
        observedAt: field == 'observedAt' ? value as DateTime : observedAt,
        sunrise: field == 'sunrise' ? value as DateTime : null,
      );

      expect(a == tweak('condition', WeatherCondition.snow), isFalse);
      expect(a == tweak('isDay', false), isFalse);
      expect(a == tweak('temperatureCelsius', 99.0), isFalse);
      expect(a == tweak('observedAt', DateTime.utc(2025, 1, 1)), isFalse);
      expect(a == tweak('sunrise', DateTime.utc(2025, 1, 1)), isFalse);
    });

    test('a non-WeatherSnapshot is never equal', () {
      expect(a == Object(), isFalse);
    });
  });

  group('WeatherSnapshot.copyWith', () {
    final base = WeatherSnapshot(
      latitude: 40.0,
      longitude: -73.9,
      locationLabel: 'NYC',
      condition: WeatherCondition.clear,
      isDay: true,
      temperatureCelsius: 21.5,
      windSpeedKmh: 12.0,
      observedAt: observedAt,
    );

    test('a single-field copyWith preserves every other field', () {
      final next = base.copyWith(temperatureCelsius: 99.0);
      expect(next.temperatureCelsius, 99.0);
      expect(next.latitude, 40.0);
      expect(next.longitude, -73.9);
      expect(next.locationLabel, 'NYC');
      expect(next.condition, WeatherCondition.clear);
      expect(next.isDay, isTrue);
      expect(next.windSpeedKmh, 12.0);
      expect(next.observedAt, observedAt);
      expect(next.sunrise, isNull);
      expect(next.sunset, isNull);
    });

    test('a no-op copyWith is equal to the original', () {
      expect(base.copyWith(), base);
    });
  });

  group('WeatherCondition.fromWmoCode', () {
    test('0 maps to clear', () {
      expect(WeatherCondition.fromWmoCode(0), WeatherCondition.clear);
    });

    test('1..3 map to clouds', () {
      for (final code in const [1, 2, 3]) {
        expect(
          WeatherCondition.fromWmoCode(code),
          WeatherCondition.clouds,
          reason: '$code -> clouds',
        );
      }
    });

    test('45 and 48 map to fog', () {
      expect(WeatherCondition.fromWmoCode(45), WeatherCondition.fog);
      expect(WeatherCondition.fromWmoCode(48), WeatherCondition.fog);
    });

    test('drizzle/rain/shower codes map to rain', () {
      expect(WeatherCondition.fromWmoCode(51), WeatherCondition.rain);
      expect(WeatherCondition.fromWmoCode(67), WeatherCondition.rain);
      expect(WeatherCondition.fromWmoCode(80), WeatherCondition.rain);
      expect(WeatherCondition.fromWmoCode(82), WeatherCondition.rain);
    });

    test('snow codes map to snow', () {
      expect(WeatherCondition.fromWmoCode(71), WeatherCondition.snow);
      expect(WeatherCondition.fromWmoCode(77), WeatherCondition.snow);
      expect(WeatherCondition.fromWmoCode(85), WeatherCondition.snow);
      expect(WeatherCondition.fromWmoCode(86), WeatherCondition.snow);
    });

    test('thunderstorm codes map to storm', () {
      for (final code in const [95, 96, 97, 98, 99]) {
        expect(
          WeatherCondition.fromWmoCode(code),
          WeatherCondition.storm,
          reason: '$code -> storm',
        );
      }
    });

    test('unrecognized codes fall back to clouds (the neutral default)', () {
      // wind is never produced by fromWmoCode — it is derived elsewhere.
      expect(WeatherCondition.fromWmoCode(-1), WeatherCondition.clouds);
      expect(WeatherCondition.fromWmoCode(100), WeatherCondition.clouds);
      expect(WeatherCondition.fromWmoCode(49), WeatherCondition.clouds);
    });

    test('boundary codes just outside the rain band are not rain', () {
      expect(
        WeatherCondition.fromWmoCode(50),
        WeatherCondition.clouds,
        reason: '50 is below the 51..67 rain band',
      );
      expect(
        WeatherCondition.fromWmoCode(68),
        WeatherCondition.clouds,
        reason: '68 is above the 51..67 rain band',
      );
    });
  });

  group('WeatherCondition.fromName', () {
    test('parses a known condition name', () {
      for (final value in WeatherCondition.values) {
        expect(
          WeatherCondition.fromName(value.name),
          value,
          reason: '${value.name} round-trips',
        );
      }
    });

    test('falls back to clouds for null or unknown input', () {
      expect(WeatherCondition.fromName(null), WeatherCondition.clouds);
      expect(
        WeatherCondition.fromName('not-a-condition'),
        WeatherCondition.clouds,
      );
    });
  });
}
