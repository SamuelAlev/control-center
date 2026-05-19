import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
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
  /// When [_filesystem] is provided and [CreateWorkspaceCommand.logoPath] is
  /// set, the source image is copied into the workspace's own directory so
  /// the workspace owns its asset — the persisted [Workspace.logoPath]
  /// points at the copy, not at the user-picked file.
  const CreateWorkspaceUseCase({
    required this._repository,
    this._eventBus,
    this._filesystem,
  });

  final WorkspaceRepository _repository;
  final DomainEventBus? _eventBus;
  final WorkspaceFilesystemPort? _filesystem;

  /// Execute.
  Future<Workspace> execute(CreateWorkspaceCommand command) async {
    final now = DateTime.now();
    final id = const Uuid().v4();

    final fs = _filesystem;
    var workspace = Workspace(
      id: id,
      name: command.name.trim(),
      // With no filesystem port there is nothing to copy the image into, so the
      // picked path is stored as-is; otherwise it stays null until the copy
      // below succeeds and the stored path can point at the workspace's own one.
      logoPath: fs == null ? command.logoPath : null,
      createdAt: now,
      updatedAt: now,
    );

    // The row goes in FIRST, before anything targets the new workspace. Copying
    // the logo runs through a workspace-scoped op and the server recognises the
    // caller as a member of this workspace only once the creating upsert has
    // recorded the owner membership row — so persisting the logo first is denied
    // (as a non-member, or for want of a workspace to name at all when this is
    // the first workspace and nothing is open yet).
    await _repository.upsert(workspace);

    // Copy the picked logo into the workspace dir so deleting the original
    // doesn't leave a broken reference, then store the path of the copy. A
    // failure here leaves the stored path null rather than failing the whole
    // creation: the workspace exists and its logo can be set from the manager.
    if (fs != null && command.logoPath != null) {
      String? persistedLogo;
      try {
        persistedLogo = await fs.persistLogo(id, command.logoPath!);
      } on Exception {
        persistedLogo = null;
      }
      if (persistedLogo != null) {
        workspace = workspace.copyWith(
          logoPath: persistedLogo,
          updatedAt: DateTime.now(),
        );
        await _repository.upsert(workspace);
      }
    }

    _eventBus?.publish(
      WorkspaceCreated(workspaceId: workspace.id, occurredAt: now),
    );

    return workspace;
  }
}
