import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/embedding_model_paths.dart';
import 'package:cc_natives/src/inference/embedding/text_embedder.dart';

/// [TextEmbedder] hosted on a dedicated worker isolate.
///
/// `TextEmbedder.embed` is async in signature but synchronous inside —
/// tokenize plus an ONNX `session.run` over FFI. Run on the server's main
/// isolate, a tight embed loop starved pending I/O completely: measured, the
/// RPC server accepted connections but could not answer a request for 40s
/// while a repo indexed. The ONNX session holds FFI handles that cannot cross
/// isolates, so — exactly like `SherpaOnnxTranscriber` — the session is
/// created INSIDE the worker and fed texts over a [SendPort]; only strings
/// and (transferable) vector bytes travel between isolates.
///
/// [embedBatch] amortizes the round-trip over a whole batch (the code-graph
/// ingest path embeds hundreds of symbols per flush). A crashed worker fails
/// everything in flight and respawns transparently on the next call.
class TextEmbedderWorker {
  /// Creates a [TextEmbedderWorker]. [libPath], when given, is the absolute
  /// path of the `cc_inference` dylib, forwarded to the worker: the worker
  /// isolate cannot see the host isolate's preferred-path static (Dart statics
  /// do not cross isolates) and a hardened `dart build cli` binary cannot
  /// resolve a bare leaf name through its rpath.
  TextEmbedderWorker({
    required this.paths,
    required this.dimension,
    required this.maxSequenceLength,
    this.libPath,
  });

  /// Resolved on-disk model + vocab paths.
  final EmbeddingModelPaths paths;

  /// Output vector size.
  final int dimension;

  /// Maximum tokens fed to the encoder.
  final int maxSequenceLength;

  /// Absolute path of the `cc_inference` dylib; null = let the worker resolve
  /// it from the environment and bundle layout itself.
  final String? libPath;

  Isolate? _isolate;
  SendPort? _commands;
  ReceivePort? _fromWorker;
  StreamSubscription<dynamic>? _fromWorkerSub;
  Completer<void>? _ready;
  final Map<int, Completer<List<Float32List>>> _pending = {};
  int _nextRequestId = 0;
  bool _disposed = false;

  /// Whether the worker is initialised and accepting requests.
  bool get isReady => (_ready?.isCompleted ?? false) && !_disposed;

  /// Spawns the worker isolate and loads the model inside it. Idempotent;
  /// concurrent callers await the same in-flight initialisation.
  Future<void> initialize() {
    if (_disposed) {
      return Future.error(StateError('TextEmbedderWorker is disposed.'));
    }
    final existing = _ready;
    if (existing != null) {
      return existing.future;
    }
    final ready = _ready = Completer<void>();
    unawaited(_spawnWorker(ready));
    return ready.future;
  }

  Future<void> _spawnWorker(Completer<void> ready) async {
    try {
      final fromWorker = _fromWorker = ReceivePort();
      final handshake = Completer<SendPort>();
      _fromWorkerSub = fromWorker.listen((Object? message) {
        if (message is SendPort) {
          handshake.complete(message);
        } else if (message is List) {
          // Uncaught error / abnormal exit forwarded via onError/onExit.
          _onWorkerCrash(message);
        } else if (message is Map) {
          _onWorkerMessage(message);
        }
      });
      _isolate = await Isolate.spawn(
        _embedderWorkerMain,
        fromWorker.sendPort,
        debugName: 'text-embedder',
        onError: fromWorker.sendPort,
        onExit: fromWorker.sendPort,
      );
      final commands = _commands = await handshake.future;
      commands.send(<String, Object?>{
        'type': 'init',
        'model': paths.model,
        'vocab': paths.vocab,
        'dimension': dimension,
        'maxSequenceLength': maxSequenceLength,
        'libPath': libPath,
      });
      // `ready` is completed by _onWorkerMessage on 'ready'/'init_error'.
    } catch (e) {
      if (!ready.isCompleted) {
        ready.completeError(e);
      }
    }
  }

