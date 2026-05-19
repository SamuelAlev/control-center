import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/providers/storage_providers.dart';

/// AppPreferences storage keys for sandbox settings.
const String _kEnabledKey = 'sandbox_enabled';
const String _kBackendKey = 'sandbox_backend';
const String _kDefaultCapsKey = 'sandbox_default_capabilities';

/// Read/write the user's sandbox preferences (master toggle, chosen backend,
/// default capabilities for new conversations).
///
/// Wrapping `SharedPreferences` instead of hitting it directly keeps the
/// settings UI testable and avoids hard-coded keys outside this file.
class SandboxPreferences {
  /// Creates [SandboxPreferences] over the given `SharedPreferences` instance.
  SandboxPreferences(this._prefs);

  final AppPreferences _prefs;

  /// Whether sandboxing is enabled at all. When false, the app falls back to
  /// the no-sandbox adapter regardless of the [backend] setting.
  ///
  /// Defaults to **true** for fresh installs — security on by default.
  bool get isEnabled => _prefs.getBool(_kEnabledKey) ?? true;

  /// Sets the master enable flag.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setEnabled(bool value) => _prefs.setBool(_kEnabledKey, value);

  /// Currently selected backend. `null` means "auto" (use the detector's
  /// recommendation).
  ///
  /// Legacy `"docker"` values are silently rewritten to `"native"` on read
  /// so existing users keep their "sandboxed" intent when Docker support was
  /// removed.
  SandboxBackend? get backend {
    final stored = _prefs.getString(_kBackendKey);
    if (stored == null || stored.isEmpty) {
      return null;
    }
    if (stored == 'docker') {
      unawaited(_prefs.setString(_kBackendKey, SandboxBackend.native.name));
      return SandboxBackend.native;
    }
    return SandboxBackend.fromName(stored);
  }

  /// Pins a specific backend. Pass `null` to fall back to auto-detect.
  Future<void> setBackend(SandboxBackend? value) async {
    if (value == null) {
      await _prefs.remove(_kBackendKey);
    } else {
      await _prefs.setString(_kBackendKey, value.name);
    }
  }

  /// Default capabilities applied to *new* conversations. Existing
  /// conversations carry their own capability snapshot.
  AgentCapabilities get defaultCapabilities {
    final raw = _prefs.getString(_kDefaultCapsKey);
    if (raw == null || raw.isEmpty) {
      return AgentCapabilities.safeDefault;
    }
    return AgentCapabilities.fromJsonString(raw);
  }

  /// Sets the default capabilities for new conversations.
  Future<void> setDefaultCapabilities(AgentCapabilities caps) =>
      _prefs.setString(_kDefaultCapsKey, caps.toJsonString());

}
