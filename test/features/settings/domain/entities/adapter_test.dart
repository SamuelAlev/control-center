import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Adapter constructor', () {
    test('creates with all fields', () {
      const adapter = Adapter(
        id: 'opencode',
        name: 'OpenCode',
        description: 'OpenCode CLI runner',
        cliName: 'opencode',
      );
      expect(adapter.id, 'opencode');
      expect(adapter.name, 'OpenCode');
      expect(adapter.description, 'OpenCode CLI runner');
      expect(adapter.cliName, 'opencode');
    });
  });

  group('Adapter == and hashCode', () {
    test('identical adapters are equal (id-based)', () {
      const a = Adapter(
        id: 'opencode',
        name: 'OpenCode',
        description: 'Desc 1',
        cliName: 'cli1',
      );
      const b = Adapter(
        id: 'opencode',
        name: 'Different',
        description: 'Desc 2',
        cliName: 'cli2',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      const a = Adapter(
        id: 'a',
        name: 'Name',
        description: 'Desc',
        cliName: 'cli',
      );
      const b = Adapter(
        id: 'b',
        name: 'Name',
        description: 'Desc',
        cliName: 'cli',
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      const a = Adapter(
        id: 'opencode',
        name: 'OpenCode',
        description: 'Desc',
        cliName: 'opencode',
      );
      expect(a, equals(a));
    });
  });

  group('predefinedAdapters', () {
    test('contains Pi and Claude Code', () {
      expect(predefinedAdapters.length, 2);
    });

    test('first adapter is Pi', () {
      expect(predefinedAdapters[0].id, 'pi-dev');
      expect(predefinedAdapters[0].name, 'Pi');
      expect(predefinedAdapters[0].cliName, 'pi');
    });

    test('second adapter is Claude Code wired to the claude CLI', () {
      expect(predefinedAdapters[1].id, 'claude-code');
      expect(predefinedAdapters[1].name, 'Claude Code');
      expect(predefinedAdapters[1].cliName, 'claude');
    });

    test('all adapters have non-empty fields', () {
      for (final adapter in predefinedAdapters) {
        expect(adapter.id.isNotEmpty, isTrue);
        expect(adapter.name.isNotEmpty, isTrue);
        expect(adapter.description.isNotEmpty, isTrue);
        expect(adapter.cliName.isNotEmpty, isTrue);
      }
    });
  });

  group('DetectionStatus enum', () {
    test('has three values', () {
      expect(DetectionStatus.values, [
        DetectionStatus.checking,
        DetectionStatus.found,
        DetectionStatus.notFound,
      ]);
    });
  });

  group('DetectedAdapter constructor', () {
    const adapter = Adapter(
      id: 'pi-dev',
      name: 'Pi',
      description: 'Pi CLI',
      cliName: 'pi',
    );

    test('creates with adapter and status', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
      );
      expect(detected.adapter, adapter);
      expect(detected.status, DetectionStatus.found);
    });

    test('stores optional version and path', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        version: 'v2.0.0',
        path: '/usr/local/bin/pi',
      );
      expect(detected.version, 'v2.0.0');
      expect(detected.path, '/usr/local/bin/pi');
    });

    test('version and path default to null', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.checking,
      );
      expect(detected.version, isNull);
      expect(detected.path, isNull);
    });
  });

  group('DetectedAdapter computed properties', () {
    const adapter = Adapter(
      id: 'pi-dev',
      name: 'Pi',
      description: 'Pi CLI',
      cliName: 'pi',
    );

    test('isResolved returns false for checking', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.checking,
      );
      expect(detected.isResolved, isFalse);
    });

    test('isResolved returns true for found', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
      );
      expect(detected.isResolved, isTrue);
    });

    test('isResolved returns true for notFound', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.notFound,
      );
      expect(detected.isResolved, isTrue);
    });

    test('isFound returns true only for found status', () {
      const found = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
      );
      const checking = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.checking,
      );
      const notFound = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.notFound,
      );
      expect(found.isFound, isTrue);
      expect(checking.isFound, isFalse);
      expect(notFound.isFound, isFalse);
    });
  });

  group('DetectedAdapter == and hashCode', () {
    const adapter = Adapter(
      id: 'pi-dev',
      name: 'Pi',
      description: 'Pi CLI',
      cliName: 'pi',
    );

    test('identical are equal', () {
      const a = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        version: '1.0',
      );
      const b = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        version: '1.0',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different status makes unequal', () {
      const a = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
      );
      const b = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.notFound,
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      const a = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.checking,
      );
      expect(a, equals(a));
    });
  });

  group('DetectedAdapter copyWith', () {
    const adapter = Adapter(
      id: 'pi-dev',
      name: 'Pi',
      description: 'Pi CLI',
      cliName: 'pi',
    );

    test('returns new instance with updated status', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.checking,
      );
      final updated = detected.copyWith(status: DetectionStatus.found);
      expect(updated.status, DetectionStatus.found);
    });

    test('clearVersion sets version to null', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        version: 'v1.0',
      );
      final updated = detected.copyWith(clearVersion: true);
      expect(updated.version, isNull);
    });

    test('clearPath sets path to null', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        path: '/bin/pi',
      );
      final updated = detected.copyWith(clearPath: true);
      expect(updated.path, isNull);
    });

    test('copyWith without changes returns equal', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
      );
      final updated = detected.copyWith();
      expect(updated, equals(detected));
    });

    test('copyWith can update version', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.checking,
      );
      final updated = detected.copyWith(version: 'v2.0');
      expect(updated.version, 'v2.0');
    });

    test('copyWith can update path', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.checking,
      );
      final updated = detected.copyWith(path: '/usr/bin/pi');
      expect(updated.path, '/usr/bin/pi');
    });

    test('copyWith can update both version and path', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
      );
      final updated = detected.copyWith(
        version: 'v3.0',
        path: '/opt/pi',
      );
      expect(updated.version, 'v3.0');
      expect(updated.path, '/opt/pi');
    });

    test('clearVersion takes priority over explicit version', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        version: 'existing',
      );
      final updated = detected.copyWith(
        clearVersion: true,
        version: 'override',
      );
      expect(updated.version, isNull);
    });

    test('clearPath takes priority over explicit path', () {
      const detected = DetectedAdapter(
        adapter: adapter,
        status: DetectionStatus.found,
        path: '/existing',
      );
      final updated = detected.copyWith(
        clearPath: true,
        path: '/override',
      );
      expect(updated.path, isNull);
    });
  });

  group('DetectedAdapter with different adapters', () {
    test('different adapter makes unequal', () {
      const adapter1 = Adapter(
        id: 'pi-dev',
        name: 'Pi',
        description: 'Pi CLI',
        cliName: 'pi',
      );
      const adapter2 = Adapter(
        id: 'opencode',
        name: 'OpenCode',
        description: 'OpenCode CLI',
        cliName: 'opencode',
      );

      const a = DetectedAdapter(
        adapter: adapter1,
        status: DetectionStatus.found,
      );
      const b = DetectedAdapter(
        adapter: adapter2,
        status: DetectionStatus.found,
      );
      expect(a, isNot(equals(b)));
    });

    test('same adapter but different version makes unequal', () {
      const adapter2 = Adapter(
        id: 'pi-dev',
        name: 'Pi',
        description: 'Pi CLI',
        cliName: 'pi',
      );

      const a = DetectedAdapter(
        adapter: adapter2,
        status: DetectionStatus.found,
        version: '1.0',
      );
      const b = DetectedAdapter(
        adapter: adapter2,
        status: DetectionStatus.found,
        version: '2.0',
      );
      expect(a, isNot(equals(b)));
    });

    test('same adapter but different path makes unequal', () {
      const adapter2 = Adapter(
        id: 'pi-dev',
        name: 'Pi',
        description: 'Pi CLI',
        cliName: 'pi',
      );

      const a = DetectedAdapter(
        adapter: adapter2,
        status: DetectionStatus.found,
        path: '/path/a',
      );
      const b = DetectedAdapter(
        adapter: adapter2,
        status: DetectionStatus.found,
        path: '/path/b',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('Adapter const', () {
    test('Adapter is a const constructor', () {
      const adapter = Adapter(
        id: 'test',
        name: 'Test',
        description: 'Test adapter',
        cliName: 'test',
      );
      expect(adapter, isA<Adapter>());
    });
  });
}
