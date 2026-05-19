import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:control_center/core/network/app_network.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Configuration for the one ASR model we ship support for today
/// (`sherpa-onnx-whisper-base.en`). Other models can be added as
/// additional [VoiceModelInfo] constants.
class VoiceModelInfo {
  /// Creates model metadata describing download source and expected on-disk layout.
  const VoiceModelInfo({
    required this.id,
    required this.displayName,
    required this.archiveUrl,
    required this.archiveBytes,
    required this.unpackedDirName,
    required this.encoderFile,
    required this.decoderFile,
    required this.tokensFile,
  });

  /// Stable id used in storage paths and settings.
  final String id;

  /// Shown in onboarding ("Whisper base.en").
  final String displayName;

  /// `tar.bz2` download URL.
  final String archiveUrl;

  /// Approximate archive size in bytes (for the progress bar's denominator
  /// when the server doesn't send `Content-Length`).
  final int archiveBytes;

  /// Top-level directory inside the tarball.
  final String unpackedDirName;

  /// Encoder ONNX model file name (relative to [unpackedDirName]).
  final String encoderFile;

  /// Decoder ONNX model file name (relative to [unpackedDirName]).
  final String decoderFile;

  /// Tokens text file name (relative to [unpackedDirName]).
  final String tokensFile;

  /// Pre-configured Whisper base.en model shipped with the app.
  static const whisperBaseEn = VoiceModelInfo(
    id: 'sherpa-onnx-whisper-base.en',
    displayName: 'Whisper base.en (sherpa-onnx)',
    archiveUrl:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-base.en.tar.bz2',
    archiveBytes: 198 * 1024 * 1024,
    unpackedDirName: 'sherpa-onnx-whisper-base.en',
    encoderFile: 'base.en-encoder.int8.onnx',
    decoderFile: 'base.en-decoder.int8.onnx',
    tokensFile: 'base.en-tokens.txt',
  );
}

/// Resolved model paths after a successful install.
class VoiceModelPaths {
  /// Creates resolved paths to the three required model files.
  const VoiceModelPaths({
    required this.encoder,
    required this.decoder,
    required this.tokens,
  });

  /// Absolute path to the encoder ONNX file.
  final String encoder;

  /// Absolute path to the decoder ONNX file.
  final String decoder;

  /// Absolute path to the tokens text file.
  final String tokens;
}

/// Owns the lifecycle of an on-disk speech model (download → extract → query).
///
/// Storage layout (see also [controlCenterRootDir]):
/// ```
/// <Documents>/control_center/
///   voice_models/
///     sherpa-onnx-whisper-base.en/
///       base.en-encoder.int8.onnx
///       base.en-decoder.int8.onnx
///       base.en-tokens.txt
///       ... (test_wavs etc., kept for parity with the upstream tarball)
/// ```
///
/// Sits as a peer of the per-workspace `<workspaceId>/agents` and
/// `<workspaceId>/skills` folders so every Control Center artifact lives
/// under one inspectable root.
class VoiceModelManager {
  /// Creates a new [Voice model manager].
  VoiceModelManager({Dio? dio, this.model = VoiceModelInfo.whisperBaseEn})
      : _dio = dio ?? createDio();

  final Dio _dio;

  /// Model to manage (defaults to [VoiceModelInfo.whisperBaseEn]).
  final VoiceModelInfo model;

  Future<Directory> _rootDir() => modelsRootDir();

  Future<Directory> _modelDir() async {
    final root = await _rootDir();
    return Directory(p.join(root.path, model.unpackedDirName));
  }

  /// Returns resolved file paths when the model is installed, or null.
  Future<VoiceModelPaths?> resolve() async {
    final dir = await _modelDir();
    final encoder = File(p.join(dir.path, model.encoderFile));
    final decoder = File(p.join(dir.path, model.decoderFile));
    final tokens = File(p.join(dir.path, model.tokensFile));
    if (encoder.existsSync() && decoder.existsSync() && tokens.existsSync()) {
      return VoiceModelPaths(
        encoder: encoder.path,
        decoder: decoder.path,
        tokens: tokens.path,
      );
    }
    return null;
  }

  /// Download the archive (with progress) and extract it. Safe to call when
  /// already installed — returns the existing paths immediately.
  ///
  /// [onProgress] receives values in `[0.0, 1.0]` representing
  /// `bytesDownloaded / totalBytes`. The download portion accounts for ~85%
  /// of the progress (the remainder reports decompression / extraction).
  Future<VoiceModelPaths> install({
    void Function(double progress, String phase)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final existing = await resolve();
    if (existing != null) {
      return existing;
    }

    final root = await _rootDir();
    final tmpArchive = File(p.join(root.path, '${model.id}.tar.bz2.part'));
    onProgress?.call(0, 'downloading');

    try {
      await _dio.download(
        model.archiveUrl,
        tmpArchive.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final expected = total > 0 ? total : model.archiveBytes;
          final pct = (received / expected).clamp(0.0, 1.0) * 0.85;
          onProgress?.call(pct, 'downloading');
        },
        options: Options(
          followRedirects: true,
          responseType: ResponseType.bytes,
        ),
      );
    } catch (e) {
      if (tmpArchive.existsSync()) {
        await tmpArchive.delete();
      }
      rethrow;
    }

    onProgress?.call(0.86, 'extracting');
    await _extract(tmpArchive, root, onProgress);

    if (tmpArchive.existsSync()) {
      await tmpArchive.delete();
    }

    final resolved = await resolve();
    if (resolved == null) {
      throw VoiceModelInstallException(
        'Archive extracted but expected files are missing in '
        '${model.unpackedDirName}/.',
      );
    }
    onProgress?.call(1, 'ready');
    return resolved;
  }

