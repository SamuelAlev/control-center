import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';

/// One snapshot in an orchestration's revision history (PRD 17 §5).
///
/// Append-only: every propose/revise/edit/rewind lands a row, so the version
/// timeline, plan diff, and "what did I actually approve?" all have a stable
/// record. The live `Orchestration` row mirrors the highest revision.
class OrchestrationRevision {
  /// Creates a revision snapshot. [revision] must be >= 1.
  OrchestrationRevision({
    required this.id,
    required this.workspaceId,
    required this.orchestrationId,
    required this.revision,
    required this.proposal,
    required this.authoredBy,
    this.authorKind = 'user',
    required this.createdAt,
  }) {
    if (id.isEmpty || workspaceId.isEmpty || orchestrationId.isEmpty) {
      throw ArgumentError(
        'OrchestrationRevision requires non-empty id, workspaceId, and '
        'orchestrationId.',
      );
    }
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be >= 1');
    }
  }

  /// Unique row id (UUID v4).
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The orchestration this snapshot belongs to.
  final String orchestrationId;

  /// The revision number this row snapshots.
  final int revision;

  /// The full proposal at this revision.
  final OrchestrationProposal proposal;

  /// User or agent id that authored the revision.
  final String authoredBy;

  /// Whether [authoredBy] is a `user` or an `agent`.
  final String authorKind;

  /// When the revision landed.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is OrchestrationRevision &&
      other.id == id &&
      other.orchestrationId == orchestrationId &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(id, orchestrationId, revision);
}
