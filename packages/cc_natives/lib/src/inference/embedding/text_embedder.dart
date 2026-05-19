import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_domain/core/domain/value_objects/embedding_model_paths.dart';
import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/inference/inference_library.dart';
import 'package:dart_wordpiece/dart_wordpiece.dart';
import 'package:ffi/ffi.dart';

/// Loads an ONNX BERT-style sentence-transformer model + its WordPiece
/// vocabulary and produces unit-norm sentence embeddings via mean-pooling over
/// the token embeddings, masked by `attention_mask`.
///
/// Compatible with `sentence-transformers/all-MiniLM-L6-v2` (384-d).
///
/// The encoder runs through the `cc_inference` native, which statically links
/// the ONNX Runtime. Tokenization, [_meanPool] and [_l2Normalize] stay on this
/// side of the FFI boundary, which is what keeps the vectors comparable with
/// everything already stored in sqlite_vector — pinned by
/// `embedding_equivalence_test.dart`.
class TextEmbedder {
  TextEmbedder._({
    required this.dimension,
    required this.maxSequenceLength,
    required CcInferenceBindings bindings,
    required Pointer<Void> handle,
    required WordPieceTokenizer tokenizer,
  }) : _bindings = bindings,
       _handle = handle,
       _tokenizer = tokenizer;

  /// Output vector size produced by [embed].
  final int dimension;

  /// Maximum tokens fed to the encoder.
  final int maxSequenceLength;

  final CcInferenceBindings _bindings;
  final WordPieceTokenizer _tokenizer;
  Pointer<Void> _handle;
  bool _disposed = false;

  /// Intra-op threads for the encoder; 0 leaves the ONNX Runtime default
  /// (one per physical core).
  ///
  /// Do NOT pin this to 1 "because the worker already serializes texts". The
  /// serialization is across texts; the threads parallelize the matmuls WITHIN
  /// one encode. Measured on all-MiniLM-L6-v2, 120 embeds: 190 ms on the
  /// default vs 531 ms pinned to one thread — a 2.8x regression that shows up
  /// as slow code-graph indexing and slow semantic search, since embedding is
  /// the expensive part of both.
  static const int _numThreads = 0;

  /// Loads the model and tokenizer from on-disk [paths].
  ///
  /// [libPath], when given, is the absolute path of the `cc_inference` dylib —
  /// worker isolates pass the path the host resolved on their behalf, since
  /// they cannot see the host isolate's preferred-path static.
  static Future<TextEmbedder> load({
    required EmbeddingModelPaths paths,
    required int dimension,
    required int maxSequenceLength,
    String? libPath,
  }) async {
    final bindings = ensureInferenceBindings(explicitPath: libPath);
    if (bindings == null) {
      throw StateError(
        inferenceLibraryUnavailableMessage(searchedPath: libPath),
      );
    }
    // Both files are checked up front so a half-installed model fails with a
    // path rather than with whatever the loader happens to throw.
    for (final (label, path) in [
      ('Embedding model', paths.model),
      ('Embedding vocabulary', paths.vocab),
    ]) {
      if (!File(path).existsSync()) {
        throw StateError('$label not found: $path');
      }
    }

    final modelPath = paths.model.toNativeUtf8(allocator: calloc);
    final Pointer<Void> handle;
    try {
      handle = bindings.embedderCreate(modelPath.cast<Uint8>(), _numThreads);
    } finally {
      calloc.free(modelPath);
    }
    if (handle == nullptr) {
      throw StateError(
        readInferenceError(
          bindings,
          fallback: 'Failed to load the embedding model at ${paths.model}.',
        ),
      );
    }

    // The session is live from here on, so anything that can still throw must
    // free it: the handle owns the model's weights (tens of MB) and a
    // Dart-side throw would otherwise strand them for the life of the isolate.
    try {
      final vocab = await VocabLoader.fromFile(File(paths.vocab));
      return TextEmbedder._(
        dimension: dimension,
        maxSequenceLength: maxSequenceLength,
        bindings: bindings,
        handle: handle,
        tokenizer: WordPieceTokenizer(vocab: vocab),
      );
    } on Object {
      bindings.embedderDestroy(handle);
      rethrow;
    }
  }

  /// Returns a unit-norm vector representation of [text].
  Future<Float32List> embed(String text) async {
    if (_disposed) {
      throw StateError('TextEmbedder is disposed.');
    }
    final tokens = _tokenizer.encode(text);
    final seqLen = math.min(tokens.realLength, maxSequenceLength);
    if (seqLen <= 0) {
      // Nothing to encode (the tokenizer produced no real tokens): a zero
      // vector is what mean-pooling over an all-masked sequence yields anyway.
      return Float32List(dimension);
    }

    final ids = calloc<Int64>(seqLen);
    final mask = calloc<Int64>(seqLen);
    final types = calloc<Int64>(seqLen);
    final out = calloc<Float>(seqLen * dimension);
    final hiddenSize = calloc<Int32>();
    try {
      final attentionMask = Int64List(seqLen);
      for (var i = 0; i < seqLen; i++) {
        ids[i] = tokens.inputIds[i];
        mask[i] = tokens.attentionMask[i];
        types[i] = tokens.tokenTypeIds[i];
        attentionMask[i] = tokens.attentionMask[i];
      }

      final rc = _bindings.embedderRun(
        _handle,
        ids,
        mask,
        types,
        seqLen,
        out,
        seqLen * dimension,
        hiddenSize,
      );
      if (rc != 0) {
        throw StateError(
          readInferenceError(
            _bindings,
            fallback: 'The embedding model failed to run.',
          ),
        );
      }
      final hidden = hiddenSize.value;
      if (hidden != dimension) {
        throw StateError(
          'Embedding model produced $hidden dimensions, expected $dimension.',
        );
      }

      // last_hidden_state, [seqLen, hidden], row-major.
      final tokenEmbeddings = out.asTypedList(seqLen * dimension);
      final pooled = _meanPool(tokenEmbeddings, attentionMask, seqLen, dimension);
      _l2Normalize(pooled);
      return pooled;
    } finally {
      calloc.free(ids);
      calloc.free(mask);
      calloc.free(types);
      calloc.free(out);
      calloc.free(hiddenSize);
    }
  }

  /// Frees the underlying native session.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _bindings.embedderDestroy(_handle);
    _handle = nullptr;
  }

  /// Attention-masked mean over the token embeddings.
  ///
  /// Reads a FLAT `[seqLen * dim]` row-major buffer — the native writes
  /// `last_hidden_state` straight into it — summing the unmasked rows and
  /// dividing by their count.
  static Float32List _meanPool(
    Float32List tokenEmbeddings,
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
      final rowStart = t * dim;
      for (var d = 0; d < dim; d++) {
        sum[d] += tokenEmbeddings[rowStart + d];
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
