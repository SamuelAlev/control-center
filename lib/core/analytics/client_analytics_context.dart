import 'package:cc_domain/cc_domain.dart' show BuildInfo;
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// When `main()` started, for `app_opened.startup_ms`.
///
/// Set by [markAppLaunch] as the first statement of `main()`; a top-level
/// initializer would run lazily on first read, long after launch.
DateTime? _appLaunchedAt;

/// Records the launch instant. Call first thing in `main()`.
void markAppLaunch() => _appLaunchedAt ??= DateTime.now();

/// Milliseconds since [markAppLaunch], or 0 when it was never called.
int millisecondsSinceAppLaunch() {
  final launchedAt = _appLaunchedAt;
  return launchedAt == null
      ? 0
      : DateTime.now().difference(launchedAt).inMilliseconds;
}

/// The analytics context of this client process: desktop or web, the build,
/// the platform and the primary display's logical size.
AnalyticsContext clientAnalyticsContext() {
  final display = PlatformDispatcher.instance.displays.firstOrNull;
  final width = display == null || display.devicePixelRatio == 0
      ? null
      : (display.size.width / display.devicePixelRatio).round();
  final height = display == null || display.devicePixelRatio == 0
      ? null
      : (display.size.height / display.devicePixelRatio).round();
  return AnalyticsContext(
    appType: kIsWeb ? AnalyticsAppType.web : AnalyticsAppType.desktop,
    appVersion: BuildInfo.buildVersion,
    appBuild: BuildInfo.buildGitSha,
    platform: kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
    launchId: AnalyticsId(const Uuid().v4()),
    locale: PlatformDispatcher.instance.locale.toString(),
    screenWidth: width == 0 ? null : width,
    screenHeight: height == 0 ? null : height,
  );
}
