import 'package:control_center/core/providers/storage_providers.dart';

/// The old calendar snapshot keyed only by workspace, not by authenticated
/// server and user. Never migrate it into the verified RPC snapshot store.
Future<void> removeLegacyCalendarSnapshots(AppPreferences preferences) async {
  for (final key in preferences.getKeys()) {
    if (key.startsWith('calendar_events_snapshot__')) {
      await preferences.remove(key);
    }
  }
}
