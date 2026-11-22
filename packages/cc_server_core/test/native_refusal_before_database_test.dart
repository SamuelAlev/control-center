import 'dart:io';

import 'package:cc_domain/core/domain/ports/media_render_port.dart'
    show MediaRenderException;
import 'package:cc_infra/cc_infra.dart' show BundledMediaTools;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart' show runCcServer;
import 'package:cc_server_core/src/server_boot_refusal.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';
import 'helpers/native_staging.dart';

/// A bundle missing a required native is refused before the boot opens or
/// migrates a database: a broken install never touches the owner's data.
void main() {
  late Directory tmp;
  late String dataDir;

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('cc_native_refusal');
    dataDir = p.join(tmp.path, 'data');
    Directory(dataDir).createSync();
    await stageServerNatives(dataDir);
    // Every native but the media tools: one missing native is enough.
    final media = Link(p.join(dataDir, 'media'));
    if (media.existsSync()) {
      media.deleteSync();
    } else if (Directory(media.path).existsSync()) {
      Directory(media.path).deleteSync(recursive: true);
    }
  });

  tearDown(() => deleteDirBestEffort(tmp));

  bool mediaMissing() {
    try {
      BundledMediaTools.locate(appSupportRoot: dataDir);
      return false;
    } on MediaRenderException {
      return true;
    }
  }

  /// Every entry under the data directory with its size and modification
  /// time; a directory has size -1.
  Map<String, (int, DateTime)> snapshot() => {
    for (final entity in Directory(dataDir).listSync(
      recursive: true,
      followLinks: false,
    ))
      p.relative(entity.path, from: dataDir): (
        entity is File ? entity.lengthSync() : -1,
        entity.statSync().modified,
      ),
  };

  Future<Object?> boot() async {
    try {
      final server = await runCcServer(
        args: ['--data-dir', dataDir, '--port', '0'],
      ).timeout(const Duration(seconds: 90));
      await server.shutdown();
      return server;
    } on Object catch (e) {
      return e;
    }
  }

  test(
    'a data directory with no database stays without one',
    () async {
      if (!hostHasServerNatives || !mediaMissing()) {
        markTestSkipped('needs the staged natives and no media tools');
        return;
      }
      final before = snapshot();
      final refusal = await boot();
      expect(refusal, isA<NativeLibrariesMissing>());
      expect((refusal as NativeLibrariesMissing).message, contains('media/'));
      final created = snapshot().keys.toSet().difference(before.keys.toSet());
      expect(created, isEmpty);
      expect(
        Directory(dataDir).listSync().map((e) => p.basename(e.path)),
        isNot(contains(startsWith('global.db'))),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'an existing data directory is left exactly as it was',
    () async {
      if (!hostHasServerNatives || !mediaMissing()) {
        markTestSkipped('needs the staged natives and no media tools');
        return;
      }
      final db = GlobalDatabase.atDataDir(dataDir);
      await db.workspaceRouteDao.setMeta('probe', 'x');
      await db.close();
      Directory(p.join(dataDir, 'logs')).createSync();
      File(p.join(dataDir, 'logs', 'cc_server.log')).writeAsStringSync('x\n');
      // Modification times are compared, so let a write show as one.
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final before = snapshot();

      expect(await boot(), isA<NativeLibrariesMissing>());
      expect(snapshot(), before);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
