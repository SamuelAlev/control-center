import 'dart:io';

/// Deletes [dir] recursively, tolerating a concurrent writer inside the tree
/// with a short retry, and finally swallowing the failure.
///
/// These tests boot the full in-process server runtime, whose guarded
/// shutdown steps are skippable on timeout by design — a straggler (a drift
/// isolate checkpointing its WAL, a model poller) can still be writing into
/// the data dir when the test's teardown unlinks it, and Linux answers a
/// recursive delete racing a creator with ENOTEMPTY. The retry outlives the
/// stragglers; a dir that still refuses goes with the runner. Real bugs
/// still surface: the assertions all run before any of this.
Future<void> deleteDirBestEffort(Directory dir) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      if (!dir.existsSync()) {
        return;
      }
      dir.deleteSync(recursive: true);
      return;
    } on FileSystemException {
      if (attempt == 4 && Platform.isWindows) {
        return;
      }
      if (attempt == 4) {
        // Last attempt on POSIX: rethrow only when nothing plausible is
        // still writing (a genuinely stuck tree is a real bug).
        rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 50 * (attempt + 1)));
    }
  }
}
