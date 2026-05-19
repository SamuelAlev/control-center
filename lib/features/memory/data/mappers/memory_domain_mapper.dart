import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';

class MemoryDomainMapper {
  const MemoryDomainMapper();

  MemoryDomain toDomain(db.MemoryDomainsTableData row) {
    return MemoryDomain(
      id: row.id,
      workspaceId: row.workspaceId,
      name: row.name,
      label: row.label,
      description: row.description,
      createdAt: row.createdAt,
      createdByRole: row.createdByRole,
    );
  }
}
