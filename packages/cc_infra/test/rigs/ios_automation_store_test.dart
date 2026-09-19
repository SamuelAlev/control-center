import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cc_infra/src/rigs/ios_automation_store.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc-wda-store-');
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  Uint8List archiveBytes({
    String infoPath = 'WebDriverAgentRunner-Runner.app/Info.plist',
    bool traversal = false,
    bool escapingLink = false,
  }) {
    final archive = Archive();
    final info = ArchiveFile.string(
      traversal ? '../outside' : infoPath,
      '<plist><dict></dict></plist>',
    )..mode = 0x1a4;
    archive.addFile(info);
    final executable = ArchiveFile.string(
      'WebDriverAgentRunner-Runner.app/WebDriverAgentRunner-Runner',
      '#!/bin/sh\n',
    )..mode = 0x1ed;
    archive.addFile(executable);
    if (escapingLink) {
      const target = '../../../outside';
      archive.addFile(
        ArchiveFile.string('WebDriverAgentRunner-Runner.app/escape', target)
          ..symbolicLink = target
          ..mode = 0xa1ff,
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  IosAutomationStore storeFor(
    Uint8List bytes, {
    String? expectedHash,
    Future<void>? gate,
    void Function()? onSource,
  }) {
    final artifact = IosAutomationArtifact(
      architecture: 'test',
      url: 'https://example.test/wda.zip',
      sha256: expectedHash ?? sha256.convert(bytes).toString(),
    );
    return IosAutomationStore.forTesting(
      dataDir: temp.path,
      artifact: artifact,
      source: (_) async {
        onSource?.call();
        if (gate != null) {
          await gate;
        }
        return Stream.value(bytes);
      },
    );
  }

  test('selects the exact pinned architecture assets', () {
    final arm = IosAutomationStore(dataDir: temp.path, architecture: 'arm64');
    final intel = IosAutomationStore(
      dataDir: temp.path,
      architecture: 'x86_64',
    );
    expect(arm.artifact, same(kIosAutomationArm64));
    expect(intel.artifact, same(kIosAutomationX64));
    expect(arm.artifact.url, contains(kIosAutomationVersion));
    expect(intel.artifact.url, contains(kIosAutomationVersion));
    expect(arm.artifact.sha256, hasLength(64));
    expect(intel.artifact.sha256, hasLength(64));
  });

  test(
    'accepts exact hash, validates structure and preserves executable mode',
    () async {
      final bytes = archiveBytes();
      final store = storeFor(bytes);
      final app = await store.install();

      expect(app, endsWith('WebDriverAgentRunner-Runner.app'));
      expect(store.isInstalled, isTrue);
      final executable = File(p.join(app, 'WebDriverAgentRunner-Runner'));
      expect(executable.existsSync(), isTrue);
      if (!Platform.isWindows) {
        expect(executable.statSync().mode & 0x49, isNot(0));
      }
    },
  );

  test('checksum mismatch deletes partial bytes and adopts nothing', () async {
    final store = storeFor(archiveBytes(), expectedHash: '0' * 64);
    await expectLater(store.install(), throwsA(isA<IosAutomationException>()));
    expect(store.isInstalled, isFalse);
    final versionRoot = Directory(p.dirname(store.installDirectory));
    final leftovers = versionRoot.existsSync()
        ? versionRoot.listSync().map((entry) => p.basename(entry.path)).toList()
        : const <String>[];
    expect(leftovers.where((name) => name.contains('.part')), isEmpty);
    expect(leftovers.where((name) => name.contains('.stage-')), isEmpty);
  });

  test('rejects traversal and escaping links before adoption', () async {
    final bytes = archiveBytes(traversal: true);
    final child = Directory(p.join(temp.path, 'traversal'))..createSync();
    final artifact = IosAutomationArtifact(
      architecture: 'test',
      url: 'https://example.test/wda.zip',
      sha256: sha256.convert(bytes).toString(),
    );
    final store = IosAutomationStore.forTesting(
      dataDir: child.path,
      artifact: artifact,
      source: (_) async => Stream.value(bytes),
    );
    await expectLater(store.install(), throwsA(isA<IosAutomationException>()));
    expect(store.isInstalled, isFalse);

    expect(
      () => validateIosArchiveSymlink(
        'WebDriverAgentRunner-Runner.app/escape',
        '../../../outside',
      ),
      throwsA(isA<IosAutomationException>()),
    );
  });

  test('concurrent installs join one source and one atomic adoption', () async {
    final gate = Completer<void>();
    var sourceCalls = 0;
    final store = storeFor(
      archiveBytes(),
      gate: gate.future,
      onSource: () => sourceCalls++,
    );
    final first = store.install();
    final second = store.install();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(sourceCalls, 1);
    gate.complete();
    expect(await first, await second);
    expect(store.isInstalled, isTrue);
  });

  test(
    'embedded and distributed license notices stay byte-identical',
    () async {
      final store = storeFor(archiveBytes());
      await store.install();
      final installed = File(
        p.join(store.installDirectory, 'LICENSE.webdriveragent.txt'),
      ).readAsBytesSync();
      final distributed = File(
        p.join(
          _repoRoot().path,
          'third_party',
          'licenses',
          'webdriveragent-BSD-3-Clause.txt',
        ),
      ).readAsBytesSync();
      expect(
        utf8.decode(installed).replaceAll('\r\n', '\n'),
        utf8.decode(distributed).replaceAll('\r\n', '\n'),
      );
      expect(
        sha256
            .convert(
              utf8.encode(utf8.decode(installed).replaceAll('\r\n', '\n')),
            )
            .toString(),
        kIosAutomationLicenseSha256,
      );
      expect(utf8.decode(installed), startsWith('BSD License'));
    },
  );
}

Directory _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final license = File(
      p.join(
        dir.path,
        'third_party',
        'licenses',
        'webdriveragent-BSD-3-Clause.txt',
      ),
    );
    if (license.existsSync() &&
        File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate repo root from ${Directory.current.path}');
    }
    dir = parent;
  }
}
