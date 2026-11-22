import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_server_core/cc_server_core.dart' show runConnectCommand;
import 'package:cc_server_core/src/server_boot_refusal.dart'
    show NativeLibrariesMissing;
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';

/// `cc_server connect` opens the global database, so a refusal the boot
/// would make ends it first: printed as one line, exit 78, nothing created.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('cc_connect_refusal'));
  tearDown(() => deleteDirBestEffort(tmp));

  Future<(int, String)> connect(
    List<String> args, {
    Future<void> Function(String dataDir)? checkNatives,
  }) async {
    final err = _Lines();
    final code = await runConnectCommand(
      args: ['status', '--data-dir', tmp.path, ...args],
      out: IOSink(_Lines()),
      err: IOSink(err),
      checkNatives: checkNatives ?? (_) async {},
    );
    return (code, err.text);
  }

  test(
    'a missing native ends it with 78 before the database is created',
    () async {
      final (code, err) = await connect(
        const [],
        checkNatives: (dataDir) async =>
            throw NativeLibrariesMissing(const ['libx'], searched: [dataDir]),
      );
      expect(code, 78);
      expect(err, contains('libx'));
      expect(err.trim(), isNot(contains('\n')));
      expect(tmp.listSync(), isEmpty);
    },
  );

  test('a code mode cap the server refuses ends it with 78 before the '
      'database is created', () async {
    final (code, err) = await connect(const [
      '--code-mode-max-processes',
      'many',
    ]);
    expect(code, 78);
    expect(err, contains('--code-mode-max-processes is "many"'));
    expect(err.trim(), isNot(contains('\n')));
    expect(tmp.listSync(), isEmpty);
  });
}

class _Lines implements StreamConsumer<List<int>> {
  final _buffer = BytesBuilder();
  String get text => String.fromCharCodes(_buffer.toBytes());

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(_buffer.add);

  @override
  Future<void> close() async {}
}
