import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:cc_domain/features/meetings/domain/value_objects/voice_model_paths.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

// Re-export the relocated value types so existing consumers that import this
// manager keep naming `VoiceModelPaths` / `VoiceModelType` without a churned
// import. The canonical definitions now live in cc_domain.
export 'package:cc_domain/features/meetings/domain/value_objects/voice_model_paths.dart'
    show VoiceModelPaths, VoiceModelType;

/// Configuration for an installable ASR model: where to download it, how it
/// unpacks, and how the recognizer should load it.
///
/// The registry (`VoiceModelInfo.all`) lists every model the app can install;
/// the user picks
/// the active one in Settings (persisted via `selectedVoiceModelProvider`).
///
/// NOTE ON DOWNLOAD URLS: the non-default entries point at the k2-fsa
/// `sherpa-onnx` GitHub release assets. Asset names occasionally change between
/// releases; if a download 404s, only the URL / file-name strings here need
/// updating — the load path is model-type driven and stays correct. A failed
/// download surfaces as a `VoiceModelStatus.error` in Settings, never a crash.
class VoiceModelInfo {
  /// Creates model metadata describing download source and on-disk layout.
  const VoiceModelInfo({
    required this.id,
    required this.displayName,
    required this.type,
    required this.archiveUrl,
    required this.archiveBytes,
    required this.unpackedDirName,
    required this.encoderFile,
    required this.decoderFile,
    required this.tokensFile,
    this.joinerFile,
    this.language,
    this.multilingual = false,
    this.recommended = false,
  }) : assert(
          type != VoiceModelType.transducer || joinerFile != null,
          'A transducer model must declare a joinerFile',
        );

  /// Stable id used in storage paths and settings persistence.
  final String id;

  /// Shown in the model picker ("Parakeet TDT v3").
  final String displayName;

  /// Model family — drives recognizer configuration.
  final VoiceModelType type;

  /// `tar.bz2` download URL.
  final String archiveUrl;

  /// Approximate archive size in bytes (progress-bar denominator when the
  /// server omits `Content-Length`).
  final int archiveBytes;

  /// Top-level directory inside the tarball.
  final String unpackedDirName;

  /// Encoder ONNX file name (relative to [unpackedDirName]).
  final String encoderFile;

  /// Decoder ONNX file name (relative to [unpackedDirName]).
  final String decoderFile;

  /// Tokens text file name (relative to [unpackedDirName]).
  final String tokensFile;

  /// Joiner ONNX file name for transducer models (null for Whisper).
  final String? joinerFile;

  /// Whisper decode language code (`'en'` for english-only models, `null` to
  /// auto-detect). Ignored for transducer models.
  final String? language;

  /// Whether the model handles multiple languages (shown in the picker).
  final bool multilingual;

  /// Whether this is the recommended pick (a hint in the picker).
  final bool recommended;

  /// Approximate download size in megabytes, for the picker subtitle.
  int get approxMb => (archiveBytes / (1024 * 1024)).round();

  /// Whisper base.en — the small, English-only fallback (the historical
  /// default). Kept as a lightweight option for English-only, low-disk setups;
  /// the default is now [parakeetTdtV3].
  static const whisperBaseEn = VoiceModelInfo(
    id: 'sherpa-onnx-whisper-base.en',
    displayName: 'Whisper base.en',
    type: VoiceModelType.whisper,
    archiveUrl:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-base.en.tar.bz2',
    archiveBytes: 198 * 1024 * 1024,
    unpackedDirName: 'sherpa-onnx-whisper-base.en',
    encoderFile: 'base.en-encoder.int8.onnx',
    decoderFile: 'base.en-decoder.int8.onnx',
    tokensFile: 'base.en-tokens.txt',
    language: 'en',
  );

  /// NVIDIA Parakeet TDT 0.6B v2 (English) — FastConformer transducer that
  /// decodes ~10x faster than Whisper base.en with comparable/better accuracy
  /// and token-level timings. Runs on the same sherpa-onnx ONNX runtime on
  /// macOS/Windows/Linux (no Apple lock-in). The recommended pick.
  static const parakeetTdtV2 = VoiceModelInfo(
    id: 'sherpa-onnx-nemo-parakeet_tdt-0.6b-v2-int8',
    displayName: 'Parakeet TDT 0.6B v2 (English)',
    type: VoiceModelType.transducer,
    archiveUrl:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet_tdt-0.6b-v2-int8.tar.bz2',
    archiveBytes: 480 * 1024 * 1024,
    unpackedDirName: 'sherpa-onnx-nemo-parakeet_tdt-0.6b-v2-int8',
    encoderFile: 'encoder.int8.onnx',
    decoderFile: 'decoder.int8.onnx',
    joinerFile: 'joiner.int8.onnx',
    tokensFile: 'tokens.txt',
    language: 'en',
  );

