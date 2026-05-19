import 'dart:io';

import 'package:cc_infra/src/log/rotating_file_log_sink.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_rotlog_');
  });

  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  RotatingFileLogSink sink({int maxBytes = 1000, int maxFiles = 3}) =>
      RotatingFileLogSink(
        directory: '${tmp.path}/logs',
        maxBytes: maxBytes,
        maxFiles: maxFiles,
      );

  List<String> logFiles(String dir) =>
      Directory(dir)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .toList()
        ..sort();

  test('creates the log directory and writes a line', () {
    final s = sink();
    s.write('hello');
    expect(s.activeFile.existsSync(), isTrue);
    expect(s.activeFile.readAsStringSync(), 'hello\n');
  });

  test('appends multiple lines without rotating under the cap', () {
    final s = sink(maxBytes: 1000);
    s
      ..write('one')
      ..write('two')
      ..write('three');
    expect(s.activeFile.readAsStringSync(), 'one\ntwo\nthree\n');
    expect(logFiles('${tmp.path}/logs'), ['cc_server.log']);
  });

  test('rotates when a write would exceed the cap', () {
    // Cap ~20 bytes: each 10-char line + newline = 11 bytes.
    final s = sink(maxBytes: 20);
    s.write('aaaaaaaaaa'); // 11 bytes → active = 11
    s.write('bbbbbbbbbb'); // 11 + 11 = 22 > 20 → rotate first
    final dir = '${tmp.path}/logs';
    expect(
      logFiles(dir),
      containsAll(<String>['cc_server.log', 'cc_server.1.log']),
    );
    // Old content moved to .1, new content in the active file.
    expect(File('$dir/cc_server.1.log').readAsStringSync(), 'aaaaaaaaaa\n');
    expect(s.activeFile.readAsStringSync(), 'bbbbbbbbbb\n');
  });

  test('retains at most maxFiles rotated files (drops the oldest)', () {
    final s = sink(maxBytes: 12, maxFiles: 2); // one line per file
    for (var i = 0; i < 6; i++) {
      s.write('line-$i-xxxx'); // 11 chars + \n = 12; next write rotates
    }
    final dir = '${tmp.path}/logs';
    // Active + exactly maxFiles (2) rotated files, nothing more.
    expect(logFiles(dir), [
      'cc_server.1.log',
      'cc_server.2.log',
      'cc_server.log',
    ]);
    // The oldest lines have been dropped; the newest is in the active file.
    expect(s.activeFile.readAsStringSync(), 'line-5-xxxx\n');
  });

  test(
    'a single line larger than the cap is still written (no empty rotate)',
    () {
      final s = sink(maxBytes: 5);
      final big = 'x' * 100;
      s.write(big);
      expect(s.activeFile.readAsStringSync(), '$big\n');
      // Nothing rotated — the fresh file was empty, so the big first line stays.
      expect(logFiles('${tmp.path}/logs'), ['cc_server.log']);
    },
  );
}
