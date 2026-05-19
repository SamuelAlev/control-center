import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/project.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_link.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_properties_rail.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_property_pickers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

/// A [PrsByRepoNotifier] that always returns an empty state without
/// watching any real providers (no database, no API, no CLI probe).
class _EmptyPrsByRepoNotifier extends PrsByRepoNotifier {
  @override
  Future<PrsByRepoState> build() async => const PrsByRepoState(
        repos: [],
        hasMore: {},
        nextPage: {},
        loadingMore: {},
      );
}

/// Stub [TicketRepository] that no-ops all mutations and returns empty
/// streams so the [TicketPropertiesRail] renders without touching real
/// storage.
class _StubTicketRepository implements TicketRepository {
  const _StubTicketRepository();

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
  Future<Ticket?> getByExternal(TicketProvider p, String ek) async => null;
  @override
  Future<List<Ticket>> forPipelineRun(String w, String pid) async => [];
  @override
  Future<List<Ticket>> forPipelineStep(String w, String r, String s) async =>
      [];
  @override
  Future<List<Ticket>> forAgent(String w, String a) async => [];
  @override
  Future<List<Ticket>> childrenOf(String w, String p) async => [];
  @override
  Stream<List<Ticket>> watchForWorkspace(String w) => const Stream.empty();
  @override
  Stream<List<Ticket>> watchByStatus(String w, TicketStatus s) =>
      const Stream.empty();
  @override
  Stream<List<Ticket>> watchByAssignee(String w, String a) =>
      const Stream.empty();
  @override
  Stream<List<Ticket>> watchForPipelineRun(String w, String pid) =>
      const Stream.empty();
  @override
  Future<void> addCollaborator(TicketCollaborator c) async {}
  @override
  Future<void> removeCollaborator(String t, String a) async {}
  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String t) =>
      const Stream.empty();
  @override
  Future<List<TicketCollaborator>> getCollaborators(String t) async => [];
}

Agent _agent(String id, String name) => Agent(
      id: id,
      name: name,
      title: name,
      agentMdPath: '/agents/$id.md',
      workspaceId: 'ws1',
      skills: AgentSkills([]),
      createdAt: DateTime(2026),
    );

