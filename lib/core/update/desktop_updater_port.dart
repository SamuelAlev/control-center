import 'package:control_center/core/update/desktop_updater.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:control_center/core/update/desktop_updater.dart'
    show DesktopUpdaterHandlerRegistration;

/// Injectable wrapper around the platform updater seam.
///
/// The seam itself is a set of top-level functions behind a conditional
/// export (`desktop_updater.dart`), which is the right shape for a
/// platform binding but impossible to substitute in a test. This port is the
/// one indirection that makes the desktop update controller's scheduling,
/// drain and escalation logic testable without Sparkle, keys, or a network.
class DesktopUpdaterPort {
  /// Creates the real port, delegating to the platform seam.
  const DesktopUpdaterPort();

  /// Whether this platform has a native in-app updater backend.
  bool get supported => desktopUpdaterSupported;

  /// Arms the updater (feed URL + takes over the check cadence).
  Future<void> init() => initDesktopUpdater();

  /// Registers the outcome handlers the native events forward to, returning a
  /// registration the caller releases when it stops caring (so a rebuilt
  /// controller can't be silently displaced without anyone noticing).
  DesktopUpdaterHandlerRegistration setHandlers({
    void Function(String? version, String? notes)? onAvailable,
    void Function()? onNotAvailable,
    void Function(String message)? onError,
  }) => setDesktopUpdaterHandlers(
    onAvailable: onAvailable,
    onNotAvailable: onNotAvailable,
    onError: onError,
  );

  /// Runs an interactive (`background: false`) or silent check.
  Future<void> check({required bool background}) =>
      desktopCheckForUpdates(background: background);

  /// The notify-only fallback for platforms with no updater backend.
  void openReleasesPage() => openExternalUrl(kDesktopReleasesUrl);
}

/// The updater port the desktop update controller drives. Overridden in
/// tests with a fake that records calls and fires outcomes on demand.
final desktopUpdaterPortProvider = Provider<DesktopUpdaterPort>(
  (ref) => const DesktopUpdaterPort(),
);
