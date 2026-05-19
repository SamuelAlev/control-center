import 'package:control_center/core/domain/entities/git_repo_info.dart'
    show GitRepoInspectionException;
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/repo_events.dart';
import 'package:control_center/core/domain/ports/git_repo_inspector_port.dart';
import 'package:control_center/core/domain/repositories/repo_repository.dart';
import 'package:uuid/uuid.dart';

/// Inspects a local folder via `git` and registers it as a [Repo].
class AddRepoFromPathUseCase {
  /// Creates an [AddRepoFromPathUseCase].
  ///
  /// When [eventBus] is provided, publishes a [RepoAdded] event after the repo
  /// is persisted so the background code indexer can run.
  const AddRepoFromPathUseCase({
    required RepoRepository repository,
    required GitRepoInspectorPort inspector,
    DomainEventBus? eventBus,
  }) : _repository = repository,
       _inspector = inspector,
       _eventBus = eventBus;

  final RepoRepository _repository;
  final GitRepoInspectorPort _inspector;
  final DomainEventBus? _eventBus;

  /// Inspects [path], builds a [Repo], persists it, and returns it.
  ///
  /// Throws [GitRepoInspectionException] when [path] is not a github.com
  /// working tree.
  ///
  /// The [RepoAdded] event is scoped to [workspaceId] so the trigger
  /// dispatcher only starts the indexing pipeline in that workspace.
  Future<Repo> execute(String path, {required String workspaceId}) async {
    final info = await _inspector.inspect(path);
    final now = DateTime.now();
    final repo = Repo(
      id: const Uuid().v4(),
      name: '${info.owner}/${info.repoName}',
      path: info.path,

      githubOwner: info.owner,
      githubRepoName: info.repoName,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(repo);
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

