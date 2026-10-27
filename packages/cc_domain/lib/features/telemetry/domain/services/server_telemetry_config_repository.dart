import 'dart:async';
import 'dart:math';

import 'package:cc_domain/core/domain/repositories/server_settings_repository.dart';
import 'package:cc_domain/features/telemetry/domain/entities/telemetry_config.dart';
import 'package:cc_domain/features/telemetry/domain/repositories/telemetry_config_repository.dart';
import 'package:uuid/uuid.dart';

/// [TelemetryConfigRepository] over the install-wide server settings.
///
/// The install ID and pseudonym salt are minted on first read and persisted,
/// so they stay stable across restarts and are shared by every client of this
/// server. Wiping the data directory mints new ones, which is the intended
/// way to break linkage with earlier analytics.
class ServerTelemetryConfigRepository implements TelemetryConfigRepository {
  /// Creates a repository over [_settings].
  ///
  /// [debugBuildsAllowed] comes from `CC_ANALYTICS_DEBUG` in the server's
  /// environment (or `.env`) and is passed through to every client.
  ServerTelemetryConfigRepository(
    this._settings, {
    this.debugBuildsAllowed = false,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// Whether debug and profile builds may send (see
  /// [TelemetryConfig.debugBuildsAllowed]).
  final bool debugBuildsAllowed;

  final ServerSettingsRepository _settings;
  final Random _random;

  /// Serializes identity minting so two concurrent first reads cannot persist
  /// different install IDs.
  Future<void>? _minting;

  @override
  Future<TelemetryConfig> get() async {
    await _ensureIdentity();
    return _parse(await _settings.getAll(), debugBuildsAllowed);
  }

  @override
  Stream<TelemetryConfig> watch() => Stream.fromFuture(_ensureIdentity())
      .asyncExpand((_) => _settings.watchAll())
      .map((settings) {
        final config = _tryParse(settings, debugBuildsAllowed);
        if (config == null) {
          // A key was deleted out from under us; mint it again and let the
          // resulting write produce the next snapshot.
          unawaited(_ensureIdentity());
        }
        return config;
      })
      .where((config) => config != null)
      .cast<TelemetryConfig>()
      .distinct();

  @override
  Future<void> setUsageAnalyticsEnabled({required bool enabled}) =>
      _settings.set(kTelemetryUsageAnalyticsKey, enabled ? 'true' : 'false');

  Future<void> _ensureIdentity() => _minting ??= _mint().whenComplete(() {
    _minting = null;
  });

  Future<void> _mint() async {
    final settings = await _settings.getAll();
    if ((settings[kTelemetryInstallIdKey] ?? '').isEmpty) {
      await _settings.set(kTelemetryInstallIdKey, const Uuid().v4());
    }
    if ((settings[kTelemetryPseudonymSaltKey] ?? '').length < 16) {
      await _settings.set(kTelemetryPseudonymSaltKey, _newSalt());
    }
  }

  String _newSalt() {
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static TelemetryConfig _parse(
    Map<String, String> settings,
    bool debugBuildsAllowed,
  ) => TelemetryConfig(
    debugBuildsAllowed: debugBuildsAllowed,
    // Opt-in: nothing is collected until the operator says yes.
    usageAnalyticsEnabled:
        settings[kTelemetryUsageAnalyticsKey]?.trim().toLowerCase() == 'true',
    installId: settings[kTelemetryInstallIdKey] ?? '',
    pseudonymSalt: settings[kTelemetryPseudonymSaltKey] ?? '',
  );

  /// [_parse], or null for a snapshot taken before minting landed (or after
  /// an operator deleted a key through `server_settings.set`).
  static TelemetryConfig? _tryParse(
    Map<String, String> settings,
    bool debugBuildsAllowed,
  ) {
    try {
      return _parse(settings, debugBuildsAllowed);
    } on ArgumentError {
      return null;
    }
  }
}
