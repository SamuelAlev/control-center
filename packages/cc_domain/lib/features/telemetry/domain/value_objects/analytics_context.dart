import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_app_type.dart';
import 'package:cc_domain/features/telemetry/domain/value_objects/analytics_id.dart';

/// How a client reaches its server, as reported in `server_mode`.
enum AnalyticsServerMode {
  /// Desktop supervising its own loopback `cc_server`.
  local,

  /// Any client connected to a server on another host.
  remote;

  /// Stable wire value.
  String get wire => name;
}

/// The super properties attached to every event a process records.
///
/// Holds only coarse, non-identifying facts about the build and the runtime:
/// surface, version, platform, locale, connection mode, display size. Values
/// that are learned after startup (server mode and version, locale changes,
/// display size) are filled in with [copyWith] as they arrive.
class AnalyticsContext {
  /// Creates an [AnalyticsContext].
  AnalyticsContext({
    required this.appType,
    required this.appVersion,
    required this.appBuild,
    required this.platform,
    required this.launchId,
    this.locale,
    this.serverMode,
    this.serverVersion,
    this.screenWidth,
    this.screenHeight,
    this.isDemo = false,
  }) {
    if (appVersion.isEmpty) {
      throw ArgumentError.value(appVersion, 'appVersion', 'must not be empty');
    }
    if (platform.isEmpty) {
      throw ArgumentError.value(platform, 'platform', 'must not be empty');
    }
  }

  /// Surface that records the events.
  final AnalyticsAppType appType;

  /// Release version (`BuildInfo.buildVersion`).
  final String appVersion;

  /// Short git sha, or `dev` for unstamped builds.
  final String appBuild;

  /// Operating platform: `macos`, `windows`, `linux`, `ios`, `android`,
  /// `web`.
  final String platform;

  /// Random per-process identifier, so one launch's events can be ordered
  /// into a funnel independently of the provider's session heuristics.
  final AnalyticsId launchId;

  /// Active UI locale (`en_US`), when known.
  final String? locale;

  /// Local or remote server connection, when known.
  final AnalyticsServerMode? serverMode;

  /// Connected server's release version, when advertised.
  final String? serverVersion;

  /// Logical display width in pixels, when known.
  final int? screenWidth;

  /// Logical display height in pixels, when known.
  final int? screenHeight;

  /// Whether the connected server is the public demo.
  final bool isDemo;

  /// `WIDTHxHEIGHT`, the screen format analytics providers expect, or null
  /// when the display size is unknown.
  String? get screen => screenWidth == null || screenHeight == null
      ? null
      : '${screenWidth}x$screenHeight';

  /// Returns a copy with the given fields replaced.
  AnalyticsContext copyWith({
    String? locale,
    AnalyticsServerMode? serverMode,
    String? serverVersion,
    int? screenWidth,
    int? screenHeight,
    bool? isDemo,
  }) => AnalyticsContext(
    appType: appType,
    appVersion: appVersion,
    appBuild: appBuild,
    platform: platform,
    launchId: launchId,
    locale: locale ?? this.locale,
    serverMode: serverMode ?? this.serverMode,
    serverVersion: serverVersion ?? this.serverVersion,
    screenWidth: screenWidth ?? this.screenWidth,
    screenHeight: screenHeight ?? this.screenHeight,
    isDemo: isDemo ?? this.isDemo,
  );

  /// The properties merged into every event. Event properties with the same
  /// key win.
  Map<String, Object> toProperties() => {
    'app_type': appType.wire,
    'app_version': appVersion,
    'app_build': appBuild,
    'platform': platform,
    'launch_id': launchId,
    'locale': ?locale,
    'server_mode': ?serverMode?.wire,
    'server_version': ?serverVersion,
    'is_demo': isDemo,
  };

  @override
  bool operator ==(Object other) =>
      other is AnalyticsContext &&
      other.appType == appType &&
      other.appVersion == appVersion &&
      other.appBuild == appBuild &&
      other.platform == platform &&
      other.launchId == launchId &&
      other.locale == locale &&
      other.serverMode == serverMode &&
      other.serverVersion == serverVersion &&
      other.screenWidth == screenWidth &&
      other.screenHeight == screenHeight &&
      other.isDemo == isDemo;

  @override
  int get hashCode => Object.hash(
    appType,
    appVersion,
    appBuild,
    platform,
    launchId,
    locale,
    serverMode,
    serverVersion,
    screenWidth,
    screenHeight,
    isDemo,
  );
}
