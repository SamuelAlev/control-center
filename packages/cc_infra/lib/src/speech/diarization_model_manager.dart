import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Description of the installable speaker-diarization models.
///
/// Diarization needs two ONNX models: a pyannote *segmentation* model (shipped
/// as a `.tar.bz2`) and a speaker *embedding* model (a bare `.onnx`). Both come
/// from the sherpa-onnx GitHub releases and run on the same ONNX runtime the
/// app already bundles for Whisper.
class DiarizationModelInfo {
  /// Creates [DiarizationModelInfo].
  const DiarizationModelInfo({
    required this.id,
    required this.displayName,
    required this.segmentationArchiveUrl,
    required this.segmentationArchiveBytes,
    required this.segmentationModelFile,
    required this.embeddingUrl,
    required this.embeddingFile,
    required this.embeddingBytes,
  });

  /// Stable id used as the storage subdirectory name.
  final String id;

  /// Human-readable label shown in onboarding/settings.
  final String displayName;

  /// `tar.bz2` URL of the pyannote segmentation model.
  final String segmentationArchiveUrl;

  /// Approximate segmentation archive size in bytes (progress fallback).
  final int segmentationArchiveBytes;

  /// Segmentation model file path *relative to the model directory* (the
  /// tarball unpacks into its own top-level folder).
  final String segmentationModelFile;

  /// Bare `.onnx` URL of the speaker embedding model.
  final String embeddingUrl;

  /// Embedding model file name (relative to the model directory).
  final String embeddingFile;

  /// Approximate embedding model size in bytes (progress fallback).
  final int embeddingBytes;

  /// Default diarization models: pyannote-segmentation-3.0 + WeSpeaker (en).
  static const pyannoteWespeaker = DiarizationModelInfo(
    id: 'sherpa-onnx-diarization',
    displayName: 'Speaker diarization (pyannote + WeSpeaker)',
    segmentationArchiveUrl:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-segmentation-models/sherpa-onnx-pyannote-segmentation-3-0.tar.bz2',
    segmentationArchiveBytes: 9 * 1024 * 1024,
    segmentationModelFile:
        'sherpa-onnx-pyannote-segmentation-3-0/model.onnx',
    // The release tag is misspelled "recongition" upstream — keep it verbatim.
    embeddingUrl:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-recongition-models/wespeaker_en_voxceleb_resnet34_LM.onnx',
    embeddingFile: 'wespeaker_en_voxceleb_resnet34_LM.onnx',
    embeddingBytes: 26 * 1024 * 1024,
  );
}

/// Resolved on-disk locations for the diarization models.
class DiarizationModelPaths {
  /// Creates a [DiarizationModelPaths].
  const DiarizationModelPaths({
    required this.segmentation,
    required this.embedding,
  });

  /// Absolute path to the pyannote segmentation ONNX file.
  final String segmentation;

  /// Absolute path to the speaker embedding ONNX file.
  final String embedding;
}

/// Thrown when a diarization-model install attempt fails.
class DiarizationModelInstallException implements Exception {
  /// Creates a [DiarizationModelInstallException].
  DiarizationModelInstallException(this.message);

  /// Human-readable error.
  final String message;

  @override
  String toString() => 'DiarizationModelInstallException: $message';
}

/// Owns the lifecycle of the on-disk diarization models (download → extract →
/// resolve). Mirrors `EmbeddingModelManager`/`VoiceModelManager` so all model
/// families coexist under `<root>/models/`.
class DiarizationModelManager {
  /// Creates a [DiarizationModelManager] rooted at [paths] (the app/server
  /// on-disk layout that supplies the `models/` directory).
  DiarizationModelManager({
    required CcPaths paths,
    Dio? dio,
    this.model = DiarizationModelInfo.pyannoteWespeaker,
  })  : _paths = paths,
        _dio = dio ?? createDio();

  final CcPaths _paths;
  final Dio _dio;

  /// Model bundle to manage.
  final DiarizationModelInfo model;

