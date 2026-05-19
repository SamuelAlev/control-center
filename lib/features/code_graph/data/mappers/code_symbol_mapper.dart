import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/value_objects/code_symbol_kind.dart';
import 'package:control_center/features/code_graph/domain/entities/code_symbol.dart';

/// Maps `code_symbols` rows to [CodeSymbol] domain entities.
class CodeSymbolMapper {
  /// Creates a [CodeSymbolMapper].
  const CodeSymbolMapper();

  /// Converts a DB row to a [CodeSymbol] domain entity.
  CodeSymbol toDomain(db.CodeSymbolsTableData row) => CodeSymbol(
    id: row.id,
    workspaceId: row.workspaceId,
    repoId: row.repoId,
    kind: CodeSymbolKind.tryParse(row.kind) ?? CodeSymbolKind.variable,
    name: row.name,
    qualifiedName: row.qualifiedName,
    filePath: row.filePath,
    language: row.language,
    startLine: row.startLine,
    endLine: row.endLine,
    signature: row.signature,
    docstring: row.docstring,
    parentName: row.parentName,
  );
}
