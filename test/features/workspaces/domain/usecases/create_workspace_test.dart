import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_filesystem_port.dart';

void main() {
  group('CreateWorkspaceUseCase', () {
    late FakeWorkspaceRepository repository;

    setUp(() {
      repository = FakeWorkspaceRepository();
    });

    test('creates workspace with idle status', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      const command = CreateWorkspaceCommand(name: 'My Workspace');

      final workspace = await useCase.execute(command);

      expect(workspace.name, 'My Workspace');
    });

    test('trims whitespace from name', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      const command = CreateWorkspaceCommand(name: '  Padded Name  ');

      final workspace = await useCase.execute(command);

      expect(workspace.name, 'Padded Name');
    });

    test('persists workspace to repository', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      const command = CreateWorkspaceCommand(name: 'Persist Test');

      final workspace = await useCase.execute(command);

      expect(repository.saved, contains(workspace));
      expect(repository.saved.length, 1);
    });

    test('publishes WorkspaceCreated event when event bus provided', () async {
      final eventBus = DomainEventBus();
      final useCase = CreateWorkspaceUseCase(
        repository: repository,
        eventBus: eventBus,
      );

      final futureEvent = eventBus.on<WorkspaceCreated>().first;
      const command = CreateWorkspaceCommand(name: 'Event WS');

      final workspace = await useCase.execute(command);
      final event = await futureEvent;

      expect(event.workspaceId, workspace.id);
    });

    test('does not crash when event bus is null', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      const command = CreateWorkspaceCommand(name: 'No Event WS');

      final workspace = await useCase.execute(command);

      expect(workspace.name, 'No Event WS');
    });

    test('upserts the workspace before persisting the logo', () async {
      // Ordering is the contract, not an implementation detail: persisting the
      // logo is a workspace-scoped server op and the server only recognises the
      // caller as a member of the new workspace once the creating upsert has
      // recorded the owner membership row. Copying first was denied outright.
      final fs = _OrderRecordingFilesystem(repository);
      final useCase = CreateWorkspaceUseCase(
        repository: repository,
        filesystem: fs,
      );

      await useCase.execute(
        const CreateWorkspaceCommand(
          name: 'Ordered WS',
          logoPath: '/assets/logo.png',
        ),
      );

      expect(fs.workspaceExistedWhenLogoPersisted, isTrue);
    });

    test('stores the copied logo path rather than the picked one', () async {
      final fs = _OrderRecordingFilesystem(repository)..baseDir = '/data';
      final useCase = CreateWorkspaceUseCase(
        repository: repository,
        filesystem: fs,
      );

      final workspace = await useCase.execute(
        const CreateWorkspaceCommand(
          name: 'Copied WS',
          logoPath: '/assets/logo.png',
        ),
      );

      // The workspace owns its asset, so the stored path points into the
      // workspace's own directory, not at the file the user picked.
      expect(workspace.logoPath, '/data/${workspace.id}/logo');
      expect(repository.saved.last.logoPath, workspace.logoPath);
    });

    test('keeps the workspace when the logo copy fails', () async {
      final fs = _OrderRecordingFilesystem(repository)..failPersistLogo = true;
      final useCase = CreateWorkspaceUseCase(
        repository: repository,
        filesystem: fs,
      );

      final workspace = await useCase.execute(
        const CreateWorkspaceCommand(
          name: 'Logoless WS',
          logoPath: '/assets/logo.png',
        ),
      );

      // A logo is decoration; losing it must not lose the workspace, which by
      // then already exists on the server.
      expect(workspace.logoPath, isNull);
      expect(repository.saved.single.id, workspace.id);
    });

    test('includes logoPath in created workspace', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      const command = CreateWorkspaceCommand(
        name: 'Logo WS',
        logoPath: '/assets/logo.png',
      );

      final workspace = await useCase.execute(command);

      expect(workspace.logoPath, '/assets/logo.png');
      expect(workspace.hasLogo, isTrue);
    });

    test('generates unique UUID id for each workspace', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      final ws1 = await useCase.execute(
        const CreateWorkspaceCommand(name: 'WS1'),
      );
      final ws2 = await useCase.execute(
        const CreateWorkspaceCommand(name: 'WS2'),
      );

      expect(ws1.id, isNotEmpty);
      expect(ws2.id, isNotEmpty);
      expect(ws1.id, isNot(equals(ws2.id)));
    });

    test('sets createdAt and updatedAt to same time', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      final ws = await useCase.execute(
        const CreateWorkspaceCommand(name: 'Time WS'),
      );

      expect(ws.createdAt, ws.updatedAt);
    });

    test(
      'does not publish event when eventBus is null and null is safe',
      () async {
        final useCase = CreateWorkspaceUseCase(repository: repository);

        final ws = await useCase.execute(
          const CreateWorkspaceCommand(name: 'Silent'),
        );

        expect(ws.name, 'Silent');
        expect(repository.saved, contains(ws));
      },
    );

    test('CreateWorkspaceCommand constructor with logoPath', () {
      const cmd = CreateWorkspaceCommand(
        name: 'Test',
        logoPath: '/path/to/logo.png',
      );
      expect(cmd.name, 'Test');
      expect(cmd.logoPath, '/path/to/logo.png');
    });

    test('CreateWorkspaceCommand constructor without logoPath', () {
      const cmd = CreateWorkspaceCommand(name: 'Test');
      expect(cmd.name, 'Test');
      expect(cmd.logoPath, isNull);
    });
  });
}

/// A [FakeFilesystemPort] that records whether the workspace row was already
/// upserted by the time the logo was persisted and can fail that step.
class _OrderRecordingFilesystem extends FakeFilesystemPort {
  _OrderRecordingFilesystem(this._repository);

  final FakeWorkspaceRepository _repository;

  /// Set when the logo copy is asked to throw, standing in for an RPC failure.
  bool failPersistLogo = false;

  /// Null until [persistLogo] runs.
  bool? workspaceExistedWhenLogoPersisted;

  @override
  Future<String?> persistLogo(String workspaceId, String sourcePath) async {
    workspaceExistedWhenLogoPersisted = _repository.saved.any(
      (w) => w.id == workspaceId,
    );
    if (failPersistLogo) {
      throw Exception('logo copy failed');
    }
    return super.persistLogo(workspaceId, sourcePath);
  }
}
