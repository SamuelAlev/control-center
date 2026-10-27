/// Server-setting key for the install-wide usage-analytics switch.
///
/// Opt-in: only `'true'` turns collection on, for every client and the server
/// itself. Any other value, or none (a fresh install whose operator has not
/// answered the onboarding question yet), leaves it off. Stored in
/// `global.db`'s server settings because the server operator decides for the
/// whole install.
const String kTelemetryUsageAnalyticsKey = 'telemetry.usage_analytics';

/// Server-setting key for the install's random analytics identifier.
const String kTelemetryInstallIdKey = 'telemetry.install_id';

/// Server-setting key for the secret that keys ID pseudonymization.
const String kTelemetryPseudonymSaltKey = 'telemetry.pseudonym_salt';

/// The install's telemetry configuration, owned by the server.
///
/// Every client reads it through `telemetry.config` / `telemetry.watch` and
/// gates collection on [usageAnalyticsEnabled]; a client never decides on its
/// own that collection is allowed.
class TelemetryConfig {
  /// Creates a [TelemetryConfig]. Throws [ArgumentError] when [installId] or
  /// [pseudonymSalt] is empty.
  TelemetryConfig({
    required this.usageAnalyticsEnabled,
    required this.installId,
    required this.pseudonymSalt,
    this.debugBuildsAllowed = false,
  }) {
    if (installId.isEmpty) {
      throw ArgumentError.value(installId, 'installId', 'must not be empty');
    }
    if (pseudonymSalt.length < 16) {
      throw ArgumentError.value(
        '<redacted>',
        'pseudonymSalt',
        'must be at least 16 characters',
      );
    }
  }

  /// Parses the `telemetry.config` wire shape.
  factory TelemetryConfig.fromWire(Map<String, dynamic> wire) =>
      TelemetryConfig(
        usageAnalyticsEnabled: wire['usage_analytics_enabled'] == true,
        installId: wire['install_id'] as String? ?? '',
        pseudonymSalt: wire['pseudonym_salt'] as String? ?? '',
        debugBuildsAllowed: wire['debug_builds_allowed'] == true,
      );

  /// Whether usage analytics may be collected on this install.
  final bool usageAnalyticsEnabled;

  /// Random identifier for this install. Exists only for analytics, so it
  /// links nothing outside them.
  final String installId;

  /// Secret key for `AnalyticsPseudonymizer`. Shared with authenticated
  /// clients so every surface hashes the same ID to the same value; never
  /// sent to the analytics provider.
  final String pseudonymSalt;

  /// Whether debug and profile builds may send too, for testing the
  /// pipeline end to end. Set by `CC_ANALYTICS_DEBUG=1` in the server's
  /// `.env`; it lifts only the build-type gate, never
  /// [usageAnalyticsEnabled].
  final bool debugBuildsAllowed;

  /// Wire shape for `telemetry.config` / `telemetry.watch`.
  Map<String, Object> toWire() => {
    'usage_analytics_enabled': usageAnalyticsEnabled,
    'install_id': installId,
    'pseudonym_salt': pseudonymSalt,
    'debug_builds_allowed': debugBuildsAllowed,
  };

  @override
  bool operator ==(Object other) =>
      other is TelemetryConfig &&
      other.usageAnalyticsEnabled == usageAnalyticsEnabled &&
      other.installId == installId &&
      other.pseudonymSalt == pseudonymSalt &&
      other.debugBuildsAllowed == debugBuildsAllowed;

  @override
  int get hashCode => Object.hash(
    usageAnalyticsEnabled,
    installId,
    pseudonymSalt,
    debugBuildsAllowed,
  );

  @override
  String toString() =>
      'TelemetryConfig(usageAnalyticsEnabled: $usageAnalyticsEnabled)';
}
