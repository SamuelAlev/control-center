import 'package:cc_domain/features/code_graph/domain/services/code_indexer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CodeIndexProgress', () {
    test('toJson round-trips the counters', () {
      const progress = CodeIndexProgress(
        filesIndexed: 10,
        filesToIndex: 20,
        totalFiles: 50,
        symbols: 200,
        edges: 350,
      );
      expect(progress.toJson(), {
        'filesIndexed': 10,
        'filesToIndex': 20,
        'totalFiles': 50,
        'symbols': 200,
        'edges': 350,
      });
    });
  });

  group('CodeIndexResult', () {
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
  });
}
