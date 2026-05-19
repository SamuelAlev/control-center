import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_edge.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps `code_edges` rows to [CodeEdge] domain entities.
class CodeEdgeMapper {
  /// Creates a [CodeEdgeMapper].
  const CodeEdgeMapper();

  /// Converts a DB row to a [CodeEdge] domain entity.
  CodeEdge toDomain(db.CodeEdgesTableData row) => CodeEdge(
    id: row.id,
    workspaceId: row.workspaceId,
    repoId: row.repoId,
    sourceSymbolId: row.sourceSymbolId,
    sourceFilePath: row.sourceFilePath,
    kind: CodeEdgeKind.tryParse(row.kind) ?? CodeEdgeKind.references,
    targetSymbolId: row.targetSymbolId,
    targetName: row.targetName,
    metadata: row.metadata == null
        ? null
        : jsonDecode(row.metadata!) as Map<String, dynamic>,
  );
}
