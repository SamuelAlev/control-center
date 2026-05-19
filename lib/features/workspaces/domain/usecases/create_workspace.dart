import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/workspace_events.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:uuid/uuid.dart';

/// Input to [CreateWorkspaceUseCase].
class CreateWorkspaceCommand {
  /// Creates a [CreateWorkspaceCommand].
  const CreateWorkspaceCommand({required this.name, this.logoPath});

  /// User-supplied workspace name.
  final String name;

  /// Optional local file path to a logo image.
  final String? logoPath;
}

/// Creates a workspace. CEO agent seeding is handled reactively by an
/// event handler listening for [WorkspaceCreated].
class CreateWorkspaceUseCase {
  /// Creates a [CreateWorkspaceUseCase].
  ///
  /// When [filesystem] is provided and [CreateWorkspaceCommand.logoPath] is
  /// set, the source image is copied into the workspace's own directory so
  /// the workspace owns its asset — the persisted [Workspace.logoPath]
  /// points at the copy, not at the user-picked file.
  const CreateWorkspaceUseCase({
    required WorkspaceRepository repository,
    DomainEventBus? eventBus,
    WorkspaceFilesystemPort? filesystem,
  }) : _repository = repository,
       _eventBus = eventBus,
       _filesystem = filesystem;

  final WorkspaceRepository _repository;
  final DomainEventBus? _eventBus;
  final WorkspaceFilesystemPort? _filesystem;

  /// Execute.
  Future<Workspace> execute(CreateWorkspaceCommand command) async {
    final now = DateTime.now();
    final id = const Uuid().v4();

    // If we have a filesystem port and a picked logo, copy it into the
    // workspace dir so deleting the original doesn't leave us with a broken
    // reference. If the copy fails (source missing) the stored path is null.
    String? persistedLogo = command.logoPath;
    final fs = _filesystem;
    if (fs != null && command.logoPath != null) {
      persistedLogo = await fs.persistLogo(id, command.logoPath!);
    }

    final workspace = Workspace(
      id: id,
      name: command.name.trim(),
      logoPath: persistedLogo,

      createdAt: now,
      updatedAt: now,
    );

    await _repository.upsert(workspace);

    _eventBus?.publish(
      WorkspaceCreated(workspaceId: workspace.id, occurredAt: now),
    );

    return workspace;
  }
}
