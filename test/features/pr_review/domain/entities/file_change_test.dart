import 'package:cc_domain/features/pr_review/domain/entities/file_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FileChange createFileChange({
    String path = 'src/main.dart',
    int additions = 10,
    int deletions = 5,
    bool isNew = false,
    bool isDeleted = false,
  }) {
    return FileChange(
      path: path,
      additions: additions,
      deletions: deletions,
      isNew: isNew,
      isDeleted: isDeleted,
    );
  }

  group('FileChange constructor', () {
    test('creates instance with all fields', () {
      const fc = FileChange(
        path: 'lib/app.dart',
        additions: 20,
        deletions: 3,
        isNew: true,
        isDeleted: true,
      );
      expect(fc.path, 'lib/app.dart');
      expect(fc.additions, 20);
      expect(fc.deletions, 3);
      expect(fc.isNew, isTrue);
      expect(fc.isDeleted, isTrue);
    });

    test('default values for optional fields', () {
      const fc = FileChange(path: 'file.txt');
      expect(fc.path, 'file.txt');
      expect(fc.additions, 0);
      expect(fc.deletions, 0);
      expect(fc.isNew, isFalse);
      expect(fc.isDeleted, isFalse);
    });

    test('is const constructable', () {
      const fc = FileChange(path: 'f');
      expect(fc.path, 'f');
    });
  });

  group('FileChange == and hashCode', () {
    test('identical instances are equal', () {
      final a = createFileChange();
      final b = createFileChange();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different path makes unequal', () {
      final a = createFileChange(path: 'a.dart');
      final b = createFileChange(path: 'b.dart');
      expect(a, isNot(equals(b)));
    });

    test('different additions makes unequal', () {
      final a = createFileChange(additions: 1);
      final b = createFileChange(additions: 2);
      expect(a, isNot(equals(b)));
    });

    test('different deletions makes unequal', () {
      final a = createFileChange(deletions: 1);
      final b = createFileChange(deletions: 2);
      expect(a, isNot(equals(b)));
    });

    test('different isNew makes unequal', () {
      final a = createFileChange(isNew: false);
      final b = createFileChange(isNew: true);
      expect(a, isNot(equals(b)));
    });

    test('different isDeleted makes unequal', () {
      final a = createFileChange(isDeleted: false);
      final b = createFileChange(isDeleted: true);
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createFileChange();
      expect(a, equals(a));
    });
  });

  group('FileChange toString', () {
    test('returns formatted string with additions and deletions', () {
      final fc = createFileChange(path: 'src/main.dart', additions: 10, deletions: 5);
      final str = fc.toString();
      expect(str, contains('FileChange'));
      expect(str, contains('src/main.dart'));
      expect(str, contains('+10'));
      expect(str, contains('-5'));
    });
  });
}
