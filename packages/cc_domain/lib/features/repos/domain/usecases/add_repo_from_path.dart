import 'package:cc_domain/core/domain/entities/git_repo_info.dart'
    show GitRepoInspectionException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/repo_events.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:uuid/uuid.dart';

/// Inspects a local folder via `git` and registers it as a [Repo].
class AddRepoFromPathUseCase {
  /// Creates an [AddRepoFromPathUseCase].
  ///
  /// When [_eventBus] is provided, publishes a [RepoAdded] event after the repo
  /// is persisted so the background code indexer can run.
  const AddRepoFromPathUseCase({
    required this._repository,
    required this._inspector,
    this._eventBus,
  });

  final RepoRepository _repository;
  final GitRepoInspectorPort _inspector;
  final DomainEventBus? _eventBus;

  /// Inspects [path], builds a [Repo] in [workspaceId], persists it and
  /// returns it.
  ///
  /// Throws [GitRepoInspectionException] when [path] is not a working tree
  /// whose `origin` remote resolves to a supported forge.
  ///
  /// Registering the same checkout in a second workspace produces a SECOND repo
  /// with its own id: repos are workspace-scoped, so a checkout's identity
  /// across workspaces is its path, never its id. Re-registering a path already
  /// present in [workspaceId] returns the existing repo instead of minting a
  /// duplicate.
  ///
  /// The [RepoAdded] event is scoped to [workspaceId] so the trigger
  /// dispatcher only starts the indexing pipeline in that workspace.
  ///
  /// [verify] runs before a new repo is persisted and refuses it by throwing;
  /// the repo it answers (with what the check learned, such as the forge's
  /// durable id) is the one persisted. [linkedBy] is the user linking it
  /// (`Repo.linkedBy`).
  ///
  /// An existing repo at the path is linked again, keeping its id, name and
  /// creation time, when [relink] says so (its stored link is no longer
  /// served): [verify] runs and the inspected remote and [linkedBy] replace
  /// what was stored.
  Future<Repo> execute(
    String path, {
    required String workspaceId,
    required String linkedBy,
    Future<Repo> Function(Repo repo)? verify,
    Future<bool> Function(Repo existing)? relink,
  }) async {
    final info = await _inspector.inspect(path);
    final existing = await _repository.findByPath(workspaceId, info.path);
    if (existing != null && !(await relink?.call(existing) ?? false)) {
      return existing;
    }
    final now = DateTime.now();
    final inspected = Repo(
      id: existing?.id ?? const Uuid().v4(),
      name: existing?.name ?? '${info.owner}/${info.repoName}',
      path: info.path,
      forge: info.forge,
      remoteOwner: info.owner,
      remoteName: info.repoName,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      linkedBy: linkedBy,
    );
    final repo = await verify?.call(inspected) ?? inspected;
    await _repository.upsert(workspaceId, repo);
    _eventBus?.publish(
      RepoAdded(
        repoId: repo.id,
        path: repo.path,
        workspaceId: workspaceId,
        occurredAt: now,
      ),
    );
    return repo;
  }
}
