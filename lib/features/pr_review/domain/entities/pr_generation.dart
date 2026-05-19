/// PrGenerationStatus and its subtypes model the lifecycle of a generated PR.
sealed class PrGenerationStatus {
  const PrGenerationStatus();

  /// Name.
  String get name {
    switch (this) {
      case Draft():
        return 'draft';
      case Published():
        return 'published';
      case Created():
        return 'created';
    }
  }

  /// From name.
  static PrGenerationStatus fromName(String name) {
    switch (name) {
      case 'draft':
        return const Draft();
      case 'published':
        return const Published();
      case 'created':
        return const Created();
      default:
        return const Draft();
    }
  }

  /// canPublish.
  bool get canPublish => this is Draft;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrGenerationStatus && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Draft.
class Draft extends PrGenerationStatus {
  /// Draft.
  const Draft();
}

/// Published.
class Published extends PrGenerationStatus {
  /// Published.
  const Published();
}

/// Created.
class Created extends PrGenerationStatus {
  /// Created.
  const Created();
}

/// Pr generation.
class PrGeneration {
  /// Creates a new [Pr generation].
  PrGeneration({
    required this.id,
    required this.workspaceId,
    required this.status,
    this.title,
    this.body,
    this.branch,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(id.isNotEmpty, 'PrGeneration id must not be empty');

  /// Identifier.
  final String id;
  /// Workspace ID.
  final String workspaceId;
  /// Status.
  final PrGenerationStatus status;
  final String? title;
  final String? body;
  final String? branch;
  /// When created.
  final DateTime createdAt;
  /// When last updated.
  final DateTime updatedAt;

  /// Whether this is a draft.
  bool get isDraft => status is Draft;
  /// isPublished.
  bool get isPublished => status is Published;
  /// isCreated.
  bool get isCreated => status is Created;

  /// canPublish.
  bool canPublish() => status.canPublish;

  /// Mark published.
  PrGeneration markPublished() {
    assert(
      status is Draft,
      'Can only publish from Draft status, current: ${status.name}',
    );
    return copyWith(status: const Published());
  }

  /// validate.
  void validate() {
    if (title == null || title!.isEmpty) {
      throw ArgumentError('PR title is required');
    }
    if (body == null || body!.isEmpty) {
      throw ArgumentError('PR body is required');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrGeneration &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          status == other.status &&
          title == other.title &&
          body == other.body &&
          branch == other.branch &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    status,
    title,
    body,
    branch,
    createdAt,
    updatedAt,
  );

  /// Copy with.
  PrGeneration copyWith({
    String? id,
    String? workspaceId,
    PrGenerationStatus? status,
    String? title,
    bool removeTitle = false,
    String? body,
    bool removeBody = false,
    String? branch,
    bool removeBranch = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrGeneration(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      status: status ?? this.status,
      title: removeTitle ? null : (title ?? this.title),
      body: removeBody ? null : (body ?? this.body),
      branch: removeBranch ? null : (branch ?? this.branch),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

