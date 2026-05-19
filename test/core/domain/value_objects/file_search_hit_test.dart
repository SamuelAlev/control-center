import 'package:cc_domain/core/domain/value_objects/file_search_hit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FileSearchHit', () {
    const hit = FileSearchHit(
      absolutePath: '/repo/lib/main.dart',
      relativePath: 'lib/main.dart',
      rootPath: '/repo',
      isDirectory: false,
      score: 0.87,
    );

    test('toJson/fromJson round-trips (the RPC wire contract)', () {
      final json = hit.toJson();
      expect(json, {
        'absolutePath': '/repo/lib/main.dart',
        'relativePath': 'lib/main.dart',
        'rootPath': '/repo',
        'isDirectory': false,
        'score': 0.87,
      });
      expect(FileSearchHit.fromJson(json), hit);
    });

    test('fromJson tolerates missing fields', () {
      const empty = FileSearchHit(
        absolutePath: '',
        relativePath: '',
        rootPath: '',
        isDirectory: false,
      );
      expect(FileSearchHit.fromJson(const {}), empty);
      expect(empty.score, 0);
    });

    test('fromJson coerces an int score to double', () {
      expect(FileSearchHit.fromJson(const {'score': 3}).score, 3.0);
    });

    test('equality is value-based', () {
      expect(
        hit,
        const FileSearchHit(
          absolutePath: '/repo/lib/main.dart',
          relativePath: 'lib/main.dart',
          rootPath: '/repo',
          isDirectory: false,
          score: 0.87,
        ),
      );
      expect(
        hit,
        isNot(const FileSearchHit(
          absolutePath: '/repo/lib/other.dart',
          relativePath: 'lib/other.dart',
          rootPath: '/repo',
          isDirectory: false,
        )),
      );
    });
  });
}
