import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/embedding/embedding_model_manager.dart';
import 'package:dart_wordpiece/dart_wordpiece.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

/// Loads an ONNX BERT-style sentence-transformer model + its WordPiece
/// vocabulary and produces unit-norm sentence embeddings via
/// mean-pooling over the token embeddings, masked by `attention_mask`.
///
/// Compatible with `sentence-transformers/all-MiniLM-L6-v2` (384-d).
class TextEmbedder {
  TextEmbedder._({
    required this.dimension,
    required OrtSession session,
    required WordPieceTokenizer tokenizer,
    required this.maxSequenceLength,
  }) : _session = session,
       _tokenizer = tokenizer;

  /// Output vector size produced by [embed].
  final int dimension;

  /// Maximum tokens fed to the encoder.
  final int maxSequenceLength;

  final OrtSession _session;
  final WordPieceTokenizer _tokenizer;
  bool _disposed = false;

  /// Loads the ONNX session and tokenizer from on-disk [paths].
  static Future<TextEmbedder> load({
    required EmbeddingModelPaths paths,
    required int dimension,
    required int maxSequenceLength,
  }) async {
    OrtEnv.instance.init();

    final sessionOptions = OrtSessionOptions();
    final session = OrtSession.fromFile(File(paths.model), sessionOptions);

    final vocab = await VocabLoader.fromFile(File(paths.vocab));
    final tokenizer = WordPieceTokenizer(vocab: vocab);

    return TextEmbedder._(
      dimension: dimension,
      session: session,
      tokenizer: tokenizer,
      maxSequenceLength: maxSequenceLength,
    );
  }

  /// Returns a unit-norm vector representation of [text].
  Future<Float32List> embed(String text) async {
    if (_disposed) {
      throw StateError('TextEmbedder is disposed.');
    }
    final tokens = _tokenizer.encode(text);
    final seqLen = math.min(tokens.realLength, maxSequenceLength);

    final inputIds = Int64List.fromList(
      tokens.inputIds.sublist(0, seqLen),
    );
    final attentionMask = Int64List.fromList(
      tokens.attentionMask.sublist(0, seqLen),
    );
    final tokenTypeIds = Int64List.fromList(
      tokens.tokenTypeIds.sublist(0, seqLen),
    );

    final shape = <int>[1, seqLen];
    final idsTensor = OrtValueTensor.createTensorWithDataList(inputIds, shape);
    final maskTensor = OrtValueTensor.createTensorWithDataList(
      attentionMask,
      shape,
    );
    final typeTensor = OrtValueTensor.createTensorWithDataList(
      tokenTypeIds,
      shape,
    );

    final runOptions = OrtRunOptions();
    try {
      final outputs = _session.run(runOptions, {
        'input_ids': idsTensor,
        'attention_mask': maskTensor,
        'token_type_ids': typeTensor,
      });

      final raw = outputs.firstOrNull?.value;
      if (raw == null) {
        throw StateError('ONNX session returned no output tensor.');
      }

      // last_hidden_state shape: [1, seqLen, hiddenSize]. The runtime returns
      // it as a nested List<List<List<double>>>.
      final tokenEmbeddings = _flattenBatchOne(raw);
      final pooled = _meanPool(
        tokenEmbeddings,
        attentionMask,
        seqLen,
        dimension,
      );
      _l2Normalize(pooled);
      return pooled;
    } finally {
      idsTensor.release();
      maskTensor.release();
      typeTensor.release();
      runOptions.release();
    }
  }

  /// Frees the underlying ONNX session.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _session.release();
  }

  /// Extracts the [seqLen, hiddenSize] matrix from a [1, seqLen, hiddenSize]
  /// nested-list output. The ONNX runtime returns tensors as nested
  /// `List<num>` whose innermost type can be `double` or `num`.
  static List<List<double>> _flattenBatchOne(Object raw) {
    final batch = raw as List;
    final firstBatch = batch.first as List;
    return [
      for (final row in firstBatch)
        [for (final v in row as List) (v as num).toDouble()],
    ];
  }

  static Float32List _meanPool(
    List<List<double>> tokenEmbeddings,
    Int64List mask,
    int seqLen,
    int dim,
  ) {
    final sum = Float32List(dim);
    var weight = 0.0;
    for (var t = 0; t < seqLen; t++) {
      if (mask[t] == 0) {
        continue;
      }
      final row = tokenEmbeddings[t];
      for (var d = 0; d < dim; d++) {
        sum[d] += row[d];
      }
      weight += 1.0;
    }
    if (weight > 0) {
      for (var d = 0; d < dim; d++) {
        sum[d] /= weight;
      }
    }
    return sum;
  }

  static void _l2Normalize(Float32List v) {
    var sumSq = 0.0;
    for (var i = 0; i < v.length; i++) {
      sumSq += v[i] * v[i];
    }
    final norm = math.sqrt(sumSq);
    if (norm == 0) {
      return;
    }
    for (var i = 0; i < v.length; i++) {
      v[i] = v[i] / norm;
    }
  }
}
