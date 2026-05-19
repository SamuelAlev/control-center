import 'dart:async';

import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

class _FixedWorkspaceId extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceId(this._id);
  final String _id;
  @override
  String? build() => _id;
}

/// Wraps child with the same safety overrides as testWrap, but allows
/// the caller to control workspacesProvider.
Widget _wrap({
  required Widget child,
  required Stream<List<Workspace>> workspacesStream,
  String? activeId,
}) {
  return ProviderScope(
    overrides: [
      githubAuthTokenProvider.overrideWith((ref) => ''),
      activeWorkspaceProvider.overrideWith((ref) => null),
      activeRepoProvider.overrideWith((ref) => null),
      prReviewRepositoryProvider
          .overrideWith((ref) => const EmptyPrReviewRepository()),
      workspacesProvider.overrideWith((ref) => workspacesStream),
      activeWorkspaceIdProvider
          .overrideWith(() => _FixedWorkspaceId(activeId ?? 'ws1')),
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
      home: FTheme(
        data: FThemes.zinc.light.desktop,
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

  testWidgets('renders loading state', (tester) async {
    await tester.pumpWidget(
      _wrap(
        child: const WorkspaceListScreen(),
        // Stream that never emits keeps the provider in loading state.
        workspacesStream: StreamController<List<Workspace>>().stream,
      ),
    );
    await tester.pump();

    expect(find.byType(FCircularProgress), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
