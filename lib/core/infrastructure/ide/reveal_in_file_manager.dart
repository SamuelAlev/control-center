import 'dart:io';

/// Runs the platform file-manager command. Injected so revealing can be
/// exercised in unit tests without spawning real processes.
typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> args);

/// Thrown when revealing a path in the OS file manager fails.
class RevealInFileManagerException implements Exception {
  /// Creates the exception with a user-facing [message].
  const RevealInFileManagerException(this.message);

  /// Human-readable failure reason.
  final String message;

  @override
  String toString() => 'RevealInFileManagerException: $message';
}

/// Opens a filesystem path in the platform's native file manager
/// (`open` on macOS, `explorer` on Windows, `xdg-open` on Linux).
///
/// Revealing an on-device path in the OS file manager is inherently a
/// client-side capability — the path lives on this machine — mirroring
/// `NativeEditorLauncher` (a sanctioned thin-client carve-out on the
/// `lib_boundary_test` Process allow-list). Extracted here so presentation
/// code no longer shells out to `Process.run` inline (see FINDINGS §20.10).
class RevealInFileManager {
  /// Creates the reveal service. The named parameters are test seams;
  /// production code constructs it with no arguments.
  RevealInFileManager({String? operatingSystem, ProcessRunner? runProcess})
    : _os = operatingSystem ?? Platform.operatingSystem,
      _run = runProcess ?? _defaultRun;

  final String _os;
  final ProcessRunner _run;

  static Future<ProcessResult> _defaultRun(
    String executable,
    List<String> args,
  ) => Process.run(executable, args);

  /// Reveals [path] in the OS file manager. Throws a
  /// [RevealInFileManagerException] when the path is empty, the platform is
  /// unsupported, or the launch fails.
  Future<void> reveal(String path) async {
    final target = path.trim();
    if (target.isEmpty) {
      throw const RevealInFileManagerException('No path to reveal.');
    }

    final (String executable, List<String> args) = switch (_os) {
      'macos' => ('open', [target]),
      'windows' => ('explorer', [target]),
      'linux' => ('xdg-open', [target]),
      _ => throw RevealInFileManagerException(
        'Revealing files is not supported on "$_os".',
      ),
    };

    try {
      final result = await _run(executable, args);
      // Windows `explorer` returns a non-zero exit code even on success, so
      // only a thrown ProcessException (command not found) counts as failure
      // there; on macOS/Linux a non-zero exit is a real error.
      if (_os != 'windows' && result.exitCode != 0) {
        final err = result.stderr?.toString().trim() ?? '';
        throw RevealInFileManagerException(
          'Failed to reveal path'
          '${err.isNotEmpty ? ': $err' : ' (exit code ${result.exitCode}).'}',
        );
      }
    } on ProcessException catch (e) {
      throw RevealInFileManagerException(
        'Could not open the file manager: ${e.message}',
      );
    }
  }
}
