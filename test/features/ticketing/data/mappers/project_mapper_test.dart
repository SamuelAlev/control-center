
import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/ticketing/data/mappers/project_mapper.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  const mapper = ProjectMapper();

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  /// Inserts a project and returns the generated row.
  Future<ProjectsTableData> insertProject({
    String id = 'proj-1',
    String workspaceId = 'ws-1',
    String name = 'Test Project',
    String? description,
    String color = 'gray',
    String status = 'active',
  }) async {
    await db.projectDao.insert(
      ProjectsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        name: name,
        description: Value.absentIfNull(description),
        color: Value(color),
        status: Value(status),
      ),
    );
    return (await db.projectDao.getById(id))!;
  }

  group('ProjectMapper', () {
    test('fromRow maps all fields correctly', timeout: const Timeout.factor(2),
        () async {
      final row = await insertProject();

      final project = mapper.fromRow(row);

      expect(project.id, 'proj-1');
      expect(project.workspaceId, 'ws-1');
      expect(project.name, 'Test Project');
      expect(project.description, isNull);
      expect(project.color, ProjectColor.gray);
      expect(project.status, ProjectStatus.active);
      expect(project.createdAt, isA<DateTime>());
      expect(project.updatedAt, isA<DateTime>());
    });

    test('fromRow maps nullable description when present', timeout: const Timeout.factor(2),
        () async {
      final row = await insertProject(description: 'Build auth system');

      final project = mapper.fromRow(row);

      expect(project.description, 'Build auth system');
    });

    test('toCompanion round-trips through fromRow', timeout: const Timeout.factor(2),
        () async {
      final original = Project(
        id: 'proj-rt',
        workspaceId: 'ws-1',
        name: 'Round Trip',
        description: 'Testing round trip',
        color: ProjectColor.blue,
        status: ProjectStatus.completed,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

      final companion = mapper.toCompanion(original);

      // Verify companion has every field set
      expect(companion.id.value, 'proj-rt');
      expect(companion.workspaceId.value, 'ws-1');
      expect(companion.name.value, 'Round Trip');
      expect(companion.description.value, 'Testing round trip');
      expect(companion.color.value, 'blue');
      expect(companion.status.value, 'completed');

      // Insert companion, read back, then fromRow
      await db.projectDao.insert(companion);
      final row = (await db.projectDao.getById('proj-rt'))!;
      final roundTripped = mapper.fromRow(row);

      expect(roundTripped.id, original.id);
      expect(roundTripped.workspaceId, original.workspaceId);
      expect(roundTripped.name, original.name);
      expect(roundTripped.description, original.description);
      expect(roundTripped.color, original.color);
      expect(roundTripped.status, original.status);
    });

    test('fromRow maps all ProjectColor values', timeout: const Timeout.factor(2),
        () async {
      for (final color in ProjectColor.values) {
        final row = await insertProject(
          id: 'proj-color-${color.name}',
          color: color.toStorageString(),
        );
        final project = mapper.fromRow(row);
        expect(project.color, color, reason: 'Failed for color ${color.name}');
      }
    });

    test('fromRow maps all ProjectStatus values', timeout: const Timeout.factor(2),
        () async {
      for (final status in ProjectStatus.values) {
        final row = await insertProject(
          id: 'proj-status-${status.name}',
          status: status.toStorageString(),
        );
        final project = mapper.fromRow(row);
        expect(project.status, status,
            reason: 'Failed for status ${status.name}');
      }
    });

    test('fromRow handles unknown color gracefully (defaults to gray)',
        timeout: const Timeout.factor(2), () async {
      final row = await insertProject(color: 'unknown_color');

      final project = mapper.fromRow(row);

      expect(project.color, ProjectColor.gray);
    });

    test('fromRow handles unknown status gracefully (defaults to active)',
        timeout: const Timeout.factor(2), () async {
      final row = await insertProject(status: 'unknown_status');

      final project = mapper.fromRow(row);

      expect(project.status, ProjectStatus.active);
    });

    test('toCompanion preserves null description', timeout: const Timeout.factor(2),
        () async {
      final original = Project(
        id: 'proj-null',
        workspaceId: 'ws-1',
        name: 'No Desc',
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final companion = mapper.toCompanion(original);

      expect(companion.description.value, isNull);
    });

    test('toCompanion serializes color and status to storage strings',
        timeout: const Timeout.factor(2), () async {
      final project = Project(
        id: 'proj-serial',
        workspaceId: 'ws-1',
        name: 'Serialization',
        color: ProjectColor.red,
        status: ProjectStatus.archived,
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );

      final companion = mapper.toCompanion(project);

      expect(companion.color.value, 'red');
      expect(companion.status.value, 'archived');
    });

    test('fromRow with special characters in name', timeout: const Timeout.factor(2),
        () async {
      final row = await insertProject(name: 'Project (Phase 2) — Build & Test');

      final project = mapper.fromRow(row);

      expect(project.name, 'Project (Phase 2) — Build & Test');
    });
  });
}
