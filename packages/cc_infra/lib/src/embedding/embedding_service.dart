import 'dart:async' show Timer, unawaited;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_infra/src/embedding/embedding_model_manager.dart';
import 'package:cc_natives/cc_natives.dart';

/// On-device text embedder: lazy ONNX load, unload after [idleUnloadAfter]
/// (weights are the largest idle allocation; reload is sub-second).
///
/// Inference on [TextEmbedderWorker] — sync FFI `session.run` on the main
/// isolate blocked RPCs for ~40s during index. One singleton per host (second
/// instance = second worker + session). Flutter-free for desktop + `cc_server`.
class EmbeddingService implements EmbeddingPort {
  /// Creates an [EmbeddingService]. The [_paths] are typically supplied
  /// by [EmbeddingModelManager.resolve] once the model is installed.
  /// [_libPath] is the absolute path of the `cc_inference` dylib, forwarded to
  /// the worker isolate: it cannot see this isolate's loader state and a
  /// hardened `dart build cli` binary rejects leaf-name dlopens.
  EmbeddingService({
    required this._modelInfo,
    this._paths,
    this._libPath,
    this.idleUnloadAfter = const Duration(minutes: 5),
  });

  /// How long the loaded ONNX session survives without an [embed] call before
  /// it is released. Embeds arrive in bursts (backfill, search, message
  /// ingest), so a short window reclaims hundreds of MB between bursts.
  final Duration idleUnloadAfter;

  final EmbeddingModelInfo _modelInfo;
  final String? _libPath;
  EmbeddingModelPaths? _paths;
  TextEmbedderWorker? _worker;
  Future<TextEmbedderWorker>? _loading;
  Timer? _idleTimer;
  int _inFlight = 0;

  @override
  int get dimension => _modelInfo.dimension;

  @override
  bool get isReady => _paths != null;

  /// Whether the underlying ONNX session (worker isolate) has been loaded.
  bool get isLoaded => _worker != null;

  /// Update the on-disk paths (called after a successful install or when
  /// the model is uninstalled).
  void updatePaths(EmbeddingModelPaths? paths) {
    if (paths == _paths) {
      return;
    }
    _paths = paths;
    _unload();
  }

  @override
  Future<Float32List> embed(String text) async =>
      (await embedAll([text])).first;

  @override
  Future<List<Float32List>> embedAll(List<String> texts) async {
    if (texts.isEmpty) {
      return const [];
    }
    final paths = _paths;
    if (paths == null) {
      throw StateError(
        'EmbeddingService.embed called before the model was installed.',
      );
    }
    _idleTimer?.cancel();
    _inFlight++;
    try {
      final worker = await _ensureLoaded(paths);
      return await worker.embedBatch(texts);
    } finally {
      _inFlight--;
      _restartIdleTimer();
    }
  }

  /// Spawns + initialises the worker once even under concurrent embeds —
  /// parallel callers await the same in-flight load instead of each opening
  /// a session.
  Future<TextEmbedderWorker> _ensureLoaded(EmbeddingModelPaths paths) {
    final existing = _worker;
    if (existing != null) {
      return Future.value(existing);
    }
    return _loading ??=
        () async {
          final worker = TextEmbedderWorker(
            paths: paths,
            dimension: _modelInfo.dimension,
            maxSequenceLength: _modelInfo.maxSequenceLength,
            libPath: _libPath,
          );
          try {
            await worker.initialize();
          } on Object {
            unawaited(worker.dispose());
            rethrow;
          }
          return worker;
        }().then(
          (worker) {
            _loading = null;
            // Paths changed while loading (model swapped/uninstalled): discard.
            if (_paths != paths) {
              unawaited(worker.dispose());
              throw StateError('Embedding model changed while loading.');
            }
            return _worker = worker;
          },
          onError: (Object e) {
            _loading = null;
            throw e;
          },
        );
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    if (_worker == null && _loading == null) {
      return;
    }
    _idleTimer = Timer(idleUnloadAfter, () {
      if (_inFlight > 0) {
        _restartIdleTimer();
        return;
      }
      _unload();
    });
  }

  void _unload() {
    _idleTimer?.cancel();
    _idleTimer = null;
    final old = _worker;
    _worker = null;
    if (old != null) {
      // Best-effort cleanup: the worker isolate dies with its session,
      // handing the whole ORT arena back to the OS.
      unawaited(old.dispose());
    }
  }

  /// Frees the loaded ONNX session (kills the worker isolate), if any.
  Future<void> dispose() async {
    _idleTimer?.cancel();
    _idleTimer = null;
    final worker = _worker;
    _worker = null;
    if (worker != null) {
      await worker.dispose();
    }
  }
}
