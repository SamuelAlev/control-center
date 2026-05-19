import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2025, 1, 1);
  final updated = DateTime(2025, 1, 2);

  Project make({
    String id = 'p1',
    String workspaceId = 'ws1',
    String name = 'My Project',
    String? description,
    ProjectColor color = ProjectColor.gray,
    ProjectStatus status = ProjectStatus.active,
  }) {
    return Project(
      id: id,
      workspaceId: workspaceId,
      name: name,
      description: description,
      color: color,
      status: status,
      createdAt: created,
      updatedAt: updated,
    );
  }

  group('ProjectStatus', () {
    group('fromStorage', () {
      test('maps canonical names', timeout: const Timeout.factor(2), () {
        for (final s in ProjectStatus.values) {
          expect(ProjectStatus.fromStorage(s.name), s);
        }
      });

      test('defaults to active for null', timeout: const Timeout.factor(2), () {
        expect(ProjectStatus.fromStorage(null), ProjectStatus.active);
      });

      test('defaults to active for unknown', timeout: const Timeout.factor(2), () {
        expect(ProjectStatus.fromStorage('unknown'), ProjectStatus.active);
      });
    });

    group('toStorageString', () {
      test('returns enum name', timeout: const Timeout.factor(2), () {
        expect(ProjectStatus.active.toStorageString(), 'active');
        expect(ProjectStatus.completed.toStorageString(), 'completed');
        expect(ProjectStatus.archived.toStorageString(), 'archived');
      });

      test('round-trips', timeout: const Timeout.factor(2), () {
        for (final s in ProjectStatus.values) {
          expect(ProjectStatus.fromStorage(s.toStorageString()), s);
        }
      });
    });

    group('isActive', () {
      test('only active is active', timeout: const Timeout.factor(2), () {
        expect(ProjectStatus.active.isActive, isTrue);
        expect(ProjectStatus.completed.isActive, isFalse);
        expect(ProjectStatus.archived.isActive, isFalse);
      });
    });
  });

  group('ProjectColor', () {
    group('fromStorage', () {
      test('maps canonical names', timeout: const Timeout.factor(2), () {
        for (final c in ProjectColor.values) {
          expect(ProjectColor.fromStorage(c.name), c);
        }
      });

      test('defaults to gray for null', timeout: const Timeout.factor(2), () {
        expect(ProjectColor.fromStorage(null), ProjectColor.gray);
      });

      test('defaults to gray for unknown', timeout: const Timeout.factor(2), () {
        expect(ProjectColor.fromStorage('unknown'), ProjectColor.gray);
      });
    });

    group('toStorageString', () {
      test('round-trips all values', timeout: const Timeout.factor(2), () {
        for (final c in ProjectColor.values) {
          expect(ProjectColor.fromStorage(c.toStorageString()), c);
        }
      });
    });

    test('has all eight colors', timeout: const Timeout.factor(2), () {
      expect(ProjectColor.values, hasLength(8));
    });
  });

  group('Project', () {
    test('creates with required fields', timeout: const Timeout.factor(2), () {
      final p = make();
      expect(p.id, 'p1');
      expect(p.workspaceId, 'ws1');
      expect(p.name, 'My Project');
      expect(p.description, isNull);
      expect(p.color, ProjectColor.gray);
      expect(p.status, ProjectStatus.active);
      expect(p.createdAt, created);
      expect(p.updatedAt, updated);
    });

    test('asserts name is not empty', timeout: const Timeout.factor(2), () {
      expect(
        () => make(name: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('allows description to be set', timeout: const Timeout.factor(2), () {
      final p = make(description: 'A longer description');
      expect(p.description, 'A longer description');
    });

    group('copyWith', () {
      test('returns new instance with updated fields', timeout: const Timeout.factor(2), () {
        final original = make();
        final copy = original.copyWith(
          name: 'Renamed',
          color: ProjectColor.blue,
          status: ProjectStatus.archived,
        );
        expect(copy.name, 'Renamed');
        expect(copy.color, ProjectColor.blue);
        expect(copy.status, ProjectStatus.archived);
        expect(copy.id, original.id);
        expect(copy.workspaceId, original.workspaceId);
      });

      test('clears description with removeDescription', timeout: const Timeout.factor(2), () {
        final p = make(description: 'has desc');
        final cleared = p.copyWith(removeDescription: true);
        expect(cleared.description, isNull);
      });

      test('preserves all fields when no args given', timeout: const Timeout.factor(2), () {
        final p = make(description: 'desc');
        final copy = p.copyWith();
        expect(copy.name, p.name);
        expect(copy.description, p.description);
        expect(copy.color, p.color);
        expect(copy.status, p.status);
      });

      test('updates updatedAt', timeout: const Timeout.factor(2), () {
        final newTs = DateTime(2025, 6, 1);
        final copy = make().copyWith(updatedAt: newTs);
        expect(copy.updatedAt, newTs);
      });
    });

    group('equality', () {
      test('equal when id, name, description, color, status, updatedAt match', timeout: const Timeout.factor(2), () {
        final a = make(id: 'x', name: 'P', color: ProjectColor.red, status: ProjectStatus.active);
        final b = make(id: 'x', name: 'P', color: ProjectColor.red, status: ProjectStatus.active);
        expect(a, equals(b));
      });

      test('not equal when id differs', timeout: const Timeout.factor(2), () {
        expect(make(id: 'a'), isNot(equals(make(id: 'b'))));
      });

      test('not equal when name differs', timeout: const Timeout.factor(2), () {
        expect(make(name: 'A'), isNot(equals(make(name: 'B'))));
      });

      test('not equal when status differs', timeout: const Timeout.factor(2), () {
        expect(
          make(status: ProjectStatus.active),
          isNot(equals(make(status: ProjectStatus.archived))),
        );
      });

      test('hashCode consistent with equality', timeout: const Timeout.factor(2), () {
        final a = make(id: 'x');
        final b = make(id: 'x');
        expect(a.hashCode, b.hashCode);
      });

      test('createdAt difference does not affect equality', timeout: const Timeout.factor(2), () {
        final a = Project(
          id: 'p', workspaceId: 'ws', name: 'N',
          createdAt: DateTime(2025, 1, 1), updatedAt: updated,
        );
        final b = Project(
          id: 'p', workspaceId: 'ws', name: 'N',
          createdAt: DateTime(2025, 12, 31), updatedAt: updated,
        );
        expect(a, equals(b));
      });
    });
  });
}
