import 'package:cc_domain/features/fleet/domain/value_objects/placement_decision.dart';

/// A persisted placement-log entry (PRD 20 §7).
class PlacementRecord {
  /// Creates a [PlacementRecord].
  const PlacementRecord({
    required this.id,
    required this.workspaceId,
    required this.jobId,
    required this.code,
    required this.reason,
    required this.createdAt,
    this.workerId,
  });

  /// Unique row id.
  final String id;

  /// Owning workspace (matches the job).
  final String workspaceId;

  /// The job this decision concerns.
  final String jobId;

  /// The chosen worker id, or null when the job stayed queued.
  final String? workerId;

  /// The decision code.
  final PlacementCode code;

  /// Human-readable explanation.
  final String reason;

  /// Decision time.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) => other is PlacementRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
