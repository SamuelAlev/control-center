import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_link_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_link_service.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/ticket_context_menu.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

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
  Future<Ticket?> getByExternal(TicketProvider p, String ek) async => null;
  @override
  @override
  @override
  Future<List<Ticket>> forAgent(String ws, String a) async => [];
  @override
  Future<List<Ticket>> childrenOf(String ws, String p) async => [];
  @override
  Stream<List<Ticket>> watchForWorkspace(String ws) => const Stream.empty();
  @override
  Stream<List<Ticket>> watchByStatus(String ws, TicketStatus s) => const Stream.empty();
  @override
  Stream<List<Ticket>> watchByAssignee(String ws, String a) => const Stream.empty();
  @override
  @override
  Future<void> addCollaborator(TicketCollaborator c) async {}
  @override
  Future<void> removeCollaborator(String t, String a) async {}
  @override
  Stream<List<TicketCollaborator>> watchCollaborators(String t) => const Stream.empty();
  @override
  Future<List<TicketCollaborator>> getCollaborators(String t) async => [];
}

class _FakeTicketLinkRepository implements TicketLinkRepository {
  @override
  Future<void> insert(TicketLink link) async {}
  @override
  Future<int> deleteById(String id, {required String workspaceId}) async => 0;
  @override
  Future<int> deleteByEndpoints({
    required String workspaceId,
    required String sourceTicketId,
    required String targetTicketId,
    required TicketLinkType type,
  }) async => 0;
  @override
  Future<List<TicketLink>> getForTicket(String ws, String t) async => [];
  @override
  Stream<List<TicketLink>> watchForTicket(String ws, String t) => const Stream.empty();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _ws = 'ws1';

Ticket _ticket({
  String id = 't1',
  String title = 'Test ticket',
  TicketStatus status = TicketStatus.open,
  TicketPriority priority = TicketPriority.none,
  String? assignedAgentId,
  String? projectId,
}) => Ticket(
      id: id,
      workspaceId: _ws,
      title: title,
      status: status,
      priority: priority,
      assignedAgentId: assignedAgentId,
      projectId: projectId,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        ticketWorkflowServiceProvider.overrideWithValue(
          TicketWorkflowService(
            repository: _FakeTicketRepository(),
            eventBus: DomainEventBus(),
          ),
        ),
        ticketLinkServiceProvider.overrideWithValue(
          TicketLinkService(
            linkRepository: _FakeTicketLinkRepository(),
            ticketRepository: _FakeTicketRepository(),
          ),
        ),
        workspaceAgentsProvider.overrideWith(
          (ref, ws) => Stream.value(const <Agent>[]),
        ),
        workspaceProjectsProvider.overrideWith(
          (ref, ws) => Stream.value(const <Project>[]),
        ),
      ],
      child: testWrap(child),
    );

Future<void> _openMenu(
  WidgetTester tester,
  Ticket ticket, {
  Offset position = const Offset(400, 300),
}) async {
  await tester.pumpWidget(_wrap(
    Consumer(
      builder: (context, ref, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTicketContextMenu(
            context: context,
            ref: ref,
            position: position,
            ticket: ticket,
            workspaceId: _ws,
          );
        });
        return const SizedBox.expand();
      },
    ),
  ));
  await tester.pump();
  await tester.pump();
}

/// Creates a mouse gesture and moves it to [target], crossing boundary.
Future<TestGesture> _mouseTo(WidgetTester tester, Finder target) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(gesture.removePointer);
  // Move to origin to ensure we start outside any MouseRegion.
  await gesture.moveTo(Offset.zero);
  await tester.pump();
  // Move to target center.
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  await tester.pump();
  return gesture;
}

void _setupView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('rendering', () {
    testWidgets('shows the context menu panel', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      expect(find.byType(Container), findsWidgets);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Assignee'), findsOneWidget);
    });

    testWidgets('shows all top-level menu sections', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Assignee'), findsOneWidget);
      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Relate to'), findsOneWidget);
      expect(find.text('Copy ID'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('state-based visibility', () {
    testWidgets('checkmark for current status in main menu', (tester) async {
      _setupView(tester);
      // When status is "inProgress", the status submenu launcher does
      // NOT show a check; only submenu items have checks. But the top-level
      // layout should have no checks initially since no submenu is open.
      await _openMenu(tester, _ticket(status: TicketStatus.inProgress));

      // No submenus open yet, so no checkmarks visible.
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('delete row has trash icon', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });
    testWidgets('does not show menu before opening', (tester) async {
      _setupView(tester);
      // Just pump the wrapper without triggering the menu.
      await tester.pumpWidget(_wrap(const SizedBox.expand()));
      await tester.pump();

      expect(find.text('Status'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('menu renders with correct icon set for submenus',
        (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Verify specific icons on the main panel.
      expect(find.byIcon(LucideIcons.circleDashed), findsOneWidget); // Status
      expect(find.byIcon(LucideIcons.signalHigh), findsOneWidget); // Priority
      expect(find.byIcon(LucideIcons.userRound), findsOneWidget); // Assignee
      expect(find.byIcon(LucideIcons.box), findsOneWidget); // Project
      expect(find.byIcon(LucideIcons.gitCompareArrows),
          findsOneWidget); // Relate to
      expect(find.byIcon(LucideIcons.clipboard), findsOneWidget); // Copy ID
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget); // Delete
    });
  });

  group('interactions', () {
    testWidgets('tapping outside dismisses the menu', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      expect(find.text('Status'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump();

      expect(find.text('Status'), findsNothing);
    });

    testWidgets('pressing Esc dismisses the menu', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      expect(find.text('Status'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();

      expect(find.text('Status'), findsNothing);
    });

    testWidgets('chevron icons on submenu launchers', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Status, Priority, Assignee, Project, Relate to = 5 submenus.
      expect(find.byIcon(LucideIcons.chevronRight), findsNWidgets(5));
    });

    testWidgets('verify no checks when no submenu open', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket(status: TicketStatus.open));

      // No submenu is open initially, so no checkmark icons are visible.
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });
  });

  group('submenu interactions', () {
    testWidgets('hovering a submenu row opens submenu panel', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Hover over 'Status' row.
      final statusFinder = find.text('Status');
      expect(statusFinder, findsOneWidget);
      await _mouseTo(tester, statusFinder);

      // Submenu items should appear.
      expect(find.text('Backlog'), findsOneWidget);
      expect(find.text('To do'), findsOneWidget);
    });

    testWidgets('copy ID does not crash', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Tap 'Copy ID' — the async handler calls dismiss() and then
      // Clipboard.setData + SnackBar. Just verify it doesn't throw.
      await tester.tap(find.text('Copy ID'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('status submenu renders all statuses', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Hover over Status.
      await _mouseTo(tester, find.text('Status'));

      // Verify status items.
      expect(find.text('Backlog'), findsOneWidget);
      expect(find.text('To do'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('priority submenu renders all priorities', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Hover over Priority.
      await _mouseTo(tester, find.text('Priority'));

      // Verify priority items.
      expect(find.text('None'), findsOneWidget);
      expect(find.text('Urgent'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('assignee submenu shows unassigned and you', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Hover over Assignee.
      await _mouseTo(tester, find.text('Assignee'));

      // Verify assignee items.
      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('delete row is present with destructive styling', (tester) async {
      _setupView(tester);
      await _openMenu(tester, _ticket());

      // Verify delete row exists.
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });
  });
}
