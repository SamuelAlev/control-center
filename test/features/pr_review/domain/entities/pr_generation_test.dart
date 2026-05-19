import 'package:control_center/features/pr_review/domain/entities/pr_generation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 5, 18, 9, 0);
  final later = DateTime(2025, 5, 18, 10, 0);

  PrGeneration createGeneration({
    String id = 'gen-1',
    String workspaceId = 'ws-1',
    PrGenerationStatus status = const Draft(),
    String? title = 'My PR',
    String? body = 'PR body',
    String? branch = 'feature/my-pr',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrGeneration(
      id: id,
      workspaceId: workspaceId,
      status: status,
      title: title,
      body: body,
      branch: branch,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('PrGeneration constructor', () {
    test('creates instance with all fields', () {
      final gen = createGeneration();
      expect(gen.id, 'gen-1');
      expect(gen.workspaceId, 'ws-1');
      expect(gen.status, isA<Draft>());
      expect(gen.title, 'My PR');
      expect(gen.body, 'PR body');
      expect(gen.branch, 'feature/my-pr');
      expect(gen.createdAt, now);
      expect(gen.updatedAt, now);
    });

    test('creates instance with nullable fields null', () {
      final gen = createGeneration(title: null, body: null, branch: null);
      expect(gen.title, isNull);
      expect(gen.body, isNull);
      expect(gen.branch, isNull);
    });

    test('throws assertion error for empty id', () {
      expect(
        () => PrGeneration(
          id: '',
          workspaceId: 'ws-1',
          status: const Draft(),
          createdAt: now,
          updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PrGeneration computed properties', () {
    test('isDraft returns true for Draft status', () {
      expect(createGeneration(status: const Draft()).isDraft, isTrue);
      expect(createGeneration(status: const Published()).isDraft, isFalse);
      expect(createGeneration(status: const Created()).isDraft, isFalse);
    });

    test('isPublished returns true for Published status', () {
      expect(createGeneration(status: const Published()).isPublished, isTrue);
      expect(createGeneration(status: const Draft()).isPublished, isFalse);
      expect(createGeneration(status: const Created()).isPublished, isFalse);
    });

    test('isCreated returns true for Created status', () {
      expect(createGeneration(status: const Created()).isCreated, isTrue);
      expect(createGeneration(status: const Draft()).isCreated, isFalse);
      expect(createGeneration(status: const Published()).isCreated, isFalse);
    });

    test('canPublish delegates to status.canPublish', () {
      expect(createGeneration(status: const Draft()).canPublish(), isTrue);
      expect(createGeneration(status: const Published()).canPublish(), isFalse);
      expect(createGeneration(status: const Created()).canPublish(), isFalse);
    });
  });

  group('PrGeneration markPublished', () {
    test('transitions from Draft to Published', () {
      final gen = createGeneration(status: const Draft());
      final published = gen.markPublished();
      expect(published.status, isA<Published>());
      expect(published.isPublished, isTrue);
    });

    test('throws assertion error when not Draft', () {
      final gen = createGeneration(status: const Created());
      expect(gen.markPublished, throwsA(isA<AssertionError>()));
    });
  });

  group('PrGeneration validate', () {
    test('does not throw when title and body are set', () {
      final gen = createGeneration(title: 'Title', body: 'Body');
      expect(gen.validate, returnsNormally);
    });

    test('throws ArgumentError when title is null', () {
      final gen = createGeneration(title: null, body: 'Body');
      expect(gen.validate, throwsA(isA<ArgumentError>()));
    });

    test('throws ArgumentError when title is empty', () {
      final gen = createGeneration(title: '', body: 'Body');
      expect(gen.validate, throwsA(isA<ArgumentError>()));
    });

    test('throws ArgumentError when body is null', () {
      final gen = createGeneration(title: 'Title', body: null);
      expect(gen.validate, throwsA(isA<ArgumentError>()));
    });

    test('throws ArgumentError when body is empty', () {
      final gen = createGeneration(title: 'Title', body: '');
      expect(gen.validate, throwsA(isA<ArgumentError>()));
    });
  });

  group('PrGeneration == and hashCode', () {
    test('identical instances are equal', () {
      final a = createGeneration();
      final b = createGeneration();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createGeneration(id: 'a');
      final b = createGeneration(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('different workspaceId makes unequal', () {
      final a = createGeneration(workspaceId: 'ws-a');
      final b = createGeneration(workspaceId: 'ws-b');
      expect(a, isNot(equals(b)));
    });

    test('different status makes unequal', () {
      final a = createGeneration(status: const Draft());
      final b = createGeneration(status: const Published());
      expect(a, isNot(equals(b)));
    });

    test('different title makes unequal', () {
      final a = createGeneration(title: 'A');
      final b = createGeneration(title: 'B');
      expect(a, isNot(equals(b)));
    });

    test('different body makes unequal', () {
      final a = createGeneration(body: 'A');
      final b = createGeneration(body: 'B');
      expect(a, isNot(equals(b)));
    });

    test('different branch makes unequal', () {
      final a = createGeneration(branch: 'feat/a');
      final b = createGeneration(branch: 'feat/b');
      expect(a, isNot(equals(b)));
    });

    test('different createdAt makes unequal', () {
      final a = createGeneration(createdAt: now);
      final b = createGeneration(createdAt: later);
      expect(a, isNot(equals(b)));
    });

    test('different updatedAt makes unequal', () {
      final a = createGeneration(updatedAt: now);
      final b = createGeneration(updatedAt: later);
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createGeneration();
      expect(a, equals(a));
    });
  });

  group('PrGeneration copyWith', () {
    test('returns new instance with updated id', () {
      final gen = createGeneration();
      final updated = gen.copyWith(id: 'gen-2');
      expect(updated.id, 'gen-2');
      expect(updated.workspaceId, 'ws-1');
    });

    test('returns new instance with updated status', () {
      final gen = createGeneration();
      final updated = gen.copyWith(status: const Published());
      expect(updated.status, isA<Published>());
    });

    test('removeTitle sets title to null', () {
      final gen = createGeneration(title: 'PR Title');
      final updated = gen.copyWith(removeTitle: true);
      expect(updated.title, isNull);
    });

    test('removeTitle false keeps title', () {
      final gen = createGeneration(title: 'PR Title');
      final updated = gen.copyWith(removeTitle: false);
      expect(updated.title, 'PR Title');
    });

    test('removeTitle with explicit title uses removeTitle', () {
      final gen = createGeneration(title: 'Old');
      final updated = gen.copyWith(title: 'New', removeTitle: true);
      expect(updated.title, isNull);
    });

    test('removeBody sets body to null', () {
      final gen = createGeneration(body: 'PR Body');
      final updated = gen.copyWith(removeBody: true);
      expect(updated.body, isNull);
    });

    test('removeBranch sets branch to null', () {
      final gen = createGeneration(branch: 'feat/x');
      final updated = gen.copyWith(removeBranch: true);
      expect(updated.branch, isNull);
    });

    test('copyWith without changes returns equal generation', () {
      final gen = createGeneration();
      final updated = gen.copyWith();
      expect(updated, equals(gen));
    });
  });

  group('PrGenerationStatus', () {
    group('name', () {
      test('Draft returns draft', () {
        expect(const Draft().name, 'draft');
      });
      test('Published returns published', () {
        expect(const Published().name, 'published');
      });
      test('Created returns created', () {
        expect(const Created().name, 'created');
      });
    });

    group('fromName', () {
      test('parses draft', () {
        expect(PrGenerationStatus.fromName('draft'), isA<Draft>());
      });
      test('parses published', () {
        expect(PrGenerationStatus.fromName('published'), isA<Published>());
      });
      test('parses created', () {
        expect(PrGenerationStatus.fromName('created'), isA<Created>());
      });
      test('unknown defaults to Draft', () {
        expect(PrGenerationStatus.fromName('bogus'), isA<Draft>());
      });
      test('empty string defaults to Draft', () {
        expect(PrGenerationStatus.fromName(''), isA<Draft>());
      });
    });

    group('canPublish', () {
      test('Draft can publish', () {
        expect(const Draft().canPublish, isTrue);
      });
      test('Published cannot publish', () {
        expect(const Published().canPublish, isFalse);
      });
      test('Created cannot publish', () {
        expect(const Created().canPublish, isFalse);
      });
    });

    group('== and hashCode', () {
      test('same type are equal', () {
        expect(const Draft(), equals(const Draft()));
        expect(const Published(), equals(const Published()));
        expect(const Created(), equals(const Created()));
      });

      test('different types are unequal', () {
        expect(const Draft(), isNot(equals(const Published())));
        expect(const Published(), isNot(equals(const Created())));
        expect(const Created(), isNot(equals(const Draft())));
      });

      test('same type have same hashCode', () {
        expect(const Draft().hashCode, equals(const Draft().hashCode));
        expect(const Published().hashCode, equals(const Published().hashCode));
        expect(const Created().hashCode, equals(const Created().hashCode));
      });

      test('different types have different hashCode', () {
        expect(const Draft().hashCode, isNot(equals(const Published().hashCode)));
      });
    });
  });
}
