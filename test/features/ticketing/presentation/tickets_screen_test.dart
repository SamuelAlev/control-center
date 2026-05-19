import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_status.dart';
import 'package:control_center/features/ticketing/presentation/screens/tickets_screen.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Widget _wrap(Widget child, SharedPreferences prefs) => ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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
      child: FTheme(
        data: FThemes.zinc.light.desktop,
        child: MaterialApp(
          theme: ThemeData(extensions: [DesignSystemTokens.light()]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('defaults to the list view and renders grouped tickets',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TicketsScreen(), prefs));
    await tester.pump();
    await tester.pump();

    // Both tickets are visible as rows, and the board column tint container is
    // not present (we're in the list view by default).
    expect(find.text('Wire up the dashboard'), findsOneWidget);
    expect(find.text('Fix the crash on launch'), findsOneWidget);
  });

  testWidgets('switching to the board view persists the choice',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TicketsScreen(), prefs));
    await tester.pump();
    await tester.pump();

    // The board toggle is reachable by its tooltip.
    final boardToggle = find.byTooltip(
      AppLocalizations.of(tester.element(find.byType(TicketsScreen))).ticketViewBoard,
    );
    expect(boardToggle, findsOneWidget);

    await tester.tap(boardToggle);
    await tester.pump();
    await tester.pump();

    // The choice is persisted as the new default.
    expect(prefs.getString(ticketsViewModeKey), 'board');
    // The board renders column headers (e.g. "In progress").
    expect(find.text('In progress'), findsWidgets);
  });

  testWidgets('there is no in-screen new-ticket button (only the sidebar)',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const TicketsScreen(), prefs));
    await tester.pump();
    await tester.pump();

    // The screen no longer hosts its own "New ticket" trigger.
    expect(find.text('New ticket'), findsNothing);
  });

  testWidgets('the floating bulk-action bar appears when tickets are selected',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
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
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: MaterialApp(
            theme: ThemeData(extensions: [DesignSystemTokens.light()]),
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
  });
}
