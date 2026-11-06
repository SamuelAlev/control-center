import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/environments/environment_log_ring.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

void main() {
  late String path;

  setUp(() {
    path = '${tempDir(addTearDown).path}/logs/web.log';
  });

  EnvironmentLogRing ring({int maxBytes = 1024}) => EnvironmentLogRing(
    path: path,
    maxBytes: maxBytes,
    flushInterval: const Duration(milliseconds: 1),
  );

  Future<EnvironmentLogRing> loaded({int maxBytes = 1024}) async {
    final subject = ring(maxBytes: maxBytes);
    await subject.load();
    return subject;
  }

  test('splits chunks into lines, however they arrive', () async {
    final subject = await loaded();
    subject
      ..addBytes(utf8.encode('one\ntw'))
      ..addBytes(utf8.encode('o\nthree'));
    expect(subject.tail(10), ['one', 'two']);
    subject.finishLine();
    expect(subject.tail(10), ['one', 'two', 'three']);
  });

  test('survives a character split across chunks', () async {
    final subject = await loaded();
    final bytes = utf8.encode('héllo\n');
    subject
      ..addBytes(bytes.sublist(0, 2))
      ..addBytes(bytes.sublist(2));
    expect(subject.tail(1), ['héllo']);
  });

  test('strips terminal codes and PTY line ends', () async {
    final subject = await loaded();
    subject.addBytes(
      utf8.encode('\x1B[32mgreen\x1B[0m\r\n\x1B]0;title\x07plain\r\n'),
    );
    expect(subject.tail(2), ['green', 'plain']);
  });

  test('keeps only the last state of a rewritten line', () async {
    final subject = await loaded();
    subject.addBytes(utf8.encode('10%\r50%\r100%\n'));
    expect(subject.tail(1), ['100%']);
  });

  test('redacts before storing', () async {
    final subject = await loaded();
    subject.addBytes(utf8.encode('--token=hunter2\n'));
    await subject.flush();
    expect(subject.tail(1).single, isNot(contains('hunter2')));
    expect(File(path).readAsStringSync(), isNot(contains('hunter2')));
  });

  test('cuts a line with no newline in sight', () async {
    final subject = EnvironmentLogRing(path: path, maxLineChars: 10);
    await subject.load();
    subject.addBytes(utf8.encode('x' * 20));
    expect(subject.tail(1).single, hasLength(20));
  });

  test('memory stays within the ring', () async {
    final subject = await loaded(maxBytes: 100);
    for (var i = 0; i < 100; i++) {
      subject.addBytes(utf8.encode('line-$i\n'));
    }
    expect(subject.tail(1000).join('\n').length, lessThanOrEqualTo(100));
    expect(subject.tail(1).single, 'line-99');
  });

  test('persists, and a new ring picks it up', () async {
    final first = await loaded();
    first.addBytes(utf8.encode('before\n'));
    await first.close();

    final second = await loaded();
    expect(second.tail(10), ['before']);
    second.addBytes(utf8.encode('after\n'));
    await second.close();
    expect(File(path).readAsStringSync(), 'before\nafter\n');
  });

  test('rotates at the ring size and keeps one old file', () async {
    final subject = await loaded(maxBytes: 100);
    for (var i = 0; i < 50; i++) {
      subject.addBytes(utf8.encode('line-$i\n'));
      await subject.flush();
    }
    expect(File('$path.1').existsSync(), isTrue);
    expect(File(path).lengthSync(), lessThan(100));
    expect(File('$path.1').lengthSync(), lessThan(120));
    expect(File('$path.2').existsSync(), isFalse);

    final reloaded = await loaded(maxBytes: 100);
    expect(reloaded.tail(1).single, 'line-49');
  });

  test('lines streams as they complete', () async {
    final subject = await loaded();
    final seen = <String>[];
    subject.lines.listen(seen.add);
    subject.addBytes(utf8.encode('a\nb'));
    expect(seen, ['a']);
  });

  test('a deleted state directory costs a log, nothing else', () async {
    final subject = await loaded();
    Directory(File(path).parent.path).deleteSync(recursive: true);
    subject.addBytes(utf8.encode('late\n'));
    await subject.flush();
    expect(subject.tail(1), ['late']);
  });
}
