/// A workspace is a user-named container with an optional logo.
///
/// Repositories targeted by a workspace are looked up separately via the
/// workspace-repo link table; the workspace entity itself carries no repo
/// state.
class Workspace {
  /// Creates a [Workspace].
  Workspace({
    required this.id,
    required this.name,
    this.logoPath,
    required this.createdAt,
    required this.updatedAt,
    this.reviewConcurrency = 3,
    this.deletedAt,
  })  : assert(name.isNotEmpty, 'Workspace name must not be empty'),
        assert(reviewConcurrency >= 1,
            'reviewConcurrency must be at least 1');

  /// Unique identifier.
  final String id;

  /// Display name (user-supplied at creation).
  final String name;

  /// Optional path to a local image file used as the workspace logo.
  final String? logoPath;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Default fan-out for parallel reviewer dispatch.
  /// Per-call `concurrency` arg on `dispatch_reviewers` overrides this.
  final int reviewConcurrency;
  /// Soft-delete timestamp. Non-null when workspace has been deleted.
  final DateTime? deletedAt;

  /// True when this workspace has been soft-deleted.
  bool get isDeleted => deletedAt != null;


  /// True when [logoPath] is non-empty.
  bool get hasLogo => logoPath != null && logoPath!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workspace &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          logoPath == other.logoPath &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          reviewConcurrency == other.reviewConcurrency &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    logoPath,
    createdAt,
    updatedAt,
    reviewConcurrency,
    deletedAt,
  );

  /// Copy with.
  Workspace copyWith({
    String? id,
    String? name,
    String? logoPath,
    bool removeLogoPath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? reviewConcurrency,
    DateTime? deletedAt,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: removeLogoPath ? null : (logoPath ?? this.logoPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewConcurrency: reviewConcurrency ?? this.reviewConcurrency,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
