import 'dart:io';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:drift/drift.dart';
import 'package:test/test.dart';

class _Schema extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}

void main() {
  test('openServerDatabase opens a pure-Dart sqlite connection and round-trips',
      () async {
    final tmp = Directory.systemTemp.createTempSync('cc_persistence_test');
    addTearDown(() => tmp.deleteSync(recursive: true));

    final exec = openServerDatabase(dataDir: tmp.path);
    await exec.ensureOpen(_Schema());
    await exec.runCustom(
      'CREATE TABLE t (id TEXT PRIMARY KEY, v TEXT NOT NULL);',
      const [],
    );
    await exec.runInsert('INSERT INTO t (id, v) VALUES (?, ?);', ['a', 'b']);
    final rows = await exec.runSelect('SELECT v FROM t;', const []);
    expect(rows.single['v'], 'b');
    await exec.close();

    // The file was created under the supplied data dir (no path_provider).
    expect(
      File('${tmp.path}${Platform.pathSeparator}control_center.sqlite')
          .existsSync(),
      isTrue,
    );
  });

  test('openServerDatabase creates the data dir if missing', () async {
    final base = Directory.systemTemp.createTempSync('cc_persistence_mkdir');
    addTearDown(() => base.deleteSync(recursive: true));
    final nested = '${base.path}${Platform.pathSeparator}nested';

    final exec = openServerDatabase(dataDir: nested);
    await exec.ensureOpen(_Schema());
    await exec.close();

    expect(Directory(nested).existsSync(), isTrue);
  });
}
