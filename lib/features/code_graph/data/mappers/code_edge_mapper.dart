import 'dart:convert';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/value_objects/code_edge_kind.dart';
import 'package:control_center/features/code_graph/domain/entities/code_edge.dart';

/// Maps `code_edges` rows to [CodeEdge] domain entities.
class CodeEdgeMapper {
  const CodeEdgeMapper();

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
