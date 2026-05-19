import 'dart:io';

/// Logging sink the host app supplies so `cc_natives` stays a leaf package
/// (no `package:control_center` dependency).
///
/// The shape matches the host's `AppLog.e(tag, message, [error, stackTrace])`.
/// When [error] is null the host should treat it as an info-level message.
/// Defaults to a no-op everywhere it is accepted, so the natives stay silent
/// rather than depending on a concrete logger.
typedef NativeLog =
    void Function(
      String tag,
      String message, [
      Object? error,
      StackTrace? stackTrace,
    ]);

/// Resolves a host-managed on-disk directory (created if missing).
///
/// Used to locate loose native libraries installed next to `control_center.db`
/// (the app-support root) and the `grammars/` subdirectory. The host injects an
/// implementation (e.g. `controlCenterRootDir` / `grammarsRootDir`); the package
/// never reaches into the app's storage layer itself.
typedef NativeDirResolver = Future<Directory> Function();
