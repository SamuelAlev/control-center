@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/embedding_model_paths.dart';
import 'package:cc_natives/src/inference/embedding/text_embedder.dart';
import 'package:test/test.dart';

/// The stability gate for semantic search.
///
/// Memory facts, code symbols and space messages hold 384-d vectors on disk,
/// and a search compares freshly computed query vectors against them. The two
/// must stay in the same vector space, so anything that moves the numbers —
/// an ONNX Runtime bump, a pooling edit, a tokenizer change — silently degrades
/// every semantic search result until the whole corpus is re-embedded.
///
/// This re-embeds a fixed corpus and requires each vector to still match
/// `golden_minilm_vectors.json` at cosine >= 0.999.
///
/// Skips when the model is not installed; regenerate goldens ONLY on a
/// deliberate model change, with
/// `packages/cc_natives/tool/gen_embedding_goldens.dart`.
void main() {
  final goldenFile = File(
    'test/inference/embedding/golden_minilm_vectors.json',
  );
  final modelDir =
      Platform.environment['CC_EMBEDDING_MODEL_DIR'] ??
      '${Platform.environment['HOME']}/Library/Application Support/'
          'control-center/models/all-MiniLM-L6-v2';
  final paths = EmbeddingModelPaths(
    model: '$modelDir/model.onnx',
    vocab: '$modelDir/vocab.txt',
  );

  final haveGoldens = goldenFile.existsSync();
  final haveModel =
      File(paths.model).existsSync() && File(paths.vocab).existsSync();

  group('embedding stability', () {
    late Map<String, Object?> goldens;
    TextEmbedder? embedder;

    setUpAll(() async {
      if (!haveGoldens || !haveModel) {
        return;
      }
      goldens =
          jsonDecode(goldenFile.readAsStringSync()) as Map<String, Object?>;
      embedder = await TextEmbedder.load(
        paths: paths,
        dimension: goldens['dimension']! as int,
        maxSequenceLength: goldens['maxSequenceLength']! as int,
      );
    });

    tearDownAll(() async {
      await embedder?.dispose();
    });

    test('every golden vector is reproduced', () async {
      final entries = (goldens['vectors']! as List).cast<Map<String, Object?>>();
      expect(entries, isNotEmpty);

      final failures = <String>[];
      for (final entry in entries) {
        final text = entry['text']! as String;
        final expected = Float32List.fromList([
          for (final v in entry['vector']! as List) (v as num).toDouble(),
        ]);
        final actual = await embedder!.embed(text);

        expect(
          actual.length,
          expected.length,
          reason: 'dimension changed for ${jsonEncode(text)}',
        );
        final similarity = _cosine(expected, actual);
        if (similarity < 0.999) {
          failures.add(
            '${jsonEncode(text)} → cosine ${similarity.toStringAsFixed(6)}',
          );
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'The new ONNX Runtime moved these embeddings away from the vectors '
            'already stored in sqlite_vector. Investigate before shipping — a '
            'real drift means existing rows need re-embedding:\n'
            '${failures.join('\n')}',
      );
    });

    test('vectors are unit-norm, as every consumer assumes', () async {
      final vector = await embedder!.embed('hello world');
      var sumSq = 0.0;
      for (final v in vector) {
        sumSq += v * v;
      }
      expect(math.sqrt(sumSq), closeTo(1.0, 1e-5));
    });
  }, skip: !haveGoldens
      ? 'golden vectors not committed'
      : !haveModel
      ? 'embedding model not installed at $modelDir'
      : null);

  group('failed loads', () {
    _leakGuard(paths.model);
  }, skip: !haveModel ? 'embedding model not installed at $modelDir' : null);
}

/// Cosine similarity. Both sides are unit-norm in practice, so this is a dot
/// product — but normalizing keeps the assertion honest if one side is not.
double _cosine(Float32List a, Float32List b) {
  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) {
    return normA == normB ? 1.0 : 0.0;
  }
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}

/// Regression guard for the native session leaked by a FAILED load.
///
/// `TextEmbedder.load` creates the ONNX session before it reads the vocabulary,
/// so anything that throws in between (an unreadable, truncated or corrupt
/// vocab) leaves the model's weights — tens of MB — stranded for the life of
/// the isolate. Measured on all-MiniLM-L6-v2: ~97 MB per failed load, so a
/// retry loop over a broken install exhausted memory.
///
/// RSS is noisy, so the bound is deliberately loose: it separates "freed" from
/// "leaking ~100 MB a time", not one allocation from another.
void _leakGuard(String modelPath) {
  test('a failed load does not strand the native session', () async {
    final dir = Directory.systemTemp.createTempSync('cc-embedder-leak');
    addTearDown(() {
      // Restore permissions first or the delete fails.
      Process.runSync('chmod', ['644', '${dir.path}/vocab.txt']);
      dir.deleteSync(recursive: true);
    });

    File('${dir.path}/model.onnx').writeAsBytesSync(
      File(modelPath).readAsBytesSync(),
    );
    // Exists (so the up-front check passes) but cannot be read, forcing the
    // failure to land AFTER the native session was created.
    File('${dir.path}/vocab.txt').writeAsStringSync('[PAD]\n');
    final chmod = Process.runSync('chmod', ['000', '${dir.path}/vocab.txt']);
    if (chmod.exitCode != 0) {
      markTestSkipped('cannot make a file unreadable here');
      return;
    }

    final paths = EmbeddingModelPaths(
      model: '${dir.path}/model.onnx',
      vocab: '${dir.path}/vocab.txt',
    );
    final before = ProcessInfo.currentRss;
    for (var i = 0; i < 12; i++) {
      await expectLater(
        TextEmbedder.load(
          paths: paths,
          dimension: 384,
          maxSequenceLength: 256,
        ),
        throwsA(isA<Object>()),
      );
    }
    final grownMb = (ProcessInfo.currentRss - before) / (1024 * 1024);

    expect(
      grownMb,
      lessThan(400),
      reason:
          '12 failed loads grew RSS by ${grownMb.round()} MB. Each one is '
          'stranding its ONNX session — `TextEmbedder.load` must destroy the '
          'handle when anything after the create throws.',
    );
  });
}
