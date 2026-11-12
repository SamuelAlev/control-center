import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart';
import 'package:cc_persistence/database/code_index/code_index_database.dart'
    as db;

/// Maps `code_symbols` rows to [CodeSymbol] domain entities.
class CodeSymbolMapper {
  /// Creates a [CodeSymbolMapper].
  const CodeSymbolMapper();

  /// Converts a DB row of [workspaceId]'s code index to a [CodeSymbol].
  ///
  /// The row carries no workspace: its file belongs to one.
  CodeSymbol toDomain(
    db.CodeSymbolsTableData row, {
    required String workspaceId,
  }) => CodeSymbol(
    id: row.id,
    workspaceId: workspaceId,
    repoId: row.repoId,
    checkoutId: row.checkoutId,
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
