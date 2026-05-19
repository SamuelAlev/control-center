import 'package:control_center/core/providers/storage_providers.dart';

const _defaultChatAdapterIdKey = 'default_chat_adapter_id';
const _defaultChatModelIdKey = 'default_chat_model_id';
const _shortTaskAdapterIdKey = 'short_task_adapter_id';
const _shortTaskModelIdKey = 'short_task_model_id';

/// Default per-adapter "YOLO" / skip-permissions argv (non-secret). Ported
/// from Orca's `YOLO_TUI_AGENT_ARGS`, scoped to the catalog adapters. Goose
/// uses env (`GOOSE_MODE=auto`) instead of a flag, so it has no default here.
const Map<String, String> defaultAdapterArgs = {
  'codex': '--dangerously-bypass-approvals-and-sandbox',
  'gemini': '--yolo',
  'cursor': '--yolo',
};

const _adapterArgsPrefix = 'adapter_args_';

/// Read/write access to default adapter + model preferences stored in
/// `SharedPreferences`.
class AdapterPreferences {
  /// Creates an `AdapterPreferences` backed by `prefs`.
  const AdapterPreferences(this._prefs);

  final AppPreferences _prefs;

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

  // -- Per-adapter args (non-secret) --

  /// Returns the persisted argv override for [adapterId], or the YOLO default
  /// when nothing is stored (see [defaultAdapterArgs]).
  String? getAdapterArgs(String adapterId) {
    final stored = _prefs.getString('$_adapterArgsPrefix$adapterId');
    if (stored != null) {
      return stored.isEmpty ? null : stored;
    }
    return defaultAdapterArgs[adapterId];
  }

  /// Persists the argv override for [adapterId]. Pass `null` (empty) to clear
  /// and fall back to the default.
  Future<bool> setAdapterArgs(String adapterId, String? value) {
    final key = '$_adapterArgsPrefix$adapterId';
    if (value == null || value.isEmpty) {
      return _prefs.remove(key);
    }
    return _prefs.setString(key, value);
  }
}
