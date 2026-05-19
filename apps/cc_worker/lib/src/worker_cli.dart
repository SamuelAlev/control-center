import 'dart:io';

/// Pure argument→configuration resolution for the `cc_worker` binary.
///
/// Lives here rather than in `bin/` so it can be TESTED: everything in `bin/`
/// is unreachable from a test, which is how the PSK-in-argv and unbounded-job
/// behaviours went unexamined.
class WorkerCliException implements Exception {
  /// Creates a [WorkerCliException] with a user-facing [message] and the
  /// process [exitCode] the binary should use (`sysexits.h` conventions).
  const WorkerCliException(this.message, this.exitCode);

  /// What went wrong, phrased for an operator.
  final String message;

  /// Exit code to report (64 = usage, 66 = unreadable input).
  final int exitCode;

  @override
  String toString() => message;
}

/// Resolves the pre-shared key, most-secure source first.
///
/// Order: `--psk-file` (by reference) → `CC_WORKER_PSK` → `--psk`. A key given
/// on the command line lands in `ps` output and shell history, so it is
/// accepted but reported through [onInsecureSource] rather than silently
/// blessed — the rig broker secret is passed by reference for the same reason.
///
/// Returns null when no source supplied one (a loopback dev server accepts an
/// unauthenticated worker).
String? resolveWorkerPsk({
  String? pskFile,
  String? pskFlag,
  Map<String, String> environment = const {},
  String Function(String path)? readFile,
  void Function(String message)? onInsecureSource,
}) {
  if (pskFile != null && pskFile.isNotEmpty) {
    final String contents;
    try {
      contents = (readFile ?? _readFile)(pskFile);
    } on Object catch (e) {
      throw WorkerCliException('could not read --psk-file "$pskFile": $e', 66);
    }
    final key = contents
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    if (key.isEmpty) {
      throw WorkerCliException('--psk-file "$pskFile" is empty.', 66);
    }
    return key;
  }
  final fromEnv = environment['CC_WORKER_PSK'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  if (pskFlag != null && pskFlag.isNotEmpty) {
    onInsecureSource?.call(
      'warning — --psk is visible in `ps` output and shell history. Use '
      '--psk-file or CC_WORKER_PSK instead.',
    );
    return pskFlag;
  }
  return null;
}

/// Parses `--max-jobs`, refusing anything that is not a positive integer.
int parseMaxJobs(String? raw, {int fallback = 4}) {
  if (raw == null || raw.isEmpty) {
    return fallback;
  }
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 1) {
    throw const WorkerCliException(
      '--max-jobs must be a positive integer.',
      64,
    );
  }
  return parsed;
}

String _readFile(String path) => File(path).readAsStringSync();
