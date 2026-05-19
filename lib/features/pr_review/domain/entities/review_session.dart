enum ReviewSessionStatus {
  inProgress,
  completed,
  abandoned;

  static ReviewSessionStatus tryParse(String value) {
    return switch (value) {
      'in_progress' => ReviewSessionStatus.inProgress,
      'completed' => ReviewSessionStatus.completed,
      'abandoned' => ReviewSessionStatus.abandoned,
      _ => ReviewSessionStatus.inProgress,
    };
  }

  String get serializedName => switch (this) {
    ReviewSessionStatus.inProgress => 'in_progress',
    ReviewSessionStatus.completed => 'completed',
    ReviewSessionStatus.abandoned => 'abandoned',
  };
}

/// Review session.
class ReviewSession {
  /// ReviewSession({.
  const ReviewSession({
    required this.id,
    required this.prNumber,
    required this.workspaceId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Session identifier.
  final String id;
  /// Pull request number this session belongs to.
  final int prNumber;
  /// Workspace where the review session is running.
  final String workspaceId;
  /// Session status.
  final ReviewSessionStatus status;
  /// DateTime.
  final DateTime createdAt;
  /// DateTime.
  final DateTime updatedAt;

  /// Whether the session is active.
  bool get isInProgress => status == ReviewSessionStatus.inProgress;
  /// Whether the session has finished.
  bool get isCompleted => status == ReviewSessionStatus.completed;
  /// Whether the session was abandoned.
  bool get isAbandoned => status == ReviewSessionStatus.abandoned;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

