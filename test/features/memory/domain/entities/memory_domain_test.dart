import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryDomain', () {
    final now = DateTime(2025, 1, 15, 10, 30);

    MemoryDomain createDomain({
      String id = 'd1',
      String workspaceId = 'ws1',
      String name = 'preferences',
      String label = 'Preferences',
      String? description,
      DateTime? createdAt,
      String createdByRole = 'coder',
    }) {
      return MemoryDomain(
        id: id,
        workspaceId: workspaceId,
        name: name,
        label: label,
        description: description,
        createdAt: createdAt ?? now,
        createdByRole: createdByRole,
      );
    }

    test('creates with required fields', timeout: const Timeout.factor(2), () {
      final domain = createDomain();
      expect(domain.id, 'd1');
      expect(domain.workspaceId, 'ws1');
      expect(domain.name, 'preferences');
      expect(domain.label, 'Preferences');
      expect(domain.description, isNull);
      expect(domain.createdAt, now);
      expect(domain.createdByRole, 'coder');
    });

    test('creates with optional description', timeout: const Timeout.factor(2), () {
      final domain = createDomain(description: 'User preferences domain');
      expect(domain.description, 'User preferences domain');
    });

    test('throws assertion error when workspaceId is empty', timeout: const Timeout.factor(2), () {
      expect(
        () => createDomain(workspaceId: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error when name is empty', timeout: const Timeout.factor(2), () {
      expect(
        () => createDomain(name: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equal domains are equal', timeout: const Timeout.factor(2), () {
      final a = createDomain();
      final b = createDomain();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('domains with different id are not equal', timeout: const Timeout.factor(2), () {
      final a = createDomain(id: 'd1');
      final b = createDomain(id: 'd2');
      expect(a, isNot(equals(b)));
    });

    test('domains with different workspaceId are not equal', timeout: const Timeout.factor(2), () {
      final a = createDomain(workspaceId: 'ws1');
      final b = createDomain(workspaceId: 'ws2');
      expect(a, isNot(equals(b)));
    });

    test('domains with different name are not equal', timeout: const Timeout.factor(2), () {
      final a = createDomain(name: 'alpha');
      final b = createDomain(name: 'beta');
      expect(a, isNot(equals(b)));
    });

    test('domains with different label are not equal', timeout: const Timeout.factor(2), () {
      final a = createDomain(label: 'Alpha');
      final b = createDomain(label: 'Beta');
      expect(a, isNot(equals(b)));
    });

    test('domains with different description are not equal', timeout: const Timeout.factor(2), () {
      final a = createDomain(description: 'desc a');
      final b = createDomain(description: 'desc b');
      expect(a, isNot(equals(b)));
    });

    test('domain with null description != domain with non-null description', timeout: const Timeout.factor(2), () {
      final a = createDomain(description: null);
      final b = createDomain(description: 'some desc');
      expect(a, isNot(equals(b)));
    });

    test('domains with different createdByRole are not equal', timeout: const Timeout.factor(2), () {
      final a = createDomain(createdByRole: 'coder');
      final b = createDomain(createdByRole: 'reviewer');
      expect(a, isNot(equals(b)));
    });

    test('equality ignores createdAt', timeout: const Timeout.factor(2), () {
      final a = createDomain(createdAt: DateTime(2024));
      final b = createDomain(createdAt: DateTime(2025));
      expect(a, equals(b));
    });

    test('is not equal to non-MemoryDomain objects', timeout: const Timeout.factor(2), () {
      final domain = createDomain();
      expect(domain == Object(), isFalse);
    });

    test('identical instances are equal', timeout: const Timeout.factor(2), () {
      final domain = createDomain();
      expect(domain == domain, isTrue);
    });
  });
}
