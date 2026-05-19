import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:dio/dio.dart';

/// Open-Meteo's keyless current-weather forecast endpoint.
const String _kForecastUrl = 'https://api.open-meteo.com/v1/forecast';

/// Open-Meteo's keyless geocoding (city → coordinates) endpoint.
const String _kGeocodingUrl = 'https://geocoding-api.open-meteo.com/v1/search';

/// Keyless IP-based geolocation endpoint (best-effort coarse location).
const String _kIpGeoUrl = 'https://ipapi.co/json/';

/// A keyless client for [Open-Meteo](https://open-meteo.com) plus a best-effort
/// IP geolocation fallback.
///
/// Lives on `cc_server` so thin clients never dial the weather provider
/// directly (the browser can't reach it cross-origin, and no client should hold
/// network I/O): the client drives `weather.*` over RPC and the host calls this.
/// Open-Meteo requires no API key. Every network method wraps its call so a
/// failure surfaces as a typed `NetworkException` (via [mapDioException]) the
/// caller can catch — except [ipGeolocate], which is best-effort and returns
/// null on any error.
class WeatherApiClient {
  /// Creates a [WeatherApiClient], optionally backed by a custom [dio]
  /// (defaults to the shared [createDio]; no base URL, since the three
  /// endpoints live on different hosts).
  WeatherApiClient({Dio? dio}) : _dio = dio ?? createDio();

  final Dio _dio;

  /// Fetches the current weather at ([latitude], [longitude]).
  ///
  /// [label] is carried through onto the returned snapshot's
  /// [WeatherSnapshot.locationLabel] (Open-Meteo's forecast endpoint returns no
  /// place name — that comes from geocoding/IP resolution upstream). The
  /// condition bucket is derived from the WMO `weather_code`; `sunrise`/`sunset`
  /// come from the single requested forecast day and may be absent.
  Future<WeatherSnapshot> fetchCurrent({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        _kForecastUrl,
        queryParameters: <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m,weather_code,is_day,wind_speed_10m',
          'daily': 'sunrise,sunset',
          'timezone': 'auto',
          'wind_speed_unit': 'kmh',
          'forecast_days': 1,
        },
      );
      final body = _asMap(response.data);
      final current = _asMap(body['current']);
      final daily = _asMap(body['daily']);
      return WeatherSnapshot(
        latitude: latitude,
        longitude: longitude,
        locationLabel: label,
        condition: WeatherCondition.fromWmoCode(
          _asInt(current['weather_code']) ?? 0,
        ),
        isDay: _asInt(current['is_day']) == 1,
        temperatureCelsius: _asDouble(current['temperature_2m']) ?? 0,
        windSpeedKmh: _asDouble(current['wind_speed_10m']) ?? 0,
        sunrise: _firstDateTime(daily['sunrise']),
        sunset: _firstDateTime(daily['sunset']),
        observedAt: DateTime.now().toUtc(),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Resolves a free-text place [name] to coordinates via Open-Meteo geocoding.
  ///
  /// Returns the top match's latitude/longitude/name, or null when the API
  /// returns no result. Network failures throw a `NetworkException`.
  Future<({double latitude, double longitude, String? label})?> geocodeCity(
    String name,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        _kGeocodingUrl,
        queryParameters: <String, dynamic>{
          'name': name,
          'count': 1,
          'language': 'en',
          'format': 'json',
        },
      );
      final body = _asMap(response.data);
      final results = body['results'];
      if (results is! List || results.isEmpty) {
        return null;
      }
      final first = _asMap(results.first);
      final latitude = _asDouble(first['latitude']);
      final longitude = _asDouble(first['longitude']);
      if (latitude == null || longitude == null) {
        return null;
      }
      return (
        latitude: latitude,
        longitude: longitude,
        label: _asString(first['name']),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Best-effort coarse geolocation from the caller's public IP.
  ///
  /// Used as the fallback location when a workspace has no manual override. IP
  /// geolocation is inherently imprecise and the service may be unreachable, so
  /// this swallows every error and returns null rather than throwing — the
  /// caller treats a null as "location unknown".
  Future<({double latitude, double longitude, String? label})?>
  ipGeolocate() async {
    try {
      final response = await _dio.get<dynamic>(_kIpGeoUrl);
      final body = _asMap(response.data);
      final latitude = _asDouble(body['latitude']);
      final longitude = _asDouble(body['longitude']);
      if (latitude == null || longitude == null) {
        return null;
      }
      return (
        latitude: latitude,
        longitude: longitude,
        label: _asString(body['city']),
      );
    } on Object catch (e) {
      CcInfraLog.warning('weather: IP geolocation failed: $e');
      return null;
    }
  }

  static Map<String, dynamic> _asMap(Object? data) =>
      data is Map<String, dynamic> ? data : const <String, dynamic>{};

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static String? _asString(Object? value) => value is String ? value : null;

  /// Parses the first ISO-8601 timestamp of a daily array (e.g. `sunrise`),
  /// returning null when the array is missing/empty or the value doesn't parse.
  static DateTime? _firstDateTime(Object? value) {
    if (value is! List || value.isEmpty) {
      return null;
    }
    final first = value.first;
    return first is String ? DateTime.tryParse(first) : null;
  }
}
