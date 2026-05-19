import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:control_center/features/ticketing/presentation/widgets/new_ticket_dialog.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import '../../../../helpers/test_wrap.dart';

/// Minimal fake repository so we can construct a [TicketWorkflowService]
/// subclass.
class _FakeTicketRepository implements TicketRepository {
  @override
  Future<void> insert(Ticket ticket) async {}

  @override
  Future<void> update(Ticket ticket, {int? expectedVersion}) async {}

  @override
  Future<void> upsertMirror(Ticket ticket) async {}

  @override
  Future<void> delete(String ticketId, {required String workspaceId}) async {}

  @override
  Future<Ticket?> getById(String id) async => null;

  @override
  Future<Ticket?> getByExternal(
    TicketProvider provider,
    String externalKey,
  ) async => null;

  @override
  Future<List<Ticket>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async => [];

  @override
  Future<List<Ticket>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async => [];

  @override
  Future<List<Ticket>> forAgent(String workspaceId, String agentId) async => [];

  @override
  Future<List<Ticket>> childrenOf(
    String workspaceId,
    String parentTicketId,
  ) async => [];

  @override
  Stream<List<Ticket>> watchForWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Stream<List<Ticket>> watchByStatus(
    String workspaceId,
    TicketStatus status,
  ) => const Stream.empty();

  @override
  Stream<List<Ticket>> watchByAssignee(
    String workspaceId,
    String agentId,
  ) => const Stream.empty();

  @override
  Stream<List<Ticket>> watchForPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) => const Stream.empty();

  @override
  Future<void> addCollaborator(TicketCollaborator collaborator) async {}

  @override
  Future<void> removeCollaborator(String ticketId, String agentId) async {}

  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String ticketId) =>
      const Stream.empty();

  @override
  Future<List<TicketCollaborator>> getCollaborators(String ticketId) async => [];
}

class _CreateTicketCall {

  _CreateTicketCall({
    required this.workspaceId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignedAgentId,
    required this.projectId,
  });
  final String workspaceId;
  final String title;
  final String? description;
  final TicketPriority priority;
  final TicketStatus status;
  final String? assignedAgentId;
  final String? projectId;
}

/// Records [createTicket] calls so tests can assert what was submitted.
class _FakeTicketWorkflowService extends TicketWorkflowService {
  _FakeTicketWorkflowService()
      : super(
          repository: _FakeTicketRepository(),
          eventBus: DomainEventBus(),
        );

  final List<_CreateTicketCall> createCalls = [];

  Ticket nextTicket = Ticket(
    id: 'new-1',
    workspaceId: 'ws-1',
    title: 'test',
    status: TicketStatus.open,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Object? nextError;

  @override
  Future<Ticket> createTicket({
    required String workspaceId,
    required String title,
    String? id,
    String? description,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    TicketStatus status = TicketStatus.open,
    List<String> labels = const [],
    String? assignedAgentId,
    String? assignedTeamId,
    String? delegatedByAgentId,
    String? parentTicketId,
    String? projectId,
    String? channelId,
    ConversationMode mode = ConversationMode.chat,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
    Map<String, String> providerExtras = const {},
  }) async {
    createCalls.add(
      _CreateTicketCall(
        workspaceId: workspaceId,
        title: title,
        description: description,
        priority: priority,
        status: status,
        assignedAgentId: assignedAgentId,
        projectId: projectId,
      ),
    );
    if (nextError != null) {
      throw nextError!;
    }
    return nextTicket;
  }
}

/// A fake that blocks [createTicket] on a completer.
class _BlockingFakeWorkflowService extends _FakeTicketWorkflowService {
  _BlockingFakeWorkflowService(this.completer);

  final Completer<Ticket> completer;

  @override
  Future<Ticket> createTicket({
    required String workspaceId,
    required String title,
    String? id,
    String? description,
    TicketProvider provider = TicketProvider.local,
    TicketPriority priority = TicketPriority.none,
    TicketStatus status = TicketStatus.open,
    List<String> labels = const [],
    String? assignedAgentId,
    String? assignedTeamId,
    String? delegatedByAgentId,
    String? parentTicketId,
    String? projectId,
    String? channelId,
    ConversationMode mode = ConversationMode.chat,
    String? pipelineRunId,
    String? pipelineStepId,
    Map<String, dynamic>? expectedOutputSchema,
    Map<String, String> providerExtras = const {},
  }) async {
    createCalls.add(
      _CreateTicketCall(
        workspaceId: workspaceId,
        title: title,
        description: description,
        priority: priority,
        status: status,
        assignedAgentId: assignedAgentId,
        projectId: projectId,
      ),
    );
    return completer.future;
  }
}

/// Fixed workspace-id notifier so the dialog sees a non-null workspace.
class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String _id;

  @override
  String? build() => _id;
}

/// Wraps [child] with [testWrap] plus the dialog's provider overrides.
Widget _wrap(_FakeTicketWorkflowService fake, Widget child) {
  return ProviderScope(
    overrides: [
      activeWorkspaceIdProvider
          .overrideWith(() => _FixedWorkspaceId('ws-1')),
      workspaceAgentsProvider.overrideWith(
        (ref, workspaceId) => Stream.value(const <Agent>[]),
      ),
      workspaceProjectsProvider.overrideWith(
        (ref, workspaceId) => Stream.value(const <Project>[]),
      ),
      ticketWorkflowServiceProvider.overrideWith((ref) => fake),
      activeTicketProviderProvider
          .overrideWith((ref) => TicketProvider.local),
    ],
    child: testWrap(child),
  );
}

