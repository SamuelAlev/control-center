import 'dart:typed_data';

import 'package:control_center/core/domain/services/cosine_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cosineSimilarity', () {
    test('identical vectors return 1.0', () {
      final a = Float32List.fromList([1.0, 0.0, 0.0]);
      expect(cosineSimilarity(a, a), closeTo(1.0, 1e-6));
    });

    test('orthogonal vectors return 0.0', () {
      final a = Float32List.fromList([1.0, 0.0]);
      final b = Float32List.fromList([0.0, 1.0]);
      expect(cosineSimilarity(a, b), closeTo(0.0, 1e-6));
    });

    test('opposite vectors return -1.0', () {
      final a = Float32List.fromList([1.0, 0.0]);
      final b = Float32List.fromList([-1.0, 0.0]);
      expect(cosineSimilarity(a, b), closeTo(-1.0, 1e-6));
    });

    test('zero vectors return 0.0', () {
      final a = Float32List.fromList([0.0, 0.0, 0.0]);
      final b = Float32List.fromList([0.0, 0.0, 0.0]);
      expect(cosineSimilarity(a, b), closeTo(0.0, 1e-6));
    });

    test('mismatched lengths return 0.0', () {
      final a = Float32List.fromList([1.0, 2.0]);
      final b = Float32List.fromList([1.0, 2.0, 3.0]);
      expect(cosineSimilarity(a, b), closeTo(0.0, 1e-6));
    });

    test('empty vectors return 0.0', () {
      final a = Float32List(0);
      final b = Float32List(0);
      expect(cosineSimilarity(a, b), closeTo(0.0, 1e-6));
    });

    test('partial similarity returns correct value', () {
      final a = Float32List.fromList([1.0, 2.0, 3.0]);
      final b = Float32List.fromList([4.0, 5.0, 6.0]);
      // dot=32, normA=sqrt(14), normB=sqrt(77)
      // cos = 32 / (sqrt(14)*sqrt(77)) = 32 / sqrt(1078) ≈ 0.9746
      expect(cosineSimilarity(a, b), closeTo(0.9746318461970762, 1e-6));
    });

    test('single element vectors', () {
      final a = Float32List.fromList([3.0]);
      final b = Float32List.fromList([4.0]);
      expect(cosineSimilarity(a, b), closeTo(1.0, 1e-6));
    });

    test('single element vectors with opposite signs', () {
      final a = Float32List.fromList([3.0]);
      final b = Float32List.fromList([-4.0]);
      expect(cosineSimilarity(a, b), closeTo(-1.0, 1e-6));
    });
  });
}
