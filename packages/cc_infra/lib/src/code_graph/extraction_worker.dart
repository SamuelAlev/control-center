import 'dart:async';
import 'dart:isolate';

import 'package:cc_infra/src/code_graph/code_extractor.dart';
import 'package:cc_infra/src/code_graph/extraction_isolate.dart';
import 'package:cc_natives/cc_natives.dart'
    show TreeSitterLoader, TreeSitterParser, TreeSitterUnavailable;

/// A LONG-LIVED tree-sitter extraction worker: one isolate serving every file
/// of an index run, instead of one throwaway `Isolate.run` per file.
///
/// The per-file isolate re-resolved the tree-sitter dylibs and recompiled the
/// whole `.scm` query for every single file — the dominant per-file overhead
/// on a big run. Here the loader/parser live inside the worker (FFI handles
/// cannot cross isolates), the parser caches compiled queries per language,
/// and only plain request/result objects travel over the [SendPort]. Follows
/// the `SherpaOnnxTranscriber` worker shape.
///
/// Lifecycle is one worker per `indexRepo` run: `maxConcurrentRuns == 1`
/// means at most one exists anyway, per-run scoping keeps loader/grammar
/// state trivially correct, and any native leak is bounded to one run. The
/// spawn cost (~tens of ms) amortizes over hundreds of files.
///
/// A worker held by a wedged parse cannot process a graceful shutdown
/// message, so the timeout path must [kill], not [dispose] — a fresh worker
/// then serves the remaining files.
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
  /// so no caller hangs, and mark the worker dead so the owner respawns.
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