void main() {
  group('NewTicketDialog rendering', () {
    testWidgets('shows title, description, chips, and footer controls',
        (tester) async {
      final fake = _FakeTicketWorkflowService();
      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Form fields.
      expect(find.byType(TextField), findsNWidgets(2));
      // Chips area: status "To do", priority "None", assignee "Unassigned",
      // project "Project".
      expect(find.text('To do'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
      // Footer.
      expect(find.text('Create more'), findsOneWidget);

      expect(find.byType(FSwitch), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('title field is autofocused', (tester) async {
      final fake = _FakeTicketWorkflowService();
      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      final titleField =
          tester.widget<TextField>(find.byType(TextField).at(0));
      expect(titleField.autofocus, isTrue);
    });

    testWidgets('description field shows placeholder', (tester) async {
      final fake = _FakeTicketWorkflowService();
      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('Add description…'), findsOneWidget);
    });

    testWidgets('header shows new ticket label', (tester) async {
      final fake = _FakeTicketWorkflowService();
      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.text('New ticket'), findsOneWidget);
    });
  });

  group('NewTicketDialog validation', () {
    testWidgets('empty title does not call createTicket', (tester) async {
      final fake = _FakeTicketWorkflowService();
      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(fake.createCalls, isEmpty);
    });

    testWidgets('whitespace-only title does not call createTicket',
        (tester) async {
      final fake = _FakeTicketWorkflowService();
      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), '   ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(fake.createCalls, isEmpty);
    });
  });

  group('NewTicketDialog submission', () {
    testWidgets('valid title creates ticket with defaults', (tester) async {
      final fake = _FakeTicketWorkflowService();
      fake.nextTicket = Ticket(
        id: 't-abc',
        workspaceId: 'ws-1',
        title: 'Fix login bug',
        status: TicketStatus.open,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Fix login bug');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(fake.createCalls, hasLength(1));
      final call = fake.createCalls.single;
      expect(call.title, 'Fix login bug');
      expect(call.workspaceId, 'ws-1');
      expect(call.priority, TicketPriority.none);
      expect(call.status, TicketStatus.open);
      expect(call.assignedAgentId, isNull);
      expect(call.projectId, isNull);
      expect(call.description, isNull);
    });

    testWidgets('submits description when provided', (tester) async {
      final fake = _FakeTicketWorkflowService();
      fake.nextTicket = Ticket(
        id: 't-xyz',
        workspaceId: 'ws-1',
        title: 'Fix auth',
        status: TicketStatus.open,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Fix auth');
      await tester.enterText(
        find.byType(TextField).at(1),
        'The login flow is broken',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(fake.createCalls, hasLength(1));
      expect(fake.createCalls.single.description, 'The login flow is broken');
    });

    testWidgets('enter on title field submits', (tester) async {
      final fake = _FakeTicketWorkflowService();
      fake.nextTicket = Ticket(
        id: 't-enter',
        workspaceId: 'ws-1',
        title: 'Quick fix',
        status: TicketStatus.open,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Quick fix');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(fake.createCalls, hasLength(1));
      expect(fake.createCalls.single.title, 'Quick fix');
    });

    testWidgets('create more clears fields and keeps dialog open',
        (tester) async {
      final fake = _FakeTicketWorkflowService();
      fake.nextTicket = Ticket(
        id: 't-1',
        workspaceId: 'ws-1',
        title: 'First ticket',
        status: TicketStatus.open,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      // Toggle "Create more".
      await tester.tap(find.byType(FSwitch));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'First ticket');
      await tester.enterText(
        find.byType(TextField).at(1),
        'Some description',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(fake.createCalls, hasLength(1));

      // Fields cleared.
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
      // Dialog still visible.
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog without creating', (tester) async {
      final fake = _FakeTicketWorkflowService();
      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Something');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(fake.createCalls, isEmpty);
      expect(find.text('Create'), findsNothing);
    });

    testWidgets('shows snackbar on submission error', (tester) async {
      final fake = _FakeTicketWorkflowService();
      fake.nextError = Exception('Network failure');

      await tester.pumpWidget(
        _wrap(
          fake,
          Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showNewTicketDialog(context),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Will fail');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      // Dialog still open after error.
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('submit button shows progress while submitting', (tester) async {
      final completer = Completer<Ticket>();
      final fake = _BlockingFakeWorkflowService(completer);
      fake.nextTicket = Ticket(
        id: 't-slow',
        workspaceId: 'ws-1',
        title: 'Slow',
        status: TicketStatus.open,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider
                .overrideWith(() => _FixedWorkspaceId('ws-1')),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
            workspaceProjectsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Project>[]),
            ),
            ticketWorkflowServiceProvider.overrideWith((ref) => fake),
            activeTicketProviderProvider
                .overrideWith((ref) => TicketProvider.local),
          ],
          child: testWrap(
            Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showNewTicketDialog(context),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Slow');
      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(find.byType(FCircularProgress), findsOneWidget);

      completer.complete(Ticket(
        id: 't-slow',
        workspaceId: 'ws-1',
        title: 'Slow',
        status: TicketStatus.open,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await tester.pumpAndSettle();
    });
  });
}
