import 'dart:io';

/// A size-capped, rotating append-only log file for the headless server, so a
/// long-running `cc_server` can't grow its logs without bound (FINDINGS §132)
/// and an uncaught crash still leaves a persistent record on disk (§130).
///
/// Writes go to `<directory>/<baseName>.log`. When appending a line would push
/// the active file past [maxBytes], the files rotate — `<base>.log` becomes
/// `<base>.1.log`, `<base>.1.log` becomes `<base>.2.log`, … — and the oldest
/// beyond [maxFiles] rotated files is deleted. On-disk growth is therefore
/// bounded by roughly `maxBytes * (maxFiles + 1)`.
///
/// Appends are **synchronous and flushed** so a line survives a crash that
/// happens immediately after it — the whole point of the crash-log use case.
/// Volume on the server is modest (one flushed line per diagnostic), so the
/// sync cost is acceptable and it keeps rotation race-free without a lock.
class RotatingFileLogSink {
  /// Creates a sink writing under [directory] (created if missing). [maxBytes]
  /// caps the active file; [maxFiles] is how many rotated files to retain.
  RotatingFileLogSink({
    required String directory,
    this.baseName = 'cc_server',
    this.maxBytes = 5 * 1024 * 1024,
    this.maxFiles = 5,
  }) : _dir = Directory(directory) {
    _dir.createSync(recursive: true);
  }

  final Directory _dir;

  /// The stem of each log file (`<baseName>.log`, `<baseName>.1.log`, …).
  final String baseName;

  /// Byte ceiling for the active file before a rotation is triggered.
  final int maxBytes;

  /// How many rotated files to keep (total files ≈ [maxFiles] + 1 active).
  final int maxFiles;

  File _file(String suffix) => File('${_dir.path}/$baseName$suffix.log');

  /// The active (most recent) log file.
  File get activeFile => _file('');

  /// Appends [line] (a trailing newline is added), rotating first if the write
  /// would exceed [maxBytes]. Best-effort: any I/O error is swallowed so
  /// logging can never crash the server.
  void write(String line) {
    try {
      final data = '$line\n';
      final active = activeFile;
      final existing = active.existsSync() ? active.lengthSync() : 0;
      // Don't rotate a fresh/empty file (a single line larger than the cap must
      // still be written somewhere).
      if (existing > 0 && existing + data.length > maxBytes) {
        _rotate();
      }
      activeFile.writeAsStringSync(data, mode: FileMode.append, flush: true);
    } on Object {
      // Broken disk / permissions — drop the line rather than take the server
      // down over a log write.
    }
  }

  /// Shifts every retained file up one slot and drops the oldest.
  void _rotate() {
    // Delete the oldest rotated file that would fall off the end.
    final oldest = _file('.$maxFiles');
    if (oldest.existsSync()) {
      oldest.deleteSync();
    }
    // base.(N-1).log → base.N.log, …, base.1.log → base.2.log.
    for (var i = maxFiles - 1; i >= 1; i--) {
      final src = _file('.$i');
      if (src.existsSync()) {
        src.renameSync(_file('.${i + 1}').path);
      }
    }
    // base.log → base.1.log.
    final active = activeFile;
    if (active.existsSync()) {
      active.renameSync(_file('.1').path);
    }
  }
}
