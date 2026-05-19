import 'package:flutter/services.dart';

/// Service that calls the native platform channel to enumerate
/// system-installed fonts.
class SystemFontService {
  static const _channel = MethodChannel('com.controlcenter/fonts');

  /// Returns a list of installed system font families with their file paths.
  /// Each entry is a map: `{ 'family': String, 'path': String }`.
  Future<List<Map<String, String>>> getInstalledFonts() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getSystemFonts',
      );
      if (result == null || result.isEmpty) {
        return [];
      }

      return result.cast<Map<dynamic, dynamic>>().map((m) {
        final map = m.cast<String, String>();
        return {'family': map['family'] ?? '', 'path': map['path'] ?? ''};
      }).toList();
    } on MissingPluginException {
      return [];
    } catch (e) {
      // If the platform channel fails (e.g., unimplemented on Linux/Windows),
      // return an empty list gracefully.
      return [];
    }
  }
}
