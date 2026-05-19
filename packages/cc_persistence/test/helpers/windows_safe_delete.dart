import 'dart:io';

/// Deletes [dir] recursively, tolerating Windows' errno 32 ("being used by
/// another process") with a short retry, and finally swallowing the failure.
///
/// Test teardowns delete temp dirs whose drift background isolate may still
/// hold the database file open (the isolate's shutdown is racing the await
/// that returned), and Windows refuses to unlink any open file. POSIX unlink
/// never fails for that reason, so on POSIX this is a plain delete that still
/// surfaces real bugs; on Windows the retry-and-swallow keeps teardown from
/// failing tests whose subject already passed. Leaked CI temp dirs are
/// reclaimed with the runner.
Future<void> deleteDirBestEffort(Directory dir) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      if (!dir.existsSync()) {
        return;
      }
      dir.deleteSync(recursive: true);
      return;
    } on FileSystemException {
      if (attempt == 4 && !Platform.isWindows) {
        rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
    }
  }
}
