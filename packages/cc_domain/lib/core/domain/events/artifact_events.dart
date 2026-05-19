import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// Base for artifact lifecycle events.
///
/// An artifact is a block document (markdown / table / chart / mermaid / code /
/// data) an agent publishes into a conversation; it is stored as a WorkProduct
/// plus one revision per publish. All events carry the work product, the
/// revision they concern, its conversation and the workspace so listeners can
/// re-scope safely.
abstract class ArtifactEvent implements DomainEvent {
  /// Creates an [ArtifactEvent].
  const ArtifactEvent({
    required this.workProductId,
    required this.revisionId,
    required this.workspaceId,
    required this.conversationId,
    required this.agentId,
    required this.revisionNumber,
    required this.blockCount,
    required this.occurredAt,
  });

  /// The work product holding the artifact (stable across revisions).
  final String workProductId;

  /// The revision this event concerns.
  final String revisionId;

  /// Workspace scope.
  final String workspaceId;

  /// The conversation the artifact was authored in.
  final String conversationId;

  /// The agent that authored it.
  final String agentId;

  /// 1-based revision number.
  final int revisionNumber;

  /// How many blocks the published revision carries.
  final int blockCount;

  @override
  final DateTime occurredAt;
}

/// Fired when an agent publishes a new artifact via `publish_artifact`.
///
/// The load-bearing half of making an artifact visible is the typed `artifact`
/// channel message the tool posts alongside this; the event is the decoupled
/// lane for notifications, the newsfeed and the artifacts side panel — anything
/// that wants to react without polling.
class ArtifactPublished extends ArtifactEvent {
  /// Creates an [ArtifactPublished] event.
  const ArtifactPublished({
    required super.workProductId,
    required super.revisionId,
    required super.workspaceId,
    required super.conversationId,
    required super.agentId,
    required super.revisionNumber,
    required super.blockCount,
    required super.occurredAt,
    required this.title,
  });

  /// The artifact's title, so a listener can render a notification without a
  /// round trip to the repository.
  final String title;
}

/// Fired when an agent replaces an artifact's content via `revise_artifact`.
///
/// A revision deliberately posts NO second channel message: the artifact bubble
/// watches the work-product row, so it re-renders in place. Feeding a fresh
/// bubble per revision would churn the conversation for what the reader
/// experiences as one evolving document.
class ArtifactRevised extends ArtifactEvent {
  /// Creates an [ArtifactRevised] event.
  const ArtifactRevised({
    required super.workProductId,
    required super.revisionId,
    required super.workspaceId,
    required super.conversationId,
    required super.agentId,
    required super.revisionNumber,
    required super.blockCount,
    required super.occurredAt,
    this.summary,
  });

  /// The author's one-line description of what changed, when supplied.
  final String? summary;
}
