import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/project_repository.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/presentation/screens/project_overview_screen.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String _id;

  @override
  String? build() => _id;
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this._projects);
  final List<Project> _projects;

  @override
  Future<void> insert(Project project) async {}

  @override
  Future<int> update(Project project) async => 0;

  @override
  Future<int> delete(String projectId, {required String workspaceId}) async =>
      0;

  @override
  Future<Project?> getById(String id) async => null;

  @override
  Future<List<Project>> getForWorkspace(String workspaceId) async => _projects;

  @override
  Stream<List<Project>> watchForWorkspace(String workspaceId) =>
      Stream.value(_projects);
}

Project _project({
  String id = 'p1',
  String workspaceId = 'ws1',
  String name = 'Test Project',
  String? description,
  ProjectStatus status = ProjectStatus.active,
}) =>
    Project(
      id: id,
      workspaceId: workspaceId,
      name: name,
      description: description,
      status: status,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Ticket _ticket({
  required String id,
  String workspaceId = 'ws1',
  String projectId = 'p1',
  required String title,
  required TicketStatus status,
  String? assignedAgentId,
}) =>
    Ticket(
      id: id,
      workspaceId: workspaceId,
      projectId: projectId,
      title: title,
      status: status,
      assignedAgentId: assignedAgentId,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

/// Wraps [child] with outer overrides, then through [testWrap].
Widget _wrap(
  Widget child, {
  required String workspaceId,
  required List<Project> projects,
  required List<Ticket> tickets,
  List<Agent> agents = const [],
}) =>
    ProviderScope(
      overrides: [
        activeWorkspaceIdProvider
            .overrideWith(() => _FixedWorkspaceId(workspaceId)),
        projectRepositoryProvider
            .overrideWithValue(_FakeProjectRepository(projects)),
        workspaceTicketsProvider.overrideWith(
          (ref, wsId) => Stream.value(tickets),
        ),
        workspaceAgentsProvider.overrideWith(
          (ref, wsId) => Stream.value(agents),
        ),
      ],
      child: testWrap(child),
    );

void main() {
  // ── Empty / missing states ────────────────────────────────────────

  testWidgets('shows empty state when there is no active workspace',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: '',
      projects: [],
      tickets: [],
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('shows empty state when the project is not found',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [],
      tickets: [],
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('No projects yet'), findsOneWidget);
  });

  testWidgets('shows empty-tickets state when project has no tickets',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Empty Project');

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: [],
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Empty Project'), findsOneWidget);
    expect(find.text('No tickets in this project yet'), findsOneWidget);
  });

  // ── Populated project ─────────────────────────────────────────────

  testWidgets('renders project header and tickets grouped by status',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'My Project', description: 'A test project');

    final tickets = [
      _ticket(id: 't1', title: 'Open ticket', status: TicketStatus.open),
      _ticket(
          id: 't2', title: 'In progress ticket', status: TicketStatus.inProgress),
      _ticket(id: 't3', title: 'Done ticket', status: TicketStatus.done),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Project name and description are visible.
    expect(find.text('My Project'), findsOneWidget);
    expect(find.text('A test project'), findsOneWidget);

    // Progress bar text: 1 done out of 3 (only done is terminal).
    expect(find.text('1 of 3 done'), findsOneWidget);

    // Status group headers (l10n labels).
    expect(find.text('To do'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Ticket titles.
    expect(find.text('Open ticket'), findsOneWidget);
    expect(find.text('In progress ticket'), findsOneWidget);
    expect(find.text('Done ticket'), findsOneWidget);
  });

  testWidgets('shows progress 0 when no tickets are terminal', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Progress Test');
    final tickets = [
      _ticket(id: 't1', title: 'Backlog ticket', status: TicketStatus.backlog),
      _ticket(id: 't2', title: 'Open ticket', status: TicketStatus.open),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('0 of 2 done'), findsOneWidget);
  });

  testWidgets('shows full progress when all tickets are terminal',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Done Project');
    final tickets = [
      _ticket(id: 't1', title: 'Done 1', status: TicketStatus.done),
      _ticket(id: 't2', title: 'Done 2', status: TicketStatus.done),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('2 of 2 done'), findsOneWidget);
  });

  // ── Status folding (blocked → inProgress, failed/cancelled → done) ─

  testWidgets('folds blocked tickets into the in-progress column',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Folding Test');
    final tickets = [
      _ticket(id: 't1', title: 'Blocked ticket', status: TicketStatus.blocked),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Blocked'), findsNothing);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Blocked ticket'), findsOneWidget);
  });

  testWidgets('folds failed and cancelled tickets into the done column',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Terminal Folder');
    final tickets = [
      _ticket(id: 't1', title: 'Failed task', status: TicketStatus.failed),
      _ticket(
          id: 't2', title: 'Cancelled task', status: TicketStatus.cancelled),
      _ticket(id: 't3', title: 'Really done', status: TicketStatus.done),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Failed'), findsNothing);
    expect(find.text('Cancelled'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('3 of 3 done'), findsOneWidget);

    expect(find.text('Failed task'), findsOneWidget);
    expect(find.text('Cancelled task'), findsOneWidget);
    expect(find.text('Really done'), findsOneWidget);
  });

  // ── Empty columns hidden ──────────────────────────────────────────

  testWidgets('hides board columns that have no tickets', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Sparse Project');
    final tickets = [
      _ticket(id: 't1', title: 'Only to do', status: TicketStatus.open),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('To do'), findsOneWidget);
    expect(find.text('Backlog'), findsNothing);
    expect(find.text('In progress'), findsNothing);
    expect(find.text('In review'), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  // ── Assignee display ──────────────────────────────────────────────

  testWidgets('shows assignee avatar when ticket has assigned agent',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Assignee Project');
    final tickets = [
      _ticket(
        id: 't1',
        title: 'Assigned ticket',
        status: TicketStatus.inProgress,
        assignedAgentId: 'agent-1',
      ),
    ];
    final agents = [
      Agent(
        id: 'agent-1',
        name: 'Alice',
        title: 'Engineer',
        agentMdPath: '/agents/alice.md',
        workspaceId: 'ws1',
        skills: AgentSkills([]),
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
      agents: agents,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('Assigned ticket'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  // ── Archived project ──────────────────────────────────────────────

  testWidgets('shows project status badge based on project status',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(
      name: 'Archived Project',
      status: ProjectStatus.archived,
    );

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: [],
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Archived Project'), findsOneWidget);
  });

  // ── Project without description ───────────────────────────────────

  testWidgets('omits the description when project has none', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'No Desc');

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: [],
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('No Desc'), findsOneWidget);
    expect(find.text('No tickets in this project yet'), findsOneWidget);
  });

  // ── Tickets from other projects are excluded ─────────────────────

  testWidgets('excludes tickets that belong to other projects',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final project = _project(name: 'Filtered Project');
    final tickets = [
      _ticket(
          id: 't1', title: 'My ticket', status: TicketStatus.open,
          projectId: 'p1'),
      _ticket(
          id: 't2', title: 'Other project ticket', status: TicketStatus.open,
          projectId: 'p2'),
    ];

    await tester.pumpWidget(_wrap(
      const ProjectOverviewScreen(projectId: 'p1'),
      workspaceId: 'ws1',
      projects: [project],
      tickets: tickets,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('My ticket'), findsOneWidget);
    expect(find.text('Other project ticket'), findsNothing);
  });
}
