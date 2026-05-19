import 'package:cc_domain/core/domain/value_objects/code_edge_kind.dart';
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
    required this.sourceSymbolId,
    required this.sourceFilePath,
    required this.kind,
    this.targetSymbolId,
    this.targetName,
    this.metadata,
  }) : assert(id.isNotEmpty, 'CodeEdge id must not be empty'),
       assert(workspaceId.isNotEmpty, 'CodeEdge workspaceId must not be empty'),
       assert(repoId.isNotEmpty, 'CodeEdge repoId must not be empty'),
       assert(
         sourceSymbolId.isNotEmpty,
         'CodeEdge sourceSymbolId must not be empty',
       ),
       assert(
         targetSymbolId != null || targetName != null,
         'CodeEdge must have a resolved targetSymbolId or a targetName',
       );

  /// Content-addressed identifier.
  final String id;

  /// Owning workspace — scopes the edge to one workspace's code graph (two
  /// workspaces can share a [repoId]).
  final String workspaceId;
  /// Owning repository identifier.
  final String repoId;
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
    sourceSymbolId,
    sourceFilePath,
    kind,
    targetSymbolId,
    targetName,
    metadata == null ? null : const DeepCollectionEquality().hash(metadata),
  );
}
