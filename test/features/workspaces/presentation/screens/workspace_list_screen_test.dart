import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String _id;
  @override
  String? build() => _id;
}

/// Records the reorder writes the rail's drag-to-reorder issues. Every other
/// member is unreachable in these tests (the list comes from the overridden
/// `workspacesProvider`), so it throws loudly rather than silently answering.
class _RecordingWorkspaceRepository implements WorkspaceRepository {
  final List<List<String>> reorders = [];

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {
    reorders.add(List.of(orderedIds));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Wraps child with the same safety overrides as testWrap, but allows
/// the caller to control workspacesProvider.
Widget _wrap({
  required Widget child,
  required Stream<List<Workspace>> workspacesStream,
  String? activeId,
  Workspace? activeWorkspace,
  WorkspaceRepository? workspaceRepository,
}) {
  return ProviderScope(
    overrides: [
      if (workspaceRepository != null)
        workspaceRepositoryProvider.overrideWithValue(workspaceRepository),
      githubAuthTokenProvider.overrideWith((ref) => ''),
      // The sidebar's workspace chip reads the cold-start display cache when
      // the workspaces stream hasn't emitted yet; keep it in-memory.
      appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
      activeWorkspaceProvider.overrideWith((ref) => activeWorkspace),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider.overrideWith(
        (ref) => const EmptyPrReviewRepository(),
      ),
      workspacesProvider.overrideWith((ref) => workspacesStream),
      // Per-row repo + agent counts read reposForWorkspaceProvider /
      // workspaceAgentsProvider, which now flow over the RPC-flipped repository
      // providers (composition flip) and would try to open an in-process host.
      // Stub both to empty streams — the counts are presentational and not
      // under test here.
      reposForWorkspaceProvider.overrideWith((ref, _) => const Stream.empty()),
      workspaceAgentsProvider.overrideWith((ref, _) => const Stream.empty()),
      activeWorkspaceIdProvider.overrideWith(
        () => _FixedWorkspaceId(activeId ?? 'ws1'),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  final testWorkspace = Workspace(
    id: 'ws1',
    name: 'Test Workspace',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testWorkspace2 = Workspace(
    id: 'ws2',
    name: 'Second Workspace',
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 2, 1),
  );

  testWidgets('renders empty state when no workspaces', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const WorkspaceListScreen(),
        workspacesStream: Stream.value(const <Workspace>[]),
      ),
    );
    await tester.pump();

    expect(find.text('No workspace'), findsOneWidget);
    expect(find.text('Add workspace'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets(
    'renders the global sidebar empty with the select-workspace placeholder',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          child: const WorkspaceListScreen(),
          workspacesStream: Stream.value([testWorkspace, testWorkspace2]),
          activeId: 'ws1',
          // Simulates the persisted last-active workspace resolving on this
          // workspace-less route: the chip must STILL invite selection rather
          // than show the previously chosen workspace.
          activeWorkspace: testWorkspace,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The global sidebar is present …
      final sidebar = find.byType(CcSidebar);
      expect(sidebar, findsOneWidget);
      // … with no nav items inside …
      expect(
        find.descendant(of: sidebar, matching: find.byType(CcSidebarItem)),
        findsNothing,
      );
      // … and its workspace switcher invites selection (no active workspace
      // on this route), with the 3-lines glyph instead of a workspace avatar.
      expect(
        find.descendant(of: sidebar, matching: find.text('Select a workspace')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sidebar, matching: find.text('Test Workspace')),
        findsNothing,
      );
      expect(
        find.descendant(of: sidebar, matching: find.byIcon(AppIcons.menu)),
        findsOneWidget,
      );

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 50));
    },
  );

  testWidgets('renders workspace list when workspaces exist', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const WorkspaceListScreen(),
        workspacesStream: Stream.value([testWorkspace, testWorkspace2]),
        activeId: 'ws1',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Test Workspace'), findsAtLeastNWidgets(1));
    expect(find.text('Second Workspace'), findsAtLeastNWidgets(1));

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('the rail renders workspaces in the persisted order', (
    tester,
  ) async {
    // The stream carries the server's manual order; the rail must render it
    // verbatim rather than re-sorting by name or update time.
    await tester.pumpWidget(
      _wrap(
        child: const WorkspaceListScreen(),
        workspacesStream: Stream.value([testWorkspace2, testWorkspace]),
        activeId: 'ws1',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final second = tester.getTopLeft(find.text('Second Workspace').first).dy;
    final first = tester.getTopLeft(find.text('Test Workspace').first).dy;
    expect(second, lessThan(first));

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('dragging a row persists the new workspace order', (
    tester,
  ) async {
    final repository = _RecordingWorkspaceRepository();
    await tester.pumpWidget(
      _wrap(
        child: const WorkspaceListScreen(),
        workspacesStream: Stream.value([testWorkspace, testWorkspace2]),
        activeId: 'ws1',
        workspaceRepository: repository,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Drag the first row's grip handle below the second row.
    final handle = find.byIcon(AppIcons.gripVertical).first;
    final rowHeight = tester.getSize(find.byType(WorkspaceAvatar).first).height;
    // The handle is a ReorderableDragStartListener, so the drag begins on the
    // first move — no long-press delay to wait out. Moving in small steps (as
    // a real pointer does) is what lets the list settle on the drop target.
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 50));
    for (var moved = 0.0; moved < rowHeight * 2; moved += 8) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.reorders, [
      ['ws2', 'ws1'],
    ]);

    // The optimistic order holds while the write is in flight, so the dragged
    // row does not snap back under the cursor.
    final second = tester.getTopLeft(find.text('Second Workspace').first).dy;
    final first = tester.getTopLeft(find.text('Test Workspace').first).dy;
    expect(second, lessThan(first));

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('renders loading state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const WorkspaceListScreen(),
        // Stream that never emits keeps the provider in loading state.
        workspacesStream: StreamController<List<Workspace>>().stream,
      ),
    );
    await tester.pump();

    expect(find.byType(CcSpinner), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
