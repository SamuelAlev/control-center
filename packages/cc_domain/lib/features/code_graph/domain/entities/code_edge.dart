import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
import 'package:cc_domain/features/code_graph/domain/entities/code_symbol.dart'
    show CodeSymbol;
import 'package:collection/collection.dart';

/// A directed relationship between code symbols (the code graph's edge).
///
/// [targetSymbolId] is set when the target was resolved at extraction time
/// (intra-file) or by a later resolution pass; otherwise it is null and
/// [targetName] carries the raw callee name / import URI.
class CodeEdge {
  /// Creates a [CodeEdge].
  CodeEdge({
    required this.id,
    required this.workspaceId,
    required this.repoId,
    this.checkoutId,
    required this.sourceSymbolId,
    required this.sourceFilePath,
    required this.kind,
    this.targetSymbolId,
    this.targetName,
    this.metadata,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('CodeEdge id must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError('CodeEdge workspaceId must not be empty');
    }
    if (repoId.isEmpty) {
      throw ArgumentError('CodeEdge repoId must not be empty');
    }
    if (sourceSymbolId.isEmpty) {
      throw ArgumentError('CodeEdge sourceSymbolId must not be empty');
    }
    if (targetSymbolId == null && targetName == null) {
      throw ArgumentError(
        'CodeEdge must have a resolved targetSymbolId or a targetName',
      );
    }
  }

  /// Content-addressed identifier.
  final String id;

  /// Owning workspace — scopes the edge to one workspace's code graph (two
  /// workspaces can share a [repoId]).
  final String workspaceId;

  /// Owning repository identifier.
  final String repoId;

  /// The checkout partition this edge belongs to (null = linked checkout,
  /// otherwise an `isolated_repos` row id). Matches [CodeSymbol.checkoutId].
  final String? checkoutId;

  /// Source symbol identifier.
  final String sourceSymbolId;

  /// File path of the source symbol.
  final String sourceFilePath;

  /// Edge relationship kind.
  final CodeEdgeKind kind;

  /// Resolved target symbol identifier, if known.
  final String? targetSymbolId;

  /// Raw target name, when not resolved.
  final String? targetName;

  /// Additional edge metadata.
  final Map<String, dynamic>? metadata;

  /// Whether the target symbol has been resolved.
  bool get isResolved => targetSymbolId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeEdge &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          repoId == other.repoId &&
          checkoutId == other.checkoutId &&
          sourceSymbolId == other.sourceSymbolId &&
          sourceFilePath == other.sourceFilePath &&
          kind == other.kind &&
          targetSymbolId == other.targetSymbolId &&
          targetName == other.targetName &&
          const DeepCollectionEquality().equals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    repoId,
    checkoutId,
    sourceSymbolId,
    sourceFilePath,
    kind,
    targetSymbolId,
    targetName,
    metadata == null ? null : const DeepCollectionEquality().hash(metadata),
  );
}
