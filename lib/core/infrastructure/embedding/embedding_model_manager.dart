import 'dart:async';
import 'dart:io';

import 'package:control_center/core/network/app_network.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

/// Description of an installable embedding model.
class EmbeddingModelInfo {
  /// Creates [EmbeddingModelInfo].
  const EmbeddingModelInfo({
    required this.id,
    required this.displayName,
    required this.dimension,
    required this.modelUrl,
    required this.modelFile,
    required this.modelBytes,
    required this.vocabUrl,
    required this.vocabFile,
    required this.maxSequenceLength,
  });

  /// Stable id used as the storage subdirectory name.
  final String id;

  /// Human-readable label shown in onboarding/settings.
  final String displayName;

  /// Output vector dimensionality.
  final int dimension;

  /// HTTPS URL of the raw ONNX model file.
  final String modelUrl;

  /// Local filename (relative to the model directory).
  final String modelFile;

  /// Approximate ONNX model file size in bytes (download progress fallback).
  final int modelBytes;

  /// HTTPS URL of the WordPiece vocab.txt.
  final String vocabUrl;

  /// Local filename of the vocab file.
  final String vocabFile;

  /// Maximum tokens the encoder accepts (sentence-transformers MiniLM = 256).
  final int maxSequenceLength;

  /// Default model: sentence-transformers/all-MiniLM-L6-v2 (384-d).
  static const allMiniLmL6V2 = EmbeddingModelInfo(
    id: 'all-MiniLM-L6-v2',
    displayName: 'all-MiniLM-L6-v2 (384-d)',
    dimension: 384,
    modelUrl:
        'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx',
    modelFile: 'model.onnx',
    modelBytes: 90 * 1024 * 1024,
    vocabUrl:
        'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/main/vocab.txt',
    vocabFile: 'vocab.txt',
    maxSequenceLength: 256,
  );
}

/// Resolved on-disk locations for the embedding model assets.
class EmbeddingModelPaths {
  /// Creates a new [EmbeddingModelPaths].
  const EmbeddingModelPaths({required this.model, required this.vocab});

  /// Absolute path to the ONNX model file.
  final String model;

  /// Absolute path to the wordpiece vocabulary file.
  final String vocab;
}

/// Thrown when an install attempt fails.
class EmbeddingModelInstallException implements Exception {
  /// Creates a new [EmbeddingModelInstallException].
  EmbeddingModelInstallException(this.message);

  /// Human-readable error.
  final String message;

  @override
  String toString() => 'EmbeddingModelInstallException: $message';
}

/// Owns the lifecycle of an on-disk embedding model (download → resolve →
/// query). Mirrors the shape of `VoiceModelManager` so the two on-disk
/// model families coexist cleanly under `<root>/models/`.
class EmbeddingModelManager {
  /// Creates a new [EmbeddingModelManager].
  EmbeddingModelManager({
    Dio? dio,
    this.model = EmbeddingModelInfo.allMiniLmL6V2,
  }) : _dio = dio ?? createDio();

  final Dio _dio;

  /// Model to manage.
  final EmbeddingModelInfo model;

  Future<Directory> _rootDir() => modelsRootDir();

  Future<Directory> _modelDir() async {
    final root = await _rootDir();
    final dir = Directory(p.join(root.path, model.id));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Returns paths to a locally installed model, or null when missing.
  Future<EmbeddingModelPaths?> resolve() async {
    final dir = await _modelDir();
    final modelFile = File(p.join(dir.path, model.modelFile));
    final vocabFile = File(p.join(dir.path, model.vocabFile));
    if (modelFile.existsSync() && vocabFile.existsSync()) {
      return EmbeddingModelPaths(
        model: modelFile.path,
        vocab: vocabFile.path,
      );
    }
    return null;
  }

  /// Download model + vocab. Safe to call repeatedly; returns the existing
  /// paths when already installed.
  Future<EmbeddingModelPaths> install({
    void Function(double progress, String phase)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final existing = await resolve();
    if (existing != null) {
      onProgress?.call(1, 'ready');
      return existing;
    }

    final dir = await _modelDir();
    final modelPath = p.join(dir.path, model.modelFile);
    final vocabPath = p.join(dir.path, model.vocabFile);

    onProgress?.call(0, 'downloading');

    try {
      await _dio.download(
        model.modelUrl,
        modelPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final expected = total > 0 ? total : model.modelBytes;
          final pct = (received / expected).clamp(0.0, 1.0) * 0.95;
          onProgress?.call(pct, 'downloading');
        },
        options: Options(
          followRedirects: true,
          responseType: ResponseType.bytes,
        ),
      );

      onProgress?.call(0.96, 'downloading');
      await _dio.download(
        model.vocabUrl,
        vocabPath,
        cancelToken: cancelToken,
        options: Options(followRedirects: true),
      );
    } catch (e) {
      // Clean up partial files so the next attempt starts fresh.
      for (final path in [modelPath, vocabPath]) {
        final f = File(path);
        if (f.existsSync()) {
          await f.delete();
        }
      }
      rethrow;
    }

    final resolved = await resolve();
    if (resolved == null) {
      throw EmbeddingModelInstallException(
        'Downloaded files are missing on disk after install.',
      );
    }
    onProgress?.call(1, 'ready');
    return resolved;
  }

  /// Removes the installed model directory.
  Future<void> uninstall() async {
    final dir = await _modelDir();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}
