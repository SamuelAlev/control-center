import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';

/// A workspace-scoped, isolated copy-on-write worktree of a registered repo,
/// provisioned for one conversation (the "closest unit" — a ticket discussion,
/// PR review channel, or plain chat) and checked out on its own branch.
///
/// Lives under `<workspace>/<workspaceId>/conversations/<channelId>/repos/<name>/`
/// so an agent cwd'd at the conversation root sees all its repos under `repos/`.
///
/// Workspace isolation: every row carries a non-null [workspaceId] and is keyed
/// uniquely by `(workspaceId, channelId, repoId)`. It is garbage-collected when
/// the unit ends (ticket done/won't-do, conversation deleted, PR merged).
class IsolatedRepo {
  /// Creates an [IsolatedRepo].
  IsolatedRepo({
    required this.id,
    required this.workspaceId,
    required this.channelId,
    required this.repoId,
    required this.path,
    required this.branch,
    required this.backend,
    required this.sourcePath,
    required this.createdAt,
    this.ticketId,
  })  : assert(workspaceId != '', 'IsolatedRepo.workspaceId must not be empty'),
        assert(channelId != '', 'IsolatedRepo.channelId must not be empty'),
        assert(repoId != '', 'IsolatedRepo.repoId must not be empty');

  /// Unique identifier.
  final String id;

  /// Owning workspace (never null — the isolation boundary).
  final String workspaceId;

  /// The conversation/channel this worktree belongs to (the unit).
  final String channelId;

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
    String? channelId,
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
      channelId: channelId ?? this.channelId,
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
          channelId == other.channelId &&
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
        channelId,
        repoId,
        path,
        branch,
        backend,
        sourcePath,
        ticketId,
      );
}
