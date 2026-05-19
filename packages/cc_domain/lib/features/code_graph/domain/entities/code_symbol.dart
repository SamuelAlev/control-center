import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';

/// A code symbol (function, class, method, field, …) extracted from source.
///
/// Pure structural data — no DB timestamps (those are a storage concern set by
/// the repository on upsert). [id] is content-addressed (see `code_graph_ids`).
class CodeSymbol {
  /// Creates a [CodeSymbol].
  CodeSymbol({
    required this.id,
    required this.workspaceId,
    required this.repoId,
    required this.kind,
    required this.name,
    required this.qualifiedName,
    required this.filePath,
    required this.language,
    required this.startLine,
    required this.endLine,
    this.signature = '',
    this.docstring,
    this.parentName,
  }) : assert(id.isNotEmpty, 'CodeSymbol id must not be empty'),
       assert(
         workspaceId.isNotEmpty,
         'CodeSymbol workspaceId must not be empty',
       ),
       assert(repoId.isNotEmpty, 'CodeSymbol repoId must not be empty'),
       assert(
         qualifiedName.isNotEmpty,
         'CodeSymbol qualifiedName must not be empty',
       ),
       assert(filePath.isNotEmpty, 'CodeSymbol filePath must not be empty'),
       assert(
         startLine <= endLine,
         'CodeSymbol startLine must be <= endLine',
       );

  /// Content-addressed identifier.
  final String id;

  /// Owning workspace — the code graph is scoped per workspace (worktree), not
  /// just per repo, because two workspaces can share a [repoId].
  final String workspaceId;
  /// Owning repository identifier.
  final String repoId;
  /// Symbol kind (class, function, method, etc.).
  final CodeSymbolKind kind;
  /// Simple name, without qualification.
  final String name;
  /// Fully qualified name with parent prefix.
  final String qualifiedName;
  /// Path of the source file containing this symbol.
  final String filePath;
  /// Language identifier (e.g. "dart", "python").
  final String language;
  /// Starting line number (1-based).
  final int startLine;
  /// Ending line number (1-based).
  final int endLine;
  /// Signature string, if known.
  final String signature;
  /// Docstring, if any.
  final String? docstring;
  /// Qualified name of the parent symbol, if any.
  final String? parentName;

  /// Returns a copy with the given fields replaced.
  CodeSymbol copyWith({
    String? id,
    String? workspaceId,
    String? repoId,
    CodeSymbolKind? kind,
    String? name,
    String? qualifiedName,
    String? filePath,
    String? language,
    int? startLine,
    int? endLine,
    String? signature,
    String? docstring,
    String? parentName,
  }) => CodeSymbol(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    repoId: repoId ?? this.repoId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    qualifiedName: qualifiedName ?? this.qualifiedName,
    filePath: filePath ?? this.filePath,
    language: language ?? this.language,
    startLine: startLine ?? this.startLine,
    endLine: endLine ?? this.endLine,
    signature: signature ?? this.signature,
    docstring: docstring ?? this.docstring,
    parentName: parentName ?? this.parentName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeSymbol &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          repoId == other.repoId &&
          kind == other.kind &&
          name == other.name &&
          qualifiedName == other.qualifiedName &&
          filePath == other.filePath &&
          language == other.language &&
          startLine == other.startLine &&
          endLine == other.endLine &&
          signature == other.signature &&
          docstring == other.docstring &&
          parentName == other.parentName;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    repoId,
    kind,
    name,
    qualifiedName,
    filePath,
    language,
    startLine,
    endLine,
    signature,
    docstring,
    parentName,
  );
}
