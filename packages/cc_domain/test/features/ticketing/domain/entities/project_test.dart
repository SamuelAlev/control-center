import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:test/test.dart';

/// Exercises [Project], [ProjectStatus], and [ProjectColor].
void main() {
  group('ProjectStatus', () {
    test('fromStorage parses known values', () {
      expect(ProjectStatus.fromStorage('active'), ProjectStatus.active);
      expect(ProjectStatus.fromStorage('completed'), ProjectStatus.completed);
      expect(ProjectStatus.fromStorage('archived'), ProjectStatus.archived);
    });

    test('fromStorage defaults to active for unknown', () {
      expect(ProjectStatus.fromStorage('bogus'), ProjectStatus.active);
      expect(ProjectStatus.fromStorage(null), ProjectStatus.active);
    });

    test('isActive is true only for active', () {
      expect(ProjectStatus.active.isActive, isTrue);
      expect(ProjectStatus.completed.isActive, isFalse);
    });

    test('toStorageString round-trips', () {
      for (final s in ProjectStatus.values) {
        expect(ProjectStatus.fromStorage(s.toStorageString()), s);
      }
    });
  });

  group('ProjectColor', () {
    test('fromStorage defaults to gray for unknown', () {
      expect(ProjectColor.fromStorage('bogus'), ProjectColor.gray);
      expect(ProjectColor.fromStorage(null), ProjectColor.gray);
    });

    test('toStorageString round-trips', () {
      for (final c in ProjectColor.values) {
        expect(ProjectColor.fromStorage(c.toStorageString()), c);
      }
    });
  });

  group('Project', () {
    Project project() => Project(
      id: 'p-1',
      workspaceId: 'ws-1',
      name: 'Auth',
      description: 'make auth work',
      color: ProjectColor.blue,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );

    test('rejects an empty name', () {
      expect(
        () => Project(
          id: 'p',
          workspaceId: 'ws',
          name: '',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith preserves fields and supports removeDescription', () {
      final p = project();
      final next = p.copyWith(name: 'New', removeDescription: true);
      expect(next.name, 'New');
      expect(next.description, isNull);
      expect(next.color, ProjectColor.blue);
      expect(next.id, 'p-1');
    });

    test('equality and hashCode', () {
      expect(project(), project());
      expect(project().hashCode, project().hashCode);
    });

    test('unequal when status differs', () {
      expect(
        project(),
        isNot(project().copyWith(status: ProjectStatus.archived)),
      );
    });
  });
}
