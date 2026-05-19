import 'dart:math' as math;
import 'dart:typed_data';

/// Bits per byte.
const int bitsPerByte = 8;

/// Number of bytes a sign-bit-packed binary vector of [dimension] dims needs.
int binaryBytesFor(int dimension) => (dimension + bitsPerByte - 1) ~/ bitsPerByte;

final Uint8List _popcountTable = _buildPopcountTable();

Uint8List _buildPopcountTable() {
  final table = Uint8List(256);
  for (var i = 0; i < 256; i++) {
    var value = i;
    var count = 0;
    while (value != 0) {
      value &= value - 1;
      count++;
    }
    table[i] = count;
  }
  return table;
}

/// Sign-bit packs [embedding] into a 1-bit-per-dimension binary vector: dim `i`
/// becomes bit `7-(i%8)` of byte `i~/8`, set iff `embedding[i] > 0`. ~32× smaller
/// than the Float32 form. Ported from oh-my-pi mnemopi `core/binary-vectors.ts`
/// `maximallyInformativeBinarization`.
Uint8List binarizeEmbedding(List<double> embedding) {
  final dim = embedding.length;
  final out = Uint8List(binaryBytesFor(dim));
  for (var i = 0; i < dim; i++) {
    if (embedding[i] > 0) {
      final byteIndex = i >> 3;
      out[byteIndex] = out[byteIndex] | (1 << (7 - (i & 7)));
    }
  }
  return out;
}

/// Quantizes a unit-range [embedding] to Int8 (`[-127,127]`). ~4× smaller than
/// Float32 with usable recall. Mirrors mnemopi `quantizeInt8`.
Int8List quantizeInt8(List<double> embedding) {
  final out = Int8List(embedding.length);
  for (var i = 0; i < embedding.length; i++) {
    final v = embedding[i].clamp(-1.0, 1.0);
    out[i] = v >= 0 ? (v * 127).round() : -(v.abs() * 127).round();
  }
  return out;
}

/// Hamming distance (count of differing bits) between two packed binary vectors,
/// via a precomputed popcount table. Trailing bytes of the longer vector count
/// their set bits. Mirrors mnemopi `hammingDistance`.
int hammingDistance(Uint8List a, Uint8List b) {
  final shared = a.length < b.length ? a.length : b.length;
  var distance = 0;
  for (var i = 0; i < shared; i++) {
    distance += _popcountTable[a[i] ^ b[i]];
  }
  for (var i = shared; i < a.length; i++) {
    distance += _popcountTable[a[i]];
  }
  for (var i = shared; i < b.length; i++) {
    distance += _popcountTable[b[i]];
  }
  return distance;
}

/// Maps a Hamming [distance] over [dimension] bits to a similarity in `[0,1]`:
/// `1 - distance/dimension`. Mirrors mnemopi `informationTheoreticScore`.
double hammingScore(int distance, int dimension) {
  if (dimension <= 0) {
    return 0;
  }
  return 1.0 - distance / dimension;
}

/// Cosine similarity between two equal-length float vectors in `[-1,1]`.
/// Returns 0 when either is empty or zero-norm.
double cosineSimilarity(List<double> a, List<double> b) {
  final n = a.length < b.length ? a.length : b.length;
  if (n == 0) {
    return 0;
  }
  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < n; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) {
    return 0;
  }
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}