import 'dart:convert';

import 'package:control_center/core/providers/storage_providers.dart';

/// Persists per-adapter environment-variable overrides (e.g. `OPENAI_API_KEY`)
/// in the platform **secure** store (keychain), never SharedPreferences —
/// AGENTS.md forbids secrets there. Stored as one JSON blob per adapter under
/// key `adapter_env_<adapterId>`.
class AdapterEnvOverridesRepository {
  /// Creates an [AdapterEnvOverridesRepository] over [storage].
  AdapterEnvOverridesRepository(this._storage);

  final SecureStore _storage;

  String _key(String adapterId) => 'adapter_env_$adapterId';

  /// Returns the env-override map for [adapterId] (empty when none stored).
  Future<Map<String, String>> getFor(String adapterId) async {
    final raw = await _storage.read(key: _key(adapterId));
    if (raw == null || raw.isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const {};
      }
      return decoded.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } catch (_) {
      return const {};
    }
  }

  /// Persists [env] for [adapterId]. Pass an empty map to clear.
  Future<void> setFor(String adapterId, Map<String, String> env) async {
    final key = _key(adapterId);
    if (env.isEmpty) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: jsonEncode(env));
  }
}
