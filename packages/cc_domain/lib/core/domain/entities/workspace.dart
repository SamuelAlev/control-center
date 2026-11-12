import 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart';

export 'package:cc_domain/core/domain/value_objects/workspace_connect_mode.dart';
export 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart';

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
    this.ownerUserId,
    this.secretExcludeGlobs = const [],
    required this.createdAt,
    required this.updatedAt,
    this.reviewConcurrency = 3,
    this.autoPublishReview = false,
    this.connectMode = WorkspaceConnectMode.inherit,
    this.connectUrl = '',
    this.githubAppId = '',
    this.deletedAt,
    this.storageState = WorkspaceStorageState.ok,
  }) {
    if (name.isEmpty) {
      throw ArgumentError('Workspace name must not be empty');
    }
    if (reviewConcurrency < 1) {
      throw ArgumentError('reviewConcurrency must be at least 1');
    }
  }

  /// Unique identifier.
  final String id;

  /// Display name (user-supplied at creation).
  final String name;

  /// Optional path to a local image file used as the workspace logo.
  final String? logoPath;

  /// The user who owns this workspace (holds the `owner` role). Nullable only
  /// until the identity bootstrap backfills it on first boot; treated as
  /// required everywhere else.
  final String? ownerUserId;

  /// Glob patterns whose matching paths are hard-blocked from guest/viewer
  /// visibility on code-bearing surfaces (secret exclusion).
  final List<String> secretExcludeGlobs;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Default fan-out for parallel reviewer dispatch.
  /// Per-call `concurrency` arg on `dispatch_reviewers` overrides this.
  final int reviewConcurrency;

  /// Whether a completed review publishes to GitHub automatically.
  /// Opt-in (off by default); publishing is otherwise user-gated.
  final bool autoPublishReview;

  /// Whose provider apps this workspace uses: the server's choice, a Connect
  /// of its own, or its own apps.
  final WorkspaceConnectMode connectMode;

  /// The canonical Connect base URL when [connectMode] is
  /// [WorkspaceConnectMode.custom]. Empty otherwise.
  final String connectUrl;

  /// Numeric id of this workspace's own GitHub App, used while [connectMode]
  /// is [WorkspaceConnectMode.own]. Empty when none is saved. The private key
  /// lives in the secrets file, never here.
  final String githubAppId;

  /// Soft-delete timestamp. Non-null when workspace has been deleted.
  final DateTime? deletedAt;

  /// Whether its database takes writes, as the server reports it on the
  /// workspace list. Server-authoritative: a client reads it and never sends
  /// it back.
  final WorkspaceStorageState storageState;

  /// True when this workspace serves reads only until it is restored.
  bool get isReadOnly => storageState == WorkspaceStorageState.readOnly;

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
          ownerUserId == other.ownerUserId &&
          _listEquals(secretExcludeGlobs, other.secretExcludeGlobs) &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          reviewConcurrency == other.reviewConcurrency &&
          autoPublishReview == other.autoPublishReview &&
          connectMode == other.connectMode &&
          connectUrl == other.connectUrl &&
          githubAppId == other.githubAppId &&
          deletedAt == other.deletedAt &&
          storageState == other.storageState;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    logoPath,
    ownerUserId,
    Object.hashAll(secretExcludeGlobs),
    createdAt,
    updatedAt,
    reviewConcurrency,
    autoPublishReview,
    connectMode,
    connectUrl,
    githubAppId,
    deletedAt,
    storageState,
  );

  /// Copy with.
  Workspace copyWith({
    String? id,
    String? name,
    String? logoPath,
    bool removeLogoPath = false,
    String? ownerUserId,
    List<String>? secretExcludeGlobs,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? reviewConcurrency,
    bool? autoPublishReview,
    WorkspaceConnectMode? connectMode,
    String? connectUrl,
    String? githubAppId,
    DateTime? deletedAt,
    WorkspaceStorageState? storageState,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: removeLogoPath ? null : (logoPath ?? this.logoPath),
      ownerUserId: ownerUserId ?? this.ownerUserId,
      secretExcludeGlobs: secretExcludeGlobs ?? this.secretExcludeGlobs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewConcurrency: reviewConcurrency ?? this.reviewConcurrency,
      autoPublishReview: autoPublishReview ?? this.autoPublishReview,
      connectMode: connectMode ?? this.connectMode,
      connectUrl: connectUrl ?? this.connectUrl,
      githubAppId: githubAppId ?? this.githubAppId,
      deletedAt: deletedAt ?? this.deletedAt,
      storageState: storageState ?? this.storageState,
    );
  }
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