  Future<Directory> _modelDir() async {
    final root = await _paths.modelsRoot();
    final dir = Directory(p.join(root.path, model.id));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns resolved paths when both models are installed, or null.
  Future<DiarizationModelPaths?> resolve() async {
    final dir = await _modelDir();
    final segmentation = File(p.join(dir.path, model.segmentationModelFile));
    final embedding = File(p.join(dir.path, model.embeddingFile));
    if (segmentation.existsSync() && embedding.existsSync()) {
      return DiarizationModelPaths(
        segmentation: segmentation.path,
        embedding: embedding.path,
      );
    }
    return null;
  }

  /// Downloads + extracts the segmentation archive and downloads the embedding
  /// model. Safe to call when already installed — returns the existing paths.
  ///
  /// Progress budget within `[0, 1]`: segmentation download `0 → 0.45`,
  /// extraction `0.45 → 0.55`, embedding download `0.55 → 1.0`.
  Future<DiarizationModelPaths> install({
    void Function(double progress, String phase)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final existing = await resolve();
    if (existing != null) {
      onProgress?.call(1, 'ready');
      return existing;
    }

    final dir = await _modelDir();
    final tmpArchive =
        File(p.join(dir.path, 'segmentation.tar.bz2.part'));
    final embeddingPath = p.join(dir.path, model.embeddingFile);

    onProgress?.call(0, 'downloading');
    try {
      await _dio.download(
        model.segmentationArchiveUrl,
        tmpArchive.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final expected =
              total > 0 ? total : model.segmentationArchiveBytes;
          final pct = (received / expected).clamp(0.0, 1.0) * 0.45;
          onProgress?.call(pct, 'downloading');
        },
        options: Options(
          followRedirects: true,
          responseType: ResponseType.bytes,
        ),
      );

      onProgress?.call(0.46, 'extracting');
      await _extractArchive(tmpArchive.path, dir.path);
      if (tmpArchive.existsSync()) {
        await tmpArchive.delete();
      }

      onProgress?.call(0.55, 'downloading');
      await _dio.download(
        model.embeddingUrl,
        embeddingPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final expected = total > 0 ? total : model.embeddingBytes;
          final pct = 0.55 + (received / expected).clamp(0.0, 1.0) * 0.45;
          onProgress?.call(pct, 'downloading');
        },
        options: Options(
          followRedirects: true,
          responseType: ResponseType.bytes,
        ),
      );
    } catch (e) {
      // Clean up partials so the next attempt starts fresh.
      for (final f in [tmpArchive, File(embeddingPath)]) {
        if (f.existsSync()) {
          await f.delete();
        }
      }
      rethrow;
    }

    final resolved = await resolve();
    if (resolved == null) {
      throw DiarizationModelInstallException(
        'Diarization files are missing on disk after install.',
      );
    }
    onProgress?.call(1, 'ready');
    return resolved;
  }

  /// Extracts the bzip2 + tar archive off the main isolate.
  ///
  /// Kept as its own method on purpose: Dart shares a single closure context
  /// across a whole function body, so running [Isolate.run] inside [install]
  /// would make its closure transitively capture `install`'s `onProgress` /
  /// `cancelToken` — and `CancelToken` holds an unsendable `Completer`, which
  /// crashes the isolate send. Here the closure's scope holds only the two
  /// (sendable) path strings.
  Future<void> _extractArchive(String archivePath, String destPath) =>
      Isolate.run(() => _extractTarBz2Sync(archivePath, destPath));

  /// Removes the installed diarization models.
  Future<void> uninstall() async {
    final dir = await _modelDir();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}

/// Decodes a bzip2+tar archive and writes its entries under [destPath].
/// Runs on a background isolate via [Isolate.run]; all I/O is synchronous.
void _extractTarBz2Sync(String archivePath, String destPath) {
  final bytes = File(archivePath).readAsBytesSync();
  final tarBytes = BZip2Decoder().decodeBytes(bytes);
  final archive = TarDecoder().decodeBytes(tarBytes);
  for (final file in archive) {
    final outPath = p.join(destPath, file.name);
    if (file.isFile) {
      final out = File(outPath);
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(outPath).createSync(recursive: true);
    }
  }
}