Ticket _ticket({
  String id = 't1',
  String title = 'Test Ticket',
  TicketStatus status = TicketStatus.open,
  TicketPriority priority = TicketPriority.none,
  String? assignedAgentId,
  String? projectId,
  List<TicketCollaborator> collaborators = const [],
}) =>
    Ticket(
      id: id,
      workspaceId: 'ws1',
      title: title,
      status: status,
      priority: priority,
      assignedAgentId: assignedAgentId,
      projectId: projectId,
      collaborators: collaborators,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _wrapRail(Ticket ticket, {List<Agent> agents = const []}) {
  const repo = _StubTicketRepository();
  final bus = DomainEventBus();
  final workflow = TicketWorkflowService(repository: repo, eventBus: bus);

  return ProviderScope(
    overrides: [
      ticketRepositoryProvider.overrideWithValue(repo),
      ticketWorkflowServiceProvider.overrideWithValue(workflow),
      workspaceAgentsProvider.overrideWith(
        (ref, workspaceId) => Stream.value(agents),
      ),
      workspaceProjectsProvider.overrideWith(
        (ref, workspaceId) => Stream.value(const <Project>[]),
      ),
      ticketCollaboratorsProvider(ticket.id).overrideWith(
        (ref) => Stream.value(ticket.collaborators),
      ),
      ticketLinksProvider(
        (workspaceId: ticket.workspaceId, ticketId: ticket.id),
      ).overrideWith((ref) => Stream.value(const <TicketLink>[])),
      workspaceTicketsProvider.overrideWith(
        (ref, workspaceId) => const Stream<List<Ticket>>.empty(),
      ),
      prsByRepoProvider.overrideWith(_EmptyPrsByRepoNotifier.new),
    ],
    child: testWrap(
      TicketPropertiesRail(
        ticket: ticket,
        workspaceId: ticket.workspaceId,
      ),
    ),
  );
}

void main() {
  group('TicketPropertiesRail', () {
    // --- Property display ---

    testWidgets('renders property labels', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Assignee'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
    });

    testWidgets('renders status labels for each status', (tester) async {
      const statuses = [
        TicketStatus.backlog,
        TicketStatus.open,
        TicketStatus.inProgress,
        TicketStatus.blocked,
        TicketStatus.inReview,
        TicketStatus.done,
        TicketStatus.cancelled,
      ];
      for (final s in statuses) {
        await tester.pumpWidget(_wrapRail(_ticket(status: s)));
        expect(tester.takeException(), isNull,
            reason: 'Render threw for status $s');
      }
    });

    testWidgets('renders all priority levels', (tester) async {
      for (final p in TicketPriority.values) {
        await tester.pumpWidget(_wrapRail(_ticket(priority: p)));
        expect(tester.takeException(), isNull,
            reason: 'Render threw for priority $p');
      }
    });

    testWidgets('renders unassigned when no assignee', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket(assignedAgentId: null)));
      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets('renders user assignee as You', (tester) async {
      await tester.pumpWidget(
        _wrapRail(_ticket(assignedAgentId: TicketCollaborator.userSentinel)),
      );
      expect(find.text('You'), findsAtLeast(1));
    });

    testWidgets('renders no project when unset', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket(projectId: null)));
      expect(find.text('No project'), findsOneWidget);
    });

    // --- Collaborators ---

    testWidgets('shows no collaborators when empty', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket(collaborators: [])));
      expect(find.text('No collaborators yet'), findsOneWidget);
    });

    testWidgets('renders collaborator names', (tester) async {
      final ticket = _ticket(
        collaborators: [
          TicketCollaborator(
            id: 'c1',
            ticketId: 't1',
            agentId: 'agent-1',
            role: TicketCollaboratorRole.collaborator,
            joinedAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      await tester.pumpWidget(
        _wrapRail(ticket, agents: [_agent('agent-1', 'Alice')]),
      );
      await tester.pump();

      expect(find.text('Alice'), findsAtLeast(1));
    });

    // --- Sub-cards ---

    testWidgets('renders linked PRs section', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));
      expect(find.text('Linked pull requests'), findsOneWidget);
    });

    testWidgets('renders relations section', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));
      expect(find.text('Relations'), findsOneWidget);
    });

    // --- Delete ---

    testWidgets('renders delete button', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));
      expect(find.text('Delete ticket'), findsOneWidget);
    });

    testWidgets('delete button opens confirmation dialog', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));

      await tester.tap(find.text('Delete ticket'));
      await tester.pumpAndSettle();

      expect(find.text('Delete ticket'), findsAtLeast(2));
    });

    testWidgets('property picker triggers render', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));

      expect(find.byType(TicketTriggerChip), findsNWidgets(4));
    });

    testWidgets('add collaborator section renders', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));

      expect(find.text('Add collaborator'), findsOneWidget);
      expect(find.byIcon(LucideIcons.userPlus), findsOneWidget);
    });

    testWidgets('relations card renders', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));

      expect(find.text('Relations'), findsOneWidget);
    });

    testWidgets('linked PRs card renders', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));

      expect(find.text('Linked pull requests'), findsOneWidget);
    });

    testWidgets('collaborator name renders for non-user collaborator',
        (tester) async {
      final ticket = _ticket(
        collaborators: [
          TicketCollaborator(
            id: 'c1',
            ticketId: 't1',
            agentId: 'agent-bob',
            role: TicketCollaboratorRole.collaborator,
            joinedAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      await tester.pumpWidget(
        _wrapRail(ticket, agents: [_agent('agent-bob', 'Bob')]),
      );
      await tester.pump();

      expect(find.text('Bob'), findsAtLeast(1));
    });

    testWidgets('collaborator shows as You for isUser', (tester) async {
      final ticket = _ticket(
        collaborators: [
          TicketCollaborator(
            id: 'c1',
            ticketId: 't1',
            agentId: TicketCollaborator.userSentinel,
            role: TicketCollaboratorRole.collaborator,
            joinedAt: DateTime(2026, 1, 1),
          ),
        ],
      );
      await tester.pumpWidget(_wrapRail(ticket));
      await tester.pump();

      // The collaborator name should show 'You' since isUser is true.
      expect(find.text('You'), findsAtLeast(1));
    });

    testWidgets('delete dialog cancel does not delete', (tester) async {
      await tester.pumpWidget(_wrapRail(_ticket()));

      await tester.tap(find.text('Delete ticket'));
      await tester.pumpAndSettle();

      // Dialog is open; tap Cancel.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The rail should still show the delete button (ticket not deleted).
      expect(find.text('Delete ticket'), findsOneWidget);
    });
  });
}
