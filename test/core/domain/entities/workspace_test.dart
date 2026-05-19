import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 1, 1);
  final testUpdatedAt = DateTime(2024, 6, 1);

  Workspace createWorkspace({
    String id = 'ws-1',
    String name = 'Test Workspace',
    String? logoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workspace(
      id: id,
      name: name,
      logoPath: logoPath,
      createdAt: createdAt ?? testCreatedAt,
      updatedAt: updatedAt ?? testUpdatedAt,
    );
  }

  group('Workspace', () {
    group('constructor', () {
      test('creates workspace with required fields', () {
        final ws = Workspace(
          id: 'ws-1',
          name: 'My Workspace',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );
        expect(ws.id, 'ws-1');
        expect(ws.name, 'My Workspace');
        expect(ws.logoPath, isNull);
        expect(ws.createdAt, testCreatedAt);
        expect(ws.updatedAt, testUpdatedAt);
      });

      test('creates workspace with all fields', () {
        final ws = Workspace(
          id: 'ws-2',
          name: 'Full Workspace',
          logoPath: '/path/to/logo.png',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );
        expect(ws.id, 'ws-2');
        expect(ws.logoPath, '/path/to/logo.png');
      });

      test('constructor asserts name is not empty', () {
        expect(
          () => Workspace(
            id: 'ws-x',
            name: '',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('convenience getters', () {
      test('hasLogo returns false when logoPath is null', () {
        final ws = createWorkspace();
        expect(ws.hasLogo, isFalse);
      });

      test('hasLogo returns false when logoPath is empty', () {
        final ws = createWorkspace(logoPath: '');
        expect(ws.hasLogo, isFalse);
      });

      test('hasLogo returns true when logoPath is set', () {
        final ws = createWorkspace(logoPath: '/logo.png');
        expect(ws.hasLogo, isTrue);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical workspaces', () {
        final ws1 = createWorkspace();
        final ws2 = createWorkspace();
        expect(ws1, equals(ws2));
      });

      test('== returns false for different id', () {
        final ws1 = createWorkspace(id: 'ws-1');
        final ws2 = createWorkspace(id: 'ws-2');
        expect(ws1, isNot(equals(ws2)));
      });

      test('== returns false for different name', () {
        final ws1 = createWorkspace(name: 'A');
        final ws2 = createWorkspace(name: 'B');
        expect(ws1, isNot(equals(ws2)));
      });

      test('== returns false for different logoPath', () {
        final ws1 = createWorkspace(logoPath: '/a.png');
        final ws2 = createWorkspace(logoPath: '/b.png');
        expect(ws1, isNot(equals(ws2)));
      });

      test('== returns false for different createdAt', () {
        final ws1 = createWorkspace(createdAt: DateTime(2024, 1, 1));
        final ws2 = createWorkspace(createdAt: DateTime(2024, 2, 1));
        expect(ws1, isNot(equals(ws2)));
      });

      test('== returns false for different updatedAt', () {
        final ws1 = createWorkspace(updatedAt: DateTime(2024, 1, 1));
        final ws2 = createWorkspace(updatedAt: DateTime(2024, 2, 1));
        expect(ws1, isNot(equals(ws2)));
      });

      test('== (identical)', () {
        final ws = createWorkspace();
        expect(ws, equals(ws));
      });

      test('hashCode matches for equal workspaces', () {
        final ws1 = createWorkspace();
        final ws2 = createWorkspace();
        expect(ws1.hashCode, equals(ws2.hashCode));
      });

      test('hashCode differs for different workspaces', () {
        final ws1 = createWorkspace(id: 'ws-1');
        final ws2 = createWorkspace(id: 'ws-2');
        expect(ws1.hashCode, isNot(equals(ws2.hashCode)));
      });
    });

    group('copyWith', () {
      test('returns identical copy with no arguments', () {
        final ws = createWorkspace();
        final copy = ws.copyWith();
        expect(copy, equals(ws));
        expect(copy.hashCode, equals(ws.hashCode));
      });

      test('updates id', () {
        final ws = createWorkspace();
        final copy = ws.copyWith(id: 'new-id');
        expect(copy.id, 'new-id');
        expect(copy.name, ws.name);
      });

      test('updates name', () {
        final ws = createWorkspace();
        final copy = ws.copyWith(name: 'New Name');
        expect(copy.name, 'New Name');
      });

      test('updates logoPath', () {
        final ws = createWorkspace();
        final copy = ws.copyWith(logoPath: '/new.png');
        expect(copy.logoPath, '/new.png');
      });

      test('removes logoPath via removeLogoPath flag', () {
        final ws = createWorkspace(logoPath: '/logo.png');
        final copy = ws.copyWith(removeLogoPath: true);
        expect(copy.logoPath, isNull);
      });

      test('removeLogoPath keeps null if already null', () {
        final ws = createWorkspace();
        final copy = ws.copyWith(removeLogoPath: true);
        expect(copy.logoPath, isNull);
      });

      test('updates createdAt', () {
        final ws = createWorkspace();
        final newDate = DateTime(2025, 1, 1);
        final copy = ws.copyWith(createdAt: newDate);
        expect(copy.createdAt, newDate);
      });

      test('updates updatedAt', () {
        final ws = createWorkspace();
        final newDate = DateTime(2025, 6, 1);
        final copy = ws.copyWith(updatedAt: newDate);
        expect(copy.updatedAt, newDate);
      });

      test('copyWith does not mutate original', () {
        final ws = createWorkspace();
        ws.copyWith(name: 'Changed');
        expect(ws.name, 'Test Workspace');
      });

      test('chaining copyWith calls', () {
        final ws = createWorkspace();
        final copy = ws
            .copyWith(name: 'Renamed')
            .copyWith(logoPath: '/logo.png');
        expect(copy.name, 'Renamed');
        expect(copy.logoPath, '/logo.png');
      });
    });
  });
}
