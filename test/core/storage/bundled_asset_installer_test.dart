import 'dart:io';

import 'package:control_center/core/storage/bundled_asset_installer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// An [AssetBundle] backed by an in-memory map, counting [load] calls so tests
/// can assert the helper does not re-read the asset once it is materialized.
class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this._assets);

  final Map<String, Uint8List> _assets;
  int loadCount = 0;

  @override
  Future<ByteData> load(String key) async {
    loadCount++;
    final bytes = _assets[key];
    if (bytes == null) {
      throw Exception('asset not found: $key');
    }
    return ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
  }

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) =>
      throw UnimplementedError();
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('bundled_asset_test');
  });

  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  group('ensureBundledAsset', () {
    test('materializes the asset to the destination path', () async {
      final payload = Uint8List.fromList(List.generate(64, (i) => i % 256));
      final bundle = _FakeAssetBundle({'assets/m/x.onnx': payload});
      final dest = p.join(tmp.path, 'nested', 'x.onnx');

      final returned = await ensureBundledAsset(
        assetKey: 'assets/m/x.onnx',
        destPath: dest,
        bundle: bundle,
      );

      expect(returned, dest);
      expect(File(dest).existsSync(), isTrue);
      expect(File(dest).readAsBytesSync(), payload);
      expect(bundle.loadCount, 1);
    });

    test('is idempotent: a second call does not re-read the asset', () async {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bundle = _FakeAssetBundle({'k': payload});
      final dest = p.join(tmp.path, 'x.onnx');

      await ensureBundledAsset(assetKey: 'k', destPath: dest, bundle: bundle);
      final second =
          await ensureBundledAsset(assetKey: 'k', destPath: dest, bundle: bundle);

      expect(second, dest);
      expect(bundle.loadCount, 1); // not re-loaded
      expect(File(dest).readAsBytesSync(), payload);
    });

    test('re-materializes when the destination is empty', () async {
      final payload = Uint8List.fromList([9, 9, 9]);
      final bundle = _FakeAssetBundle({'k': payload});
      final dest = p.join(tmp.path, 'x.onnx');
      // A zero-length leftover must not be treated as already materialized.
      File(dest).writeAsBytesSync(<int>[]);

      await ensureBundledAsset(assetKey: 'k', destPath: dest, bundle: bundle);

      expect(bundle.loadCount, 1);
      expect(File(dest).readAsBytesSync(), payload);
    });

    test('leaves no .part file behind', () async {
      final bundle = _FakeAssetBundle({'k': Uint8List.fromList([7])});
      final dest = p.join(tmp.path, 'x.onnx');

      await ensureBundledAsset(assetKey: 'k', destPath: dest, bundle: bundle);

      expect(File('$dest.part').existsSync(), isFalse);
    });
  });
}