  /// Decode + write the tarball off the main isolate so the UI stays
  /// responsive. The worker streams a `[0..1]` fraction back over a
  /// [SendPort]; we remap it into the `[0.86, 1.0)` window used by the
  /// overall install progress bar.
  ///
  /// The bulk of the wall-clock time is spent inside the synchronous
  /// `BZip2Decoder` call, which can't emit progress. To keep the bar from
  /// freezing at 86% for ~10 seconds we run a "creep" timer on the main
  /// side that nudges the bar forward at a steady rate, capped just shy of
  /// the worker's real progress so honest events always win when they
  /// arrive.
  Future<void> _extract(
    File archive,
    Directory destinationRoot,
    void Function(double progress, String phase)? onProgress,
  ) async {
    final progressPort = ReceivePort();
    final exitPort = ReceivePort();
    final errorPort = ReceivePort();
    final completer = Completer<void>();

    const startPct = 0.86;
    const creepCap = 0.97;
    var current = startPct;

    void emit(double value) {
      if (value <= current) {
        return;
      }
      current = value;
      onProgress?.call(current.clamp(0.0, 0.99), 'extracting');
    }

    // Creep timer: while the worker is silently decompressing, advance the
    // bar by ~2% per second so the user sees activity. Real progress events
    // from the worker still snap the bar forward via [emit].
    final creep = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (current < creepCap) {
        emit(current + 0.005);
      }
    });

    progressPort.listen((message) {
      if (message is double) {
        emit(startPct + message * (1.0 - startPct));
      } else if (message == _extractDoneSignal) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    errorPort.listen((error) {
      if (!completer.isCompleted) {
        // Dart sends errors as a 2-element list: [errorString, stackString].
        final msg = error is List && error.isNotEmpty
            ? error.first.toString()
            : error.toString();
        completer.completeError(VoiceModelInstallException(msg));
      }
    });

    exitPort.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          VoiceModelInstallException(
            'Extraction isolate exited before completing.',
          ),
        );
      }
    });

    final isolate = await Isolate.spawn<_ExtractArgs>(
      _extractEntry,
      _ExtractArgs(
        archivePath: archive.path,
        destinationPath: destinationRoot.path,
        sendPort: progressPort.sendPort,
      ),
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
      errorsAreFatal: true,
      debugName: 'voice_model_extract',
    );

    try {
      await completer.future;
    } finally {
      creep.cancel();
      progressPort.close();
      errorPort.close();
      exitPort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Removes the installed model and any in-progress archive part files.
  Future<void> uninstall() async {
    final dir = await _modelDir();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    final root = await _rootDir();
    final part = File(p.join(root.path, '${model.id}.tar.bz2.part'));
    if (part.existsSync()) {
      await part.delete();
    }
  }
}

/// Sentinel sent by the extraction isolate when all files have been written.
const String _extractDoneSignal = '__voice_model_extract_done__';

/// Arguments passed across the isolate boundary. Plain types only — the Dart
/// VM copies these into the worker isolate.
class _ExtractArgs {
  const _ExtractArgs({
    required this.archivePath,
    required this.destinationPath,
    required this.sendPort,
  });

  final String archivePath;
  final String destinationPath;
  final SendPort sendPort;
}

/// Top-level entry point for the extraction isolate. Reads the archive,
/// decompresses bzip2 + tar, writes each entry to disk, and reports progress
/// back as a `[0..1]` fraction via the send port. All file I/O uses the
/// `*Sync` variants because we are off the main isolate.
///
/// Progress budget within the `[0..1]` fraction:
/// * `0.00` — entry
/// * `0.05` — archive bytes read into memory
/// * `0.80` — bzip2 + tar decode done (opaque; can't subdivide)
/// * `0.80 → 1.00` — per-file writes (smoothly interpolated)
void _extractEntry(_ExtractArgs args) {
  args.sendPort.send(0.0);
  final bytes = File(args.archivePath).readAsBytesSync();
  args.sendPort.send(0.05);

  final tarBytes = BZip2Decoder().decodeBytes(bytes);
  final archiveData = TarDecoder().decodeBytes(tarBytes);
  args.sendPort.send(0.80);

  final total = archiveData.length;
  var i = 0;
  for (final file in archiveData) {
    final outPath = p.join(args.destinationPath, file.name);
    if (file.isFile) {
      final out = File(outPath);
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(file.content as List<int>);
    } else {
      Directory(outPath).createSync(recursive: true);
    }
    i++;
    // Report every file so the writing phase fills smoothly even when the
    // archive only contains a handful of entries (the Whisper tarball has
    // ~5 files).
    args.sendPort.send(0.80 + (i / total) * 0.20);
  }
  args.sendPort.send(_extractDoneSignal);
}

/// Voice model install exception.
class VoiceModelInstallException implements Exception {
  /// Creates a new [Voice model install exception].
  VoiceModelInstallException(this.message);

  /// Human-readable explanation of the install failure.
  final String message;

  @override
  String toString() => 'VoiceModelInstallException: $message';
}
