import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Adapter', () {
    const adapter = Adapter(
      id: 'test-adapter',
      name: 'Test',
      description: 'A test adapter',
      cliName: 'test',
    );

    test('construction and field access', timeout: const Timeout.factor(2), () {
      expect(adapter.id, 'test-adapter');
      expect(adapter.name, 'Test');
      expect(adapter.description, 'A test adapter');
      expect(adapter.cliName, 'test');
    });

    test('equality is based on id', timeout: const Timeout.factor(2), () {
      const other = Adapter(
        id: 'test-adapter',
        name: 'Different',
        description: 'Other',
        cliName: 'other',
      );

      expect(adapter, equals(other));
    });

    test('different id means not equal', timeout: const Timeout.factor(2), () {
      const other = Adapter(
        id: 'other',
        name: 'Test',
        description: 'A test adapter',
        cliName: 'test',
      );

      expect(adapter, isNot(equals(other)));
    });

    test('hashCode consistency with id', timeout: const Timeout.factor(2), () {
      const other = Adapter(
        id: 'test-adapter',
        name: 'Different',
        description: '',
        cliName: 'zzz',
      );

      expect(adapter.hashCode, equals(other.hashCode));
    });
  });

  group('DetectionStatus', () {
    test('has exactly three values', timeout: const Timeout.factor(2), () {
      expect(DetectionStatus.values, hasLength(3));
    });

    test('contains expected values', timeout: const Timeout.factor(2), () {
      expect(DetectionStatus.values, containsAll([
        DetectionStatus.checking,
        DetectionStatus.found,
        DetectionStatus.notFound,
      ]));
    });
  });

  group('DetectedAdapter', () {
    const baseAdapter = Adapter(
      id: 'a',
      name: 'A',
      description: 'd',
      cliName: 'a-cli',
    );

    test('construction and field access', timeout: const Timeout.factor(2), () {
      const da = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.2.3',
        path: '/usr/local/bin/a-cli',
      );

      expect(da.adapter, baseAdapter);
      expect(da.status, DetectionStatus.found);
      expect(da.version, '1.2.3');
      expect(da.path, '/usr/local/bin/a-cli');
    });

    test('construction with nullable fields null', timeout: const Timeout.factor(2), () {
      const da = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.notFound,
      );

      expect(da.version, isNull);
      expect(da.path, isNull);
    });

    test('isResolved is true when found', timeout: const Timeout.factor(2), () {
      const da = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
      );

      expect(da.isResolved, isTrue);
    });

    test('isResolved is true when notFound', timeout: const Timeout.factor(2), () {
      const da = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.notFound,
      );

      expect(da.isResolved, isTrue);
    });

    test('isResolved is false when checking', timeout: const Timeout.factor(2), () {
      const da = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.checking,
      );

      expect(da.isResolved, isFalse);
    });

    test('isFound is true only when status is found', timeout: const Timeout.factor(2), () {
      const found = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
      );
      const notFound = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.notFound,
      );

      expect(found.isFound, isTrue);
      expect(notFound.isFound, isFalse);
    });

    test('equality considers all fields', timeout: const Timeout.factor(2), () {
      const a = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.0',
        path: '/bin/a',
      );
      const b = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.0',
        path: '/bin/a',
      );

      expect(a, equals(b));
    });

    test('inequality when fields differ', timeout: const Timeout.factor(2), () {
      const a = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.0',
      );
      const b = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '2.0',
      );

      expect(a, isNot(equals(b)));
    });

    test('hashCode consistency', timeout: const Timeout.factor(2), () {
      const a = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.0',
        path: '/bin/a',
      );
      const b = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.0',
        path: '/bin/a',
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith overrides status', timeout: const Timeout.factor(2), () {
      const original = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.checking,
      );
      final updated = original.copyWith(status: DetectionStatus.found);

      expect(updated.status, DetectionStatus.found);
      expect(updated.adapter, baseAdapter);
    });

    test('copyWith overrides version', timeout: const Timeout.factor(2), () {
      const original = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
      );
      final updated = original.copyWith(version: '2.0');

      expect(updated.version, '2.0');
    });

    test('copyWith overrides path', timeout: const Timeout.factor(2), () {
      const original = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
      );
      final updated = original.copyWith(path: '/new/path');

      expect(updated.path, '/new/path');
    });

    test('copyWith clearVersion sets version to null', timeout: const Timeout.factor(2), () {
      const original = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.0',
      );
      final updated = original.copyWith(clearVersion: true);

      expect(updated.version, isNull);
    });

    test('copyWith clearPath sets path to null', timeout: const Timeout.factor(2), () {
      const original = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        path: '/old',
      );
      final updated = original.copyWith(clearPath: true);

      expect(updated.path, isNull);
    });

    test('copyWith with no args preserves original', timeout: const Timeout.factor(2), () {
      const original = DetectedAdapter(
        adapter: baseAdapter,
        status: DetectionStatus.found,
        version: '1.0',
        path: '/bin/a',
      );
      final copy = original.copyWith();

      expect(copy, equals(original));
    });
  });

  group('predefinedAdapters', () {
    test('is non-empty', timeout: const Timeout.factor(2), () {
      expect(predefinedAdapters, isNotEmpty);
    });

    test('contains expected ids', timeout: const Timeout.factor(2), () {
      final ids = predefinedAdapters.map((a) => a.id).toList();

      expect(ids, containsAll(['pi-dev', 'claude-code', 'opencode', 'gemini', 'goose', 'cursor', 'codex']));
    });

    test('all adapters have non-empty fields', timeout: const Timeout.factor(2), () {
      for (final adapter in predefinedAdapters) {
        expect(adapter.id, isNotEmpty);
        expect(adapter.name, isNotEmpty);
        expect(adapter.description, isNotEmpty);
        expect(adapter.cliName, isNotEmpty);
      }
    });
  });
}
