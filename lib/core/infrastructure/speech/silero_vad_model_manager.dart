import 'dart:io';

import 'package:control_center/core/storage/bundled_asset_installer.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:path/path.dart' as p;

/// Owns the on-disk Silero VAD model (`silero_vad.onnx`) used to gate meeting
/// transcription on speech presence. A single bare `.onnx` from the sherpa-onnx
/// releases — the same runtime the app already bundles for Whisper/diarization.
///
/// The model is **bundled as an app asset** (`assets/models/silero-vad/`) and
/// materialized to `<root>/models/silero-vad/` on first [resolve], so it is
/// always available without a download. onnxruntime opens the model by path, so
/// it can't read the asset key directly — hence the one-time copy into a
/// writable location (see [ensureBundledAsset]).
///
/// If materialization ever fails (a corrupt/missing asset in a broken build),
/// [resolve] returns null and the transcription service falls back to the RMS
/// energy gate, so a bad bundle degrades rather than crashes.
class SileroVadModelManager {
  /// Creates a [SileroVadModelManager].
  SileroVadModelManager();

  /// Storage subdirectory under `<root>/models/`.
  static const String dirName = 'silero-vad';

  /// File name of the model.
  static const String fileName = 'silero_vad.onnx';

  /// Bundled asset key for the model (declared in `pubspec.yaml`).
  static const String assetKey = 'assets/models/silero-vad/silero_vad.onnx';

  Future<Directory> _modelDir() async {
    final root = await modelsRootDir();
    final dir = Directory(p.join(root.path, dirName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Absolute path to the model file, materializing it from the bundled asset
  /// on first use. Returns null only if extraction fails.
  Future<String?> resolve() async {
    try {
      final dir = await _modelDir();
      return await ensureBundledAsset(
        assetKey: assetKey,
        destPath: p.join(dir.path, fileName),
      );
    } catch (e, st) {
      AppLog.w(
        'SileroVadModelManager',
        'failed to materialize bundled VAD model: $e',
      );
      AppLog.e('SileroVadModelManager', 'materialize failed', e, st);
      return null;
    }
  }

  /// Whether the bundled model is available (materializes if needed).
  Future<bool> isInstalled() async => (await resolve()) != null;
}
