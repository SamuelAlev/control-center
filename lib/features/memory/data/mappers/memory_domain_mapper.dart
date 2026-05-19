import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';

/// Maps [db.MemoryDomainsTableData] rows to [MemoryDomain] domain entities.
class MemoryDomainMapper {
  /// Creates a const [MemoryDomainMapper].
  const MemoryDomainMapper();

  /// Converts a [db.MemoryDomainsTableData] row to a [MemoryDomain].
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
