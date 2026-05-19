import 'dart:typed_data';

import 'package:control_center/core/infrastructure/embedding/cosine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cosineSimilarity', () {
    test('returns 0 for mismatched lengths', () async {
      final a = Float32List.fromList([1.0, 2.0]);
      final b = Float32List.fromList([1.0]);
      expect(cosineSimilarity(a, b), 0);
    });

    test('returns 0 for empty vectors', () async {
      final a = Float32List(0);
      final b = Float32List(0);
      expect(cosineSimilarity(a, b), 0);
    });

    test('returns 0 when both vectors are zero vectors', () async {
      final a = Float32List.fromList([0.0, 0.0, 0.0]);
      final b = Float32List.fromList([0.0, 0.0, 0.0]);
      expect(cosineSimilarity(a, b), 0);
    });

    test('returns 0 when one vector is zero', () async {
      final a = Float32List.fromList([1.0, 2.0, 3.0]);
      final b = Float32List.fromList([0.0, 0.0, 0.0]);
      expect(cosineSimilarity(a, b), 0);
    });

    test('identical unit vector returns 1', () async {
      final a = Float32List.fromList([1.0, 0.0]);
      final b = Float32List.fromList([1.0, 0.0]);
      expect(cosineSimilarity(a, b), closeTo(1.0, 1e-10));
    });

    test('orthogonal vectors return 0', () async {
      final a = Float32List.fromList([1.0, 0.0]);
      final b = Float32List.fromList([0.0, 1.0]);
      expect(cosineSimilarity(a, b), closeTo(0.0, 1e-10));
    });

    test('opposite vectors return -1', () async {
      final a = Float32List.fromList([1.0, 0.0]);
      final b = Float32List.fromList([-1.0, 0.0]);
      expect(cosineSimilarity(a, b), closeTo(-1.0, 1e-10));
    });

    test('computes correct similarity for arbitrary vectors', () async {
      // a = [1, 2, 3], b = [4, 5, 6]
      // dot = 4+10+18=32, |a|=sqrt(14), |b|=sqrt(77)
      // cos = 32 / sqrt(14*77) ≈ 0.9746
      final a = Float32List.fromList([1.0, 2.0, 3.0]);
      final b = Float32List.fromList([4.0, 5.0, 6.0]);
      expect(cosineSimilarity(a, b), closeTo(0.9746318461970762, 1e-10));
    });

    test('single-element vectors', () async {
      final a = Float32List.fromList([3.0]);
      final b = Float32List.fromList([4.0]);
      expect(cosineSimilarity(a, b), closeTo(1.0, 1e-10));
    });

    test('is commutative', () async {
      final a = Float32List.fromList([1.0, 2.0, 3.0]);
      final b = Float32List.fromList([4.0, 5.0, 6.0]);
      expect(cosineSimilarity(a, b), closeTo(cosineSimilarity(b, a), 1e-10));
    });
  });
}
