import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/workspace_events.dart';
import 'package:control_center/features/workspaces/domain/usecases/create_workspace.dart';

import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_workspace_repository.dart';

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

    test('does not publish event when eventBus is null and null is safe', () async {
      final useCase = CreateWorkspaceUseCase(repository: repository);

      final ws = await useCase.execute(
        const CreateWorkspaceCommand(name: 'Silent'),
      );

      expect(ws.name, 'Silent');
      expect(repository.saved, contains(ws));
    });

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
