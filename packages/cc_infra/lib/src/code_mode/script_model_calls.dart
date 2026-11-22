import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/embedding_ranking.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/code_mode/code_runner_slots.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The `status` a script sees on a call the host refused because a per-script
/// limit (tool calls, questions, model text) ran out.
const String kScriptLimitStatus = 'limit_exceeded';

/// The `models.*` host functions of one script: embeddings, ranking and
/// classification on the server's on-device embedding model.
///
/// A script sends the model at most [CodeModeLimits.maxModelBytesPerScript]
/// of text and has at most [CodeModeLimits.maxConcurrentModelCalls] batches
/// in flight; scripts across the server share `serverBatches`. A batch
/// starts only once `mayStart` lets it, which holds it while the script
/// waits on a person, as a tool call is held.
class ScriptModelCalls {
  /// Creates the model calls of one script. Without `embeddings` (or with
  /// one not ready) every call fails and says the model is not installed.
  ScriptModelCalls({
    required this._embeddings,
    required this._serverBatches,
    required this._scriptEnd,
    required this._ended,
    required this._mayStart,
    required this._reply,
    required this._reject,
  });

  final EmbeddingPort? _embeddings;
  final CountingSemaphore _serverBatches;
  final CancellationToken _scriptEnd;
  final bool Function() _ended;
  final Future<void> Function() _mayStart;
  final void Function(String id, Object? value) _reply;
  final void Function(String id, String message, {String? status}) _reject;
  int _calls = 0;
  int _bytes = 0;
  final Queue<Completer<void>> _waiters = Queue();

  /// Lets every batch waiting for a place go; called once the script ended,
  /// so each sees the end and does nothing.
  void end() {
    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    }
  }

  /// Answers the `models.*` host call [call].
  Future<void> answer(CodeSandboxCall call) async {
    final embeddings = _embeddings;
    if (embeddings == null || !embeddings.isReady) {
      _reject(
        call.id,
        'The on-device embedding model is not installed on this server, so '
        'models.embed, models.rank and models.classify are unavailable.',
        status: 'unavailable',
      );
      return;
    }
    final args = call.arguments;
    List<String>? strings(Object? raw) {
      if (raw is! List || raw.any((e) => e is! String)) {
        return null;
      }
      return raw.cast<String>();
    }

    final List<String> texts;
    String? query;
    List<String>? labels;
    int? top;
    switch (call.name) {
      case 'models.embed':
        final t = strings(args['texts']);
        if (t == null) {
          _reject(call.id, 'models.embed(texts) needs an array of strings.');
          return;
        }
        texts = t;
      case 'models.rank':
        final q = args['query'];
        final c = strings(args['candidates']);
        final rawTop = args['top'];
        if (q is! String || c == null || (rawTop != null && rawTop is! int)) {
          _reject(
            call.id,
            'models.rank(query, candidates, { top }) needs a string query, an '
            'array of strings and an integer top.',
          );
          return;
        }
        query = q;
        texts = c;
        top = rawTop as int?;
        if (top != null && top < 0) {
          _reject(call.id, 'models.rank top must not be negative.');
          return;
        }
      default:
        final t = strings(args['texts']);
        final l = strings(args['labels']);
        if (t == null || l == null || l.isEmpty) {
          _reject(
            call.id,
            'models.classify(texts, labels) needs an array of strings and a '
            'non-empty array of labels.',
          );
          return;
        }
        texts = t;
        labels = l;
        if (l.length > CodeModeLimits.maxModelBatch) {
          _reject(
            call.id,
            'models.classify takes at most ${CodeModeLimits.maxModelBatch} '
            'labels.',
          );
          return;
        }
    }
    if (texts.length > CodeModeLimits.maxModelBatch) {
      _reject(
        call.id,
        '${call.name} takes at most ${CodeModeLimits.maxModelBatch} texts in '
        'one call; split the batch.',
      );
      return;
    }
    var batchBytes = 0;
    for (final text in [?query, ...texts, ...?labels]) {
      final bytes = utf8Length(text);
      if (bytes > CodeModeLimits.maxModelTextBytes) {
        _reject(
          call.id,
          '${call.name} takes texts of at most '
          '${CodeModeLimits.maxModelTextBytes ~/ 1024} KiB; one is $bytes '
          'bytes. Shorten it: the model reads only the start of a text.',
        );
        return;
      }
      batchBytes += bytes;
    }
    if (_bytes + batchBytes > CodeModeLimits.maxModelBytesPerScript) {
      _reject(
        call.id,
        'This script has sent the embedding model '
        '${CodeModeLimits.maxModelBytesPerScript ~/ (1024 * 1024)} MiB of '
        'text, its limit. Return what you have and continue in another '
        'script.',
        status: kScriptLimitStatus,
      );
      return;
    }
    _bytes += batchBytes;
    // Nothing new starts while the script waits on a person.
    await _mayStart();
    await _acquire();
    // Embeddings run on one worker the code index shares: scripts across
    // the server get a bounded share of its queue.
    final serverSlot = await _serverBatches.acquire(cancel: _scriptEnd);
    try {
      if (_ended() || !serverSlot) {
        return;
      }
      final Object? value;
      switch (call.name) {
        case 'models.embed':
          final vectors = await embeddings.embedAll(texts);
          value = [for (final v in vectors) _vector(v)];
        case 'models.rank':
          final vectors = await embeddings.embedAll([query!, ...texts]);
          final hits = EmbeddingRanking.rank(_doubles(vectors.first), [
            for (final v in vectors.skip(1)) _doubles(v),
          ], top: top);
          value = [
            for (final hit in hits) {...hit.toJson(), 'text': texts[hit.index]},
          ];
        default:
          final vectors = await embeddings.embedAll([...texts, ...labels!]);
          final results = EmbeddingRanking.classify(
            [for (final v in vectors.take(texts.length)) _doubles(v)],
            [for (final v in vectors.skip(texts.length)) _doubles(v)],
          );
          value = [
            for (final r in results)
              {
                'label': labels[r.label],
                'index': r.label,
                'score': r.toJson()['score'],
              },
          ];
      }
      _reply(call.id, value);
    } on Object catch (e, st) {
      // The model's error can name a host path: it goes to the log.
      CcInfraLog.error('code mode: ${call.name} failed', e, st);
      _reject(call.id, '${call.name} failed on the server.');
    } finally {
      if (serverSlot) {
        _serverBatches.release();
      }
      _release();
    }
  }

  static List<double> _doubles(List<double> v) => List<double>.of(v);

  static List<double> _vector(List<double> v) => [
    for (final x in v) double.parse(x.toStringAsFixed(6)),
  ];

  Future<void> _acquire() async {
    if (_calls < CodeModeLimits.maxConcurrentModelCalls) {
      _calls++;
      return;
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    await waiter.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    } else {
      _calls--;
    }
  }
}
