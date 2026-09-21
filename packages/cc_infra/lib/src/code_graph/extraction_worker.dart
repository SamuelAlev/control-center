import 'dart:async';
import 'dart:isolate';

import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_infra/src/code_graph/extraction_isolate.dart';
import 'package:cc_natives/cc_natives.dart'
    show TreeSitterLoader, TreeSitterParser, TreeSitterUnavailable;

/// Long-lived tree-sitter extraction worker: one isolate per `indexRepo` run
/// (not per file). Loader/parser stay in-worker (FFI cannot cross isolates);
/// queries cache per language. Timeout path [kill]s (wedged parse cannot
/// dispose). Spawn cost amortizes over hundreds of files.
class ExtractionWorker {
  ExtractionWorker._();

  /// Spawns the worker isolate and completes the [SendPort] handshake.
  static Future<ExtractionWorker> spawn() async {
    final worker = ExtractionWorker._();
    await worker._spawn();
    return worker;
  }

  Isolate? _isolate;
  SendPort? _commands;
  ReceivePort? _fromWorker;
  StreamSubscription<dynamic>? _fromWorkerSub;
  final Map<int, Completer<ExtractionResult>> _pending = {};
  int _nextRequestId = 0;
  bool _dead = false;

  /// Whether the worker can still take requests.
  bool get isAlive => !_dead && _commands != null;

  Future<void> _spawn() async {
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
      _extractionWorkerMain,
      fromWorker.sendPort,
      debugName: 'code-extraction',
      onError: fromWorker.sendPort,
      onExit: fromWorker.sendPort,
    );
    _commands = await handshake.future;
  }

  void _onWorkerMessage(Map<Object?, Object?> msg) {
    switch (msg['type']) {
      case 'result':
        _pending
            .remove(msg['id'])
            ?.complete(msg['result']! as ExtractionResult);
      case 'error':
        final message = msg['message'] as String? ?? 'extraction failed';
        _pending
            .remove(msg['id'])
            ?.completeError(
              msg['unavailable'] == true
                  ? TreeSitterUnavailable(message)
                  : StateError(message),
            );
    }
  }

  /// The worker isolate threw or exited abnormally: fail everything in flight
  /// so no caller hangs and mark the worker dead so the owner respawns.
  void _onWorkerCrash(List<Object?> error) {
    if (_dead) {
      return;
    }
    _dead = true;
    final detail = error.isNotEmpty ? '${error.first}' : 'unknown error';
    final err = StateError('extraction worker isolate crashed: $detail');
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    }
    _pending.clear();
  }

  /// Extracts one file inside the worker. Requests are processed one at a
  /// time (the worker's message loop is single-threaded), matching the
  /// indexer's sequential await.
  Future<ExtractionResult> extract(ExtractionRequest request) {
    final commands = _commands;
    if (_dead || commands == null) {
      return Future.error(StateError('extraction worker is not running'));
    }
    final id = _nextRequestId++;
    final completer = Completer<ExtractionResult>();
    _pending[id] = completer;
    commands.send(<String, Object?>{
      'type': 'extract',
      'id': id,
      'request': request,
    });
    return completer.future;
  }

  /// Graceful shutdown: the worker frees its native parser/query handles
  /// (an isolate's death does NOT reclaim native allocations) and exits.
  /// Call at run end / cancellation; for a wedged worker use [kill].
  Future<void> dispose() async {
    if (_dead) {
      await _closeHostSide();
      return;
    }
    _dead = true;
    _commands?.send(const <String, Object?>{'type': 'dispose'});
    await _closeHostSide();
  }

  /// Forceful shutdown for a worker wedged inside a native parse (it cannot
  /// process a 'dispose' message). Fails anything in flight. The wedged
  /// parse's native allocations leak — bounded to the pathological file that
  /// earned the kill.
  Future<void> kill() async {
    _dead = true;
    final err = StateError('extraction worker killed (parse timeout)');
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(err);
      }
    }
    _pending.clear();
    _isolate?.kill(priority: Isolate.immediate);
    await _closeHostSide();
  }

  Future<void> _closeHostSide() async {
    await _fromWorkerSub?.cancel();
    _fromWorkerSub = null;
    _fromWorker?.close();
    _fromWorker = null;
    _commands = null;
    _isolate = null;
  }
}

/// Worker isolate entry point: owns the tree-sitter loader/parser (created
/// in here — FFI handles cannot cross isolates) and serves extraction
/// requests until told to dispose. A request for a language it has not seen
/// yet extends the grammar map and rebuilds the loader/parser (once per
/// language per run, not per file).
void _extractionWorkerMain(SendPort toHost) {
  final commands = ReceivePort();
  toHost.send(commands.sendPort);

  final grammarPaths = <String, String>{};
  String? runtimePath;
  TreeSitterParser? parser;

  commands.listen((Object? message) {
    if (message is! Map) {
      return;
    }
    switch (message['type']) {
      case 'extract':
        final id = message['id'];
        final request = message['request']! as ExtractionRequest;
        try {
          if (parser == null ||
              runtimePath != request.runtimePath ||
              grammarPaths[request.languageId] != request.grammarPath) {
            parser?.dispose();
            runtimePath = request.runtimePath;
            grammarPaths[request.languageId] = request.grammarPath;
            parser = TreeSitterParser(
              TreeSitterLoader(
                runtimePath: request.runtimePath,
                grammarPaths: Map.of(grammarPaths),
              ),
            );
          }
          final result = const CodeExtractor().extract(
            workspaceId: request.workspaceId,
            repoId: request.repoId,
            checkoutId: request.checkoutId,
            filePath: request.filePath,
            source: request.source,
            languageId: request.languageId,
            querySource: request.querySource,
            parser: parser!,
          );
          toHost.send(<String, Object?>{
            'type': 'result',
            'id': id,
            'result': result,
          });
        } on TreeSitterUnavailable catch (e) {
          toHost.send(<String, Object?>{
            'type': 'error',
            'id': id,
            'message': e.message,
            'unavailable': true,
          });
        } on Object catch (e) {
          toHost.send(<String, Object?>{
            'type': 'error',
            'id': id,
            'message': '$e',
            'unavailable': false,
          });
        }
      case 'dispose':
        parser?.dispose();
        parser = null;
        commands.close();
    }
  });
}
