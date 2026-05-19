import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/features/memory/data/mappers/memory_domain_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryDomainMapper', () {
    const mapper = MemoryDomainMapper();

    db.MemoryDomainsTableData createRow({
      String id = 'd1',
      String workspaceId = 'ws1',
      String name = 'codebase',
      String label = 'Codebase',
      String? description,
      DateTime? createdAt,
      String createdByRole = 'coder',
    }) {
      return db.MemoryDomainsTableData(
        id: id,
        workspaceId: workspaceId,
        name: name,
        label: label,
        description: description,
        createdAt: createdAt ?? DateTime(2025, 6, 10),
        createdByRole: createdByRole,
      );
    }

    test('maps all fields correctly', timeout: const Timeout.factor(2), () {
      final now = DateTime(2025, 6, 10);
      final row = createRow(
        id: 'domain-1',
        workspaceId: 'ws-1',
        name: 'preferences',
        label: 'User Preferences',
        createdAt: now,
        createdByRole: 'ceo',
      );

      final domain = mapper.toDomain(row);

      expect(domain.id, 'domain-1');
      expect(domain.workspaceId, 'ws-1');
      expect(domain.name, 'preferences');
      expect(domain.label, 'User Preferences');
      expect(domain.createdAt, now);
      expect(domain.createdByRole, 'ceo');
    });

    test('maps nullable description when present', timeout: const Timeout.factor(2), () {
      final row = createRow(description: 'User preference settings');

      final domain = mapper.toDomain(row);

      expect(domain.description, 'User preference settings');
    });

    test('maps null description', timeout: const Timeout.factor(2), () {
      final row = createRow(description: null);

      final domain = mapper.toDomain(row);

      expect(domain.description, isNull);
    });
  });
}
