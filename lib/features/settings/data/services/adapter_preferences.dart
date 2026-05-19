import 'package:shared_preferences/shared_preferences.dart';

const _defaultChatAdapterIdKey = 'default_chat_adapter_id';
const _defaultChatModelIdKey = 'default_chat_model_id';
const _shortTaskAdapterIdKey = 'short_task_adapter_id';
const _shortTaskModelIdKey = 'short_task_model_id';

/// Read/write access to default adapter + model preferences stored in
/// `SharedPreferences`.
class AdapterPreferences {
  /// Creates an `AdapterPreferences` backed by `prefs`.
  const AdapterPreferences(this._prefs);

  final SharedPreferences _prefs;

  // -- Default Chat --

  /// Returns the persisted default chat adapter id, or `null`.
  String? getDefaultChatAdapterId() => _prefs.getString(_defaultChatAdapterIdKey);

  /// Persists the default chat adapter id. Pass `null` to clear.
  Future<bool> setDefaultChatAdapterId(String? value) =>
      value == null
          ? _prefs.remove(_defaultChatAdapterIdKey)
          : _prefs.setString(_defaultChatAdapterIdKey, value);

  /// Returns the persisted default chat model id, or `null`.
  String? getDefaultChatModelId() => _prefs.getString(_defaultChatModelIdKey);

  /// Persists the default chat model id. Pass `null` to clear.
  Future<bool> setDefaultChatModelId(String? value) =>
      value == null
          ? _prefs.remove(_defaultChatModelIdKey)
          : _prefs.setString(_defaultChatModelIdKey, value);

  // -- Short Task --

  /// Returns the persisted short-task adapter id, or `null`.
  String? getShortTaskAdapterId() => _prefs.getString(_shortTaskAdapterIdKey);

  /// Persists the short-task adapter id. Pass `null` to clear.
  Future<bool> setShortTaskAdapterId(String? value) =>
      value == null
          ? _prefs.remove(_shortTaskAdapterIdKey)
          : _prefs.setString(_shortTaskAdapterIdKey, value);

  /// Returns the persisted short-task model id, or `null`.
  String? getShortTaskModelId() => _prefs.getString(_shortTaskModelIdKey);

  /// Persists the short-task model id. Pass `null` to clear.
  Future<bool> setShortTaskModelId(String? value) =>
      value == null
          ? _prefs.remove(_shortTaskModelIdKey)
          : _prefs.setString(_shortTaskModelIdKey, value);
}
