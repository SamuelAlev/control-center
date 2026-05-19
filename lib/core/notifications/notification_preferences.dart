import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/providers/storage_providers.dart';

/// SharedPreferences-backed implementation of [NotificationPreferencesPort].
class SharedPreferencesNotificationPreferences
    implements NotificationPreferencesPort {
  /// Creates a [SharedPreferencesNotificationPreferences].
  SharedPreferencesNotificationPreferences(this._prefs);

  final AppPreferences _prefs;

  static const _globalKey = 'notifications_enabled';
  static const _categoryPrefix = 'notifications_category_';
  static const _batchPolicyKey = 'notifications_batch_policy';
  static const _quietEnabledKey = 'notifications_quiet_enabled';
  static const _quietStartHourKey = 'notifications_quiet_start_hour';
  static const _quietStartMinKey = 'notifications_quiet_start_min';
  static const _quietEndHourKey = 'notifications_quiet_end_hour';
  static const _quietEndMinKey = 'notifications_quiet_end_min';
  static const _soundKey = 'notifications_sound';
  static const _volumeKey = 'notifications_sound_volume';
  static const _calendarAlertLeadKey =
      'notifications_calendar_alert_lead_minutes';

  @override
  Future<bool> isGlobalEnabled() async => _prefs.getBool(_globalKey) ?? true;

  @override
  Future<void> setGlobalEnabled({required bool enabled}) async =>
      _prefs.setBool(_globalKey, enabled);
  @override
  Future<bool> isCategoryEnabled(NotificationCategory category) async =>
      _prefs.getBool('$_categoryPrefix${category.name}') ?? true;

  @override
  Future<void> setCategoryEnabled(
    NotificationCategory category, {
    required bool enabled,
  }) async =>
      _prefs.setBool('$_categoryPrefix${category.name}', enabled);
  @override
  Future<BatchDeliveryPolicy> getBatchDeliveryPolicy() async {
    final raw = _prefs.getString(_batchPolicyKey);
    return BatchDeliveryPolicy.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => BatchDeliveryPolicy.realtime,
    );
  }

  @override
  Future<void> setBatchDeliveryPolicy(BatchDeliveryPolicy policy) async =>
      _prefs.setString(_batchPolicyKey, policy.name);

  @override
  Future<QuietHoursConfig> getQuietHours() async {
    return QuietHoursConfig(
      enabled: _prefs.getBool(_quietEnabledKey) ?? false,
      start: TimeOfDay(
        hour: _prefs.getInt(_quietStartHourKey) ?? 22,
        minute: _prefs.getInt(_quietStartMinKey) ?? 0,
      ),
      end: TimeOfDay(
        hour: _prefs.getInt(_quietEndHourKey) ?? 8,
        minute: _prefs.getInt(_quietEndMinKey) ?? 0,
      ),
    );
  }

  @override
  Future<void> setQuietHours(QuietHoursConfig config) async {
    await _prefs.setBool(_quietEnabledKey, config.enabled);
    await _prefs.setInt(_quietStartHourKey, config.start.hour);
    await _prefs.setInt(_quietStartMinKey, config.start.minute);
    await _prefs.setInt(_quietEndHourKey, config.end.hour);
    await _prefs.setInt(_quietEndMinKey, config.end.minute);
  }
  @override
  Future<NotificationSound> getNotificationSound() async {
    final raw = _prefs.getString(_soundKey);
    return NotificationSound.fromName(raw);
  }

  @override
  Future<void> setNotificationSound(NotificationSound sound) async {
    await _prefs.setString(_soundKey, sound.name);
  }
  @override
  Future<double> getVolume() async =>
      _prefs.getDouble(_volumeKey) ?? 1.0;

  @override
  Future<void> setVolume(double volume) async =>
      _prefs.setDouble(_volumeKey, volume.clamp(0.0, 1.0));

  @override
  Future<int> getCalendarAlertLeadMinutes() async =>
      _prefs.getInt(_calendarAlertLeadKey) ?? 5;

  @override
  Future<void> setCalendarAlertLeadMinutes(int minutes) async =>
      _prefs.setInt(_calendarAlertLeadKey, minutes);
}
