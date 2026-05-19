import 'package:control_center/features/code_graph/domain/services/code_indexer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodeIndexProgress', () {
    test('holds all fields', () {
      const progress = CodeIndexProgress(
        filesIndexed: 10,
        totalFiles: 50,
        symbols: 200,
        edges: 350,
      );
      expect(progress.filesIndexed, 10);
      expect(progress.totalFiles, 50);
      expect(progress.symbols, 200);
      expect(progress.edges, 350);
    });

    test('zero progress', () {
      const progress = CodeIndexProgress(
        filesIndexed: 0,
        totalFiles: 100,
        symbols: 0,
        edges: 0,
      );
      expect(progress.filesIndexed, 0);
      expect(progress.totalFiles, 100);
      expect(progress.symbols, 0);
      expect(progress.edges, 0);
    });

    test('completed state', () {
      const progress = CodeIndexProgress(
        filesIndexed: 100,
        totalFiles: 100,
        symbols: 500,
        edges: 1200,
      );
      expect(progress.filesIndexed, progress.totalFiles);
    });
  });

  group('CodeIndexResult', () {
    test('full result with all fields', () {
      const result = CodeIndexResult(
        filesIndexed: 30,
        filesSkipped: 20,
        symbols: 400,
        edges: 800,
        removedFiles: 5,
        resolvedReferences: 150,
        nativeAvailable: true,
      );
      expect(result.filesIndexed, 30);
      expect(result.filesSkipped, 20);
      expect(result.symbols, 400);
      expect(result.edges, 800);
      expect(result.removedFiles, 5);
      expect(result.resolvedReferences, 150);
      expect(result.nativeAvailable, isTrue);
      expect(result.skippedReason, isNull);
    });

    test('skipped result with reason', () {
      const result = CodeIndexResult.skipped('natives not found');
      expect(result.filesIndexed, 0);
      expect(result.filesSkipped, 0);
      expect(result.symbols, 0);
      expect(result.edges, 0);
      expect(result.removedFiles, 0);
      expect(result.resolvedReferences, 0);
      expect(result.nativeAvailable, isFalse);
      expect(result.skippedReason, 'natives not found');
    });

    test('skipped result with different reason', () {
      const result = CodeIndexResult.skipped('unsupported platform');
      expect(result.nativeAvailable, isFalse);
      expect(result.skippedReason, 'unsupported platform');
      expect(result.symbols, 0);
    });

    test('toJson includes all numeric fields', () {
      const result = CodeIndexResult(
        filesIndexed: 10,
        filesSkipped: 5,
        symbols: 100,
        edges: 200,
        removedFiles: 2,
        resolvedReferences: 50,
        nativeAvailable: true,
      );
      final json = result.toJson();
      expect(json['filesIndexed'], 10);
      expect(json['filesSkipped'], 5);
      expect(json['symbols'], 100);
      expect(json['edges'], 200);
      expect(json['removedFiles'], 2);
      expect(json['resolvedReferences'], 50);
      expect(json['nativeAvailable'], true);
      expect(json.containsKey('skippedReason'), isFalse);
    });

    test('toJson on skipped includes skippedReason', () {
      const result = CodeIndexResult.skipped('missing binary');
      final json = result.toJson();
      expect(json['filesIndexed'], 0);
      expect(json['nativeAvailable'], false);
      expect(json['skippedReason'], 'missing binary');
    });

    test('zero result that is not skipped', () {
      const result = CodeIndexResult(
        filesIndexed: 0,
        filesSkipped: 0,
        symbols: 0,
        edges: 0,
        removedFiles: 0,
        resolvedReferences: 0,
        nativeAvailable: true,
      );
      expect(result.nativeAvailable, isTrue);
      expect(result.skippedReason, isNull);
      expect(result.filesIndexed, 0);
    });
  });
}
