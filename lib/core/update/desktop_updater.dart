/// Desktop in-app updater seam (macOS Sparkle 2 / Windows WinSparkle via the
/// auto_updater plugin, behind a conditional export so web/mobile builds
/// compile clean). The seam is deliberately narrow: feed URL + check + the
/// three outcomes. Everything with an opinion (WHEN to check, the drain
/// rule, the Linux fallback) lives in the desktop update controller.
library;

export 'desktop_update_config.dart';
export 'desktop_updater_stub.dart'
    if (dart.library.io) 'desktop_updater_io.dart';
