import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025, 6, 15, 10, 30);

  Workspace createWorkspace({
    String id = 'ws-1',
    String name = 'My Workspace',
    String? logoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workspace(
      id: id,
      name: name,
      logoPath: logoPath,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('Workspace constructor', () {
    test('creates workspace with required fields', () {
      final ws = createWorkspace();
      expect(ws.id, 'ws-1');
      expect(ws.name, 'My Workspace');
    });

    test('throws assertion error for empty name', () {
      expect(
        () => Workspace(
          id: '1',
          name: '',
          createdAt: now,
          updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Workspace computed properties', () {
    test('hasLogo returns true when logoPath is set', () {
      expect(createWorkspace().hasLogo, isFalse);
      expect(createWorkspace(logoPath: '/path/to/logo.png').hasLogo, isTrue);
      expect(createWorkspace(logoPath: '').hasLogo, isFalse);
    });
  });

  group('Workspace == and hashCode', () {
    test('identical workspaces are equal', () {
      final a = createWorkspace();
      final b = createWorkspace();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different id makes unequal', () {
      final a = createWorkspace(id: 'a');
      final b = createWorkspace(id: 'b');
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createWorkspace();
      expect(a, equals(a));
    });
  });

  group('Workspace copyWith', () {
    test('returns new instance with updated name', () {
      final ws = createWorkspace();
      final updated = ws.copyWith(name: 'New Name');
      expect(updated.name, 'New Name');
      expect(updated.id, 'ws-1');
      expect(updated, isNot(equals(ws)));
    });

    test('removeLogoPath sets logo to null', () {
      final ws = createWorkspace(logoPath: '/logo.png');
      final updated = ws.copyWith(removeLogoPath: true);
      expect(updated.logoPath, isNull);
    });

    test('copyWith without changes returns equal workspace', () {
      final ws = createWorkspace();
      final updated = ws.copyWith();
      expect(updated, equals(ws));
    });
  });
}
