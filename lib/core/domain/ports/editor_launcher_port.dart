import 'package:control_center/core/domain/entities/ide_editor.dart';
import 'package:control_center/core/errors/app_exceptions.dart';

/// Detects installed code editors / IDEs and opens a local directory in one.
///
/// Implementations must be resilient to a minimal `PATH`: production desktop
/// builds launched from Finder / Explorer / the desktop environment inherit a
/// stripped environment that omits Homebrew, Nix, snap and user-local
/// prefixes. Detection therefore relies on well-known absolute install
/// locations (and platform launchers like `open`) rather than `PATH` lookups.
abstract interface class EditorLauncherPort {
  /// Returns the full editor catalog for the current platform, each entry
  /// flagged [IdeEditor.installed].
  ///
  /// Never throws — an editor that cannot be probed is simply reported as not
  /// installed. The file manager (Finder / Explorer / Files) is always present
  /// and installed, so the result is non-empty on supported platforms.
  Future<List<IdeEditor>> detectEditors();

  /// Opens [directoryPath] in the editor identified by [editorId].
  ///
  /// Throws [EditorLaunchException] when the editor is unknown, not installed,
  /// the path is empty, or the OS launch process fails.
  Future<void> openDirectory({
    required String editorId,
    required String directoryPath,
  });
}
