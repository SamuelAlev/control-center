import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';

/// A workspace-scoped, isolated copy-on-write worktree of a registered repo,
/// provisioned for one SPACE (the "closest unit" — a ticket discussion, PR
/// review space, or plain chat) and checked out on its own branch.
///
/// Lives under `<workspace>/<workspaceId>/spaces/<spaceId>/repos/<name>/` so an
/// agent cwd'd in that space sees all its repos under `repos/`. Every
/// conversation in the space shares this one checkout — a conversation is never
/// a key here.
///
/// Workspace isolation: every row carries a non-null [workspaceId] and is keyed
/// uniquely by `(workspaceId, spaceId, repoId)`. It is garbage-collected when
/// the unit ends (ticket done/won't-do, space deleted, PR merged).
class IsolatedRepo {
  /// Creates an [IsolatedRepo].
  IsolatedRepo({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.repoId,
    required this.path,
    required this.branch,
    required this.backend,
    required this.sourcePath,
    required this.createdAt,
    this.ticketId,
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError('IsolatedRepo.workspaceId must not be empty');
    }
    if (spaceId.isEmpty) {
      throw ArgumentError('IsolatedRepo.spaceId must not be empty');
    }
    if (repoId.isEmpty) {
      throw ArgumentError('IsolatedRepo.repoId must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// Owning workspace (never null — the isolation boundary).
  final String workspaceId;

  /// The conversation/space this worktree belongs to (the unit).
  final String spaceId;

  /// The source repo this is a copy of.
  final String repoId;

  /// Absolute path to the isolated worktree on disk.
  final String path;

  /// Branch checked out in the worktree (or a detached-ref label).
  final String branch;

  /// How the copy was produced.
  final RepoIsolationBackend backend;

  /// Absolute path to the original (untouched) repo this was copied from.
  final String sourcePath;

  /// Owning ticket id, when the unit is a ticket (for ticket-event GC mapping).
  final String? ticketId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Copy with overrides.
  IsolatedRepo copyWith({
    String? id,
    String? workspaceId,
    String? spaceId,
    String? repoId,
    String? path,
    String? branch,
    RepoIsolationBackend? backend,
    String? sourcePath,
    String? ticketId,
    DateTime? createdAt,
  }) {
    return IsolatedRepo(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      spaceId: spaceId ?? this.spaceId,
      repoId: repoId ?? this.repoId,
      path: path ?? this.path,
      branch: branch ?? this.branch,
      backend: backend ?? this.backend,
      sourcePath: sourcePath ?? this.sourcePath,
      ticketId: ticketId ?? this.ticketId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IsolatedRepo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          spaceId == other.spaceId &&
          repoId == other.repoId &&
          path == other.path &&
          branch == other.branch &&
          backend == other.backend &&
          sourcePath == other.sourcePath &&
          ticketId == other.ticketId;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    spaceId,
    repoId,
    path,
    branch,
    backend,
    sourcePath,
    ticketId,
  );
}
