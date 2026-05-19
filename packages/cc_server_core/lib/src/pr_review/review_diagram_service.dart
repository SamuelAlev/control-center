import 'package:cc_domain/features/pr_review/domain/services/diagram_verifier.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:cc_persistence/cc_persistence.dart';

/// Builds the corroborated edge set from the real code graph and verifies
/// agent-emitted diagrams against it (PRD 18 §3). A sequence/state edge the
/// graph doesn't know is flagged (dashed + "unverified") or, in strict mode,
/// dropped — so a diagram is a view of verified edges, never prose with arrows.
///
/// Server-side; depends on [CodeGraphDao] directly for the file-scoped symbol/
/// edge queries, resolved per call from the workspace's own database file.
class ReviewDiagramService {
  /// Creates a [ReviewDiagramService] over the per-workspace databases.
  ReviewDiagramService(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  CodeGraphDao _codeGraph(String workspaceId) =>
      _dbs.of(workspaceId).codeGraphDao;

  static const _verifier = DiagramVerifier();

  /// Verifies [diagram] against the code graph edges among [filePaths] in
  /// `(workspaceId, repoId)`. Uncorroborated edges are flagged; when
  /// [dropUncorroborated] they are removed.
  Future<ReviewDiagram> verify({
    required String workspaceId,
    required String repoId,
    required List<String> filePaths,
    required ReviewDiagram diagram,
    bool dropUncorroborated = false,
  }) async {
    final keys = await corroboratedEdgeKeys(
      workspaceId: workspaceId,
      repoId: repoId,
      filePaths: filePaths,
    );
    return _verifier.verify(
      diagram,
      keys,
      dropUncorroborated: dropUncorroborated,
    );
  }

  /// The set of corroborated `from→to` edge keys derived from real resolved
  /// call/extends/implements edges among [filePaths]. Both function-level
  /// (symbol name) and container-level (parent name) keys are emitted so an
  /// agent's class-level participant labels can corroborate.
  Future<Set<String>> corroboratedEdgeKeys({
    required String workspaceId,
    required String repoId,
    required List<String> filePaths,
  }) async {
    if (filePaths.isEmpty) {
      return const {};
    }
    final symbols = await _codeGraph(
      workspaceId,
    ).getSymbolsByFiles(workspaceId, repoId, filePaths);
    final nameById = {for (final s in symbols) s.id: s.name};
    final parentById = {for (final s in symbols) s.id: s.parentName};

    final edges = await _codeGraph(
      workspaceId,
    ).getResolvedEdgesBySourceFiles(workspaceId, repoId, filePaths);
    final keys = <String>{};
    for (final e in edges) {
      final fromName = nameById[e.sourceSymbolId];
      final toName = nameById[e.targetSymbolId];
      if (fromName != null && toName != null) {
        keys.add(DiagramVerifier.edgeKey(fromName, toName));
      }
      final fromParent = parentById[e.sourceSymbolId];
      final toParent = parentById[e.targetSymbolId];
      if (fromParent != null &&
          fromParent.isNotEmpty &&
          toParent != null &&
          toParent.isNotEmpty) {
        keys.add(DiagramVerifier.edgeKey(fromParent, toParent));
      }
      // Also allow container→callee-function edges (a common diagram shape).
      if (fromParent != null && fromParent.isNotEmpty && toName != null) {
        keys.add(DiagramVerifier.edgeKey(fromParent, toName));
      }
    }
    return keys;
  }
}
