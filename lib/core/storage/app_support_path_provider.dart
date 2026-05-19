import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Captures the device's real **application support** directory once at boot —
/// the single root for everything the app persists — and keeps
/// `path_provider`'s own answer pointed at a `fonts/` subfolder.
///
/// Our own code never calls `getApplicationSupportDirectory()`. It reads
/// [AppSupportPathProvider.realAppSupportDir], captured **before** the override
/// is installed and everything else derives from it (see `CcPaths`).
///
/// WHY THE REDIRECT STAYS, even though nothing downloads fonts to disk any
/// more: it was introduced to keep `package:google_fonts` from scattering `.ttf`
/// files across the data root and font bytes are now cached server-side
/// instead. But the override is not font-specific — it moves the path for
/// *every* plugin that resolves app support and on Windows and Linux that
/// includes `shared_preferences`. Its file has been living under
/// `<root>/fonts/` for as long as this override has existed, so removing the
/// redirect would silently strip a user's theme, font and workspace
/// preferences. The subfolder name is legacy; the compatibility is not.
///
/// Installation must happen exactly once, very early in `main()` — before any
/// code asks `path_provider` for the application support directory. See
/// [AppSupportPathProvider.install].
class AppSupportPathProvider extends PathProviderPlatform {
  AppSupportPathProvider._({
    required this.delegate,
    required this.realAppSupportPath,
  }) : super();

  /// The original [PathProviderPlatform] this wrapper delegates to.
  final PathProviderPlatform delegate;

  /// The real application-support directory captured at install time
  /// (before the override redirected the support path into `fonts/`).
  final String realAppSupportPath;

  static Directory? _realAppSupportDir;

  /// The real Application Support directory — i.e. what
  /// `getApplicationSupportDirectory()` would have returned **without** this
  /// override. Use this as the single root for all app data (database,
  /// workspaces, voice models, …).
  ///
  /// Throws [StateError] if accessed before [install] has run.
  static Directory get realAppSupportDir {
    final dir = _realAppSupportDir;
    if (dir == null) {
      throw StateError(
        'AppSupportPathProvider.install() has not been called yet. '
        'Call it in main() before any code that reads app data paths.',
      );
    }
    return dir;
  }

  /// Whether [install] has run.
  static bool get isInstalled => _realAppSupportDir != null;

  /// Capture the real Application Support path, then register a wrapper
  /// platform implementation that returns `<realPath>/fonts` for
  /// [getApplicationSupportPath]. Idempotent.
  ///
  /// Returns the real (non-redirected) Application Support directory.
  static Future<Directory> install() async {
    final existing = _realAppSupportDir;
    if (existing != null) {
      return existing;
    }
    final original = PathProviderPlatform.instance;
    final realPath = await original.getApplicationSupportPath();
    if (realPath == null) {
      throw StateError(
        'PathProviderPlatform.getApplicationSupportPath() returned null. '
        'Unable to determine the real application-support directory.',
      );
    }
    final realDir = Directory(realPath);
    if (!realDir.existsSync()) {
      await realDir.create(recursive: true);
    }
    _realAppSupportDir = realDir;

    PathProviderPlatform.instance = AppSupportPathProvider._(
      delegate: original,
      realAppSupportPath: realPath,
    );
    return realDir;
  }

  /// Test-only: reset the captured state. Allows tests to re-install the
  /// override against a temporary directory.
  static void resetForTesting() {
    _realAppSupportDir = null;
  }

  /// Test-only: set the captured real-app-support directory directly without
  /// going through [AppSupportPathProvider.install] or the platform override
  /// machinery.
  ///
  /// Call once in `flutter_test_config.dart` before any test accesses
  /// [realAppSupportDir]. Must be reset between test runs via
  /// [resetForTesting].
  static void setRealAppSupportDirForTesting(Directory dir) {
    _realAppSupportDir = dir;
  }

  // ─── Overrides ────────────────────────────────────────────────────────────

  @override
  Future<String?> getApplicationSupportPath() async {
    final dir = Directory(p.join(realAppSupportPath, 'fonts'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  // ─── Delegated methods ────────────────────────────────────────────────────

  @override
  Future<String?> getTemporaryPath() => delegate.getTemporaryPath();

  @override
  Future<String?> getLibraryPath() => delegate.getLibraryPath();

  @override
  Future<String?> getApplicationDocumentsPath() =>
      delegate.getApplicationDocumentsPath();

  @override
  Future<String?> getApplicationCachePath() =>
      delegate.getApplicationCachePath();

  @override
  Future<String?> getDownloadsPath() => delegate.getDownloadsPath();

  @override
  Future<String?> getExternalStoragePath() => delegate.getExternalStoragePath();

  @override
  Future<List<String>?> getExternalCachePaths() =>
      delegate.getExternalCachePaths();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) =>
      delegate.getExternalStoragePaths(type: type);
}
