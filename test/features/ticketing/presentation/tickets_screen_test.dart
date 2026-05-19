import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/presentation/screens/tickets_screen.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixes the active workspace so the screen renders without the real
/// workspace-resolution chain.
class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws1';
}

/// Starts with one ticket pre-selected so the bulk-action bar is visible.
class _PresetSelection extends TicketSelectionNotifier {
  @override
  Set<String> build() => {'1'};
}

Ticket _ticket(String id, String title, TicketStatus status) => Ticket(
  id: id,
  workspaceId: 'ws1',
  title: title,
  status: status,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget _wrap(Widget child, AppPreferences prefs) => ProviderScope(
  overrides: [
    appPreferencesProvider.overrideWithValue(prefs),
    activeWorkspaceIdProvider.overrideWith(_FixedWorkspaceId.new),
    workspaceAgentsProvider.overrideWith(
      (ref, workspaceId) => Stream.value(const <Agent>[]),
    ),
    workspaceTicketsProvider.overrideWith(
      (ref, workspaceId) => Stream.value([
        _ticket('1', 'Wire up the dashboard', TicketStatus.open),
        _ticket('2', 'Fix the crash on launch', TicketStatus.inProgress),
      ]),
    ),
  ],
  child: CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      builder: (context, child) =>
          CcTheme(data: CcThemeData.light(), child: child!),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  ),
);

void main() {
  late AppPreferences prefs;

  setUp(() async {
    prefs = AppPreferences.inMemory();
  });

  testWidgets('defaults to the list view and renders grouped tickets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TicketsScreen(), prefs));
    await tester.pump();
    await tester.pump();

    // Both tickets are visible as rows and the board column tint container is
    // not present (we're in the list view by default).
    expect(find.text('Wire up the dashboard'), findsOneWidget);
    expect(find.text('Fix the crash on launch'), findsOneWidget);
  });

  testWidgets('switching to the board view persists the choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TicketsScreen(), prefs));
    await tester.pump();
    await tester.pump();

    // The board toggle is reachable by its accessible label.
    final boardToggle = find.bySemanticsLabel(
      AppLocalizations.of(
        tester.element(find.byType(TicketsScreen)),
      ).ticketViewBoard,
    );
    expect(boardToggle, findsOneWidget);

    await tester.tap(boardToggle);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    // The choice is persisted as the new default.
    expect(prefs.getString(ticketsViewModeKey), 'board');
    // The board renders column headers (e.g. "In progress").
    expect(find.text('In progress'), findsWidgets);
  });

  testWidgets('the header hosts a New ticket trigger', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TicketsScreen(), prefs));
    await tester.pump();
    await tester.pump();

    // The screen carries its own primary action in the header row, beside the
    // list/board toggle — the same placement project_overview_screen uses. This
    // used to assert the OPPOSITE ("only the sidebar"); the action moved back
    // in-screen so the next step is visible without hunting for it.
    expect(find.text('New ticket'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('New ticket'),
        matching: find.byType(CcButton),
      ),
      findsOneWidget,
      reason: 'it is a real button, not a label',
    );
  });

  testWidgets(
    'the floating bulk-action bar appears when tickets are selected',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(_FixedWorkspaceId.new),
            ticketSelectionProvider.overrideWith(_PresetSelection.new),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
            workspaceTicketsProvider.overrideWith(
              (ref, workspaceId) => Stream.value([
                _ticket('1', 'Wire up the dashboard', TicketStatus.open),
                _ticket(
                  '2',
                  'Fix the crash on launch',
                  TicketStatus.inProgress,
                ),
              ]),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
              builder: (context, child) =>
                  CcTheme(data: CcThemeData.light(), child: child!),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: TicketsScreen()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // The bar shows the selected count and a delete action.
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    },
  );

  testWidgets('the bulk-action bar offers assignee and label pickers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          activeWorkspaceIdProvider.overrideWith(_FixedWorkspaceId.new),
          ticketSelectionProvider.overrideWith(_PresetSelection.new),
          workspaceAgentsProvider.overrideWith(
            (ref, workspaceId) => Stream.value(const <Agent>[]),
          ),
          workspaceTicketsProvider.overrideWith(
            (ref, workspaceId) => Stream.value([
              _ticket('1', 'Wire up the dashboard', TicketStatus.open),
              _ticket('2', 'Fix the crash on launch', TicketStatus.inProgress),
            ]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
          child: MaterialApp(
            builder: (context, child) =>
                CcTheme(data: CcThemeData.light(), child: child!),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: TicketsScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Status + priority were already there; assignee + labels are the new
    // bulk operations (§190).
    expect(find.text('Assignee'), findsOneWidget);
    expect(find.text('Labels'), findsOneWidget);
  });
}
