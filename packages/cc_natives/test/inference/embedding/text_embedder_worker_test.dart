import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/embedding_model_paths.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The embedder worker moved ONNX inference off the server's main isolate:
/// `session.run` is synchronous FFI, and a tight embed loop left the RPC
/// server unable to answer a request for a measured 40s while a repo indexed.
/// These tests pin the worker's contract — vectors come back unit-norm and in
/// order, a batch is ONE round trip, a bad init surfaces as an error rather
/// than a hang, and dispose is idempotent.
///
/// The model-dependent cases skip when the on-device model isn't installed;
/// the init-failure and dispose cases run unconditionally.
void main() {
  final home = Platform.environment['HOME'] ?? '';
  final appSupport = Platform.isMacOS
      ? p.join(
          home,
          'Library',
          'Application Support',
          'com.alev.control-center',
        )
      : p.join(home, '.local', 'share', 'control-center');

  // The worker isolate cannot see this isolate's loader state, so it is handed
  // the dylib path explicitly — exactly as the server does.
  final libPath = resolveInferenceLibraryPath(appSupportRoot: appSupport);

  EmbeddingModelPaths? resolveModel() {
    for (final dir in [p.join(appSupport, 'models'), appSupport]) {
      final model = File(p.join(dir, 'model.onnx'));
      final vocab = File(p.join(dir, 'vocab.txt'));
      if (model.existsSync() && vocab.existsSync()) {
        return EmbeddingModelPaths(model: model.path, vocab: vocab.path);
      }
    }
    return null;
  }

  final paths = resolveModel();

  TextEmbedderWorker makeWorker(EmbeddingModelPaths modelPaths) =>
      TextEmbedderWorker(
        paths: modelPaths,
        dimension: 384,
        maxSequenceLength: 256,
        libPath: libPath,
      );

  test('embed returns a unit-norm 384-vector', () async {
    if (paths == null) {
      markTestSkipped('embedding model not installed');
      return;
    }
    final worker = makeWorker(paths);
    addTearDown(worker.dispose);
    await worker.initialize();
    expect(worker.isReady, isTrue);

    final vector = await worker.embed('a function that parses source code');
    expect(vector, hasLength(384));
    var sumSq = 0.0;
    for (final v in vector) {
      sumSq += v * v;
    }
    expect(sumSq, closeTo(1.0, 0.01), reason: 'vectors must be L2-normalized');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('embedBatch returns one vector per text, in order', () async {
    if (paths == null) {
      markTestSkipped('embedding model not installed');
      return;
    }
    final worker = makeWorker(paths);
    addTearDown(worker.dispose);
    await worker.initialize();

    const texts = ['alpha symbol', 'beta symbol', 'gamma symbol'];
    final vectors = await worker.embedBatch(texts);
    expect(vectors, hasLength(3));
    // Order is positional, so the same text at the same index must match a
    // single-shot embed of it.
    final single = await worker.embed(texts[1]);
    expect(vectors[1].first, closeTo(single.first, 1e-6));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('an empty batch is a no-op that never spawns work', () async {
    final worker = TextEmbedderWorker(
      paths: const EmbeddingModelPaths(model: '/nope', vocab: '/nope'),
      dimension: 384,
      maxSequenceLength: 256,
    );
    addTearDown(worker.dispose);
    expect(await worker.embedBatch(const []), isEmpty);
    expect(worker.isReady, isFalse, reason: 'no init for an empty batch');
  });

  test(
    'a bad model path fails initialize (no hang) and can be disposed',
    () async {
      final worker = TextEmbedderWorker(
        paths: const EmbeddingModelPaths(
          model: '/definitely/missing/model.onnx',
          vocab: '/definitely/missing/vocab.txt',
        ),
        dimension: 384,
        maxSequenceLength: 256,
        libPath: libPath,
      );
      addTearDown(worker.dispose);

      await expectLater(
        worker.initialize().timeout(const Duration(seconds: 30)),
        throwsA(isA<StateError>()),
        reason:
            'the worker must report init_error rather than leaving the '
            'caller waiting forever',
      );
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );

  test('dispose is idempotent and rejects later use', () async {
    final worker = TextEmbedderWorker(
      paths: const EmbeddingModelPaths(model: '/nope', vocab: '/nope'),
      dimension: 384,
      maxSequenceLength: 256,
    );
    await worker.dispose();
    await worker.dispose();
    expect(worker.isReady, isFalse);
    await expectLater(worker.embed('x'), throwsA(isA<StateError>()));
  });
}
