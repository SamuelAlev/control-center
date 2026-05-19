import 'dart:convert';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_persistence/database/global/global_database.dart';

/// Maps database rows to [Workspace] domain entities.
class WorkspaceMapper {
  /// Creates a const [WorkspaceMapper].
  const WorkspaceMapper();

  /// To domain.
  Workspace toDomain(WorkspacesTableData row) {
    return Workspace(
      id: row.id,
      name: row.name,
      logoPath: row.logoPath,
      ownerUserId: row.ownerUserId,
      secretExcludeGlobs: _decodeGlobs(row.secretExcludeGlobs),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      reviewConcurrency: row.reviewConcurrency,
      deletedAt: row.deletedAt,
    );
  }

  /// To domain list.
  List<Workspace> toDomainList(List<WorkspacesTableData> rows) =>
      rows.map(toDomain).toList(growable: false);
}

List<String> _decodeGlobs(String json) {
  try {
    final raw = jsonDecode(json);
    return raw is List ? raw.whereType<String>().toList() : const [];
  } catch (_) {
    return const [];
  }
}
