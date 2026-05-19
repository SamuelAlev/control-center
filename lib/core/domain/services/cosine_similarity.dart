import 'dart:math';
import 'dart:typed_data';

/// Computes the cosine similarity between two vectors.
///
/// Returns 0 for zero-length or mismatched vectors.
double cosineSimilarity(Float32List a, Float32List b) {
  if (a.length != b.length) {
    return 0;
  }
  double dot = 0, normA = 0, normB = 0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  final denom = sqrt(normA) * sqrt(normB);
  return denom == 0 ? 0 : dot / denom;
}
