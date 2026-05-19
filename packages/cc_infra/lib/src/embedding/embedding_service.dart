import 'dart:async' show unawaited;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_natives/cc_natives.dart';

/// On-device text embedder. Loads the ONNX session lazily on first use
/// once the model has been installed on disk.
///
/// Lives in cc_infra (Flutter-free) so BOTH the desktop app and the headless
/// `cc_server` construct the SAME on-device embedder — it depends only on
/// cc_domain (the port), cc_infra (the model manager), and cc_natives (the
/// ONNX/FFI runtime), never on Flutter.
class EmbeddingService implements EmbeddingPort {
  /// Creates an [EmbeddingService]. The [paths] are typically supplied
  /// by [EmbeddingModelManager.resolve] once the model is installed.
  EmbeddingService({
    required EmbeddingModelInfo modelInfo,
    EmbeddingModelPaths? paths,
  }) : _modelInfo = modelInfo,
       _paths = paths;

  final EmbeddingModelInfo _modelInfo;
  EmbeddingModelPaths? _paths;
  TextEmbedder? _embedder;

  @override
  int get dimension => _modelInfo.dimension;

  @override
  bool get isReady => _paths != null;

  /// Whether the underlying ONNX session has been loaded into memory.
  bool get isLoaded => _embedder != null;

  /// Update the on-disk paths (called after a successful install or when
  /// the model is uninstalled).
  void updatePaths(EmbeddingModelPaths? paths) {
    if (paths == _paths) {
      return;
    }
    _paths = paths;
    final old = _embedder;
    _embedder = null;
    if (old != null) {
      // Best-effort cleanup of the previous session.
      unawaited(old.dispose());
    }
  }

  @override
  Future<Float32List> embed(String text) async {
    final paths = _paths;
    if (paths == null) {
      throw StateError(
        'EmbeddingService.embed called before the model was installed.',
      );
    }
    final embedder = _embedder ??= await TextEmbedder.load(
      paths: paths,
      dimension: _modelInfo.dimension,
      maxSequenceLength: _modelInfo.maxSequenceLength,
    );
    return embedder.embed(text);
  }

  /// Frees the loaded ONNX session, if any.
  Future<void> dispose() async {
    final embedder = _embedder;
    _embedder = null;
    if (embedder != null) {
      await embedder.dispose();
    }
  }
}
