import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// A coarse device position used only to place soundscape weather.
typedef DeviceLocationFix = ({double latitude, double longitude});

/// Reads the desktop or web app's location. A null result means the OS or
/// the person declined, and the server keeps its IP fallback.
abstract class DeviceLocationReader {
  /// The current position, or null when location is unavailable.
  Future<DeviceLocationFix?> read();
}

/// [DeviceLocationReader] that never returns a fix. Widget tests override
/// [deviceLocationReaderProvider] with this so the shell does not touch the OS.
class UnavailableDeviceLocationReader implements DeviceLocationReader {
  /// Creates a reader that always returns null.
  const UnavailableDeviceLocationReader();

  @override
  Future<DeviceLocationFix?> read() async => null;
}

/// [DeviceLocationReader] backed by the platform geolocation API.
class GeolocatorDeviceLocationReader implements DeviceLocationReader {
  /// Creates a reader that asks the OS or browser for a low-accuracy fix.
  const GeolocatorDeviceLocationReader();

  @override
  Future<DeviceLocationFix?> read() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } on Object {
      return null;
    }
  }
}

/// The location source the soundscape shell uses. Tests override this.
final deviceLocationReaderProvider = Provider<DeviceLocationReader>(
  (ref) => const GeolocatorDeviceLocationReader(),
);

/// Reads the device fix and reports it for [workspaceId].
///
/// Returns true when a position was sent. A null fix or a failed report
/// returns false so the caller can fall back to a plain weather refresh.
Future<bool> reportDeviceWeatherLocation(
  WidgetRef ref,
  String workspaceId,
) async {
  try {
    final fix = await ref.read(deviceLocationReaderProvider).read();
    if (fix == null) {
      return false;
    }
    await ref
        .read(weatherRepositoryProvider)
        .reportDeviceLocation(
          workspaceId,
          latitude: fix.latitude,
          longitude: fix.longitude,
        );
    return true;
  } on Object {
    return false;
  }
}
