import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PrFile createPrFile({
    String filename = 'src/main.dart',
    PrFileStatus status = PrFileStatus.modified,
    int additions = 10,
    int deletions = 5,
    String patch = '@@ -1,3 +1,7 @@',
    String? previousFilename,
  }) {
    return PrFile(
      filename: filename,
      status: status,
      additions: additions,
      deletions: deletions,
      patch: patch,
      previousFilename: previousFilename,
    );
  }

  group('PrFile constructor', () {
    test('creates instance with all required fields', () {
      final file = createPrFile();
      expect(file.filename, 'src/main.dart');
      expect(file.status, PrFileStatus.modified);
      expect(file.additions, 10);
      expect(file.deletions, 5);
      expect(file.patch, '@@ -1,3 +1,7 @@');
      expect(file.previousFilename, isNull);
    });

    test('creates instance with optional previousFilename', () {
      final file = createPrFile(
        filename: 'src/old.dart',
        previousFilename: 'src/new.dart',
      );
      expect(file.filename, 'src/old.dart');
      expect(file.previousFilename, 'src/new.dart');
    });

    test('throws assertion error for empty filename', () {
      expect(
        () => PrFile(
          filename: '',
          status: PrFileStatus.modified,
          additions: 0,
          deletions: 0,
          patch: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PrFile computed properties', () {
    test('extension returns file extension', () {
      expect(createPrFile(filename: 'src/main.dart').extension, 'dart');
      expect(createPrFile(filename: 'test/foo_test.dart').extension, 'dart');
      expect(createPrFile(filename: 'pubspec.yaml').extension, 'yaml');
    });

    test('extension returns lowercase', () {
      expect(createPrFile(filename: 'Image.PNG').extension, 'png');
    });

    test('extension returns empty string for no extension', () {
      expect(createPrFile(filename: 'Makefile').extension, '');
      expect(createPrFile(filename: 'Dockerfile').extension, '');
    });

    test('extension returns empty string for trailing dot', () {
      expect(createPrFile(filename: 'file.').extension, '');
    });
  });

  group('PrFile == and hashCode', () {
    test('identical instances are equal', () {
      final a = createPrFile();
      final b = createPrFile();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different filename makes unequal', () {
      final a = createPrFile(filename: 'a.dart');
      final b = createPrFile(filename: 'b.dart');
      expect(a, isNot(equals(b)));
    });

    test('same filename but different other fields are equal (identity by filename)', () {
      final a = createPrFile(filename: 'x.dart', additions: 1);
      final b = createPrFile(filename: 'x.dart', additions: 999);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('self equality', () {
      final a = createPrFile();
      expect(a, equals(a));
    });
  });

  group('PrFileStatus', () {
    group('name', () {
      test('added returns added', () {
        expect(PrFileStatus.added.name, 'added');
      });
      test('modified returns modified', () {
        expect(PrFileStatus.modified.name, 'modified');
      });
      test('removed returns removed', () {
        expect(PrFileStatus.removed.name, 'removed');
      });
      test('renamed returns renamed', () {
        expect(PrFileStatus.renamed.name, 'renamed');
      });
      test('unchanged returns unchanged', () {
        expect(PrFileStatus.unchanged.name, 'unchanged');
      });
    });

    group('fromString', () {
      test('parses added', () {
        expect(PrFileStatusExtension.fromString('added').name, PrFileStatus.added.name);
      });
      test('parses modified', () {
        expect(PrFileStatusExtension.fromString('modified').name, PrFileStatus.modified.name);
      });
      test('parses removed', () {
        expect(PrFileStatusExtension.fromString('removed').name, PrFileStatus.removed.name);
      });
      test('parses renamed', () {
        expect(PrFileStatusExtension.fromString('renamed').name, PrFileStatus.renamed.name);
      });
      test('parses unchanged', () {
        expect(PrFileStatusExtension.fromString('unchanged').name, PrFileStatus.unchanged.name);
      });
      test('unknown defaults to modified', () {
        expect(PrFileStatusExtension.fromString('bogus').name, PrFileStatus.modified.name);
      });
      test('empty string defaults to modified', () {
        expect(PrFileStatusExtension.fromString('').name, PrFileStatus.modified.name);
      });
    });
  });
}
