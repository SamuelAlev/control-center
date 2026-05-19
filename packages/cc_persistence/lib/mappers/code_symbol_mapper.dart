import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

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
