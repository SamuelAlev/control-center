import 'package:collection/collection.dart';
import 'package:control_center/core/domain/value_objects/code_edge_kind.dart';

/// A directed relationship between code symbols (the code graph's edge).
///
/// [targetSymbolId] is set when the target was resolved at extraction time
/// (intra-file) or by a later resolution pass; otherwise it is null and
/// [targetName] carries the raw callee name / import URI.
class CodeEdge {
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

  final String id;

  /// Owning workspace — scopes the edge to one workspace's code graph (two
  /// workspaces can share a [repoId]).
  final String workspaceId;
  final String repoId;
  final String sourceSymbolId;
  final String sourceFilePath;
  final CodeEdgeKind kind;
  final String? targetSymbolId;
  final String? targetName;
  final Map<String, dynamic>? metadata;

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