  void _onWorkerMessage(Map<Object?, Object?> msg) {
    switch (msg['type']) {
      case 'ready':
        if (!(_ready?.isCompleted ?? true)) {
          _ready!.complete();
        }
      case 'init_error':
        if (!(_ready?.isCompleted ?? true)) {
          _ready!.completeError(
            StateError(msg['message'] as String? ?? 'embedder init failed'),
          );
        }
      case 'result':
        final raw = msg['vectors']! as List;
        _pending.remove(msg['id'])?.complete([
          for (final v in raw)
            (v! as TransferableTypedData).materialize().asFloat32List(),
        ]);
      case 'error':
        _pending
            .remove(msg['id'])
            ?.completeError(
              StateError(msg['message'] as String? ?? 'embed failed'),
            );
    }
  }

  /// The worker isolate threw or exited abnormally: fail everything in flight
  /// so no caller hangs and reset [_ready] so the next call respawns a fresh
  /// worker (and reloads the session) transparently.
  void _onWorkerCrash(List<Object?> error) {
    final detail = error.isNotEmpty ? '${error.first}' : 'unknown error';
    final err = StateError('embedder worker isolate crashed: $detail');
    final ready = _ready;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(err);
    }
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    }
    _pending.clear();
    _ready = null;
    _commands = null;
    _isolate = null;
  }

  /// Returns a unit-norm vector for [text].
  Future<Float32List> embed(String text) async =>
      (await embedBatch([text])).first;

  /// Returns a unit-norm vector for every entry of [texts], in order — ONE
  /// worker round-trip for the whole batch.
  Future<List<Float32List>> embedBatch(List<String> texts) async {
    if (texts.isEmpty) {
      return const [];
    }
    if (_disposed) {
      throw StateError('TextEmbedderWorker is disposed.');
    }
    await initialize();
    final commands = _commands;
    if (_disposed || commands == null) {
      throw StateError('TextEmbedderWorker is not running.');
    }
    final id = _nextRequestId++;
    final completer = Completer<List<Float32List>>();
    _pending[id] = completer;
    commands.send(<String, Object?>{'type': 'embed', 'id': id, 'texts': texts});
    return completer.future;
  }

  /// Shuts the worker down, releasing the whole ONNX session + arena with the
  /// isolate. Idempotent. The next [initialize] after dispose fails; create a
  /// fresh instance instead (the owning service does).
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final err = StateError('TextEmbedderWorker disposed.');
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    }
    _pending.clear();
    _commands?.send(const <String, Object?>{'type': 'dispose'});
    await _fromWorkerSub?.cancel();
    _fromWorkerSub = null;
    _fromWorker?.close();
    _fromWorker = null;
    _commands = null;
    // Backstop for a worker that never processes the graceful message
    // (mirrors SherpaOnnxTranscriber.dispose).
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _isolate = null;
    _ready = null;
  }
}

/// Worker isolate entry point: loads the ONNX session in here (FFI handles
/// cannot cross isolates) and serves embed batches until told to dispose.
Future<void> _embedderWorkerMain(SendPort toHost) async {
  final commands = ReceivePort();
  toHost.send(commands.sendPort);

  TextEmbedder? embedder;

  await for (final Object? message in commands) {
    if (message is! Map) {
      continue;
    }
    switch (message['type']) {
      case 'init':
        try {
          // The dylib is opened HERE, on the worker isolate: bindings are
          // per-isolate and this is also the only place a genuine load
          // failure can surface as an actionable `init_error` rather than
          // freezing a host that probed by opening.
          embedder = await TextEmbedder.load(
            paths: EmbeddingModelPaths(
              model: message['model']! as String,
              vocab: message['vocab']! as String,
            ),
            dimension: message['dimension']! as int,
            maxSequenceLength: message['maxSequenceLength']! as int,
            libPath: message['libPath'] as String?,
          );
          toHost.send(const <String, Object?>{'type': 'ready'});
        } on Object catch (e) {
          toHost.send(<String, Object?>{'type': 'init_error', 'message': '$e'});
        }
      case 'embed':
        final id = message['id'];
        try {
          final texts = (message['texts']! as List).cast<String>();
          final vectors = <TransferableTypedData>[];
          for (final text in texts) {
            final v = await embedder!.embed(text);
            vectors.add(
              TransferableTypedData.fromList([Uint8List.view(v.buffer)]),
            );
          }
          toHost.send(<String, Object?>{
            'type': 'result',
            'id': id,
            'vectors': vectors,
          });
        } on Object catch (e) {
          toHost.send(<String, Object?>{
            'type': 'error',
            'id': id,
            'message': '$e',
          });
        }
      case 'dispose':
        await embedder?.dispose();
        embedder = null;
        commands.close();
    }
  }
}