  /// NVIDIA Parakeet TDT 0.6B v3 (25 European languages) — the default. A
  /// FastConformer transducer that decodes ~10x faster than Whisper with
  /// comparable/better accuracy, token-level timings, and multilingual
  /// coverage, all on the same cross-platform sherpa-onnx ONNX runtime
  /// (macOS/Windows/Linux, no Apple lock-in). Asset verified against k2-fsa's
  /// `asr-models` release (`encoder/decoder/joiner.int8.onnx` + `tokens.txt`).
  static const parakeetTdtV3 = VoiceModelInfo(
    id: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
    displayName: 'Parakeet TDT 0.6B v3 (multilingual)',
    type: VoiceModelType.transducer,
    archiveUrl:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8.tar.bz2',
    archiveBytes: 600 * 1024 * 1024,
    unpackedDirName: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
    encoderFile: 'encoder.int8.onnx',
    decoderFile: 'decoder.int8.onnx',
    joinerFile: 'joiner.int8.onnx',
    tokensFile: 'tokens.txt',
    multilingual: true,
    recommended: true,
  );

  /// Whisper large-v3-turbo (99+ languages) — the high-accuracy multilingual
  /// fallback when Parakeet's language set is insufficient. Slower than
  /// Parakeet but reliable. Verify the asset name against the current release.
  static const whisperLargeV3Turbo = VoiceModelInfo(
    id: 'sherpa-onnx-whisper-large-v3-turbo',
    displayName: 'Whisper large-v3-turbo (multilingual)',
    type: VoiceModelType.whisper,
    archiveUrl:
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-large-v3-turbo.tar.bz2',
    archiveBytes: 626 * 1024 * 1024,
    unpackedDirName: 'sherpa-onnx-whisper-large-v3-turbo',
    encoderFile: 'large-v3-turbo-encoder.int8.onnx',
    decoderFile: 'large-v3-turbo-decoder.int8.onnx',
    tokensFile: 'large-v3-turbo-tokens.txt',
    multilingual: true,
  );

  /// Every installable model, in picker order (recommended default first).
  static const List<VoiceModelInfo> all = [
    parakeetTdtV3,
    parakeetTdtV2,
    whisperLargeV3Turbo,
    whisperBaseEn,
  ];

  /// The default model id used when nothing is persisted yet — Parakeet TDT v3
  /// (fast, multilingual, fully portable).
  static const String defaultId = 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8';

  /// Looks up a model by [id], falling back to [parakeetTdtV3] (the default) for
  /// an unknown or null id (e.g. a persisted id that was later removed from the
  /// registry).
  static VoiceModelInfo byId(String? id) =>
      all.firstWhere((m) => m.id == id, orElse: () => parakeetTdtV3);
}

/// Owns the lifecycle of an on-disk speech model (download → extract → query).
///
/// Storage layout (rooted at the injected [CcPaths]):
/// ```
/// <Documents>/control_center/
///   voice_models/
///     <model.unpackedDirName>/
///       <encoder/decoder/[joiner]/tokens files>
/// ```
///
/// Sits as a peer of the per-workspace `<workspaceId>/agents` and
/// `<workspaceId>/skills` folders so every Control Center artifact lives
/// under one inspectable root. The active model is chosen by the caller
/// (`voiceModelManagerProvider` reads `selectedVoiceModelProvider`).
class VoiceModelManager {
  /// Creates a manager for [model] (defaults to Parakeet TDT v3), rooted at
  /// [paths] (the app/server on-disk layout that supplies the `models/` dir).
  VoiceModelManager({
    required CcPaths paths,
    Dio? dio,
    this.model = VoiceModelInfo.parakeetTdtV3,
  })  : _paths = paths,
        _dio = dio ?? createDio();

  final CcPaths _paths;
  final Dio _dio;

  /// Model to manage.
  final VoiceModelInfo model;

  Future<Directory> _rootDir() => _paths.modelsRoot();

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
    final joiner = model.joinerFile != null
        ? File(p.join(dir.path, model.joinerFile!))
        : null;
    final present = encoder.existsSync() &&
        decoder.existsSync() &&
        tokens.existsSync() &&
        (joiner == null || joiner.existsSync());
    if (present) {
      return VoiceModelPaths(
        type: model.type,
        encoder: encoder.path,
        decoder: decoder.path,
        tokens: tokens.path,
        joiner: joiner?.path,
        language: model.language,
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
    // archive only contains a handful of entries.
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
