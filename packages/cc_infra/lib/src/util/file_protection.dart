import 'dart:io';

/// Restricts [path] to its owner: `0700` for a directory, `0600` for a file.
///
/// dart:io has no chmod API, so this shells out to `chmod` — which is exactly
/// why it lives in cc_infra: process execution never belongs in the client
/// app. No-op on Windows, where the app-support directory's ACLs govern.
///
/// Throws [FileSystemException] when chmod fails, so a caller can refuse to
/// write private bytes into a file it could not protect.
Future<void> restrictToOwner(String path, {required bool directory}) async {
  if (Platform.isWindows) {
    return; // App-support ACLs govern Windows.
  }
  final result = await Process.run('chmod', [directory ? '700' : '600', path]);
  if (result.exitCode != 0) {
    throw FileSystemException('Cannot protect path', path);
  }
}
