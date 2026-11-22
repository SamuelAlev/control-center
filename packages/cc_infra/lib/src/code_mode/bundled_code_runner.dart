import 'dart:io';

import 'package:path/path.dart' as p;

/// The runner executable could not be found. A packaging error: the server
/// ships `cc_codemode` in its bundle, and there is no other place it may come
/// from.
class CodeRunnerNotFoundException implements Exception {
  /// Creates the exception.
  const CodeRunnerNotFoundException(this.message, {this.searched = const []});

  /// What went wrong, with the paths that were tried.
  final String message;

  /// Every path that was tried, in order.
  final List<String> searched;

  @override
  String toString() => 'CodeRunnerNotFoundException: $message';
}

/// The code mode runner (`cc_codemode`) shipped with the server, never
/// searched on `PATH`.
///
/// The runner is the sandbox a model-written script runs in, so which binary
/// runs matters as much as how it is started: a `cc_codemode` found on `PATH`
/// could be anything. It is found only in the places the build installs it:
///
/// 1. `CC_CODEMODE_RUNNER`, an absolute path to the executable, for
///    development and tests. When set it is the only candidate.
/// 2. `<server executable directory>/codemode/`: the bundle's
///    `bin/codemode/cc_codemode[.exe]`.
/// 3. `$CC_NATIVE_LIB_DIR/codemode/`, the configured native directory.
/// 4. `<app-support root>/codemode/`, where `scripts/natives/build_codemode.sh`
///    installs it for development.
///
/// Both variables are read from the server process's own environment only,
/// never from a `.env` file merged at start: whoever can write a file the
/// server reads at boot must not choose, or move, the binary every script
/// runs in. A `CC_NATIVE_LIB_DIR` set only in `.env` still moves the other
/// native libraries; it does not move the runner.
///
/// A missing runner is an error naming every path tried. There is no
/// fallback.
class BundledCodeRunner {
  /// Uses [executable], an absolute path.
  const BundledCodeRunner(this.executable);

  /// The environment variable that names the runner explicitly.
  static const String environmentOverride = 'CC_CODEMODE_RUNNER';

  /// The executable's file name on this platform.
  static String get executableName =>
      Platform.isWindows ? 'cc_codemode.exe' : 'cc_codemode';

  /// The absolute path of the runner.
  final String executable;

  /// The paths [locate] tries, in order.
  ///
  /// [processEnvironment] (default [Platform.environment]) must be the
  /// server process's own environment, never one merged with a `.env` file;
  /// [serverExecutable] defaults to [Platform.resolvedExecutable]. Both are
  /// parameters so the order can be tested without changing the process.
  static List<String> candidates({
    required String appSupportRoot,
    Map<String, String>? processEnvironment,
    String? serverExecutable,
  }) {
    final env = processEnvironment ?? Platform.environment;
    final explicit = env[environmentOverride];
    if (explicit != null && explicit.isNotEmpty) {
      return [explicit];
    }
    final executableDirectory = File(
      serverExecutable ?? Platform.resolvedExecutable,
    ).parent.path;
    final nativeDirectory = env['CC_NATIVE_LIB_DIR'];
    return [
      p.join(executableDirectory, 'codemode', executableName),
      if (nativeDirectory != null && nativeDirectory.isNotEmpty)
        p.join(nativeDirectory, 'codemode', executableName),
      p.join(appSupportRoot, 'codemode', executableName),
    ];
  }

  /// The directories a runner is installed in that agent sandboxes must not
  /// be able to change: the server executable's directory and its
  /// `codemode/`, and `$CC_NATIVE_LIB_DIR` and its `codemode/` when set
  /// ([processEnvironment] as in [candidates]). The app-support candidate is
  /// inside the data directory, which every sandbox hides already.
  static List<String> installDirectories({
    Map<String, String>? processEnvironment,
    String? serverExecutable,
  }) {
    final env = processEnvironment ?? Platform.environment;
    final executableDirectory = File(
      serverExecutable ?? Platform.resolvedExecutable,
    ).parent.path;
    final nativeDirectory = env['CC_NATIVE_LIB_DIR'];
    return [
      executableDirectory,
      p.join(executableDirectory, 'codemode'),
      if (nativeDirectory != null && p.isAbsolute(nativeDirectory)) ...[
        nativeDirectory,
        p.join(nativeDirectory, 'codemode'),
      ],
    ];
  }

  /// Finds the runner, or throws [CodeRunnerNotFoundException].
  ///
  /// A candidate must be an absolute path to a regular file (symbolic links
  /// are resolved). A relative `CC_CODEMODE_RUNNER` is refused rather than
  /// resolved against whatever the working directory happens to be.
  static BundledCodeRunner locate({
    required String appSupportRoot,
    Map<String, String>? processEnvironment,
    String? serverExecutable,
  }) {
    final paths = candidates(
      appSupportRoot: appSupportRoot,
      processEnvironment: processEnvironment,
      serverExecutable: serverExecutable,
    );
    for (final candidate in paths) {
      if (!p.isAbsolute(candidate)) {
        throw CodeRunnerNotFoundException(
          'The code mode runner path must be absolute: $candidate.',
          searched: paths,
        );
      }
      final file = File(candidate);
      if (file.existsSync() &&
          file.statSync().type == FileSystemEntityType.file) {
        return BundledCodeRunner(file.resolveSymbolicLinksSync());
      }
    }
    throw CodeRunnerNotFoundException(
      "Control Center's code mode runner (cc_codemode) is missing. Reinstall "
      'the application or server bundle, or run '
      'scripts/natives/build_codemode.sh in a development checkout. '
      'Searched: ${paths.join(', ')}.',
      searched: paths,
    );
  }
}
