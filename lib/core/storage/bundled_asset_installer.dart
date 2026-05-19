import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Idempotently materializes a bundled `rootBundle` asset to a real on-disk
/// file and returns that path.
///
/// Native runtimes (onnxruntime via `OrtSession.fromFile`) need a real
/// filesystem path, not an asset key, and the signed macOS `.app` Resources are
/// read-only — so bundled models are copied once into a writable app-support
/// location. The copy is a no-op when the destination already exists with a
/// non-zero length (a cheap stat), so this is safe to call on every resolve.
///
/// Writes to a `.part` sibling then atomically renames, mirroring the
/// download-then-rename idiom the model managers use, so a crash mid-copy never
/// leaves a truncated file at [destPath].
Future<String> ensureBundledAsset({
  required String assetKey,
  required String destPath,
  AssetBundle? bundle,
}) async {
  final dest = File(destPath);
  if (dest.existsSync() && dest.lengthSync() > 0) {
    return dest.path;
  }
  final data = await (bundle ?? rootBundle).load(assetKey);
  await dest.parent.create(recursive: true);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final tmp = File('$destPath.part');
  await tmp.writeAsBytes(bytes, flush: true);
  await tmp.rename(destPath);
  return dest.path;
}
